# HiveApp — Flutter

Aplicativo Flutter com login, seleção de condomínio, menu lateral, Home com
avisos e eventos, reclamações integradas à API e configurações de idioma.
O código Dart fica em `lib`, com arquivos em `snake_case`.

## Estrutura

```text
lib/
├── main.dart                    # Inicialização do Flutter
├── app.dart                     # Tema, idiomas, dependências e navegação
├── config.dart                  # AUTH_URL, CORE_URL, COMMUNICATION_URL, COMPLAINT_URL e APP_LANGUAGE
├── features/complaints/         # Domínio, controller, adaptador HTTP e interface
├── theme/app_theme.dart         # Tokens compartilhados do design system
├── components/login_box/        # Logo, campos e botão
├── components/navigation/       # Menu lateral e identificação do condomínio
├── components/home/             # Seções, conteúdo expansível e data dos eventos
├── components/shared/           # Feedback de erro, estado vazio e tentativa
├── helpers/
│   ├── auth_service.dart        # Requisição HTTP e classificação de erros
│   ├── api_client.dart          # GET/POST/PATCH autenticados, timeout e falhas HTTP
│   ├── core_service.dart        # Listagem e seleção dos vínculos
│   ├── communication_service.dart # Avisos e eventos do usuário
│   ├── preferences_storage.dart # Idioma persistido
│   ├── load_user_data.dart      # Decodificação, validação e persistência do vínculo
│   ├── user_data_storage.dart   # Dados locais de apresentação em JSON
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
    ├── home.dart                # Avisos e calendário em uma única rolagem
    └── settings.dart            # Troca de idioma

test/                           # Serviço, interface e traduções
```

## Executar

Na pasta deste projeto, com o Flutter SDK no PATH:

```sh
flutter pub get
flutter run -d chrome
```

Os serviços de autenticação, core e comunicação precisam estar em execução;
reclamações usa também o serviço na porta 8007. As demais portas padrão são
8001, 8000 e 8006, respectivamente. O host é `localhost`;
no emulador Android, `10.0.2.2`. Em um celular físico, configure URLs acessíveis
pelo dispositivo:

```sh
flutter run --dart-define=AUTH_URL=https://seu-servidor.example/api/auth --dart-define=CORE_URL=https://seu-servidor.example/api/core --dart-define=COMMUNICATION_URL=https://seu-servidor.example/api/communication --dart-define=COMPLAINT_URL=https://seu-servidor.example/api/complaint
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

## Autenticação e escopo

- Envia `POST /auth/login` com JSON `{ email, password }`.
- Mantém a validação de campos obrigatórios do web; não altera a senha ou o email enviados.
- Trata HTTP 400/401/5xx, problemas de rede, timeout de 15 segundos e respostas inválidas.
- Salva o token da conta em `accountToken`, usando `flutter_secure_storage`.
- Aguarda a gravação antes de listar os vínculos por `GET /account`.
- Seleciona o vínculo por `GET /auth?userId=...`, usando o token de conta,
  e passa o JWT retornado ao helper `loadUserData`. Ele decodifica uma vez,
  valida identidade, condomínio e expiração, salva `userToken` no armazenamento
  protegido e os dados de apresentação no armazenamento local.
- Só abre a Home depois de concluir ambas as gravações. Em caso de falha, tenta
  remover o token de vínculo e os dados locais parciais; mantém `accountToken`
  para permitir nova tentativa na seleção.
- A opção Sair remove os dois tokens, os dados locais do usuário e a pilha de navegação.
- A senha não é persistida pelo aplicativo. O gerenciador de senhas do sistema pode oferecer autofill.
- A navegação protege seleção, Home e Configurações contra acesso direto.
- O aplicativo começa no login; ainda não há restauração automática ou renovação
  de sessão. Um novo login bem-sucedido descarta o token de vínculo e os dados locais anteriores.
- HTTP 401, expiração do token durante o uso e retomada do aplicativo com token
  expirado retornam ao login. HTTP 403 apresenta uma mensagem de falta de acesso.

O JSON fica na chave `hive.userData`, via `SharedPreferencesAsync`: `localStorage`
no Flutter web e armazenamento de preferências da plataforma nos aplicativos
nativos. Contém `userId`, `buildingId`, `buildingName`, `residencyId`,
`residencyName`, `permissions`, `tokenKind`, `iat` e `exp`, quando presentes no JWT.
Nulos, listas e números são preservados; os tokens não são duplicados nesse JSON.
Uma seleção substitui o objeto inteiro e a expiração também o remove. O idioma
fica separado e sobrevive ao logout.

As views recebem `UserSession` em memória para acesso imediato aos dados tipados,
sem ler o armazenamento ou decodificar o token durante `build`. O JSON persistido
não restaura uma sessão ao reabrir o aplicativo e não é fonte de autorização.

As claims do JWT são usadas para apresentação. A verificação da assinatura e
a autorização das operações são responsabilidade dos serviços.

## Home e navegação

- `GET /posts` usa exclusivamente o token de usuário e mantém a ordem da API.
- Posts sem `eventAt` aparecem em Avisos; os demais, no Calendário.
- Datas são convertidas para o fuso do dispositivo e formatadas conforme o idioma.
- Uma única rolagem contém as duas seções. Os textos podem ser expandidos.
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
- Home, Configurações e Reclamações estão disponíveis. Moradores, Reservas, Encomendas e
  Acessos aparecem indisponíveis até a migração dessas telas.
- A regra de permissão aceita qualquer permissão exigida ou `@core:admin`,
  como no web. Itens sem permissão ficam desabilitados e explicam o motivo no
  texto, tooltip e rótulo acessível.

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
persistido. `user_data_storage_test.dart` cobre JSON, isolamento da chave,
substituição do vínculo, rejeição de tokens inválidos e limpeza após gravações
parciais. Os testes de fluxo cobrem a espera pelas duas gravações e a ausência
de restauração automática. Os layouts são exercitados em telas de 320 pixels com texto ampliado
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
