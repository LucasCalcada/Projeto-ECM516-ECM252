# HiveApp — Flutter

Interface de login em Flutter, organizada de forma similar ao frontend web.
O código Dart fica em `lib`, com arquivos em `snake_case`.

## Estrutura

```text
lib/
├── main.dart                    # Inicialização do Flutter
├── app.dart                     # Tema, idiomas, dependências e navegação
├── config.dart                  # AUTH_URL e APP_LANGUAGE
├── components/login_box/        # Logo, campos e botão
├── helpers/
│   ├── auth_service.dart        # Requisição HTTP e classificação de erros
│   └── session_storage.dart     # Persistência do token da conta
├── lang/
│   ├── login_localizations.dart # Delegate de localização
│   ├── pt/login.json
│   ├── en/login.json
│   └── es/login.json
├── layouts/auth_layout.dart     # Layout adaptável e rolagem com teclado
├── routes/app_routes.dart       # Nomes das rotas
├── types/auth_result.dart       # Resposta e falhas de autenticação
└── views/
    ├── login.dart               # Formulário e estados da tela
    └── account_session.dart     # Confirmação da autenticação e saída

test/                           # Serviço, interface e traduções
```

## Executar

Na pasta deste projeto, com o Flutter SDK no PATH:

```sh
flutter pub get
flutter run -d chrome
```

A API precisa estar em execução. Por padrão, o aplicativo usa
`http://localhost:8001`; no emulador Android, usa `http://10.0.2.2:8001`.
Em um celular físico, configure um endereço acessível pelo dispositivo:

```sh
flutter run --dart-define=AUTH_URL=https://seu-servidor.example
```

`AUTH_URL` é a URL base; o aplicativo acrescenta `/auth/login`.
A porta do backend deve estar acessível ao dispositivo. Para Flutter web,
a API também deve permitir a origem do aplicativo por CORS.

Português é o idioma padrão. Para usar inglês ou espanhol:

```sh
flutter run -d chrome --dart-define=APP_LANGUAGE=en
flutter run -d chrome --dart-define=APP_LANGUAGE=es
```

## Autenticação e escopo

- Envia `POST /auth/login` com JSON `{ email, password }`.
- Mantém a validação de campos obrigatórios do web; não altera a senha ou o email enviados.
- Trata HTTP 400/401/5xx, problemas de rede, timeout de 15 segundos e respostas inválidas.
- Salva apenas o token recebido, na chave `accountToken`, usando `flutter_secure_storage`.
- Aguarda a gravação antes de abrir a confirmação; a opção Sair remove o token.
- A senha não é persistida pelo aplicativo. O gerenciador de senhas do sistema pode oferecer autofill.
- A navegação remove o formulário anterior e protege a rota de confirmação contra acesso direto.
- Como no fluxo web inicial, o aplicativo começa no login. Ainda não há restauração automática
  de sessão, renovação de token ou seleção de residência.

O backend emite um token de conta com validade de uma hora. A confirmação atual
não representa uma residência selecionada. A próxima etapa é migrar
`BuildingSelector` e integrar o token de usuário, sem confundi-lo com `accountToken`.

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
[armazenamento](https://pub.dev/packages/flutter_secure_storage) e
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
da navegação, saída, descarte da tela durante uma requisição e layout pequeno com
teclado e texto ampliado nos três idiomas. A validação com credenciais reais exige
uma instância acessível da API e uma conta de teste.
