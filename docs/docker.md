# Executar com Docker

[Voltar ao README principal](../README.md)

Execute os comandos deste guia na raiz do repositório.

Requisitos: Docker com suporte a containers Linux e Docker Compose 2.17 ou superior.
Na raiz do repositório, execute:

```sh
docker compose up --build -d
docker compose ps
docker compose logs -f
```

O `docker-compose.yml` na raiz contém a configuração completa de todos os serviços,
incluindo os frontends React e Flutter, o event bus, o PostgreSQL e o pgAdmin.
Cada aplicação tem seu Dockerfile em `docker/Dockerfile`, dentro da pasta do serviço.
Todos usam a raiz do repositório como contexto de build. As aplicações Node usam
os Yarn Workspaces e o `yarn.lock` principal; o serviço Dart usa seu `pubspec.lock`.
Por exemplo:

```sh
docker build -f back/auth-service/docker/Dockerfile -t hiveapp-auth .
```

| Componente   | Endereço local        |
| ------------ | --------------------- |
| React        | http://localhost:5173 |
| Flutter      | http://localhost:5174 |
| Core         | http://localhost:8000 |
| Autenticação | http://localhost:8001 |
| Encomendas   | http://localhost:8002 |
| Visitantes   | http://localhost:8003 |
| Event bus    | http://localhost:8004 |
| Reservas     | http://localhost:8005 |
| Comunicação  | http://localhost:8006 |
| Reclamações  | http://localhost:8007 |
| pgAdmin      | http://localhost:9000 |
| PostgreSQL   | localhost:5432        |

O event bus oferece `GET /health`. Os seis serviços TypeScript só iniciam depois
que o healthcheck do event bus e o do PostgreSQL passam. O serviço Dart de
reclamações aguarda o PostgreSQL e a preparação dos bancos e executa sua migração.
Os frontends dependem da inicialização das sete APIs. As inscrições do event bus ficam em memória.
O serviço de comunicação renova sua inscrição a cada 15 segundos e repete tentativas
após falhas, permitindo recuperar a inscrição quando o event bus reinicia.
O Compose também mantém o reinício dos dependentes em reinícios explícitos do bus.

O React é compilado com Vite; o Flutter é compilado em release dentro da imagem
com SDK fixado e seu `pubspec.lock`. Ambos são servidos pelo Nginx. As chamadas `/api/core`,
`/api/auth`, `/api/delivery`, `/api/visitor`, `/api/reservation`, `/api/communication` e `/api/complaint`
são encaminhadas aos respectivos containers. Assim, o navegador utiliza a mesma
origem do frontend e não precisa resolver os nomes internos do Docker. As rotas
dos frontends também têm fallback ao atualizar a página diretamente.

O Flutter usa `frontMobile/front_flutter/docker/Dockerfile` e `nginx.conf`, com
URLs `/api/*` da mesma origem. Não depende de SDK Flutter ou de `build/web`
preparado no host. O antigo `docker-compose.flutter.yml` foi incorporado ao
Compose principal. Para reconstruir apenas o Flutter:

```sh
docker compose up --build -d flutter-web
```

React e Flutter oferecem a interface de reclamações. Criação, consulta por
residência/condomínio, resposta por residência/condomínio e mudança de status têm
permissões independentes; `@core:admin` concede todas dentro do condomínio do token.
A organização da interface Flutter está no [guia do Flutter](../frontMobile/front_flutter/README.md#organização-de-reclamações).

Os backends executam TypeScript com `tsx`, como nos scripts existentes, e aceitam
`PORT`, `DATABASE_URL`, `JWT_SECRET`, `INTERNAL_SECRET`, `CORE_URL`, `EVENT_BUS_URL`
e `SERVICE_URL`, conforme as configurações de cada serviço. Fora do Docker, os
valores locais anteriores continuam sendo usados. O Compose fornece os nomes
dos containers nas URLs internas; `JWT_SECRET` e `INTERNAL_SECRET` podem ser
sobrescritos no ambiente ou no `.env` usado pelo Compose.

### Banco de dados de desenvolvimento

O PostgreSQL prepara os sete bancos com `back/init-dbs.sql`. O serviço `db-init`
também cria bancos ausentes em volumes existentes, sem apagar os demais.
Os serviços TypeScript sincronizam suas tabelas com `drizzle-kit push` antes de iniciar a API;
reclamações usa sua migração SQL em Dart.
Essa configuração destina-se ao desenvolvimento; alterações futuras de schema que
exijam confirmação do Drizzle devem ser revisadas antes da inicialização.
Os dados ficam no volume `postgres-data`, e as configurações do pgAdmin no
volume `pgadmin-data`, inclusive depois de `docker compose down`.

Os bancos começam sem dados de exemplo. Para carregar os exemplos, execute
explicitamente os comandos abaixo **somente em um banco de desenvolvimento**:
os scripts existentes limpam as tabelas correspondentes antes de inserir os dados.

```sh
docker compose exec auth-service yarn db:populate
docker compose exec core-service yarn db:populate
docker compose exec reservation-service yarn db:populate
docker compose exec communication-service yarn db:populate
```

Nenhum script de população é executado automaticamente ao iniciar ou reiniciar
containers. Para parar a stack preservando os volumes:

```sh
docker compose down
```
