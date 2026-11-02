# Serviço de reclamações

Livro de reclamações do HiveApp escrito em Dart, com HTTP/Shelf e PostgreSQL. Cada ação exige uma permissão: moradores podem criar, consultar e responder registros de sua residência; administradores consultam e respondem pelo condomínio e alteram status conforme as concessões. O serviço usa um banco próprio, `complaintDb`, e a identidade assinada pelo Core.

## Requisitos funcionais atendidos

| ID | Requisito | Comportamento |
| --- | --- | --- |
| RF01 | Registrar reclamação | Criação com título, categoria e descrição obrigatórios. |
| RF02 | Identificar autoria e condomínio | Autor e condomínio vêm do JWT autenticado; o servidor registra as datas. |
| RF03 | Listar reclamações da residência | Consulta por condomínio e residência do token, incluindo outros autores da mesma residência. |
| RF04 | Consultar detalhes | Detalhes incluem o registro, suas respostas e mudanças de status. |
| RF05 | Listar reclamações do condomínio | Administração consulta os registros do condomínio presente no seu JWT. |
| RF06 | Filtrar reclamações | Ambas as listagens aceitam status, categoria e paginação. |
| RF07 | Responder reclamação | Permissões independentes para residência e condomínio; servidor registra conteúdo, autor, origem administrativa e data. |
| RF08 | Atualizar status | Administração move o atendimento para análise ou encerramento. |
| RF09 | Encerrar reclamação | Encerramento exige pelo menos uma resposta administrativa. |
| RF10 | Consultar histórico | Respostas e mudanças de status são preservadas, cada coleção em ordem cronológica. |
| RF11 | Controlar acesso | Seis permissões independentes e escopos derivados do token; core:admin é god mode do próprio condomínio. |

## Regras e dados

Categorias: `barulho`, `limpeza`, `convivencia`, `areas_comuns`, `seguranca` e `outros`.

Toda reclamação começa como `aberta`. As transições permitidas são `aberta → em_analise`, `aberta → encerrada` e `em_analise → encerrada`. O encerramento exige uma resposta administrativa já registrada (`isAdministrative: true`); uma resposta residencial não a substitui. Uma reclamação encerrada fica disponível para consulta, sem novas respostas ou mudanças de status. Encerrar registra o fim do atendimento administrativo, sem exigir concordância do morador.

Reclamações e respostas não têm edição ou exclusão. Há resposta residencial com a permissão correspondente. Não há anonimato, reabertura, anexos ou notificações neste escopo.

O banco mantém as entidades `complaints`, `complaint_responses` e `complaint_status_history`. Uma mudança de status e seu histórico são gravados na mesma transação; respostas e encerramentos concorrentes são serializados por reclamação. IDs e datas são definidos no servidor. As datas retornam em UTC, no formato ISO 8601.

## Autenticação e administração

As rotas de reclamações exigem um JWT HS256 emitido com o mesmo `JWT_SECRET` do Core. O token deve ter `tokenKind: "user"`, `userId`, `buildingId` e a lista `permissions`. Tokens de conta usados no login não representam um vínculo com o condomínio e não dão acesso ao serviço.

O header aceita `Authorization: Bearer <JWT>` e o formato já utilizado pelos outros serviços, `Authorization: <JWT>`.

| Ação | Permissão | Restrição |
| --- | --- | --- |
| Criar | `@complaint:create` | `buildingId` válido; `residencyId` opcional. |
| Visualizar residência | `@complaint:view:residency` | `buildingId` e `residencyId` iguais aos do registro. |
| Visualizar condomínio | `@complaint:view:building` | Mesmo `buildingId`. |
| Mudar status | `@complaint:update:status` | Mesmo `buildingId` e transição permitida. |
| Responder residência | `@complaint:respond:residency` | Mesmo `buildingId` e `residencyId`; marca resposta residencial. |
| Responder condomínio | `@complaint:respond:building` | Mesmo `buildingId`; marca resposta administrativa. |

As concessões não implicam umas nas outras. `@core:admin` concede todas dentro do condomínio do JWT, sem dispensar estado aberto e resposta administrativa para encerrar. `@complaint:manage` não concede mais acesso; usuários com essa permissão antiga precisam receber concessões explícitas. Para conceder permissões no array `users.permissions` de `coreDb`, preserve as existentes e obtenha novo token pelo Core: `GET http://localhost:8000/auth?userId=<UUID_DO_USUARIO>`. Tokens antigos não se atualizam automaticamente.

O serviço valida assinatura HS256 e expiração, e deriva `userId`, `buildingId`, `residencyId` e permissões exclusivamente do JWT. IDs de escopo não são escolhidos no corpo ou filtros. Sem a permissão da ação retorna `403`; recurso fora do escopo permitido retorna `404`. Ser autor não concede leitura. Mudar de residência posteriormente não altera a residência registrada na reclamação.

Novas populações do Core atribuem criar/visualizar residência/responder residência ao perfil comum; o síndico mantém `@core:admin`. Não execute novamente a população em bancos existentes para migrar permissões. A migração `002_residency_permissions.sql` adiciona residência e origem das respostas sem apagar registros. Reclamações históricas sem residência conhecida permanecem com `residencyId: null`, acessíveis somente pela leitura de condomínio. Não inferir a residência histórica pelo vínculo atual do autor. Respostas antigas eram exclusivamente administrativas, por isso recebem `isAdministrative: true`. Veja [contrato e migração](../../audit/permissoes-reclamacoes.md).

## Executar localmente

Pré-requisitos: Dart **3.13.5 ou superior, menor que 4.0**, PostgreSQL e, para obter os tokens, Core/Auth configurados. O `pubspec.lock` é versionado para fixar as dependências da aplicação.

Na raiz do repositório, suba o banco de desenvolvimento:

```powershell
docker compose up -d db-init
```

O serviço `db-init` executa `back/init-dbs.sql` e cria somente os bancos ausentes, inclusive em volumes antigos, sem apagar dados. É esperado que esse serviço termine com código `0`. O mesmo SQL também funciona na inicialização de um volume vazio. As migrações da API criam as tabelas dentro de `complaintDb`; elas não criam o banco PostgreSQL.

Depois, no diretório `back/complaint-service`, configure as variáveis no PowerShell e inicie:

```powershell
$env:PORT = "8007"
$env:HOST = "0.0.0.0"
$env:JWT_SECRET = "test-token"
$env:DATABASE_URL = "postgres://admin:adminPasswd@localhost:5432/complaintDb"
$env:DATABASE_SSL_MODE = "disable"
dart pub get --enforce-lockfile
dart run bin/migrate.dart
dart run bin/server.dart
```

O arquivo `.env.example` documenta a configuração; a execução direta em Dart lê as variáveis do processo e não carrega um arquivo `.env` automaticamente. `test-token` é o segredo de desenvolvimento usado pelo Core neste repositório; configure o mesmo segredo nos dois serviços ao alterá-lo.

| Variável | Uso |
| --- | --- |
| `PORT` | Porta HTTP, normalmente `8007`. |
| `HOST` | Interface de escuta, normalmente `0.0.0.0`. |
| `JWT_SECRET` | Segredo compartilhado com o emissor dos JWTs. |
| `DATABASE_URL` | URL de conexão PostgreSQL com o banco `complaintDb`. |
| `DATABASE_SSL_MODE` | `disable` para PostgreSQL local; `require` ou `verifyFull` para conexões TLS. |

## Executar com Docker

O único arquivo Compose do projeto é `docker-compose.yml`, na raiz, e inclui o serviço de reclamações junto aos demais serviços da aplicação. Para iniciar somente a API de reclamações e suas dependências, execute na raiz do repositório:

```powershell
docker compose up -d --build complaint-service
```

O Compose aguarda o PostgreSQL ficar saudável e o `db-init` preparar os bancos, executa as migrações e inicia a API em `http://localhost:8007`. Esse fluxo também prepara `complaintDb` em volumes antigos. O valor de `JWT_SECRET` pode ser definido no ambiente do Compose ou no arquivo `.env` da raiz do repositório; o padrão local é `test-token`.

A imagem é construída a partir de `back/complaint-service/docker/Dockerfile`, com contexto de build na raiz, seguindo a organização dos demais serviços. Ela usa o SDK oficial Dart 3.13.5 no estágio de compilação e executáveis AOT em uma imagem de runtime separada. A inicialização só inicia o servidor se as migrações concluírem com sucesso.

## API HTTP

| Método | Rota | Acesso | Resultado |
| --- | --- | --- | --- |
| `GET` | `/health` | Público | Verifica o serviço e sua conexão com o banco. |
| `POST` | `/complaints` | `create` | Registra uma reclamação e retorna o registro criado. |
| `GET` | `/complaints/residency` | `view:residency` | Lista registros da residência e condomínio do token. |
| `GET` | `/complaints/mine` | `view:residency` | Alias compatível da rota residencial, com a mesma autorização; não filtra por autor. |
| `GET` | `/complaints` | `view:building` | Lista as reclamações do condomínio. |
| `GET` | `/complaints/:id` | `view:residency` ou `view:building` | Detalhes no escopo permitido, com `responses` e `history`. |
| `POST` | `/complaints/:id/responses` | `respond:residency` ou `respond:building` | Adiciona resposta no escopo permitido. |
| `PATCH` | `/complaints/:id/status` | `update:status` | Altera o status no condomínio do token. |

Na tabela, os nomes abreviados têm o prefixo `@complaint:`. `@core:admin` também autoriza todas as rotas protegidas dentro do seu escopo.

As listagens retornam um array JSON, ordenado pelas reclamações mais recentes, incluindo `residencyId` (nullable). Parâmetros opcionais: `status`, `category`, `limit` (padrão `20`, máximo `100`) e `offset` (padrão `0`). Exemplo: `/complaints/residency?status=aberta&category=barulho&limit=20&offset=0`. O detalhe também inclui `isAdministrative` em cada resposta, definido pelo servidor. Os limites de texto são: título até 200 caracteres, descrição até 10.000 e resposta até 5.000; textos são obrigatórios e espaços nas extremidades são removidos. Campos extras no corpo ou nos filtros são rejeitados.

Cadastro:

```json
{
  "title": "Barulho após as 22h",
  "category": "barulho",
  "description": "Música alta na área comum depois do horário permitido."
}
```

Resposta residencial ou administrativa (origem definida pela permissão do token):

```json
{ "message": "Entramos em contato com os responsáveis e reforçamos as regras." }
```

Alteração de status:

```json
{ "status": "em_analise" }
```

Os erros usam o formato `{ "error": { "code": "...", "message": "..." } }` e códigos HTTP: `400` para dados/filtros inválidos, `401` para autenticação inválida ou ausência de condomínio no token, `403` para falta da permissão ou ausência de residência em ação residencial, `404` para recurso fora do escopo e `409` para conflito com as regras do atendimento. Corpos devem usar `Content-Type: application/json` (`415` caso contrário) e têm limite de 64 KiB (`413` quando excedido). A saúde retorna `503` se o banco estiver indisponível. As transições e as respostas após encerramento são rejeitadas.

## Verificação

No diretório do serviço:

```powershell
dart analyze
dart test
```

Para incluir os testes de integração, aponte para um banco de teste dedicado:

```powershell
$env:TEST_DATABASE_URL = "postgres://admin:adminPasswd@localhost:5432/complaint_test"
dart test
```

Os testes executam todas as migrações nesse banco e removem somente os registros dos condomínios gerados pela execução. Sem `TEST_DATABASE_URL`, os testes de PostgreSQL são ignorados; os testes de domínio, HTTP e autenticação continuam sendo executados. O workflow `.github/workflows/complaint-check.yml` executa formatação, análise e toda a suíte com PostgreSQL.

Em pastas sincronizadas pelo OneDrive, o Dart e o Docker podem falhar ao resolver os arquivos locais. Caso ocorra `package_config.json did not contain its own root package` ou `invalid file request Dockerfile`, use uma cópia do projeto em uma pasta local fora do OneDrive e execute novamente `dart pub get --enforce-lockfile` antes das verificações.

O arquivo `test.rest` contém o fluxo manual completo. Preencha `residentToken`, `adminToken` e, após criar o registro, `complaintId`. Use usuários do mesmo condomínio para o fluxo administrativo e usuários de outro condomínio para conferir o isolamento de acesso.
