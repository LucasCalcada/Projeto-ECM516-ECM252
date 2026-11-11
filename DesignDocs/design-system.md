# HiveApp — Design system

Versão documental: **1.9**. Atualizado em **08/11/2026**. Aplicação: React e Flutter.

Este arquivo é a referência dos fundamentos visuais, tokens, componentes, estados e critérios de qualidade para os próximos desenvolvimentos. Ele consolida as regras DS-01 a DS-16 extraídas da análise do React e revisadas no planejamento das duas plataformas. É uma especificação documental: sua existência não significa que as telas atuais já estejam padronizadas.

## Como consultar

- Use este documento para decidir valores e comportamentos compartilhados.
- Use o [Style guide](style-guide.md) para compor telas, escrever mensagens e revisar uma entrega.
- Consulte o [relatório de análise e planejamento](padronizacao-front-reclamacoes.md) para diagnóstico, evidências, planos Flutter/React e QA.
- Regras de negócio, permissões, campos e endpoints seguem o código/contrato vigente do serviço. Os exemplos específicos de reclamações em DS-09, DS-14 e DS-15 não se tornam regras de outros serviços.

Este documento é a fonte normativa de design; o style guide explica sua aplicação. A seção de design do relatório original permanece como registro da análise de origem. Em novas revisões, atualizar primeiro estes dois documentos específicos, mantendo os IDs DS estáveis.

## Índice das regras

| Regra | Consulta |
| --- | --- |
| DS-01 | [Identidade e hierarquia](#ds-01--identidade-e-hierarquia) |
| DS-02 | [Cores e semântica](#ds-02--cores-e-semântica) |
| DS-03 | [Tipografia](#ds-03--tipografia) |
| DS-04 | [Espaçamento](#ds-04--espaçamento) |
| DS-05 | [Raios, bordas e elevação](#ds-05--raios-bordas-e-elevação) |
| DS-06 | [Componentes e interação](#ds-06--componentes-e-interação) |
| DS-07 | [Acessibilidade e foco](#ds-07--acessibilidade-e-foco) |
| DS-08 | [Responsividade](#ds-08--responsividade) |
| DS-09 | [Estados e status](#ds-09--estados-e-status) |
| DS-10 | [Feedback e recuperação](#ds-10--feedback-e-recuperação) |
| DS-11 | [Conteúdo](#ds-11--conteúdo) |
| DS-12 | [Internacionalização e datas](#ds-12--internacionalização-e-datas) |
| DS-13 | [Comunicação com backend](#ds-13--comunicação-com-backend) |
| DS-14 | [Sessão e acesso](#ds-14--sessão-e-acesso) |
| DS-15 | [Privacidade da apresentação](#ds-15--privacidade-da-apresentação) |
| DS-16 | [Governança e verificação](#ds-16--governança-e-verificação) |

## Base e unidades

A identidade vem dos serviços React de Encomendas, Visitantes e Reservas: tema escuro, neutros, acento ciano, ícones de traço e poucas bordas aparentes. Azul alternativo, raios 12/16 e contornos repetidos do legado são divergências a migrar.

Medidas de layout correspondem a CSS px no React e unidades lógicas no Flutter. No React, converter tipografia para rem preservando a escala relativa; no Flutter, respeitar escala de texto do sistema. As larguras responsivas se referem ao espaço de conteúdo disponível após navegação e margens.

O mapeamento atual está no [tema compartilhado Flutter](../frontMobile/front_flutter/lib/theme/app_theme.dart) e nos utilitários Tailwind usados diretamente no JSX React, como em [Encomendas](../front/src/components/packages/PackagesHeader.tsx), [Visitantes](../front/src/components/visitorAccess/VisitorAccessForm.tsx) e [Reclamações](../front/src/components/complaints/ComplaintsList.tsx). No React, seguir esse padrão: estilizar com Tailwind no JSX, sem folhas de estilo por funcionalidade, classes CSS próprias, estilos inline ou novas regras globais para a tela. `index.css` permanece somente como entrada do Tailwind e base já existente. Novas funcionalidades devem reutilizar os tokens e os mecanismos da plataforma.

## DS-01 — Identidade e hierarquia

Adotar o tema escuro como baseline compartilhado React/Flutter. Hierarquizar por superfície, espaço, tipografia e estado; manter aparência plana e poucas bordas aparentes. O shell existente organiza navegação, condomínio e sessão. O tema claro isolado da prévia Flutter não é baseline compartilhado: eventual manutenção exige extensão explícita futura do guia, sem outra identidade na integração inicial.

## DS-02 — Cores e semântica

Os nomes abaixo derivam do Tailwind v4 instalado, cuja fonte é OKLCH em `node_modules/tailwindcss/theme.css`. HEX são equivalentes sRGB aproximados para implementação Flutter; não usar tabelas de versões antigas. O ciano atual não é o HEX de cyan-300 do Tailwind v3.

| Token | Base React | sRGB aproximado | Uso |
| --- | --- | --- | --- |
| canvas | neutral-950 | `#0A0A0A` | Fundo geral e campos. |
| surface | neutral-900 | `#171717` | Painéis e sidebar. |
| surfaceRaised | neutral-800 | `#262626` | Hover, seleção neutra e camada elevada. |
| divider | neutral-800 | `#262626` | Divisor estrutural discreto. |
| borderMuted | neutral-700 | `#404040` | Contorno legado, sem obrigatoriedade no padrão novo. |
| controlBoundary | neutral-500 | `#737373` | Limite funcional de campo quando necessário. |
| textPrimary | neutral-100 | `#F5F5F5` | Títulos e conteúdo essencial. |
| textBody | neutral-300 | `#D4D4D4` | Corpo. |
| textSecondary | neutral-400 | `#A1A1A1` | Datas, descrição auxiliar e ajuda. |
| primary | cyan-300 | `#53EAFD` | Ação principal, foco e destaque. |
| primaryHover | cyan-200 | `#A2F4FD` | Hover da ação principal. |
| onPrimary | neutral-950 | `#0A0A0A` | Texto/ícone sobre ciano. |
| success | green-400 | `#05DF72` | Sucesso confirmado. |
| warning | yellow-400 | `#FDC700` | Aviso e Em análise. |
| danger | red-400 | `#FF6467` | Erro. |

Ciano canônico: `oklch(86.5% 0.127 207.078)`; hover: `oklch(91.7% 0.08 205.041)`. Texto/ícone sobre ciano usa onPrimary escuro. Cores semânticas acompanham rótulo/ícone. Vazio usa neutros, sem aparência de erro. Painéis novos usam superfícies sólidas; o `bg-neutral-900/40` observado é normalizado para permitir equivalência entre plataformas.

## DS-03 — Tipografia

Fonte de sistema, como a pilha `ui-sans-serif`, `system-ui`, `sans-serif` já usada pelo Tailwind, com fallbacks de emoji. Flutter usa a fonte de sistema; não pressupor Inter instalada. CSS rem no React e unidades lógicas no Flutter, sempre respeitando ampliação pelo usuário.

| Papel | Tamanho / entrelinha | Peso |
| --- | --- | --- |
| Título de página | 24 / 32 | 700 |
| Título de seção | 20 / 28 | 600 |
| Corpo | 16 / 24 | 400 |
| Campo, botão e rótulo | 14 / 20 | 600 em botão; 400–500 em campo/rótulo. |
| Metadado e badge | 12 / 16 | 400–600 |

Sentence case em títulos; caixa alta apenas em cabeçalhos curtos de tabela. Erro obrigatório e conteúdo principal não devem ser rebaixados a metadado.

## DS-04 — Espaçamento

Escala: **4, 8, 12, 16, 24, 32, 48**. Ícone/rótulo: 8; rótulo/campo/ajuda: 4–8; campos relacionados: 12–16; painel: padding 16, ou 24 em painel amplo; cabeçalho/conteúdo: 24; grandes regiões: 24–32. Margem de página: 16 no compacto, 32 a partir de largura disponível 768. Aplicar padding de página uma única vez, reconciliando o `p-2` externo do SidebarLayout com as margens dos serviços na futura migração.

## DS-05 — Raios, bordas e elevação

**Raio 6 em controles/badges; raio 8 em painéis/diálogos.** Elementos naturalmente circulares podem permanecer circulares. Base: `rounded-md` e `rounded-lg` dos serviços React. Raios 12/16 são divergências a migrar, incluindo a prévia Flutter.

Painel/cartão: borda decorativa 0 e sombra 0. Separar por superfície e espaço; divisor estrutural opcional de 1 em divider, sem grade completa. Campos usam contorno funcional de 1 em controlBoundary quando a superfície não bastar para identificá-los. Na composição canvas sobre surface definida aqui, esse contorno é necessário; só omitir com alternativa funcional comprovada de contraste ≥3:1. Evitar cartões aninhados com contornos repetidos. Diálogo: surfaceRaised, raio 8, backdrop preto a 60%, sem sombra pesada. Foco e erro permanecem visíveis: “poucas bordas” não elimina indicadores funcionais.

Decisão específica para listas de Reclamações no Flutter: cards por residência e condomínio usam canvas `#0A0A0A` sobre a página surface `#171717`, contorno de 1 em divider `#262626`, raio 8 e sombra 0. Preservar padding 16 e intervalo 12 entre cards. O detalhe expandido, carregamento e erros pertencem à mesma superfície escura. Divisores discretos, alinhados ao padding, separam cabeçalho/detalhes e antecedem Relato, Respostas, Histórico e ações disponíveis; não criar caixas aninhadas. Essa exceção não altera o formulário de cadastro, os contornos funcionais dos campos ou a sidebar sem divisores.

Decisão específica para a Home Flutter de 08/11/2026: delimitar cada lista de Avisos e Calendário com painel surface `#171717`, borda estrutural de 1 em divider `#262626`, raio 8 e padding 16. Os itens usam canvas `#0A0A0A`, raio 8, padding 16, intervalo 12 e sombra 0, sem segundo contorno decorativo. A descrição expandida mantém a superfície escura do item. A borda do painel é organizacional; foco continua usando indicador funcional de 2 em primary. Essa exceção atende à diferenciação visual solicitada para a Home e não altera o tema global de cartões nem o shell.

## DS-06 — Componentes e interação

Planejar componentes compartilhados de cabeçalho de página, painel, botão, campo, select, textarea, modos, badge, lista/tabela, feedback e confirmação. Uma ação principal contextual em ciano; secundárias neutras; terciárias em texto. Botão com ícone opcional 16, gap 8, padding horizontal 12/vertical 8 e raio 6, ampliando área de toque conforme DS-07. Hover primário usa primaryHover; neutro usa surfaceRaised; pressionar não desloca layout.

Disabled remove interação e explica impedimento relevante; opacidade 60% observada não autoriza tornar conteúdo essencial ilegível. Pending informa o verbo em andamento e impede duplicidade na ação afetada. Modos aparecem quando há mais de uma opção acessível; ativo em ciano/onPrimary, inativo neutro, sem contorno decorativo. Lucide 16 em menus/controles e 22–24 em cabeçalhos React; Flutter usa ícones de traço e significado equivalentes já disponíveis, sem pressupor nova dependência.

Decisão de interação de 02/11/2026 para Reclamações em React e Flutter: lista única em toda a largura útil, com expansão dos detalhes e ações dentro do registro selecionado, para morador e administrador. O cadastro substitui integralmente a listagem até concluir ou cancelar. O administrador inicia na visão do condomínio. Essa decisão do usuário prevalece sobre a composição anterior em duas colunas e deve ser aplicada também em telas amplas; ver o padrão de listas no [style guide](style-guide.md).

Na Home Flutter, avisos e eventos expandem no próprio item, sem “Ler mais”. Avisos recolhidos mostram título; eventos recolhidos mantêm título, data e horário para consulta rápida. Acionar novamente recolhe a descrição; permitir vários itens abertos, com estado por ID preservado ao atualizar e redimensionar enquanto o registro existir. O cabeçalho acionável aceita teclado e anuncia expansão. As duas listas permanecem lado a lado a partir de 768 de largura útil, com rolagens independentes e títulos fixos; abaixo disso ficam empilhadas em uma única rolagem.

## DS-07 — Acessibilidade e foco

Metas de aceitação do projeto, a verificar em cada implementação: contraste de texto normal ≥4,5:1, texto grande ≥3:1 e indicadores/limites funcionais ≥3:1 contra adjacentes. Foco visível de 2 em primary com afastamento de 2; não remover indicador sem substituto. Alvo mínimo **44×44 CSS px no React / 48×48 unidades lógicas no Flutter**, mesmo com ícone visual menor.

Garantir teclado e ordem previsível, controles semânticos, seleção/expansão anunciadas, rótulos persistentes, obrigatoriedade e erros associados. Placeholder não substitui rótulo. Diálogo recebe e contém foco, pode ser fechado e devolve foco ao acionador. Não depender apenas de cor. Conteúdo essencial deve funcionar com texto a 200%, teclado virtual e rolagem. Medir contraste real de cada composição na implementação, inclusive disabled e campos.

## DS-08 — Responsividade

Decisão de navegação Flutter de 02/11/2026: o shell autenticado mantém a sidebar sempre visível. Pela largura total disponível ao shell, usar 240 unidades lógicas com ícones/textos a partir de 1024 e 64 apenas com ícones abaixo disso, com tooltips e rótulos semânticos. Essa regra substitui a navegação recolhível no Flutter; React permanece com seu comportamento atual. Sidebar e main box usam a mesma surface contínua, sem margem externa, contorno, sombra ou recorte arredondado. O shell não usa divisores na sidebar nem abaixo do título; organiza grupos por espaço e estado selecionado. Essa decisão substitui o raio 8 e as margens externas inicialmente previstos para a main box, preservando o padding interno das views, SafeArea e ajuste ao teclado. Os breakpoints das features continuam considerando a largura útil após sidebar.

O shell troca a view sem empilhar seções. Uma nova seleção recria a view; resize, idioma ou seleção do item atual preservam seu estado. Voltar fecha primeiro formulário/detalhe, depois retorna à Home. Confirmar descarte de rascunho antes de trocar de seção ou sair e bloquear saída durante envio. Sidebar e conteúdo têm rolagens independentes, inclusive em telas baixas; mensagens locais ficam restritas à main box.

Breakpoints por **largura disponível de conteúdo**, em CSS px/unidades lógicas: compacto <768; médio 768–1023; amplo ≥1024. Compacto: navegação recolhível, uma coluna, filtros quebrando linha, formulário com largura útil, lista/detalhe em etapas. Médio: uma região principal; duas colunas de formulário apenas se rótulos/erros couberem. Amplo: lista/detalhe simultâneos quando ambos forem legíveis.

Descontar o shell ao avaliar espaço; não forçar duas colunas por largura externa da janela. Não depender de altura fixa para texto longo. Preferir rolagem principal; rolagem independente só em composição ampla intencional. Tabela pode rolar horizontalmente localmente, com ações acessíveis, sem transbordar a página.

## DS-09 — Estados e status

Distinguir carregamento inicial, sucesso, vazio, atualização com conteúdo, falha de leitura com retentativa, falha de gravação com rascunho, expiração e acesso negado. Para reclamações: `aberta` → “Aberta”, primary; `em_analise` → “Em análise”, warning; `encerrada` → “Encerrada”, neutro. Sempre texto/ícone além da cor. Valor desconhecido usa fallback neutro, sem habilitar ações. Resposta recebida não cria status `answered`; “encerrada” não afirma “resolvida”.

## DS-10 — Feedback e recuperação

Confirmar sucesso somente após resposta do servidor. Erro de leitura e “Tentar novamente” persistem na região afetada; erro de campo fica associado ao campo. Toast complementa a informação. Proposta: informativo/sucesso por pelo menos 5 segundos; aviso/erro que exige decisão permanece em região persistente até correção/dispensa. Os dois segundos atuais não são padrão. Preservar rascunho em falha no mesmo contexto; não repetir gravação automaticamente. No fluxo de reclamações, encerrar exige confirmação. Refresh e retentativa não apagam indiscriminadamente formulário/seleção válidos.

## DS-11 — Conteúdo

Verbos diretos: “Nova reclamação”, “Enviar reclamação”, “Responder”, “Marcar em análise”, “Encerrar reclamação”, “Tentar novamente”. Frases curtas, sem jargão de API, stack trace ou mensagem bruta do backend. Resumo de lista pode truncar com acesso claro ao detalhe completo. Usar “Identificador” para ID real; não inventar protocolo oficial.

## DS-12 — Internacionalização e datas

Usar PT/EN/ES existentes. Traduzir textos de estado, campos, erros conhecidos, confirmações e acessibilidade; manter valores da API intactos. React usa i18next; incluir futuramente namespace próprio no registro. Flutter reutiliza localização global, sem seletor independente na feature integrada. Datas respeitam idioma ativo e fuso de exibição definido como o fuso local do usuário/dispositivo, com indicação de fuso quando necessário. Receber UTC preservado e converter na apresentação; não subtrair horas manualmente nem fixar pt-BR.

## DS-13 — Comunicação com backend

`useService` é registro de instâncias Axios estáveis, com URLs configuradas e interceptor que lê `userToken` a cada requisição (`front/src/helpers/useService.ts`). Apesar do nome, não contém estado de hook. Reclamações React segue, por decisão do usuário, a organização de Acesso de Visitantes: a view consulta permissões e define a renderização; formulário, lista e detalhe executam suas requisições e ações diretamente pelo `useService` obtido no topo do componente. Não criar hook de coordenação, controller ou repositório HTTP específico para essa feature React. Peças puramente visuais continuam recebendo dados/callbacks. Reclamações está registrada como `complaint`, com URL configurável e sem endereço hardcoded por componente. Reutilizar Bearer de usuário; `accountToken` não substitui o token de vínculo.

O responsável pela integração trata DTOs, datas, status e erros, sem inventar campos/endpoints: componentes no React de Reclamações, adaptador no Flutter. Consultas e gravações têm recuperação distinta, sem retry indiscriminado de gravação. Troca de usuário/condomínio limpa contexto e invalida respostas tardias. Falha não vira lista vazia.

## DS-14 — Sessão e acesso

Separar cada ação e seu escopo segundo o contrato do serviço. **`@core:admin` é o god mode do administrador do prédio e concede todas as seis capacidades de reclamações dentro do `buildingId` do token.** As demais concessões são independentes:

| Ação | Permissão | Escopo |
| --- | --- | --- |
| Criar | `@complaint:create` | Exige `buildingId`; associa `residencyId` quando presente no token. |
| Visualizar residência | `@complaint:view:residency` | `buildingId` + `residencyId`; inclui registros de outros moradores da mesma residência. |
| Visualizar condomínio | `@complaint:view:building` | `buildingId`. |
| Mudar status | `@complaint:update:status` | `buildingId`. |
| Responder pela residência | `@complaint:respond:residency` | `buildingId` + `residencyId`. |
| Responder pela administração | `@complaint:respond:building` | `buildingId`. |

Não inferir ação a partir da permissão de leitura, nem leitura a partir de outra ação. Criação exige condomínio, sem exigir residência. A consulta residencial não é filtrada por autor. Não consultar escopo sem a permissão correspondente. No formulário exclusivo de quem só pode criar, não consultar lista/detalhe após o envio. As ações do detalhe exigem a respectiva permissão e o estado permitido do registro. Encerramento continua exigindo resposta administrativa persistida; resposta residencial não a substitui. O backend valida assinatura, expiração, permissões e IDs do JWT recebido em `Authorization`, sem confiar no armazenamento do navegador nem em IDs enviados pelo formulário. `@complaint:manage` foi substituída pelas seis permissões e não autoriza mais ações. Histórico e migração estão em [Permissões de reclamações](permissoes-reclamacoes.md).

### Sessão persistida no React

**Os dados de usuário e as permissões já são armazenados no `localStorage` pelo fluxo existente de autenticação e seleção de vínculo. Novas funcionalidades React devem consumir esses dados, sem repetir a decodificação do token.**

O fluxo atual funciona assim:

1. [Login](../front/src/views/Login.tsx) armazena `accountToken` e abre a seleção de vínculo.
2. [BuildingSelector](../front/src/views/BuildingSelector.tsx) obtém o token de usuário e chama [loadUserData](../front/src/helpers/loadUserData.ts).
3. `loadUserData` faz a decodificação centralizada e persiste `userToken` e os dados fornecidos pelo token, como `userId`, `buildingId`, `permissions`, `exp` e `residencyId`, quando presente. `permissions` é armazenado como JSON.
4. As telas e os helpers existentes usam esses dados persistidos; [useService](../front/src/helpers/useService.ts) já lê `userToken` para autenticar requisições.

O `localStorage` da sessão existente é a fonte de dados para a apresentação React. Não criar armazenamento paralelo nem decodificar novamente o JWT na tela, no hook, no repositório ou em outro helper para recuperar informações já persistidas. Por decisão do usuário, manter `loadUserData` e a verificação de permissões como na `main`, sem limpeza adicional de campos ou eventos próprios de sessão. A assinatura e a autorização do token continuam sendo verificadas pelo servidor.

Os guards existentes verificam a presença de `accountToken` e `userToken`; a tela usa diretamente `hasPermission` e `hasResidency`. Não acrescentar validação local obrigatória de `exp`, `userId` ou `buildingId`, temporizadores, listeners de sessão ou um hook de sessão observável para habilitar a funcionalidade. Se a API responder HTTP `401`, usar o fluxo de autenticação/seleção de vínculo existente. Essa decisão substitui o acompanhamento reativo de sessão introduzido na primeira implementação de reclamações.

### Reutilização dos helpers de acesso

| Necessidade | Ponto existente a reutilizar |
| --- | --- |
| Verificar permissões armazenadas | [hasPermission](../front/src/helpers/hasPermission.ts), que lê `permissions` do `localStorage`. |
| Verificar vínculo de residência | [hasResidency](../front/src/helpers/hasResidency.ts), que lê `residencyId` do `localStorage`. |
| Combinar sessão, permissão e estado do registro | Coordenação da tela/view ou hook da funcionalidade. |

**Não é necessário criar `complaintAccess` no React para duplicar essas verificações.** As condições específicas de atendimento, como registro não encerrado e resposta persistida antes de encerrar, ficam na coordenação da tela e continuam validadas pela API.

O `hasPermission` existente retorna verdadeiro quando encontra qualquer permissão solicitada **ou** `@core:admin`. Consultar separadamente cada permissão da tabela pelo helper contempla automaticamente o administrador do prédio. Reutilizar a implementação da `main`, sem modo estrito, novas validações do armazenamento ou novo `complaintAccess` no React. Verificar `buildingId` armazenado para habilitar o cadastro é uma condição dessa ação, sem acrescentar um novo guard de sessão.

Essa orientação sobre `localStorage` é específica do React. No Flutter, reutilizar `UserSession` já carregado e injetado e a estrutura de acesso existente; não repetir a decodificação na feature nem remover o `ComplaintAccess` que já faz parte do módulo.

## DS-15 — Privacidade da apresentação

Preservar a decisão de apresentação já descrita para a feature Flutter: não mostrar nome, avatar ou ID de autor/respondente e não enriquecer a tela consultando o cadastro do autor em outro serviço. Mostrar conteúdo, datas e movimentações sem identidade pessoal. Limitar os campos do adaptador que chegam à apresentação. Essa escolha, registrada no escopo da [documentação da feature](../docs/frontend/complaints/README.md), não promete anonimato no armazenamento: o backend mantém autoria interna. ID da reclamação pode ser exibido como identificador do registro.

## DS-16 — Governança e verificação

DS-01 a DS-15 orientam novos desenvolvimentos React/Flutter; exceções exigem registro e revisão. Na futura implementação, comparar plataformas com mesmos dados, perfil, idioma e largura útil: **320/375, 768 e 1280**, texto **100%/200%** e estados de carregamento, vazio, erro, conteúdo longo, visão própria/gestão, expiração, inválido e envio pendente. Capturas do baseline escuro devem comprovar paleta, hierarquia, raios 6/8, superfícies, foco e adaptação. Testes devem comprovar contrato, escopo, duplicidade, recuperação e troca de contexto. Revisão documental não comprova conformidade de telas ainda não implementadas.

## Evolução e controle de mudanças

Ao propor alteração, registrar a regra DS afetada, motivo, valor/comportamento anterior e novo, impacto em React/Flutter e evidência de revisão. Atualizar os exemplos e o checklist do [Style guide](style-guide.md) no mesmo trabalho. Não criar uma paleta ou escala local para contornar uma regra compartilhada.

Mudanças no contrato de um serviço devem atualizar sua documentação funcional; os fundamentos visuais só mudam se houver uma decisão de design correspondente. Aplicar a matriz DS-16 antes de declarar uma tela padronizada.

| Versão | Data | Registro |
| --- | --- | --- |
| 1.0 | 29/10/2026 | Separação das 16 regras do relatório de auditoria em referência própria para desenvolvimento. |
| 1.1 | 01/11/2026 | Registrado o contrato de sessão React em localStorage, a reutilização de hasPermission/hasResidency e o planejamento de verificação explícita sem novo complaintAccess. |
| 1.2 | 01/11/2026 | Decisão do usuário: core:admin é god mode do prédio; gestão aceita core:admin OU complaint:manage, reutilizando hasPermission sem modo estrito e preservando isolamento por condomínio. |
| 1.3 | 01/11/2026 | Decisão do usuário: restaurar loadUserData e hasPermission da main; remover validação local adicional e acompanhamento observável da sessão React. Expiração/autorização continuam tratadas pelo servidor e pelo fluxo existente de autenticação. |
| 1.4 | 02/11/2026 | Decisão do usuário: Reclamações no Flutter usa lista em toda a largura, expansão de detalhes e ações no próprio item e cadastro em etapa exclusiva, também para administradores. |
| 1.5 | 02/11/2026 | Mesmo fluxo aplicado ao React: lista com expansão por item, cadastro exclusivo e administrador iniciando nas reclamações do condomínio. Mantido o gerenciamento de sessão da main. |
| 1.6 | 02/11/2026 | Correção do padrão React: Tailwind diretamente no JSX, seguindo as demais interfaces. Removidos CSS próprio de Reclamações e regras próprias adicionadas ao shell; mantida apenas a entrada/base global existente. |
| 1.7 | 02/11/2026 | Seis permissões independentes, leitura/resposta por residência e condomínio, criação com buildingId e residência opcional, autorização pelo JWT no backend. Substitui manage e a consulta por autor. |
| 1.8 | 02/11/2026 | Reclamações React segue Visitantes: view define acesso/composição; componentes executam consultas e ações via useService, sem hook/repositório específicos. Flutter e backend preservam suas arquiteturas. |

