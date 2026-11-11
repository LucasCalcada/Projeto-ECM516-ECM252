# HiveApp no Kubernetes com Minikube

A implantação é feita diretamente com Docker, Minikube e kubectl, usando os YAMLs
versionados e Kustomize (`kubectl apply -k`). Não há scripts próprios de automação.
Execute os comandos da raiz do repositório e avance somente quando cada etapa
terminar com sucesso. Não execute duas implantações simultâneas no namespace.

## 1. Pré-requisitos e cluster

Windows: Docker Desktop executando containers Linux, Minikube, kubectl e PowerShell.
Linux: Docker Engine, Minikube, kubectl e Bash. Flutter SDK não é necessário no host.
Não habilite o Kubernetes integrado do Docker Desktop para este fluxo.

Instalação Windows (reabra o terminal após instalar):

```powershell
winget install --id Kubernetes.minikube --exact
minikube version
```

No Linux x86-64, após instalar Docker Engine e kubectl conforme suas documentações:

```bash
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
minikube version
```

Para Linux ARM64, substitua `amd64` por `arm64` no download e no nome do arquivo.
O usuário deve conseguir executar `docker info` sem sudo. Instruções oficiais:
[Minikube](https://minikube.sigs.k8s.io/docs/start/),
[Docker Engine](https://docs.docker.com/engine/install/) e
[kubectl](https://kubernetes.io/docs/tasks/tools/).

Use inicialmente 4 CPUs e 6 GiB para o perfil. Disponibilize mais memória ao Docker
que a reserva do cluster; builds também consomem recursos. Confira espaço livre no
host e dentro do armazenamento Docker. As imagens TypeScript atuais são grandes;
reserve espaço adicional aos 20 GB mínimos do Minikube. Não execute limpeza automática
nem exclua o cluster antigo para liberar recursos.

Comandos iguais nos dois sistemas:

```sh
docker info
docker system df
kubectl version --client
kubectl config current-context
minikube version
minikube profile list
minikube start -p hiveapp-minikube --driver=docker --cpus=4 --memory=6144 --keep-context
minikube status -p hiveapp-minikube
kubectl --context hiveapp-minikube version
kubectl --context hiveapp-minikube get nodes
kubectl --context hiveapp-minikube get storageclass
```

Use a versão estável padrão do Minikube e registre as versões efetivas. O kubectl deve
estar no máximo uma versão minor acima/abaixo do servidor. Se necessário, use o cliente
compatível fornecido por `minikube -p hiveapp-minikube kubectl -- <argumentos>`.

O perfil e contexto são `hiveapp-minikube`; o namespace da aplicação é `hiveapp`.
`--keep-context` solicita preservar a seleção anterior, e todos os comandos de aplicação deste guia especificam
o contexto. Anote a seleção antes de começar (`current-context is not set` significa
que nenhuma estava selecionada) e confira novamente após iniciar o perfil e abrir
os túneis. Na validação, foi necessário restaurar a ausência de seleção ao final.
Se houver diferença, restaure apenas o estado anotado: `kubectl config use-context NOME_ANTERIOR`
para uma seleção existente, ou `kubectl config unset current-context` somente se
ela já estava ausente. Isso não remove clusters nem credenciais.
O Minikube administra as referências/certificados em seu kubeconfig usual;
não reutilize o kubeconfig específico do kind. Não copie PVCs ou dados do cluster antigo.
O novo banco começa vazio. A mesma imagem Docker pode ser reutilizada, mas precisa ser
carregada no novo cluster.

Confirme uma StorageClass padrão com provisionamento dinâmico antes de aplicar o banco.
Se os addons padrão estiverem desabilitados, habilite-os e confira novamente:

```sh
minikube -p hiveapp-minikube addons enable storage-provisioner
minikube -p hiveapp-minikube addons enable default-storageclass
```

Se o perfil já existir, confirme que é o ambiente desejado e retome-o com o mesmo comando
start; não o exclua. Se faltar memória, interrompa e ajuste os recursos do Docker ou pare
explicitamente o ambiente antigo, preservando seus dados. Kind e Compose não são removidos.

Se o início ficar sem progresso em `Downloading Kubernetes ... preload`, interrompa
essa tentativa com Ctrl+C e repita desabilitando somente o download opcional do
pacote de imagens pré-carregadas:

```sh
minikube start -p hiveapp-minikube --driver=docker --cpus=4 --memory=6144 --keep-context --preload=false
```

Isso não exclui o perfil nem seus dados. No primeiro início, as imagens de sistema
ainda precisarão ser obtidas dos registries; em uma retomada, podem estar no nó.
Essa alternativa foi necessária na validação Windows por falta de progresso no
download do pacote do GitHub.

## 2. Credenciais

Se `k8s/overlays/local/secrets.env` não existir, copie `secrets.example.env` para esse
nome e edite os quatro valores. Não sobrescreva um arquivo de credenciais existente.
Use senhas e segredos aleatórios próprios; não deixe `CHANGE_ME`. Para POSTGRES_USER
e POSTGRES_PASSWORD, use apenas letras, números, `_` e `-`, pois entram na URL do banco.
O arquivo é ignorado pelo Git. Não publique a saída de `kubectl kustomize` da infraestrutura,
pois ela contém o Secret codificado em base64.

Mudar o Secret não muda a senha de um PostgreSQL já inicializado: preserve a senha
associada ao PVC. Nesta execução manual, não há validação automática de placeholders.

## 3. Construir e carregar as imagens

As APIs, barramento e React usam `local`; Flutter usa a tag versionada indicada abaixo. Construa todas as imagens antes de aplicar os recursos:

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
minikube -p hiveapp-minikube image load hiveapp/auth-service:local --daemon
minikube -p hiveapp-minikube image load hiveapp/core-service:local --daemon
minikube -p hiveapp-minikube image load hiveapp/delivery-service:local --daemon
minikube -p hiveapp-minikube image load hiveapp/visitor-service:local --daemon
minikube -p hiveapp-minikube image load hiveapp/reservation-service:local --daemon
minikube -p hiveapp-minikube image load hiveapp/communication-service:local --daemon
minikube -p hiveapp-minikube image load hiveapp/complaint-service:local --daemon
minikube -p hiveapp-minikube image load hiveapp/event-bus:local --daemon
minikube -p hiveapp-minikube image load hiveapp/front:local --daemon
minikube -p hiveapp-minikube image load hiveapp/flutter-web:complaints-refactor-20261111-071233 --daemon
```

Aguarde o carregamento terminar. O Docker Hub não é necessário. A imagem PostgreSQL
é obtida do registry pelo cluster. Os mesmos Dockerfiles continuam sendo usados
pelo Compose; seus dados e volumes são independentes.

Alternativa à carga individual: exportar todas as imagens em um único arquivo,
compartilhando camadas comuns. Isso reduz a transferência das imagens grandes.
Crie `k8s/.local` se necessário (diretório ignorado pelo Git) e execute, nos dois sistemas:

```sh
docker image save -o k8s/.local/minikube-images.tar hiveapp/auth-service:local hiveapp/core-service:local hiveapp/delivery-service:local hiveapp/visitor-service:local hiveapp/reservation-service:local hiveapp/communication-service:local hiveapp/complaint-service:local hiveapp/event-bus:local hiveapp/front:local hiveapp/flutter-web:complaints-refactor-20261111-071233
minikube -p hiveapp-minikube image load k8s/.local/minikube-images.tar
minikube -p hiveapp-minikube image ls
```

Escolha uma das formas de carga; não é necessário executar ambas. Após uma atualização,
gere novamente o arquivo antes de carregá-lo para não reutilizar imagens antigas.

## 4. Aplicar os YAMLs em etapas

Infraestrutura: namespace, configurações, Secret, PostgreSQL e barramento:

```sh
kubectl --context hiveapp-minikube apply -k k8s/overlays/local
kubectl --context hiveapp-minikube -n hiveapp rollout status statefulset/db --timeout=300s
kubectl --context hiveapp-minikube -n hiveapp rollout status deployment/event-bus --timeout=180s
```

Migrações (sete Jobs). Em uma nova implantação, crie e aguarde:

```sh
kubectl --context hiveapp-minikube apply -k k8s/overlays/local/migrations
kubectl --context hiveapp-minikube -n hiveapp wait --for=condition=complete job -l hiveapp/task=migrate --timeout=210s
```

Se algum Job falhar, consulte seus logs antes de continuar:

```sh
kubectl --context hiveapp-minikube -n hiveapp get jobs
kubectl --context hiveapp-minikube -n hiveapp logs job/migrate-auth-service --all-containers=true --tail=80
```

APIs e frontends, somente depois das migrações concluírem:

```sh
kubectl --context hiveapp-minikube apply -k k8s/overlays/local/apps
kubectl --context hiveapp-minikube -n hiveapp rollout status deployment --timeout=240s
kubectl --context hiveapp-minikube -n hiveapp get pods,services,pvc,jobs
```

Resultado esperado: dez Deployments disponíveis, PostgreSQL pronto e PVC Bound.
O banco usa StatefulSet, sete bases e volume de 2 GiB; as APIs usam init containers
para aguardar suas dependências. Healthchecks não certificam todos os fluxos funcionais.

Para validar os quatro conjuntos no servidor, com o namespace já criado, sem
executar os Jobs opcionais de população:

```sh
kubectl --context hiveapp-minikube apply --dry-run=server -k k8s/overlays/local
kubectl --context hiveapp-minikube apply --dry-run=server -k k8s/overlays/local/migrations
kubectl --context hiveapp-minikube apply --dry-run=server -k k8s/overlays/local/apps
kubectl --context hiveapp-minikube apply --dry-run=server -k k8s/overlays/local/populate
```

## 5. Acessar e verificar

Os frontends conservam NodePorts 30080 (React) e 30081 (Flutter web). Obtenha seus
endereços executando cada comando em um terminal separado:

```sh
minikube -p hiveapp-minikube service front -n hiveapp --url
minikube -p hiveapp-minikube service flutter-web -n hiveapp --url
```

Abra as URLs retornadas. No Windows com Docker, mantenha os terminais abertos para
preservar os túneis; as portas são atribuídas pelo Minikube e podem mudar ao reabri-los.
Não presuma `localhost:8080/8081` nem acesso direto pelo IP do nó no Windows.
No Linux nativo, o comando pode retornar diretamente IP do nó e NodePort.
Veja [acesso no Minikube](https://minikube.sigs.k8s.io/docs/handbook/accessing/).

Os Nginx encaminham `/api/*` aos Services internos, usando a mesma origem no navegador.
APIs, PostgreSQL e barramento permanecem internos. A mudança de porta externa não
exige alterações no frontend nem nos destinos de proxy.

Abra `/health` nos dois endereços. Para as APIs, verifique `/api/auth/health/ready`,
`/api/core/health/ready`, `/api/delivery/health/ready`, `/api/visitor/health/ready`,
`/api/reservation/health/ready`, `/api/communication/health/ready` e
`/api/complaint/health`. Espera-se HTTP 200 e status `ready` nas rotas de readiness,
e `ok` em `/health`. Saúde não substitui os testes funcionais.

Para diagnóstico:

```sh
kubectl --context hiveapp-minikube -n hiveapp get pods,services,pvc,jobs
kubectl --context hiveapp-minikube -n hiveapp get events --sort-by=.metadata.creationTimestamp
kubectl --context hiveapp-minikube -n hiveapp logs deployment/communication-service --tail=50
```

## 6. Atualizações e repetição das migrações

Preferencialmente, use uma nova tag por versão: altere `image:` nos YAMLs dos Deployments,
Jobs e init containers correspondentes; construa/carregue as imagens com a mesma tag.
A alteração do template dispara o rollout ao aplicar os YAMLs novamente.

Para uma atualização local mantendo `:local`, reconstrua/carregue as imagens e,
depois de aplicar os manifests e concluir as migrações, reinicie os Deployments:

```sh
kubectl --context hiveapp-minikube -n hiveapp rollout restart deployment
kubectl --context hiveapp-minikube -n hiveapp rollout status deployment --timeout=240s
```

Esse reinício também é necessário após mudar ConfigMap/Secret consumidos como variáveis
de ambiente. A antiga substituição automática de tags/checksum não faz parte do fluxo.

Jobs têm nomes fixos e seus templates são imutáveis. Antes de repetir migrações ou
alterar suas imagens, confirme que não há Jobs de migração em execução. Remova somente
os Jobs encerrados desse grupo e reaplique:

```sh
kubectl --context hiveapp-minikube -n hiveapp get jobs -l hiveapp/task=migrate
kubectl --context hiveapp-minikube -n hiveapp delete jobs -l hiveapp/task=migrate
kubectl --context hiveapp-minikube apply -k k8s/overlays/local/migrations
kubectl --context hiveapp-minikube -n hiveapp wait --for=condition=complete job -l hiveapp/task=migrate --timeout=210s
```

A exclusão desses Jobs não exclui o PVC. Nas seis APIs TypeScript, o histórico de migração fica no banco e evita
reaplicar SQL registrado. Reclamações (Dart) reexecuta seus SQLs idempotentes com
`IF NOT EXISTS` e lock consultivo; não possui o mesmo histórico do Drizzle. Nunca interrompa uma migração em andamento com essa limpeza.
Jobs também expiram uma hora após terminar. As migrações TypeScript versionadas se
destinam a bases novas; bases criadas por `push` precisam de reconciliação do histórico.
Novas migrações devem ser compatíveis com a aplicação anterior; rollback de imagem
não reverte alterações no banco.

## 7. Dados fictícios (opcional)

Após as migrações e as aplicações estarem prontas, execute os dois Jobs novos:

```sh
kubectl --context hiveapp-minikube apply -k k8s/overlays/local/populate
kubectl --context hiveapp-minikube -n hiveapp wait --for=condition=complete job/populate-demo-bootstrap job/populate-demo-scenarios --timeout=450s
kubectl --context hiveapp-minikube -n hiveapp logs job/populate-demo-bootstrap
kubectl --context hiveapp-minikube -n hiveapp logs job/populate-demo-scenarios
```

O bootstrap cria contas, condomínio, residências e área comum; cenários aguarda as
 dependências e cria exemplos pelas APIs, incluindo encomenda/notificação. Não apagam
 dados existentes nem sobrescrevem identidades; usam IDs e marcadores próprios para
 evitar duplicação. Reexecuções preservam as datas originais. São exclusivos de
 demonstração local, com credenciais públicas documentadas no
 [tutorial da raiz](../README.md#9-dados-fictícios-com-jobs-opcional).

Reutilizam a imagem auth-service já carregada e recebem demo.cjs via ConfigMap;
 não exigem rebuild. Para repetir, confira que os dois Jobs estão encerrados e
 remova somente esses Jobs antes de reaplicar:

```sh
kubectl --context hiveapp-minikube -n hiveapp get jobs -l hiveapp/demo=v1
```

Somente se ambos estiverem Complete/Failed ou ausentes (TTL):

```sh
kubectl --context hiveapp-minikube -n hiveapp delete job populate-demo-bootstrap populate-demo-scenarios --ignore-not-found
kubectl --context hiveapp-minikube apply -k k8s/overlays/local/populate
kubectl --context hiveapp-minikube -n hiveapp wait --for=condition=complete job/populate-demo-bootstrap job/populate-demo-scenarios --timeout=450s
```

A exclusão dos Jobs não exclui os exemplos. Não interrompa Jobs ativos. Os antigos
 quatro Jobs destrutivos foram substituídos; os scripts do Compose continuam
 disponíveis e destrutivos. O fixture antigo scripts/populate-local.cjs não está
 nesta revisão. Consulte [comportamento e limites](jobs/populate/README.md).

## 8. Reinícios e parada preservando dados

O barramento usa uma réplica e `Recreate`: suas inscrições são mantidas em memória.
Comunicação renova a inscrição a cada 15 segundos e repete tentativas após falhas.
Eventos durante a interrupção podem ser perdidos; não há fila durável.

```sh
kubectl --context hiveapp-minikube -n hiveapp rollout restart deployment/event-bus
kubectl --context hiveapp-minikube -n hiveapp rollout status deployment/event-bus --timeout=180s
```

Para parar o perfil preservando seus dados:

```sh
minikube stop -p hiveapp-minikube
```

Para retomar:

```sh
minikube start -p hiveapp-minikube --driver=docker --cpus=4 --memory=6144 --keep-context
kubectl --context hiveapp-minikube -n hiveapp rollout status statefulset/db --timeout=300s
kubectl --context hiveapp-minikube -n hiveapp rollout status deployment --timeout=240s
```

Reabra os dois comandos `minikube service` para obter URLs atuais. `stop` preserva o
perfil; excluir perfil, namespace ou PVC pode apagar dados. Não há backup automático
nem importação dos dados do kind/Compose. Não use `minikube delete` como forma de parar.

## Relação com a aula

Deployments/labels, Services ClusterIP/DNS, acesso NodePort, atualização de imagens
e consulta de logs seguem os conceitos da apostila. Minikube com driver Docker uniformiza Windows/Linux;
StatefulSet, PVC e Jobs complementam o roteiro. Os arquivos Kustomize apenas agrupam
YAMLs para `kubectl apply -k`; não exigem uma ferramenta adicional ao kubectl.
A demonstração é React/Flutter web: não certifica a entrega mobile Android.

Veja [VALIDATION-MINIKUBE.md](VALIDATION-MINIKUBE.md) para esta migração e
[VALIDATION.md](VALIDATION.md) para evidências históricas do kind.
