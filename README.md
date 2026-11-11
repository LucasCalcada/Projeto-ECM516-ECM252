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
A organização da interface Flutter está no [guia do Flutter](frontMobile/front_flutter/README.md#organização-de-reclamações).

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

## Executar com Kubernetes — tutorial Minikube

Este fluxo sobe React, Flutter web, sete APIs, barramento e PostgreSQL usando
os YAMLs existentes e comandos diretos. Execute **um bloco por vez**, na raiz do
repositório, e avance apenas se os comandos terminarem com sucesso.
Não execute `docker compose up` para esta implantação: o Kubernetes gerencia os serviços.

### 1. Preparar o terminal e o Docker

Windows: abra o Docker Desktop com containers Linux e um terminal PowerShell novo.
São necessários Docker, Minikube e kubectl. Não é necessário instalar Flutter SDK
nem habilitar o Kubernetes integrado do Docker Desktop.

```powershell
cd C:\Users\vtaka\ProjetoLP\Projeto-ECM516-ECM252
docker info
minikube version
kubectl version --client
docker system df
```

Adapte o caminho ao local do clone. Se Minikube ainda não estiver instalado:

```powershell
winget install --id Kubernetes.minikube --exact
```

Reabra o terminal depois da instalação. Se já estiver instalado, mas o terminal
antigo não o encontrar, reabrir o terminal também atualiza seu PATH.
Linux: use Docker Engine, kubectl e Minikube; veja a
[instalação Linux](k8s/README.md#1-pré-requisitos-e-cluster) e entre na raiz do clone
com `cd`. Os comandos `docker`, `minikube` e `kubectl` abaixo são iguais nos dois sistemas.
Disponibilize 4 CPUs e 6 GiB para o perfil, com memória adicional para o Docker e os builds.

### 2. Escolher entre preservar e começar do zero

O container `hiveapp-minikube` representa o nó Kubernetes. Os Pods das aplicações
rodam dentro dele; não espere dez containers de aplicações separados no Docker Desktop.
Excluir containers manualmente no Docker não equivale a excluir corretamente o perfil.

Para somente parar e preservar os dados, use:

```sh
minikube stop -p hiveapp-minikube
```

**Opcional — somente para começar com banco vazio:** o comando abaixo exclui o
perfil `hiveapp-minikube` e seus dados locais. Feche os túneis antigos com Ctrl+C
antes de executá-lo. Não execute esta opção se quiser conservar o banco.

```sh
minikube delete -p hiveapp-minikube
```

Essa exclusão é limitada a esse perfil; não use `--all`, `--purge` nem limpeza global
de volumes. Não é necessário excluir o kind ou os volumes do Compose para subir o
Minikube. Se você já apagou o container pelo Docker, tente iniciar pelo próximo passo;
se houver erro de perfil inconsistente, use a exclusão acima apenas se aceitar perder
os dados desse perfil, e então inicie novamente.
[Referência oficial da exclusão](https://minikube.sigs.k8s.io/docs/commands/delete/).

### 3. Criar ou iniciar o perfil

```sh
kubectl config current-context
minikube start -p hiveapp-minikube --driver=docker --cpus=4 --memory=6144 --keep-context --preload=false
minikube status -p hiveapp-minikube
kubectl --context hiveapp-minikube version
kubectl --context hiveapp-minikube get nodes
kubectl --context hiveapp-minikube get storageclass
```

`current-context is not set` apenas indica que não havia contexto global selecionado;
anote esse estado. Usamos `--preload=false` porque o download opcional do pacote de
imagens ficou sem progresso na validação desta máquina. Isso não dispensa downloads
de componentes/imagens necessários no primeiro início.
Espere o nó `Ready` e uma StorageClass marcada como `(default)` antes de continuar.
O cliente kubectl deve ficar no máximo uma versão minor acima/abaixo do servidor;
consulte o [guia detalhado](k8s/README.md) se precisar ajustar o cliente ou os addons.

### 4. Preparar as credenciais locais

Preserve `k8s/overlays/local/secrets.env` se ele já existir. **Somente se estiver ausente**,
copie o exemplo e edite os valores antes de aplicar os YAMLs.

PowerShell:

```powershell
Test-Path k8s/overlays/local/secrets.env
```

Se retornar `False`:

```powershell
Copy-Item k8s/overlays/local/secrets.example.env k8s/overlays/local/secrets.env
notepad k8s/overlays/local/secrets.env
```

No Bash, confira com `test -f k8s/overlays/local/secrets.env`; se ausente, use
`cp k8s/overlays/local/secrets.example.env k8s/overlays/local/secrets.env` e seu editor.
Defina `POSTGRES_USER`, `POSTGRES_PASSWORD`, `JWT_SECRET` e `INTERNAL_SECRET`; substitua
todos os `CHANGE_ME` por valores próprios. Use valores aleatórios para os segredos e
apenas letras, números, `_` e `-` nas credenciais PostgreSQL, que entram na URL.
Não publique esse arquivo. Se reutilizar o PVC, mantenha a senha original do banco.

### 5. Construir as dez imagens

Se você apagou apenas containers, as imagens podem continuar disponíveis. Pode pular
o build somente se as dez imagens nas tags indicadas abaixo já existirem e corresponderem ao
código desejado. Em caso de alteração de código ou imagem ausente, execute:

```sh
docker build -f back/auth-service/docker/Dockerfile -t hiveapp/auth-service:local .
docker build -f back/core-service/docker/Dockerfile -t hiveapp/core-service:local .
docker build -f back/delivery-service/docker/Dockerfile -t hiveapp/delivery-service:local .
docker build -f back/visitor-service/docker/Dockerfile -t hiveapp/visitor-service:local .
docker build -f back/reservation-service/docker/Dockerfile -t hiveapp/reservation-service:local .
docker build -f back/communication-service/docker/Dockerfile -t hiveapp/communication-service:local .
docker build -f back/complaint-service/docker/Dockerfile -t hiveapp/complaint-service:local .
docker build -f back/event-bus/docker/Dockerfile -t hiveapp/event-bus:local .
docker build -f front/docker/Dockerfile -t hiveapp/front:local .
docker build -f frontMobile/front_flutter/docker/Dockerfile -t hiveapp/flutter-web:complaints-refactor-20261111-071233 .
```

### 6. Carregar as imagens no Minikube

Crie o diretório local ignorado pelo Git. PowerShell:

```powershell
New-Item -ItemType Directory -Force k8s/.local | Out-Null
```

Bash:

```bash
mkdir -p k8s/.local
```

Nos dois sistemas, exporte as imagens em um arquivo conjunto e carregue-o no perfil.
Essa forma compartilha camadas e foi mais rápida nesta máquina que dez cargas separadas:

```sh
docker image save -o k8s/.local/minikube-images.tar hiveapp/auth-service:local hiveapp/core-service:local hiveapp/delivery-service:local hiveapp/visitor-service:local hiveapp/reservation-service:local hiveapp/communication-service:local hiveapp/complaint-service:local hiveapp/event-bus:local hiveapp/front:local hiveapp/flutter-web:complaints-refactor-20261111-071233
minikube -p hiveapp-minikube image load k8s/.local/minikube-images.tar
minikube -p hiveapp-minikube image ls
```

Aguarde a carga terminar e confira as dez imagens. Estarem no Docker do computador
não basta: elas precisam estar também no perfil Minikube. Gere novamente o arquivo
depois de cada rebuild para não carregar imagens antigas.

### 7. Implantar infraestrutura, migrações e aplicações

Primeiro, banco e barramento:

```sh
kubectl --context hiveapp-minikube apply -k k8s/overlays/local
kubectl --context hiveapp-minikube -n hiveapp rollout status statefulset/db --timeout=300s
kubectl --context hiveapp-minikube -n hiveapp rollout status deployment/event-bus --timeout=180s
```

Depois, as sete migrações:

```sh
kubectl --context hiveapp-minikube apply -k k8s/overlays/local/migrations
kubectl --context hiveapp-minikube -n hiveapp wait --for=condition=complete job -l hiveapp/task=migrate --timeout=210s
```

Somente com todas concluídas, aplique as APIs e os frontends:

```sh
kubectl --context hiveapp-minikube apply -k k8s/overlays/local/apps
kubectl --context hiveapp-minikube -n hiveapp rollout status deployment --timeout=240s
kubectl --context hiveapp-minikube -n hiveapp get deployments,statefulsets,pvc,jobs
```

Resultado esperado: dez Deployments `1/1`, StatefulSet `db` pronto, PVC `Bound` e
sete Jobs de migração `Complete`. Os Jobs expiram uma hora após concluir.
Se reutilizou um perfil com aplicações existentes e reconstruiu imagens na mesma
tag `local`, faça também `kubectl --context hiveapp-minikube -n hiveapp rollout restart deployment`
e aguarde novamente os rollouts. Para reexecutar Jobs já encerrados ou alterar seus
templates, siga [Atualizações e repetição das migrações](k8s/README.md#6-atualizações-e-repetição-das-migrações).
Não exclua Jobs em execução nem prossiga se uma migração falhar.

### 8. Abrir React e Flutter web

Em um terminal separado, para React:

```sh
minikube -p hiveapp-minikube service front -n hiveapp --url
```

Em outro terminal, para Flutter web:

```sh
minikube -p hiveapp-minikube service flutter-web -n hiveapp --url
```

Abra os endereços retornados. **No Windows, deixe os dois terminais abertos**:
eles mantêm os túneis. As portas podem mudar a cada abertura; não reutilize as URLs
de uma execução anterior. Aguarde alguns segundos se o túnel ainda estiver iniciando.
APIs, banco e barramento são internos; o Nginx dos frontends encaminha `/api/*`.

Confira `kubectl config current-context` novamente. Se a seleção tiver mudado,
restaure o estado anotado no passo 3 conforme o [guia Kubernetes](k8s/README.md#1-pré-requisitos-e-cluster).

Após F5, o Flutter restaura a sessão e a última seção permitida na mesma origem.
Não restaura formulários não salvos. Ao mudar a porta do túnel, pode ser necessário
entrar novamente. A cópia redundante de dados locais foi removida; tokens continuam
no armazenamento de sessão. Veja [como atualizar somente o Flutter](frontMobile/front_flutter/README.md#atualização-do-flutter-no-minikube).
Esta alteração foi entregue para teste manual: sem execução de testes, análise estática ou validação funcional.

### 9. Dados fictícios com Jobs (opcional)

Depois das migrações e dos dez Deployments prontos, execute nos dois sistemas:

```sh
kubectl --context hiveapp-minikube apply -k k8s/overlays/local/populate
kubectl --context hiveapp-minikube -n hiveapp wait --for=condition=complete job/populate-demo-bootstrap job/populate-demo-scenarios --timeout=450s
kubectl --context hiveapp-minikube -n hiveapp logs job/populate-demo-bootstrap
kubectl --context hiveapp-minikube -n hiveapp logs job/populate-demo-scenarios
```

São dois Jobs manuais, separados da implantação:

- `populate-demo-bootstrap`: cria três contas, um condomínio, três residências e uma área comum.
- `populate-demo-scenarios`: aguarda a preparação e as APIs; cria reserva, visitante,
  reclamação com resposta, evento no calendário e encomenda com notificação pelo barramento.

O código vem de um ConfigMap e usa a imagem `hiveapp/auth-service:local` já carregada:
**não precisa de novo build** para essa população. Os exemplos ficam no condomínio
**Condomínio Demonstração Kubernetes**.

| Perfil | E-mail | Senha de demonstração |
| --- | --- | --- |
| Administrador | `admin@demo.hiveapp.test` | `HiveDemo@123` |
| Portaria | `portaria@demo.hiveapp.test` | `HiveDemo@123` |
| Morador | `morador@demo.hiveapp.test` | `HiveDemo@123` |

São credenciais públicas para demonstração local, não para produção. Portaria recebe
permissões de encomendas e visitantes; morador recebe permissões da própria residência;
administrador recebe `@core:admin`.

Os novos Jobs **não usam TRUNCATE nem apagam registros**. IDs e marcadores próprios
evitam duplicar os exemplos em reexecuções. Senhas, permissões e identidades existentes
não são sobrescritas: uma colisão ou alteração nas identidades demo faz o bootstrap
falhar para revisão. Dados criados pelas APIs conservam alterações manuais posteriores.
Reserva e evento usam datas futuras relativas à primeira criação; repetir a população
não muda essas datas nem cria novos exemplos a cada dia.

Para executar novamente, primeiro confira que ambos estão `Complete` ou `Failed`:

```sh
kubectl --context hiveapp-minikube -n hiveapp get jobs -l hiveapp/demo=v1
```

**Somente depois que ambos estiverem encerrados** (ou ausentes por TTL):

```sh
kubectl --context hiveapp-minikube -n hiveapp delete job populate-demo-bootstrap populate-demo-scenarios --ignore-not-found
kubectl --context hiveapp-minikube apply -k k8s/overlays/local/populate
kubectl --context hiveapp-minikube -n hiveapp wait --for=condition=complete job/populate-demo-bootstrap job/populate-demo-scenarios --timeout=450s
```

Excluir esses Jobs não exclui os dados. Eles também expiram uma hora após terminar.
Se ocorrer erro, consulte os logs dos dois Jobs antes de repetir. Se o barramento
estiver indisponível, a encomenda pode existir sem aviso; a reexecução tenta publicar
seu evento novamente sem criar outra encomenda.
Detalhes e limitações: [população de demonstração](k8s/jobs/populate/README.md).
Os antigos comandos `yarn db:populate` do Compose continuam destrutivos e não são
executados por esses novos Jobs.

### 10. Diagnosticar, parar e retomar

Teste `/health` nas duas URLs e, por exemplo, `/api/auth/health/ready` e
`/api/complaint/health` pelos frontends. A lista das sete APIs está no
[guia Kubernetes](k8s/README.md#5-acessar-e-verificar).

```sh
kubectl --context hiveapp-minikube -n hiveapp get pods,services,pvc,jobs
kubectl --context hiveapp-minikube -n hiveapp get events --sort-by=.metadata.creationTimestamp
kubectl --context hiveapp-minikube -n hiveapp logs deployment/communication-service --tail=50
kubectl --context hiveapp-minikube -n hiveapp logs job/migrate-auth-service --all-containers=true --tail=80
```

Para encerrar o uso, feche os túneis com Ctrl+C e pare preservando o banco:

```sh
minikube stop -p hiveapp-minikube
```

Na próxima vez, sem excluir o perfil, basta retomar e reabrir os dois túneis do passo 8:

```sh
minikube start -p hiveapp-minikube --driver=docker --cpus=4 --memory=6144 --keep-context --preload=false
kubectl --context hiveapp-minikube -n hiveapp rollout status statefulset/db --timeout=300s
kubectl --context hiveapp-minikube -n hiveapp rollout status deployment --timeout=240s
```

Não é necessário reconstruir imagens, reaplicar YAMLs ou popular dados em cada retomada.
Os volumes do Compose são independentes. Veja as
[evidências da validação Windows e pendências Linux](k8s/VALIDATION-MINIKUBE.md).

## 👤 Integrantes

| Nome                                  | RA         |
| ------------------------------------- | ---------- |
| Alan Martins                          | 23.01552-7 |
| Diogo Musso Coutinho                  | 23.01099-0 |
| Gabriel Coutinho                      | 22.95007-9 |
| Gustavo Gomes                         | 23.01268-4 |
| Lucas Mammoccio Gomes Martins Calçada | 23.01372-9 |
| Vinicius Takashi                      | 23.01037-0 |

### Arquitetura Flutter de reclamações

A view `lib/views/complaints.dart` coordena renderização por permissões, estado e
navegação. Os elementos da tela ficam em `lib/components/complaints`, recebendo
dados e callbacks. Controller, acesso e repositório ficam em `lib/helpers`,
modelos e falhas em `lib/types`, e textos em `lib/lang`. O shell usa
`ComplaintsNavigationController` para confirmar descarte de rascunhos e Voltar.
A antiga pasta `features/complaints` e o preview independente foram removidos.

Para verificar a refatoração, execute `flutter test test/complaints` dentro de
`frontMobile/front_flutter`. A suíte inclui comparações visuais em duas larguras,
além de permissões, integração HTTP e navegação.
