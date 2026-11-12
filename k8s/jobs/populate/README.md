# Dados fictícios do Kubernetes

Entrada: `kubectl --context hiveapp-minikube apply -k k8s/overlays/local/populate`.
Execute após as sete migrações e os dez Deployments estarem prontos. Veja os comandos
de espera, logs, reexecução e contas no [tutorial do Minikube](../../../docs/minikube.md#9-dados-fictícios-com-jobs-opcional).

`bootstrap.yaml` prepara autenticação, core e a área comum por SQL parametrizado.
É necessário criar as identidades antes de autenticar chamadas às APIs. O último
registro (área comum) sinaliza a preparação das dependências. `scenarios.yaml`
aguarda esse registro e a saúde das APIs, autentica as três contas e cria os exemplos
pelos contratos HTTP existentes. Uma notificação consultável pelo morador confirma
o processamento da encomenda. Os dois Jobs usam `demo.cjs`, montado por ConfigMap
com hash gerado pelo Kustomize, e os módulos pg/bcrypt da imagem auth-service.
Não é necessário reconstruir imagens ao modificar somente esse arquivo.

## Reexecução e limites

- Identificadores de preparação usam o prefixo `d3e00000`; os exemplos das APIs usam
  o condomínio/residência demo e marcadores como `[Demo K8s]`. Não há alteração de schema.
- Inserções de preparação usam `ON CONFLICT DO NOTHING` e validam os campos existentes.
  Uma identidade divergente causa falha, sem redefinir senha, perfil ou nome.
- Um advisory lock em authDb serializa os Jobs de demonstração. As APIs não usam
  esse lock: evite editar os exemplos manualmente durante a execução dos Jobs.
- Cada exemplo é consultado antes de ser criado. Falha parcial não desfaz os exemplos
  já criados: a execução seguinte completa os que faltam. Não existe transação
  distribuída nem garantia geral de exactly-once para APIs durante falhas de rede.
- Os dados retornados pelas APIs têm IDs gerados por elas; não alteramos contratos
  para aceitar IDs externos. Alterar/remover manualmente os marcadores de identificação
  pode fazer a reexecução entender que um exemplo está ausente.
- Reserva: três dias depois da criação; assembleia: sete dias depois; visita: horário
  atual. Reexecuções preservam datas originais e alterações de estado. Para uma nova
  demonstração com datas futuras, use outro ambiente/banco de demonstração.
- Se uma encomenda existir sem notificação, o Job republica PACKAGE_ARRIVED usando
  o mesmo pacote e autor. Comunicação já deduplica esse aviso. A reinscrição do serviço
  no barramento ocorre periodicamente; o Job aguarda com limite e falha se não recuperar.
- `backoffLimit: 0`, prazo de 420 segundos e TTL de uma hora. Consulte logs para
  distinguir falha de preparação, login, API ou evento antes de reexecutar.
- Não são carregadas credenciais nos logs. A senha das contas fictícias é pública
  e intencional: esses Jobs são somente para ambiente local de demonstração.

Os quatro YAMLs antigos que chamavam populações destrutivas foram substituídos.
Jobs antigos já existentes no cluster não são removidos pelo `apply`; não reexecute
`populate-auth-service`, `populate-core-service`, `populate-reservation-service` ou
`populate-communication-service`. Os scripts de população do Compose foram preservados.

## Validação em 11/11/2026

Executada no Windows/Docker Desktop, Minikube 1.39.0 e Kubernetes 1.37.0, em
namespace temporário com PostgreSQL/PVC próprios e as sete APIs reais. O namespace
principal `hiveapp` não recebeu os dados deste teste.

| Teste | Resultado |
| --- | --- |
| Primeira execução após migrações | Dois Jobs concluídos; três contas autenticadas; cenários criados; notificação consultada pelo morador |
| Segunda execução | Conteúdo completo das tabelas das sete bases comparado por SHA-256; nenhuma alteração ou duplicação |
| Registro anterior | Registro sentinela fora dos IDs demo permaneceu idêntico |
| Notificação ausente | Aviso removido somente no banco de teste e recuperado via barramento; nenhuma nova encomenda |
| Identidade alterada | Nome demo alterado somente no teste; bootstrap falhou explicitamente e preservou o nome |

Os recursos temporários foram removidos após os testes. A execução nativa em Linux
permanece pendente; os comandos publicados usam as mesmas ferramentas nos dois sistemas.
