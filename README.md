# Noite de Crepúsculo

Aplicação Next.js, React, TypeScript e Supabase.

## Requisitos

- Node.js 22.x
- npm
- Projeto Supabase configurado

## Configuração local

1. Copie `.env.example` para `.env.local`.
2. Preencha `NEXT_PUBLIC_SUPABASE_URL` e `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`.
3. Instale as dependências com `npm ci` quando o `package-lock.json` estiver disponível; caso contrário, use `npm install`.
4. Inicie com `npm run dev`.

## Comandos

- `npm run dev`: ambiente local.
- `npm run build`: build de produção.
- `npm test`: testes unitários dos utilitários de campanha.

## Campanhas

As operações de criar, entrar, editar e sair usam `try/catch/finally` para liberar o estado de carregamento mesmo em caso de falha. A consulta de participantes busca os dados de perfil pela relação da chave estrangeira em uma única consulta e descarta respostas antigas quando a campanha selecionada muda. Eventos Realtime de `campaigns` e `campaign_members` atualizam a lista e os participantes.

## Banco e migrações

`supabase/migrations/20261114000000_campaign_core.sql` documenta o bootstrap do núcleo de campanhas (`profiles`, `campaigns` e `campaign_members`), funções, políticas RLS e publicação Realtime. **Não é um snapshot completo do banco de produção**: as tabelas de personagens, sessões, dados, bestiário, inventário, habilidades, encontros e pistas ainda precisam de migrations próprias para reproduzir todo o projeto em um Supabase vazio.

Não aplique essa migration sobre produção sem revisar o estado e o histórico de migrations do projeto. Ela foi adicionada ao repositório de trabalho, mas não foi executada no banco remoto.

## Testes

`tests/campaign-utils.test.mjs` contém testes unitários executáveis localmente. Os cenários de integração que dependem de duas ou três contas, autenticação, Realtime e RLS estão descritos em `tests/INTEGRATION-CHECKLIST.md`; eles ainda precisam ser executados em um ambiente de teste Supabase.

## Dependências

As versões diretas estão fixadas no `package.json`. O `package-lock.json` não foi gerado neste ambiente porque o acesso ao registro npm expirou; não foi criado um lockfile artificial. Gere-o em um ambiente com acesso ao npm usando `npm install` e versione o arquivo resultante.

## Segurança

Use somente a chave publishable no navegador. Nunca coloque `service_role`, chaves secretas ou tokens de sessão em variáveis `NEXT_PUBLIC_` ou no código cliente.


## Autenticação (0.4.3)

A sessão inicial é obtida pelo evento `INITIAL_SESSION` de `onAuthStateChange`. A chamada paralela a `getSession()` foi removida para evitar dois caminhos concorrentes de inicialização da sessão. A ocorrência de HTTP 429 deve ser reavaliada após publicar esta versão; essa alteração reduz uma possível disputa, mas não comprova sozinha a causa do rate limit.

## Biblioteca de regras (0.5.0)

A rota `/regras` apresenta o códice digital de Noite de Crepúsculo, com índice navegável, busca de capítulos, layout responsivo e seções de atributos, perícias, raças e origens, combate, magia, condições, descanso, equipamentos e economia. O acesso está disponível no cabeçalho e na seção de ferramentas da página inicial.

Observações editoriais: as regras de raças/origens recebidas até esta versão detalham Humano e Bruxo; as demais descrições ainda precisam ser fornecidas. O exemplo de atributos enviado soma três pontos adicionais, embora a regra geral conceda quatro; o exemplo foi preservado e sinalizado na interface para revisão.
