# HiveApp — Flutter

Aplicativo Flutter com login, seleção de condomínio, menu lateral, Home com
avisos e eventos, notificações, visitantes, reservas, gerenciamento de moradores, reclamações
integradas à API e configurações de idioma.
O código Dart fica em `lib`, com arquivos em `snake_case`.

## Estrutura

```text
lib/
├── main.dart                    # Inicialização do Flutter
├── app.dart                     # Tema, idiomas, dependências e navegação
├── config.dart                  # URLs dos serviços, RESERVATION_URL e APP_LANGUAGE
├── components/complaints/       # Cabeçalho, filtros, lista, formulário, detalhes e diálogos
├── theme/app_theme.dart         # Tokens compartilhados do design system
├── components/login_box/        # Logo, campos e botão
├── components/navigation/       # Menu lateral e identificação do condomínio
├── components/home/             # Seções, conteúdo expansível e data dos eventos
├── components/notifications/    # Formulário e seletor de residências
├── components/reservations/     # Modos, calendário, cadastro e listas de reservas
├── components/residents/        # Grupos, residências, moradores e editor
├── components/shared/           # Feedback de erro, estado vazio e tentativa
├── helpers/
│   ├── auth_service.dart        # Requisição HTTP e classificação de erros
│   ├── api_client.dart          # GET/POST/PATCH/PUT autenticados, timeout e falhas HTTP
│   ├── core_service.dart        # Vínculos e residências do prédio
│   ├── communication_service.dart # Listagem (Home) e envio de notificações
│   ├── reservation_service.dart # Áreas comuns e reservas
│   ├── residents_service.dart   # Consulta e edição de moradores
│   ├── preferences_storage.dart # Idioma persistido
│   ├── persist_user_session.dart # Validação e persistência do token do vínculo
│   └── session_storage.dart     # Tokens da conta e do vínculo
├── lang/
│   ├── login_localizations.dart # Delegate de localização
│   ├── app_localizations.dart   # Textos da área autenticada e meses
│   ├── pt/                     # login.json e app.json
│   ├── en/
│   └── es/
├── layouts/auth_layout.dart     # Layout adaptável e rolagem com teclado
├── layouts/app_shell.dart       # Sidebar permanente, view ativa e expiração da sessão
├── routes/app_routes.dart       # Nomes das rotas
├── routes/menu_destination.dart # Destinos, disponibilidade e permissões
├── types/                       # Conta, sessão, posts e falhas tipadas
└── views/
    ├── login.dart               # Formulário e estados da tela
    ├── building_selector.dart   # Seleção do vínculo após o login
    ├── home.dart                # Avisos e calendário responsivos
    ├── notifications.dart       # Envio de notificações (somente administradores)
    ├── reservations.dart        # Modos autorizados e composição de reservas
    ├── residents.dart           # Acesso e composição do gerenciamento
    └── settings.dart            # Troca de idioma

test/                           # Serviço, interface e traduções
```

## Executar

Com Docker, execute na raiz do repositório:

```sh
docker compose up --build -d
```

O Flutter fica em http://localhost:5174 e o React em http://localhost:5173.
`docker/Dockerfile` compila a aplicação com o SDK Flutter 3.47.7 e lockfile;
o runtime contém apenas Nginx e os arquivos web. Não é necessário Flutter no
host. O Nginx usa proxy `/api/*` na mesma origem e fallback de navegação.
Para atualizar apenas esta aplicação, use `docker compose up --build -d flutter-web`.

### Kubernetes com Minikube (Windows e Linux)

Obtenha o endereço web com `minikube -p hiveapp-minikube service flutter-web -n hiveapp --url`.
No Windows, mantenha esse terminal aberto. A aplicação usa NodePort e proxy `/api/*`
na mesma origem. O build reutiliza o Dockerfile existente, sem Flutter SDK no host.
Siga os [comandos diretos para Windows/Linux](../../k8s/README.md). Esta validação usa somente
o navegador; não certifica a entrega mobile exigida pelo enunciado.

### Execução fora do Docker

Na pasta deste projeto, com o Flutter SDK no PATH:

```sh
flutter pub get
flutter run -d chrome
```

Os serviços de autenticação, core e comunicação precisam estar em execução;
reclamações usa também o serviço na porta 8007. As demais portas padrão são
8001, 8000 e 8006, respectivamente. Visitantes usa 8003 e reservas 8005
(`VISITOR_URL` e `RESERVATION_URL`). Moradores utiliza o core. O host é `localhost`;
no emulador Android, `10.0.2.2`. Em um celular físico, configure URLs acessíveis
pelo dispositivo:

```sh
flutter run --dart-define=AUTH_URL=https://seu-servidor.example/api/auth --dart-define=CORE_URL=https://seu-servidor.example/api/core --dart-define=COMMUNICATION_URL=https://seu-servidor.example/api/communication --dart-define=COMPLAINT_URL=https://seu-servidor.example/api/complaint --dart-define=VISITOR_URL=https://seu-servidor.example/api/visitor --dart-define=RESERVATION_URL=https://seu-servidor.example/api/reservation
```

As variáveis são URLs base. O aplicativo acrescenta `/auth/login` ao serviço
de autenticação, `/account` e `/auth` ao core e `/posts` ao de comunicação.
A porta do backend deve estar acessível ao dispositivo. Para Flutter web,
a API também deve permitir a origem do aplicativo por CORS.

Português é o idioma padrão. A tela Configurações permite escolher português,
inglês ou espanhol e salva a preferência entre aberturas e desconexões.
`APP_LANGUAGE` define o idioma inicial quando não existe preferência salva:

```sh
flutter run -d chrome --dart-define=APP_LANGUAGE=en
flutter run -d chrome --dart-define=APP_LANGUAGE=es
```

## Autenticação, sessão e atualização da página

- O login salva accountToken em flutter_secure_storage; a seleção de condomínio valida e salva userToken pelo helper persistUserSession.
- Ao iniciar, o app mostra carregamento e lê a sessão antes de decidir a tela. Token de usuário válido restaura o condomínio e a última seção autorizada; somente token de conta válido abre a seleção de condomínio; sem tokens válidos, abre login.
- Os tokens continuam nas chaves existentes. A chave sessionSection guarda apenas userId, buildingId e route. Escritas e limpezas são serializadas; um novo login, seleção de condomínio ou logout limpa a seção anterior.
- A última seção só é gravada após a navegação ser aceita pelos bloqueios de formulário. Falha ao gravar apresenta uma mensagem, mas não impede navegar. Falha na leitura inicial permite tentar novamente sem descartar credenciais.
- Não há renovação automática de tokens. HTTP 401 e expiração durante o uso encerram a sessão; falhas de rede não equivalem a logout. Idioma permanece separado e sobrevive ao logout.
- A cópia redundante hive.userData e a dependência shared_preferences foram removidas. Valores antigos dessa chave ficam inertes e não são consultados. Os dados tipados de UserSession são reconstruídos do token; assinatura e autorização continuam sendo verificadas pelas APIs.
- F5 conserva sessão e seção na mesma origem do navegador. Não conserva formulários, filtros, detalhes ou rolagem, nem sincroniza a seção com a URL. Alterar a porta do túnel Minikube muda a origem e pode exigir novo login.

### Atualização do Flutter no Minikube

A versão desta alteração usa a imagem hiveapp/flutter-web:complaints-refactor-20261111-071233. Em uma atualização futura,
use uma tag nova e altere a imagem em k8s/base/flutter-web/deployment.yaml antes de aplicar.
Da raiz do repositório:

```sh
docker build -f frontMobile/front_flutter/docker/Dockerfile -t hiveapp/flutter-web:complaints-refactor-20261111-071233 .
minikube -p hiveapp-minikube image load hiveapp/flutter-web:complaints-refactor-20261111-071233 --daemon
kubectl --context hiveapp-minikube -n hiveapp apply -f k8s/base/flutter-web/deployment.yaml
kubectl --context hiveapp-minikube -n hiveapp rollout status deployment/flutter-web --timeout=240s
minikube -p hiveapp-minikube service flutter-web -n hiveapp --url
```

Entrega de 11/11/2026: testes afetados foram adaptados, mas não executados. Não foram
executadas análise estática ou validação funcional, por solicitação do usuário.
Build e rollout são etapas operacionais, não evidência de correção funcional.

## Home e navegação

- `GET /posts` usa exclusivamente o token de usuário e mantém a ordem da API.
- Posts sem `eventAt` aparecem em Avisos; os demais, no Calendário.
- Datas são convertidas para o fuso do dispositivo e formatadas conforme o idioma.
- A Home usa duas colunas de mesma largura quando a área de conteúdo tem pelo
  menos 768 pixels: Avisos à esquerda e Calendário à direita, com títulos fixos e
  rolagens independentes. Em telas menores, as seções ficam empilhadas com uma
  única rolagem e atualização por gesto.
- Avisos mostram inicialmente apenas o título e um indicador. Clicar ou ativar
  pelo teclado expande/recolhe a data de publicação e a descrição completa.
  Vários avisos podem ficar abertos; a expansão é preservada por ID ao atualizar
  os dados ou redimensionar a janela. Eventos mantêm título, data e horário no
  cabeçalho e expandem a descrição completa ao clicar, sem “Ler mais”.
- Cada lista tem painel surface com borda discreta e itens canvas mais escuros,
  conforme a exceção da Home registrada no design system.
- Atualização por gesto ou botão, carregamento, listas vazias e falhas com nova
  tentativa têm estados próprios. Uma atualização que falha preserva os posts.
- A sidebar permanece visível: 240 unidades lógicas com ícones e textos em
  janelas a partir de 1024; abaixo disso, 64 com ícones, tooltips e rótulos
  acessíveis. Identifica o condomínio e destaca a view ativa.
- O `AppShell` mantém a navegação e troca apenas a view da main box, sem empilhar
  seções. Sidebar e conteúdo compartilham a mesma superfície contínua, sem margem
  externa, contorno, recorte arredondado ou linhas divisórias no shell. O padding
  interno das views, a área segura e o ajuste ao teclado são preservados.
  Login e seleção de condomínio ficam fora do shell.
- Reabrir uma seção recria a view e consulta os dados novamente; selecionar a
  seção atual, redimensionar ou trocar o idioma preserva a instância ativa.
- Voltar fecha primeiro formulário/detalhe de Reclamações, depois retorna à Home.
  Na Home, segue a saída normal da plataforma. Rascunhos exigem confirmação ao
  sair e envios em andamento bloqueiam a navegação. Mensagens locais ficam
  dentro do painel, mantendo a sidebar acessível.
- Home, Configurações, Reclamações, Acessos, Moradores e Reservas estão
  disponíveis conforme as permissões. Encomendas permanece indisponível.
- A regra de permissão aceita qualquer permissão exigida ou `@core:admin`,
  como no web. Itens sem permissão ficam desabilitados e explicam o motivo no
  texto, tooltip e rótulo acessível.

## Reservas e moradores

Reservas apresenta os modos Criar, Condomínio e Minha residência, nesta ordem,
selecionando inicialmente o primeiro autorizado. Criar exige `@reservation:create`
e residência vinculada; Condomínio exige `@reservation:view:building`; Minha
residência exige `@reservation:view:residency` e vínculo. `@core:admin` libera as
permissões, mas não substitui o vínculo residencial. O calendário usa dias
inteiros e envia `reservationDate` como `YYYY-MM-DD`, sem conversão UTC.
Áreas comuns e reservas são carregadas do serviço; falhas de consulta não são
tratadas como disponibilidade confirmada. Não há edição nem cancelamento.

Moradores exige `@core:user:manage` ou `@core:admin`, como o React. A view
coordena a árvore de grupos/residências/moradores; o editor permite nome e
permissões textuais, sem duplicatas. Cancelar não altera os dados exibidos;
salvar atualiza a linha com a resposta do servidor. Na própria conta, o editor
permite somente nome, conforme o contrato atual do core. Não inclui cadastro,
exclusão, transferência ou ativação de moradores.

Views compõem as telas; componentes próprios ficam em `components/reservations`
e `components/residents`, serviços HTTP em `helpers` e modelos em `types`.
As pendências do backend excluídas do escopo e a validação adiada estão em
[registro desta implementação](../../audit/implementacao-flutter-reservas-moradores-home-docker.md).

## Plataformas

- Android: permissão de Internet e backup desabilitado para o armazenamento protegido.
  HTTP sem TLS está liberado somente no build de debug para desenvolvimento local.
  Use HTTPS em release e em dispositivos Apple.
- iOS/macOS: capacidades de Keychain configuradas; no macOS também há permissão de
  cliente de rede. Compilar e validar essas plataformas requer macOS e a configuração
  de assinatura/provisionamento no Xcode.
- Web: o armazenamento do plugin depende de HTTPS ou localhost e é isolado por origem
  do navegador. Não equivale ao Keychain nativo. Use HTTPS para o aplicativo e a API
  em produção.
- Windows: o plugin requer as ferramentas C++/ATL do Visual Studio.
- Linux: consulte os pré-requisitos de libsecret do plugin antes do build nativo.

Documentação das dependências: [HTTP](https://pub.dev/packages/http),
[tokens](https://pub.dev/packages/flutter_secure_storage),
[preferências locais](https://pub.dev/packages/shared_preferences) e
[localização](https://docs.flutter.dev/ui/internationalization).

## Verificar

```sh
dart format --output=none --set-exit-if-changed lib test
dart analyze lib test
flutter test
flutter build web
```

Os testes usam respostas HTTP simuladas e armazenamento em memória. Eles cobrem
validação, contrato da API, falhas, prevenção de envios duplicados, gravação antes
da navegação, saída, descarte da tela durante uma requisição, proteção das rotas,
permissões, classificação dos posts, expiração, atualização com falha e idioma
persistido. Os testes de sessão cobrem tokens, restauração e nova tentativa após
falha de armazenamento. Os layouts são exercitados em telas de 320 pixels com texto ampliado
nos três idiomas.

Para gerar imagens locais de inspeção a partir dos testes de widgets:

```sh
flutter test test/main_flow_test.dart --dart-define=CAPTURE_PREVIEWS=true
```

As imagens ficam em `build/previews`. No Windows, essa opção carrega Segoe UI
para que as imagens usem uma fonte legível em vez da fonte de teste Ahem.
As imagens usam dados simulados. A validação com credenciais reais exige uma
instância acessível da API e uma conta de teste; a validação Android exige um
emulador configurado ou um aparelho conectado.

Reclamações usa as seis permissões independentes documentadas na
[matriz de acesso](../../audit/permissoes-reclamacoes.md), derivadas do `UserSession`
já carregado. Visualização/resposta residencial usa `residencyId` e `buildingId`;
criação exige condomínio e aceita residência opcional. `@core:admin` concede todas
as ações dentro do condomínio; leitura não concede resposta ou alteração de status.

## Organização de reclamações

`views/complaints.dart` compõe a tela, controla seleção/formulário/rascunho,
avalia as permissões de apresentação e coordena a expiração da sessão.
`ComplaintsNavigationController` conecta descarte de rascunho e Voltar ao shell,
sem expor o State da view por uma GlobalKey.

- `components/complaints/`: widgets visuais com dados, capacidades e callbacks
  explícitos. Os formulários mantêm seus campos, foco e validação local; os
  componentes não acessam repositórios, sessão ou controller.
- `helpers/complaint_access.dart`: interpretação das permissões e identidade.
- `helpers/complaints_controller.dart`: requisições, paginação, concorrência,
  reconciliação e bloqueios defensivos de acesso.
- `helpers/complaints_repository.dart` e `http_complaints_repository.dart`:
  contrato de dados e implementação HTTP.
- `types/complaint.dart` e `complaint_failure.dart`: modelos, enums e erros.
- `lang/complaint_strings.dart`: textos e formatação, junto das traduções existentes.

O diretório `features/complaints` e o preview independente foram removidos.
A tela continua usando a mesma API, regras, estilos e traduções.

Execute `flutter test test/complaints` para verificar controller, HTTP, permissões,
navegação e a comparação visual. Os 12 goldens em `test/complaints/goldens` foram
capturados antes da extração: lista, detalhes, cadastro, vazio, erro e carregamento
em 390 e 1280 pixels. Usam a fonte padrão dos testes Flutter e dados fictícios.
Não atualize as referências automaticamente para aceitar uma divergência visual.

### Evidências da extração (11/11/2026, Windows)

- Suíte de reclamações: 104 testes aprovados, incluindo 12 comparações visuais
  com referências capturadas antes da refatoração.
- Suíte completa: 213 aprovados, 2 ignorados e 13 falhas em login/restauração.
  As mesmas 13 falhas foram reproduzidas em uma cópia temporária com a integração
  antiga de reclamações; não são regressões desta extração.
- `flutter analyze`: 6 avisos/informações remanescentes em `app.dart` e
  `helpers/session_storage.dart`, fora da lógica alterada de reclamações.
  Nenhum diagnóstico nos componentes, helpers, tipos e view de reclamações.
- Build Docker concluído e Deployment `flutter-web` atualizado no contexto
  `hiveapp-minikube` para `hiveapp/flutter-web:complaints-refactor-20261111-071233`.
- Edge: login com conta demo, seleção de condomínio, lista de reclamações e F5
  passaram antes e depois da implantação, sem gravar dados ou mudar permissões.
- Nenhuma execução nativa em Linux nesta entrega.

Os logs e capturas locais estão em `k8s/.local/complaints-*` (ignorados pelo Git).
