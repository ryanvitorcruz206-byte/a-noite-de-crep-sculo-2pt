-- Bootstrap do núcleo de campanhas do Noite de Crepúsculo.
-- Este arquivo cobre profiles, campaigns e campaign_members.
-- As demais tabelas de jogo devem receber migrations próprias antes de provisionar
-- um ambiente novo que precise reproduzir o banco completo.

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;
create schema if not exists private;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Aventureiro',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.campaigns (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  description text not null default '',
  ruleset text not null default 'hybrid'
    check (ruleset in ('dnd', 'paranormal', 'hybrid', 'custom')),
  join_code text not null unique default upper(substr(encode(extensions.gen_random_bytes(8), 'hex'), 1, 10)),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.campaign_members (
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'player' check (role in ('master', 'player')),
  joined_at timestamptz not null default now(),
  primary key (campaign_id, user_id)
);

create index if not exists campaigns_owner_created_idx
  on public.campaigns(owner_id, created_at desc);
create index if not exists campaign_members_user_idx
  on public.campaign_members(user_id, joined_at desc);

create or replace function public.handle_new_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data->>'display_name', ''),
      nullif(new.raw_user_meta_data->>'full_name', ''),
      'Aventureiro'
    )
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
after insert on auth.users
for each row execute function public.handle_new_profile();

create or replace function private.is_campaign_member(p_campaign_id uuid, p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.campaign_members m
    where m.campaign_id = p_campaign_id and m.user_id = p_user_id
  );
$$;

create or replace function private.is_campaign_master(p_campaign_id uuid, p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.campaign_members m
    where m.campaign_id = p_campaign_id and m.user_id = p_user_id and m.role = 'master'
  );
$$;

create or replace function private.are_campaign_mates(p_other_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.campaign_members mine
    join public.campaign_members theirs on theirs.campaign_id = mine.campaign_id
    where mine.user_id = auth.uid() and theirs.user_id = p_other_user_id
  );
$$;

create or replace function public.handle_new_campaign_master()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.campaign_members(campaign_id, user_id, role)
  values (new.id, new.owner_id, 'master')
  on conflict (campaign_id, user_id) do update set role = 'master';
  return new;
end;
$$;

drop trigger if exists on_campaign_created_add_master on public.campaigns;
create trigger on_campaign_created_add_master
after insert on public.campaigns
for each row execute function public.handle_new_campaign_master();

create or replace function public.join_campaign_by_code(p_code text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_campaign_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Você precisa entrar na sua conta.';
  end if;

  select c.id into v_campaign_id
  from public.campaigns c
  where upper(c.join_code) = upper(trim(p_code)) and c.is_active = true;

  if v_campaign_id is null then
    raise exception 'Código de campanha inválido ou inativo.';
  end if;

  insert into public.campaign_members(campaign_id, user_id, role)
  values (v_campaign_id, auth.uid(), 'player')
  on conflict (campaign_id, user_id) do nothing;

  return v_campaign_id;
end;
$$;

alter table public.profiles enable row level security;
alter table public.campaigns enable row level security;
alter table public.campaign_members enable row level security;

grant select, update on public.profiles to authenticated;
grant select, insert, update, delete on public.campaigns to authenticated;
grant select, insert, update, delete on public.campaign_members to authenticated;

drop policy if exists "profiles read self or tablemates" on public.profiles;
create policy "profiles read self or tablemates" on public.profiles
for select to authenticated
using (id = (select auth.uid()) or private.are_campaign_mates(id));

drop policy if exists "profiles update self" on public.profiles;
create policy "profiles update self" on public.profiles
for update to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

drop policy if exists "campaigns create own" on public.campaigns;
create policy "campaigns create own" on public.campaigns
for insert to authenticated
with check (owner_id = (select auth.uid()));

drop policy if exists "campaigns read members" on public.campaigns;
create policy "campaigns read members" on public.campaigns
for select to authenticated
using (owner_id = (select auth.uid()) or private.is_campaign_member(id));

drop policy if exists "campaigns update master" on public.campaigns;
create policy "campaigns update master" on public.campaigns
for update to authenticated
using (owner_id = (select auth.uid()))
with check (owner_id = (select auth.uid()));

drop policy if exists "campaigns delete owner" on public.campaigns;
create policy "campaigns delete owner" on public.campaigns
for delete to authenticated
using (owner_id = (select auth.uid()));

drop policy if exists "members read campaign" on public.campaign_members;
create policy "members read campaign" on public.campaign_members
for select to authenticated
using (private.is_campaign_member(campaign_id));

drop policy if exists "master manage members" on public.campaign_members;
create policy "master manage members" on public.campaign_members
for all to authenticated
using (private.is_campaign_master(campaign_id))
with check (private.is_campaign_master(campaign_id));

drop policy if exists "members leave own campaign" on public.campaign_members;
create policy "members leave own campaign" on public.campaign_members
for delete to authenticated
using (user_id = (select auth.uid()) and role = 'player');

revoke all on schema private from public, anon;
grant usage on schema private to authenticated;
revoke all on function private.is_campaign_member(uuid, uuid) from public, anon;
revoke all on function private.is_campaign_master(uuid, uuid) from public, anon;
revoke all on function private.are_campaign_mates(uuid) from public, anon;
grant execute on function private.is_campaign_member(uuid, uuid) to authenticated;
grant execute on function private.is_campaign_master(uuid, uuid) to authenticated;
grant execute on function private.are_campaign_mates(uuid) to authenticated;
revoke all on function public.join_campaign_by_code(text) from public, anon;
grant execute on function public.join_campaign_by_code(text) to authenticated;
revoke all on function public.handle_new_profile() from public, anon, authenticated;
revoke all on function public.handle_new_campaign_master() from public, anon, authenticated;

alter table public.campaign_members replica identity full;

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'campaigns'
    ) then
      alter publication supabase_realtime add table public.campaigns;
    end if;
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'campaign_members'
    ) then
      alter publication supabase_realtime add table public.campaign_members;
    end if;
  end if;
end;
$$;
