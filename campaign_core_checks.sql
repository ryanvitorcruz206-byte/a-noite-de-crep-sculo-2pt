-- Verificações estruturais para executar após as migrations locais.
-- Não substitui os testes funcionais com usuários reais descritos em tests/INTEGRATION-CHECKLIST.md.
do $$
begin
  if to_regclass('public.profiles') is null then raise exception 'Tabela public.profiles ausente'; end if;
  if to_regclass('public.campaigns') is null then raise exception 'Tabela public.campaigns ausente'; end if;
  if to_regclass('public.campaign_members') is null then raise exception 'Tabela public.campaign_members ausente'; end if;

  if not (select relrowsecurity from pg_class where oid = 'public.profiles'::regclass) then
    raise exception 'RLS desabilitado em public.profiles';
  end if;
  if not (select relrowsecurity from pg_class where oid = 'public.campaigns'::regclass) then
    raise exception 'RLS desabilitado em public.campaigns';
  end if;
  if not (select relrowsecurity from pg_class where oid = 'public.campaign_members'::regclass) then
    raise exception 'RLS desabilitado em public.campaign_members';
  end if;

  if to_regprocedure('public.join_campaign_by_code(text)') is null then
    raise exception 'RPC public.join_campaign_by_code(text) ausente';
  end if;
  if not exists (
    select 1 from pg_trigger
    where tgrelid = 'public.campaigns'::regclass
      and tgname = 'on_campaign_created_add_master'
      and not tgisinternal
  ) then
    raise exception 'Trigger de associação do mestre ausente';
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'campaign_members'
  ) then
    raise exception 'campaign_members não está na publicação supabase_realtime';
  end if;
end;
$$;
