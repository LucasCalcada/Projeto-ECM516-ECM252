# Interface Flutter de reclamações

Implementada na branch `feat/complaint-flutter-interface` após a preparação do plano e do protótipo na conversa. A branch `feat/flutter_interface` foi consultada exclusivamente por leitura de objetos Git. Nenhum arquivo dela foi copiado ou alterado; não houve checkout, merge ou cherry-pick.

## Escopo entregue

- Lista e detalhe responsivos; no compacto, navegação entre essas duas etapas.
- Formulário de nova reclamação, histórico de respostas e confirmação de encerramento.
- Gestão visual de acesso e sessão; bloqueio de ações administrativas sem `@complaint:manage`.
- Estados de carregamento, vazio, erro com nova tentativa, sessão ausente/expirada e perfil sem acesso.
- Textos em português, inglês e espanhol; temas claro/escuro locais à feature.
- Superfícies sólidas, espaçamento e raios do DS, sem bordas decorativas. Campos mantêm contorno de foco e mensagem de erro.
- Nenhum nome, avatar ou ID de autor/respondente é apresentado. Os modelos de reclamação/resposta não contêm esses campos.

`main.dart`, `app.dart`, dependências e interfaces existentes foram preservados. O módulo é conteúdo para o shell existente, não um novo login ou shell substituto.

## Prévia independente

Na pasta `frontMobile/front_flutter`, com o SDK configurado:

```sh
flutter run -t lib/complaints_preview.dart
```

O seletor da prévia permite experimentar morador/administração/sem sessão/sem acesso, registros/vazio/falha de leitura, idioma e tema. **Essa entrada usa somente dados em memória**, não lê credenciais e não chama o back-end. Criar, responder e encerrar nessa prévia apenas alteram os dados de demonstração durante a execução. Ela não é importada pela entrada normal da aplicação.

## Sessão existente e persistência

A leitura da branch de referência confirmou:

1. `Login` aguarda `SessionStorage.saveAccountToken` antes de avançar.
2. `BuildingSelector` aguarda `saveUserToken` ao selecionar o vínculo.
3. A implementação usa `FlutterSecureStorage`, com chaves `accountToken` e `userToken`.
4. As permissões são extraídas do JWT por `UserSession.fromToken` e disponibilizadas em `UserSession.permissions`. Não há uma chave separada `permissions` como no React.

O módulo reutiliza **o contrato da sessão já carregada** por injeção. Não cria armazenamento paralelo nem volta a decodificar tokens. Em Flutter Web, armazenamento depende da origem; chaves semelhantes não compartilham dados automaticamente com o React em outra porta/domínio.

## Ponto de integração com a base

O arquivo público é `lib/features/complaints/complaints.dart`. Quando a equipe integrar as branches, montar a tela dentro do `AppShell` existente com os campos que `UserSession` já oferece:

```dart
// Exemplo de composição futura no roteador da base.
// session, complaintsRepository e callbacks pertencem à aplicação hospedeira.
ComplaintsScreen(
  access: ComplaintAccess.fromSession(
    userId: session.userId,
    buildingId: session.buildingId,
    permissions: session.permissions,
    expiresAt: session.expiresAt,
    residentAccess: true,
  ),
  buildingName: session.buildingName,
  repository: complaintsRepository,
  onSessionExpired: onSessionExpired,
  onSignIn: onSignIn,
)
```

Registrar a rota e o destino no menu será uma mudança da composição hospedeira, quando os arquivos dessa base estiverem integrados. Eles não foram recriados nesta entrega. `residentAccess` deve refletir a elegibilidade ao fluxo de morador definida pela aplicação/serviço; usar `false` quando esse perfil não tiver acesso. O padrão `true` oferece a visão própria para uma sessão válida; nunca libera a visão do condomínio.

## Matriz visual de ações

| Contexto | Consulta | Criação | Resposta / encerramento |
| --- | --- | --- | --- |
| Morador com sessão válida | Próprias reclamações, `ComplaintScope.mine` | Sim | Não |
| Permissão exata `@complaint:manage` | Condomínio, `ComplaintScope.building` | Não nesta visão | Sim, enquanto não encerrada |
| Apenas `@core:admin` | Nunca libera gestão por si só; mantém visão própria se elegível | Conforme elegibilidade de morador | Não |
| Sem sessão, expirada ou acesso negado | Não consulta | Não | Não |

Não reutilizamos automaticamente o bypass `@core:admin` de outras áreas: o contrato documentado de reclamações exige `@complaint:manage`. A matriz é de apresentação; a autorização e o isolamento por usuário/condomínio continuam responsabilidade do servidor/adaptador autenticado.

Trocar identidade, condomínio, permissões ou concessão de sessão limpa o estado da feature. O controlador invalida respostas assíncronas anteriores; a tela acompanha a expiração e fecha formulário de criação de outra sessão. Não há repetição automática de gravações após falha de rede.

## Contrato de dados e limite da entrega visual

`ComplaintsRepository` define operações de listagem por escopo, criação, resposta e encerramento. Nenhum endpoint HTTP foi inventado. O serviço `back/complaint-service` está sem fontes e README nesta cópia; o README geral confirma apenas a finalidade, a permissão administrativa e o endereço previsto.

`ComplaintStatus.open`, `answered` e `closed` são estados do **modelo de apresentação**, não uma enumeração comprovada da API. O futuro adaptador deve mapear os valores reais e normalizar DTOs, datas e erros. Os campos assunto, descrição e protocolo também são o contrato da UI proposto, a reconciliar com os payloads reais.

Antes de conectar dados reais, o adaptador deve garantir:

- consulta de morador restrita aos seus registros e gestão restrita ao condomínio ativo;
- autorização no servidor para resposta/encerramento;
- conversão de falha de autenticação para `ComplaintSessionExpired`;
- mapeamento dos status e limites de texto realmente aceitos;
- validação de nulabilidade, histórico, regras de encerramento e fuso dos timestamps;
- ausência de nomes/dados de autores nos modelos usados pela apresentação.

O repositório de demonstração não serve como adaptador de produção e não valida direitos de um usuário real.

## Verificação

```sh
dart analyze --fatal-infos
flutter test --no-pub test/complaints
```

Verificação executada em 25/10/2026: formatação dos novos arquivos, análise Dart sem ocorrências e **45 testes aprovados**. A matriz de widgets inclui 320 × 800 e 1280 × 900, dois temas, escala de texto 1 e 2 e visões de morador/administração. Os demais testes cobrem gates, escopos, falhas, envio duplicado, contexto/expiração e respostas tardias.

`flutter analyze` foi afetado pelo [problema conhecido de caminhos Unicode no cliente LSP](https://github.com/flutter/flutter/issues/191309) presente no SDK instalado. A análise foi concluída com `dart analyze --fatal-infos`; o SDK e o caminho do projeto não foram alterados.
