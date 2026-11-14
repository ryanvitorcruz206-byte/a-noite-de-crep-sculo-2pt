# Checklist de integração — campanhas

Estes cenários exigem duas contas autenticadas em um ambiente de teste. Não os execute na produção com contas de terceiros.

## Conta A — mestre
- [ ] Entrar e abrir a área de campanhas.
- [ ] Criar uma campanha com nome, descrição e cada sistema de regras.
- [ ] Confirmar que a campanha aparece na lista após atualizar a página.
- [ ] Confirmar que a conta A aparece como mestre e que o código de convite é exibido.
- [ ] Editar nome, descrição e sistema; atualizar a página e conferir persistência.

## Conta B — jogador
- [ ] Entrar com a conta B em outro navegador ou janela privada.
- [ ] Inserir um código válido e confirmar a entrada.
- [ ] Confirmar que a campanha aparece na lista e a conta B aparece como jogador.
- [ ] Manter o painel da conta A aberto e verificar se a lista de participantes atualiza sem recarregar a página.
- [ ] Sair da campanha pela conta B e verificar se a conta A vê a remoção em tempo real.

## Isolamento e RLS
- [ ] Com uma terceira conta C, tentar consultar a campanha sem ser membro; a consulta não deve retornar a campanha.
- [ ] Confirmar que a conta B não consegue editar ou excluir a campanha do mestre.
- [ ] Confirmar que a conta B não consegue remover outro participante.
- [ ] Confirmar que um código inexistente ou de campanha inativa é rejeitado.
- [ ] Confirmar que chamadas de criação/entrada sem sessão são rejeitadas.

## Resultado
Registrar navegador, horário, usuário de teste e resultado de cada cenário. Os testes unitários locais não substituem esta validação real de autenticação, Realtime e RLS.
