# HiveApp

O app HiveApp oferece um sistema de gerenciamento para condomínios, com o foco em reduzir os conflitos entre moradores e a administração do prédio. O sistema oferece funcionalidades para o gerenciamento de acesso, controle e gestão dos automóveis e vagas, reservas das áreas comuns, notificações de eventos do condomínio, gerenciamento de encomendas e entrega de boletos.

## Executar com Docker

Requisitos: Docker com suporte a containers Linux e Docker Compose 2.17 ou superior.
Na raiz do repositório, execute:

```sh
docker compose up --build -d
docker compose ps
docker compose logs -f
```

O `docker-compose.yml` na raiz contém a configuração completa de todos os serviços,
incluindo o frontend, o event bus, o PostgreSQL e o pgAdmin.
Cada aplicação tem seu Dockerfile em `docker/Dockerfile`, dentro da pasta do serviço.
Todos usam a raiz do repositório como contexto de build para respeitar os Yarn Workspaces
e o `yarn.lock` principal. Por exemplo:

```sh
docker build -f back/auth-service/docker/Dockerfile -t hiveapp-auth .
```

| Componente   | Endereço local        |
| ------------ | --------------------- |
| Frontend     | http://localhost:5173 |
| Core         | http://localhost:8000 |
| Autenticação | http://localhost:8001 |
| Encomendas   | http://localhost:8002 |
| Visitantes   | http://localhost:8003 |
| Event bus    | http://localhost:8004 |
| Reservas     | http://localhost:8005 |
| Comunicação  | http://localhost:8006 |
| pgAdmin      | http://localhost:9000 |
| PostgreSQL   | localhost:5432        |

O event bus oferece `GET /health`. Os seis serviços de negócio só iniciam depois
que o healthcheck do event bus e o do PostgreSQL passam. O frontend depende da
inicialização dos seis serviços. As inscrições do event bus ficam em memória;
ao executar `docker compose restart event-bus`, o Compose também reinicia seus
dependentes para restabelecer a inscrição do serviço de comunicação. Reinícios
automáticos do processo não acionam essa dependência; nesse caso, reinicie também
o `communication-service` para refazer a inscrição.

O frontend é compilado com Vite e servido pelo Nginx. As chamadas `/api/core`,
`/api/auth`, `/api/delivery`, `/api/visitor`, `/api/reservation` e `/api/communication`
são encaminhadas aos respectivos containers. Assim, o navegador utiliza a mesma
origem do frontend e não precisa resolver os nomes internos do Docker. As rotas
do React também funcionam ao atualizar a página diretamente.

Os backends executam TypeScript com `tsx`, como nos scripts existentes, e aceitam
`PORT`, `DATABASE_URL`, `JWT_SECRET`, `INTERNAL_SECRET`, `CORE_URL`, `EVENT_BUS_URL`
e `SERVICE_URL`, conforme as configurações de cada serviço. Fora do Docker, os
valores locais anteriores continuam sendo usados. O Compose fornece os nomes
dos containers nas URLs internas; `JWT_SECRET` e `INTERNAL_SECRET` podem ser
sobrescritos no ambiente ou no `.env` usado pelo Compose.

### Banco de dados de desenvolvimento

No primeiro uso do volume, o PostgreSQL cria os seis bancos com `back/init-dbs.sql`.
Cada serviço sincroniza suas tabelas com `drizzle-kit push` antes de iniciar a API.
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

## 👤 Integrantes

| Nome                                  | RA         |
| ------------------------------------- | ---------- |
| Alan Martins                          | 23.01552-7 |
| Diogo Musso Coutinho                  | 23.01099-0 |
| Gabriel Coutinho                      | 22.95007-9 |
| Gustavo Gomes                         | 23.01268-4 |
| Lucas Mammoccio Gomes Martins Calçada | 23.01372-9 |
| Vinicius Takashi                      | 23.01037-0 |
