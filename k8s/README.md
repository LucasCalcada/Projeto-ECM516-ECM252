# HiveApp no Kubernetes local

Esta implantação usa kind, um cluster Kubernetes local executado no Docker.
Requisitos: Docker com containers Linux, kubectl, kind e PowerShell 5.1 ou superior.
Reserve recursos para o cluster e as aplicações (como ponto inicial, 4 CPUs e 8 GB
de memória disponíveis ao Docker). Instale kind conforme o
[guia oficial](https://kind.sigs.k8s.io/docs/user/quick-start/).

Todos os comandos abaixo partem da raiz do repositório. O namespace é `hiveapp`.
Os scripts exigem um kubeconfig explícito e usam o contexto `kind-hiveapp`; não
alteram o contexto global do kubectl. Para outro cluster, passe `-Context` e
disponibilize as imagens e uma StorageClass padrão com provisionamento dinâmico.

## Primeira implantação

```powershell
New-Item -ItemType Directory -Force k8s/.local | Out-Null
kind create cluster --name hiveapp --kubeconfig ./k8s/.local/kubeconfig --wait 120s
./k8s/scripts/init-secrets.ps1
./k8s/scripts/build.ps1 -ImageTag k8s-v1 -KindCluster hiveapp
./k8s/scripts/deploy.ps1 -Kubeconfig ./k8s/.local/kubeconfig -ImageTag k8s-v1
```

Se kind não estiver no PATH, use o caminho do executável no comando de criação e
o parâmetro `-KindPath` no build. O build reutiliza os oito Dockerfiles existentes
e carrega as imagens no kind, sem exigir um registry. Em outro cluster, publique
as imagens num registry acessível e use os mesmos `-ImagePrefix` e `-ImageTag`
nos scripts de build e deploy. O script de build não faz push ao registry.

`init-secrets.ps1` gera senhas aleatórias em `overlays/local/secrets.env` e preserva
o arquivo quando já existe. Esse arquivo e `.local/` são ignorados pelo Git;
toda a pasta `k8s/` fica fora do contexto das imagens Docker. O exemplo em
`overlays/local/secrets.example.env` documenta as quatro variáveis necessárias.
As credenciais PostgreSQL devem usar letras, números, `_` e `-`, pois compõem
a URL de conexão. Não regenere a senha de um banco já inicializado sem também
alterá-la no próprio PostgreSQL: mudar o Secret não modifica a senha no banco.

A implantação segue esta sequência e interrompe em caso de erro:

1. Aplica namespace, configurações, Secret, PostgreSQL e event bus.
2. Aguarda banco e event bus ficarem prontos.
3. Cria seis Jobs de migração e aguarda todos terminarem.
4. Aplica as seis APIs e o frontend; aguarda os oito Deployments.

Cada backend também possui init containers que verificam o banco e o endpoint
`/health` do event bus antes de iniciar a API. Não há população automática.
Execute somente um deploy por vez no namespace para evitar migrações concorrentes.

## Acessar e verificar

```powershell
kubectl --kubeconfig ./k8s/.local/kubeconfig --context kind-hiveapp -n hiveapp port-forward service/front 5173:80
```

Mantenha esse terminal aberto e acesse http://localhost:5173. Se a porta estiver
ocupada pelo Compose, use `5174:80`. O Nginx encaminha `/api/auth`, `/api/core`,
`/api/delivery`, `/api/visitor`, `/api/reservation` e `/api/communication` aos
Services internos. Atualizar uma rota do React diretamente continua funcionando.
Banco, APIs e event bus não são publicados em portas do host. O pgAdmin não faz
parte desta implantação; permanece disponível pelo Compose quando necessário.

Em outro terminal:

```powershell
./k8s/scripts/deploy.ps1 -Kubeconfig ./k8s/.local/kubeconfig -Action Status
Invoke-RestMethod http://localhost:5173/health
Invoke-RestMethod http://localhost:5173/api/auth/health/ready
Invoke-RestMethod http://localhost:5173/api/core/health/ready
Invoke-RestMethod http://localhost:5173/api/delivery/health/ready
Invoke-RestMethod http://localhost:5173/api/visitor/health/ready
Invoke-RestMethod http://localhost:5173/api/reservation/health/ready
Invoke-RestMethod http://localhost:5173/api/communication/health/ready
kubectl --kubeconfig ./k8s/.local/kubeconfig --context kind-hiveapp -n hiveapp logs deployment/communication-service --tail=50
```

As seis APIs respondem `200 {"status":"ok"}` em `/health/live` e
`200 {"status":"ready"}` em `/health/ready` quando seu banco responde a `SELECT 1`.
Se o banco falhar, readiness retorna 503; liveness continua independente do banco.
Readiness não certifica todas as funcionalidades nem verifica o event bus.

## Popular os bancos de desenvolvimento

Os Jobs reutilizam exclusivamente os quatro scripts `db:populate` já existentes.
**Eles limpam tabelas antes de inserir exemplos.** Para executá-los explicitamente:

```powershell
./k8s/scripts/deploy.ps1 -Kubeconfig ./k8s/.local/kubeconfig -ImageTag k8s-v1 -Action Populate -ResetDevelopmentData
```

As contas de exemplo incluem `joao@example.com` e `fernanda@example.com`. Os scripts
originais contêm hashes e não documentam a senha em texto. A senha temporária usada
na validação anterior do Compose não é aplicada neste cluster. Para entrar com os
exemplos, será necessário conhecer a senha original ou definir uma senha de teste
explicitamente nessa base. A implantação não altera contas, senhas de usuários ou
regras de autenticação.

## Organização e persistência

| Local                            | Conteúdo                                                        |
| -------------------------------- | --------------------------------------------------------------- |
| `base/`                          | Infraestrutura: namespace, configuração, PostgreSQL e event bus |
| `base/apps/`                     | Conjunto das APIs e frontend                                    |
| `base/services/` e `base/front/` | Deployments, Services, recursos e probes                        |
| `jobs/migrations/`               | Jobs separados das APIs, com nomes únicos por execução          |
| `jobs/populate/`                 | Jobs manuais dos scripts de exemplos                            |
| `overlays/local/`                | Configuração local e geração do Secret                          |
| `scripts/`                       | Criação de segredos, build e implantação em etapas              |
| `../back/*-service/migrations/`  | Histórico SQL e snapshots versionados                           |

O PostgreSQL 17 usa um StatefulSet de uma réplica e o PVC `postgres-data-db-0`
de 2 GiB, provisionado pela StorageClass padrão. A primeira inicialização cria os
seis bancos. `base/postgres/init.yaml` contém o mesmo SQL de `back/init-dbs.sql`;
ao adicionar um banco, mantenha ambos sincronizados. Reiniciar ou substituir um
Pod não apaga o PVC. Não há replicação do banco nem backup automático nesta versão.
Os dados do Compose não são importados automaticamente.

## Migrações e atualização de imagens

Kubernetes sobrescreve o comando das imagens para iniciar apenas a API. O Compose
mantém seu comportamento atual de executar `drizzle-kit push` no startup.
Os Jobs Kubernetes usam `drizzle.k8s.config.ts` e o diretório `migrations/`,
separados do histórico local ignorado em `drizzle/`. A migração inicial corresponde
ao schema existente e se destina a bancos novos; não a aplique diretamente sobre
uma base criada por `push` sem antes reconciliar seu histórico.

Para uma futura alteração de schema, gere e revise uma migração no serviço afetado:

```powershell
cd back/core-service
yarn drizzle-kit generate --config=drizzle.k8s.config.ts --name=descricao_da_alteracao
cd ../..
```

Versione o SQL e os metadados de `migrations/`. Para implantar uma nova versão:

```powershell
./k8s/scripts/build.ps1 -ImageTag k8s-v2 -KindCluster hiveapp
./k8s/scripts/deploy.ps1 -Kubeconfig ./k8s/.local/kubeconfig -ImageTag k8s-v2
```

Use uma tag nova por versão. As migrações já registradas não são reaplicadas.
Os Jobs recebem nomes únicos e expiram uma hora após terminar. As APIs existentes
podem continuar atendendo durante as migrações; mudanças futuras precisam ser
compatíveis com a versão anterior ou ter uma janela explícita de manutenção.
Reverter a imagem não reverte migrações do banco.

## Reinícios e limites do event bus

O event bus mantém uma única réplica com atualização `Recreate`, pois seu registro
de inscrições fica em memória. O serviço de comunicação renova a mesma inscrição
a cada 15 segundos e tenta novamente após 3 segundos quando há falhas. Cada chamada
tem timeout de 5 segundos. As renovações usam a URL estável do Service e não acumulam
inscrições duplicadas no Set do event bus.

```powershell
kubectl --kubeconfig ./k8s/.local/kubeconfig --context kind-hiveapp -n hiveapp rollout restart deployment/event-bus
kubectl --kubeconfig ./k8s/.local/kubeconfig --context kind-hiveapp -n hiveapp rollout status deployment/event-bus
```

A recuperação é eventual; eventos enviados durante a interrupção podem ser perdidos.
Esta implementação não adiciona fila durável nem garantia de entrega. A inscrição
é recuperada sem exigir reinício do serviço de comunicação.

## Parar preservando os dados

Encerre o port-forward com Ctrl+C. Para parar as aplicações e o banco sem excluir o PVC:

```powershell
kubectl --kubeconfig ./k8s/.local/kubeconfig --context kind-hiveapp -n hiveapp scale deployment --all --replicas=0
kubectl --kubeconfig ./k8s/.local/kubeconfig --context kind-hiveapp -n hiveapp scale statefulset/db --replicas=0
```

Execute novamente `deploy.ps1` para retomar. Excluir o namespace/PVC ou apagar o
cluster kind remove o armazenamento desta instalação local; essas ações não são
equivalentes a parar os Pods.

Os manifests tratam a infraestrutura. As falhas funcionais identificadas na
validação anterior não são corrigidas por esta implantação.
