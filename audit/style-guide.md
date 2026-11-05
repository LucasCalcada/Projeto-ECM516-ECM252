# Style guide — HiveApp

Versão documental: 1.8. Atualizado em: 02/11/2026. Aplicação: interfaces React e Flutter.

Este guia orienta a composição de telas e o comportamento dos componentes nos próximos desenvolvimentos. A fonte normativa de tokens e regras DS-01 a DS-16 é o [design system](design-system.md). O [relatório de padronização e reclamações](padronizacao-front-reclamacoes.md) preserva o diagnóstico, o contrato examinado, os planos e a revisão de QA que originaram os dois documentos.

As regras orientam a adoção futura; sua documentação não significa que todas as telas existentes já foram migradas. Este guia não contém implementação de componentes.

## Índice

- [Como começar uma tela](#como-começar-uma-tela)
- [Receitas de interface](#receitas-de-interface)
- [Estados e mensagens](#estados-e-mensagens)
- [Aplicação em React e Flutter](#aplicação-em-react-e-flutter)
- [Sessão e helpers de acesso no React](#sessão-e-helpers-de-acesso-no-react)
- [Regras específicas de reclamações](#regras-específicas-de-reclamações)
- [Checklist de entrega](#checklist-de-entrega)
- [Manutenção do guia](#manutenção-do-guia)

## Como começar uma tela

1. **Defina a tarefa e o perfil.** Registre o que a pessoa precisa consultar ou concluir, seu condomínio ativo e as capacidades necessárias. Separe consulta, cadastro e gestão conforme o serviço, sem presumir que um administrador genérico pode executar qualquer ação.
2. **Confira o contrato real.** Liste operações, campos obrigatórios, limites, filtros, paginação, datas e erros. Defina o modelo de apresentação sem inventar valores, protocolos, totais ou endpoints.
3. **Escolha a composição.** Use o shell existente, cabeçalho de serviço, conteúdo principal e ação contextual. Determine os estados de leitura/gravação antes de desenhar somente o caso de sucesso.
4. **Aplique o design system.** Use tokens por papel semântico; mantenha o tema escuro, superfícies sólidas e poucos contornos. Planeje controles de raio 6 e painéis de raio 8, sem copiar inconsistências de telas legadas.
5. **Desenhe pela largura útil.** Desconte navegação e margens; uma coluna no compacto/médio, regiões simultâneas apenas quando legíveis. Inclua texto longo, erro, foco e teclado virtual.
6. **Planeje a verificação.** Vincule decisões às regras DS aplicáveis e aos critérios do serviço. Prepare os cenários do checklist deste guia.

Referências: DS-01 a DS-08 para composição; DS-09 a DS-15 para estados, conteúdo, integração e acesso; DS-16 para verificação.

## Receitas de interface

### Cabeçalho e navegação

No Flutter autenticado, usar a sidebar permanente e main box definidas na decisão DS-08 de 02/11/2026: sidebar de 64 com ícones no compacto e 240 com ícones/textos quando o shell dispõe de pelo menos 1024. O compacto mantém tooltips, nomes acessíveis e estado selecionado; não usa drawer. Sidebar e conteúdo formam uma superfície contínua, sem margem externa, contorno ou recorte arredondado na main box. Separar grupos por espaço, sem divisores na sidebar ou abaixo do título. Preservar padding interno das views, SafeArea e ajuste ao teclado. O título da seção fica no painel e mensagens locais não cobrem a sidebar. Configurações e Sair ficam ao final da navegação, alcançáveis por rolagem em alturas reduzidas. A orientação de recolhimento abaixo continua aplicável ao React.

O cabeçalho de serviço contém ícone de traço 22–24, título 24/32, contexto/ajuda secundária e ações que quebram linha. Preserve o significado e a escala do título entre modos. O shell mantém navegação, condomínio e sessão; a feature ocupa seu conteúdo, sem recriar outro shell.

No menu, ícone visual de 16 e rótulo persistente; item ativo com superfície neutra e estado anunciado. No seletor de modos da página, opção ativa em primary/onPrimary e inativas neutras. Exiba o seletor apenas quando houver mais de uma opção acessível. No compacto, a navegação deve poder ser recolhida e operada por teclado/leitor de tela.

Uma restrição apresentada no menu não substitui a proteção da página acessada por URL nem das operações. Referências: DS-01, DS-03, DS-06, DS-07, DS-08 e DS-14.

### Painéis e agrupamentos

Use surface sólida, raio 8, padding 16 ou 24 e espaço de 24–32 entre grandes regiões. Separe grupos por hierarquia e espaço. Painéis e cartões têm borda decorativa 0 e sombra 0; divisores estruturais discretos podem ser usados quando explicarem a organização.

Nas listas de Reclamações Flutter, aplicar a exceção registrada em DS-05: card canvas `#0A0A0A`, borda de 1 em `#262626`, raio 8, padding 16 e intervalo 12. Cabeçalho e detalhe expandido compartilham o fundo escuro, inclusive durante carregamento e erro. Usar separadores da mesma cor da borda entre cabeçalho/detalhe e antes de Relato, Respostas, Histórico e ações, com respiro e sem caixas internas. Aplicar igualmente nos escopos residência e condomínio; preservar cadastro, foco e limites dos campos.

Evite envolver cada campo, linha e subgrupo em outro cartão com contorno. A margem de página é aplicada uma vez: 16 no compacto e 32 a partir de largura útil 768. Referências: DS-02, DS-04 e DS-05.

### Botões e ações

| Papel | Aplicação |
| --- | --- |
| Principal | Uma ação principal por contexto; primary ciano com texto/ícone onPrimary escuro. |
| Secundária | Preenchimento neutro, para alternativas como Cancelar ou Voltar. |
| Terciária | Texto, para ação de menor ênfase quando permanecer identificável. |
| Indisponível | Sem interação e com explicação do impedimento quando relevante. |
| Pendente | Verbo em andamento, indicação de progresso e bloqueio de envio duplicado na ação afetada. |

Raio 6; ícone opcional 16 com gap 8; padding horizontal 12 e vertical 8, ampliando a área interativa ao mínimo de 44×44 CSS px no React ou 48×48 unidades lógicas no Flutter. Preserve a posição do conteúdo ao mudar de estado. Primary atual é aproximadamente `#53EAFD`, com texto escuro: texto branco sobre ciano não é a composição prescrita. Consulte os valores completos no design system.

Hover/pressed não substituem foco visível. Mantenha foco de 2 com afastamento de 2. Referências: DS-02, DS-05, DS-06 e DS-07.

### Campos e formulários

Organize o formulário na ordem natural da tarefa: rótulo persistente, controle, ajuda/limite e erro associado. Indique obrigatoriedade, valide conforme o serviço e direcione o foco ao primeiro erro quando o envio for impedido. Placeholder pode exemplificar; não substitui rótulo.

Campos usam canvas e raio 6. Na composição canvas sobre surface, use contorno funcional de 1 em controlBoundary; só omita com alternativa funcional comprovada de contraste ≥3:1. A proposta de poucas bordas decorativas não autoriza retirar limite do campo, foco ou erro. Textarea acomoda conteúdo longo sem ocultar ações.

Uma coluna no compacto; duas colunas apenas quando rótulos, valores e erros couberem. Ao enviar, preserve os valores e bloqueie duplicidade. Em falha no mesmo contexto, mantenha o rascunho; ao trocar usuário/condomínio ou perder acesso, limpe os dados incompatíveis. Confirme descarte de alterações quando necessário para evitar perda involuntária. Referências: DS-04 a DS-10, DS-13 e DS-14.

### Lista, tabela e detalhe

Mostre primeiro as informações que ajudam a reconhecer e escolher o registro. Seleção deve ser identificável visualmente e por semântica. Resumo pode truncar somente quando houver acesso claro ao conteúdo integral no detalhe. Colunas e ações essenciais precisam permanecer alcançáveis.

No compacto, lista e detalhe são etapas com retorno que conserva filtros/posição válidos. No médio, mantenha região principal única. No amplo, permita simultaneidade se ambos os conteúdos couberem após descontar o shell. Prefira rolagem principal; rolagem horizontal local de tabela não deve transbordar a página.

Exceção definida pelo usuário em 02/11/2026 para Reclamações em React e Flutter: em todas as larguras, usar uma única lista em toda a área útil e expandir os detalhes e ações no próprio item selecionado. Não reservar uma coluna lateral para detalhes nem esconder a lista ao expandir um item. Aplicar também à visão de condomínio de `@core:admin`/`@complaint:view:building`, que é a visão inicial de quem pode ler o condomínio. O cadastro é uma etapa exclusiva, sem lista, filtros ou alternância de escopo; cancelar retorna à lista autorizada e rascunhos exigem confirmação antes do descarte. Essa decisão substitui o planejamento anterior de lista/detalhe simultâneos em colunas nessa funcionalidade. No React, os cabeçalhos dos itens são botões com `aria-expanded` e `aria-controls`; manter foco no acionador, permitindo expandir e recolher pelo teclado.

Distinga resumo de listagem e detalhe retornados pelo serviço. Não preencha ausências com dados imaginados. Exiba totais ou quantidade de respostas somente se houver fonte contratual confiável. Paginação/filtros seguem o contrato de cada serviço; páginas antigas não podem reaparecer após troca de filtro ou contexto. Referências: DS-06, DS-08, DS-09, DS-11 e DS-13.

### Status e badges

Use rótulo e ícone além da cor; raio 6 se houver badge. Selecione o token semântico pelo significado do estado. Não use verde para afirmar resolução quando o serviço informa apenas encerramento, nem vermelho para ausência de registros.

Traduza rótulos e preserve valores de transporte. Estado desconhecido recebe apresentação neutra e não habilita operações cujo direito dependa do estado. Os status exatos de reclamações estão na seção específica abaixo; outros serviços seguem sua própria máquina de estados. Referências: DS-02, DS-05, DS-09 e DS-12.

### Feedback e confirmações

Apresente erro na região afetada e erro de campo junto ao controle. Toast/snackbar complementa a informação: informativo/sucesso por pelo menos 5 segundos; aviso/erro que exige decisão permanece em região persistente até correção/dispensa. Confirme sucesso somente após confirmação do servidor.

Uma confirmação descreve a ação, sua consequência e a escolha de cancelar. Use linguagem concreta e a mesma nomenclatura do botão de origem. O diálogo tem surfaceRaised, raio 8 e backdrop preto a 60%; recebe/contém foco, pode ser fechado e devolve foco ao acionador. Não encadeie gravações automaticamente após falha ou confirmação incerta. Referências: DS-05, DS-07, DS-10 e DS-11.

## Estados e mensagens

| Situação | Tratamento visual e comportamento | Exemplo de texto |
| --- | --- | --- |
| Carregamento inicial | Indicação na região que está sendo consultada, com rótulo acessível. | “Carregando registros…” |
| Atualização | Preservar conteúdo válido e indicar que a consulta está em andamento. | “Atualizando…” |
| Vazio | Texto neutro e próxima ação pertinente ao perfil. | “Nenhum registro encontrado.” |
| Filtro sem resultado | Diferenciar ausência global e resultado do filtro; permitir alterar/limpar filtros. | “Nenhum resultado para os filtros selecionados.” |
| Falha de leitura | Mensagem persistente e retentativa explícita, sem simular vazio. | “Não foi possível carregar os registros. Tentar novamente.” |
| Validação | Mensagem associada ao campo, indicando correção necessária. | “Informe um título.” |
| Envio pendente | Verbo em andamento e proteção contra duplicidade. | “Enviando…” |
| Sucesso | Confirmar a ação persistida e atualizar a representação com a resposta real. | “Registro enviado.” |
| Falha de gravação | Manter rascunho no mesmo contexto; explicar resultado incerto quando aplicável. | “Não foi possível confirmar o envio. Consulte os registros antes de tentar novamente.” |
| Sessão expirada | Limpar contexto protegido e usar o fluxo existente de autenticação/vínculo. | “Sua sessão expirou. Entre novamente.” |
| Ação negada | Explicar a capacidade indisponível, sem confundir com expiração. | “Você não tem permissão para esta ação.” |
| Estado concorrente alterado | Reconsultar os dados e explicar o estado atual, sem repetir a gravação. | “O registro foi atualizado. Confira a situação atual.” |

Os textos são modelos editoriais, a adaptar ao resultado efetivamente conhecido. Use frases curtas, sentence case e verbos diretos; não apresente stack trace, URL interna ou mensagem bruta do backend. Traduza rótulos, erros conhecidos, confirmações e acessibilidade em PT/EN/ES. Formate datas no idioma ativo e fuso local do usuário/dispositivo, preservando UTC no transporte. Referências: DS-09 a DS-12.

## Aplicação em React e Flutter

No React, usar **utilitários Tailwind diretamente no JSX**, como nas interfaces de Encomendas e Visitantes. Não criar arquivo `.css` por funcionalidade, classes CSS próprias, atributo `style` ou regras globais para implementar a aparência da tela. Aplicar os tokens pelos utilitários existentes: `bg-neutral-950`/`bg-neutral-900`/`bg-neutral-800`, `text-neutral-100`/`text-neutral-300`/`text-neutral-400`, `bg-cyan-300` com `text-neutral-950`, `rounded-md` nos controles e `rounded-lg` nos painéis. Foco, erro, estado expandido, responsividade e backdrop também usam variantes Tailwind. O `index.css` mantém a entrada do Tailwind e a base existente, sem receber estilos de features. Identificadores de teste usam atributos `data-*`, separados da estilização.

| Decisão | React | Flutter |
| --- | --- | --- |
| Componentes | Em Reclamações, seguir Visitantes: view define permissões e composição; componentes de formulário/lista/detalhe mantêm dados e ações. Peças visuais reutilizáveis recebem dados/callbacks. | Centralizar tema e componentes compartilhados, sem identidade local concorrente por feature. |
| Tipografia e medida | Fonte de sistema, tamanhos em rem e área interativa em CSS px. | Fonte de sistema, unidades lógicas e escala de texto do usuário. |
| Ícones | Lucide nos tamanhos do DS. | Ícones de traço/significado equivalentes disponíveis no projeto. |
| Layout | Descontar sidebar/margens ao avaliar largura útil; evitar dependência de altura fixa. | Avaliar constraints do conteúdo após shell; acomodar teclado virtual e texto ampliado. |
| Transporte | Em Reclamações, consumir useService diretamente nos componentes responsáveis, sem hook ou repositório HTTP específicos; preservar cancelamento de consultas, validação e tratamento de falhas. | Reutilizar cliente/sessão injetados e adaptador da feature; não colocar a demo no caminho de produção. |
| Dados e acesso | Separar modelos de transporte/apresentação e gates de página/ação. | Separar modelos, controller e apresentação; conferir as capacidades reais do serviço. |
| Sessão e permissões | Consumir os dados já persistidos no localStorage; reutilizar hasPermission e hasResidency, sem nova decodificação do JWT por feature. | Receber UserSession já carregado por injeção e reutilizar a estrutura de acesso existente. |
| Localização | Reutilizar i18next e registros de idioma existentes. | Reutilizar localização/delegates e idioma global da aplicação. |

Nas duas plataformas, o token de usuário representa o vínculo com condomínio; token de conta não o substitui. No React de Reclamações, componentes tratam o contrato HTTP; no Flutter, o adaptador mantém essa responsabilidade. Troca de contexto invalida consultas pendentes e limpa dados anteriores. Ocultar uma ação não substitui autorização no servidor. Consulte DS-13 e DS-14 para os padrões de integração.

## Sessão e helpers de acesso no React

**Antes de propor leitura/decodificação de JWT ou novo helper de acesso, considerar que o fluxo existente já persiste os dados de usuário no `localStorage`.** Login armazena `accountToken`; após a seleção de vínculo, `BuildingSelector` chama `loadUserData`, que decodifica centralmente e armazena `userToken` e seus dados, incluindo `permissions` em JSON e `residencyId` quando presente. A funcionalidade usa esses dados já carregados. Detalhamento e fontes estão em [DS-14 — Sessão e acesso](design-system.md#ds-14--sessão-e-acesso).

Reutilizar `hasPermission` para verificar permissões e `hasResidency` para verificar residência, diretamente na tela, conforme o padrão da `main`. Combinar os resultados com o estado do registro na coordenação da funcionalidade. **Retirar da estrutura React proposta a criação de `complaintAccess`: ela duplicaria helpers existentes.** A decodificação inicial permanece em `loadUserData`, com a implementação da `main`; não é refeita na funcionalidade.

Manter os guards existentes de presença de `accountToken` e `userToken`. Não exigir `exp`, `userId` ou `buildingId` como uma nova validação de sessão no cliente, nem adicionar hook observável, temporizadores, listeners ou eventos próprios de sessão. O retorno HTTP `401` da API conduz ao fluxo existente de autenticação/seleção de vínculo. Essa orientação registra a decisão do usuário de voltar ao gerenciamento da `main`.

Para reclamações, consultar separadamente as seis permissões de [DS-14](design-system.md#ds-14--sessão-e-acesso) pelo `hasPermission` atual, que inclui `@core:admin` automaticamente. Cada botão depende de sua ação; a lista depende da leitura do respectivo escopo. O servidor repete a autorização usando o JWT assinado de `Authorization`, validando também condomínio e residência. Não usar `@complaint:manage` nem tratar login/autoria como permissão de leitura. Verificar condomínio para criar é uma condição da ação, sem acrescentar um guard de sessão.

No React, manter o fluxo de seleção e navegação da `main`, sem limpeza adicional do armazenamento em `loadUserData`; o estado da funcionalidade segue o ciclo de montagem/desmontagem da tela. Condições como registro encerrado e resposta prévia não são permissões: ficam na coordenação da funcionalidade e são verificadas pelo serviço. No Flutter, as views continuam usando a sessão tipada injetada e o `ComplaintAccess` existente. O helper `loadUserData` centraliza a decodificação e grava as claims de apresentação em um JSON `hive.userData` via preferências da plataforma, mantendo tokens no armazenamento protegido. A Home aguarda as duas gravações; novo login, logout e expiração limpam os dados do vínculo. Não ler preferências no `build` nem usar o JSON para restaurar autenticação automaticamente.

## Regras específicas de reclamações

Estas regras pertencem ao domínio de reclamações; não devem ser generalizadas automaticamente para outras features. O contrato vigente está em [Permissões de reclamações](permissoes-reclamacoes.md); o [relatório original](padronizacao-front-reclamacoes.md) preserva o histórico do planejamento.

- Status: aberta em primary, em análise em warning e encerrada em neutro, sempre com rótulo/ícone. Responder não altera o status; marcar em análise é uma ação separada.
- Encerramento exige resposta administrativa persistida e confirmação; não promete resolução nem concordância do morador.
- Aplicar seis permissões independentes: criar, visualizar residência, visualizar condomínio, mudar status, responder residência e responder condomínio. `@core:admin` concede todas dentro do condomínio do token. A visão residencial inclui todos os autores da mesma residência. Administradores iniciam na visão condomínio quando autorizados a lê-la.
- Criar exige `@complaint:create` e `buildingId`; residência é opcional e vem do token. Permissão somente de criação abre o formulário sem consultas de lista/detalhe; após sucesso, limpa os campos e permanece no formulário. Quem também pode ler retorna à lista.
- Formulário contém título, categoria e descrição conforme os limites reais. Resposta residencial e administrativa usam a mesma ação visual, mostrando a origem sem identidade pessoal. Não oferecer anexos, edição, exclusão ou reabertura.
- Não inventar protocolo ou total de registros. ID real, se exibido, recebe o rótulo Identificador. Listagem e detalhe têm contratos diferentes.
- Preservar a decisão DS-15 de não exibir nome, avatar ou ID de autor/respondente e não consultar outro serviço para enriquecer essas identidades. Isso não significa anonimato no armazenamento.

## Checklist de entrega

- [ ] A tela identifica sua tarefa, perfil, contexto e capacidades reais do serviço.
- [ ] No React, os dados de usuário vêm da sessão já persistida no localStorage, sem repetir a decodificação do JWT nem criar outro armazenamento.
- [ ] O gerenciamento React mantém o padrão da main, sem validação local adicional de sessão, listeners ou temporizadores de expiração; HTTP 401 usa o fluxo existente de autenticação.
- [ ] hasPermission e hasResidency são reutilizados; cada ação e consulta exige sua permissão, com core:admin como god mode do condomínio. Criar exige buildingId; leitura/resposta residencial exige residencyId.
- [ ] Tokens e regras aplicáveis foram consultados no design system; não há identidade paralela.
- [ ] Ciano usa foreground escuro; vazio é neutro; status/erros não dependem só de cor.
- [ ] Controles/badges usam raio 6; painéis/diálogos usam raio 8; contornos decorativos não se repetem.
- [ ] Campos canvas sobre surface mantêm limite funcional ou alternativa comprovada; foco e erro estão visíveis.
- [ ] Tipografia, escala de espaço e margem única seguem o guia.
- [ ] Componentes reutilizáveis cobrem interação normal, hover, foco, disabled e pending.
- [ ] Layout funciona nas larguras úteis 320/375/768/1280 e texto 100%/200%, com conteúdo longo e teclado virtual.
- [ ] Teclado/leitor de tela percorrem controles em ordem; alvos atingem 44 no React/48 no Flutter; diálogos recebem e devolvem foco.
- [ ] Contraste real de texto e indicadores foi medido conforme DS-07.
- [ ] Carregamento, atualização, vazio, filtro vazio, falha, sucesso, expiração e acesso negado são distinguíveis.
- [ ] Gravação duplicada é impedida; falha preserva rascunho no mesmo contexto; não há repetição automática de envio.
- [ ] Navegação/desmontagem da tela descarta seu estado e respostas assíncronas antigas; no React, não há acompanhamento adicional de mudanças do localStorage.
- [ ] PT/EN/ES incluem acessibilidade; datas respeitam idioma/fuso e valores da API permanecem intactos.
- [ ] Contrato, autorização, filtros/paginação e integração real foram verificados; dados demo não contam como integração.
- [ ] Capturas, resultados de verificações e exceções foram registrados, sem atribuir aprovação a cenários não executados.

Os itens são critérios para futuras entregas. Esta publicação documental não executou testes da aplicação nem comprova migração das telas existentes.

## Manutenção do guia

Altere tokens e regras primeiro no [design system](design-system.md), preservando os IDs DS para rastreabilidade. Atualize em seguida as receitas afetadas deste guia. Registre motivo, versão/data, impacto em React/Flutter e evidências necessárias de migração.

Uma exceção deve indicar a regra DS afetada, sua razão, alcance e verificação prevista. Não transforme automaticamente um override legado ou necessidade isolada em novo padrão global. Mudanças de contrato de domínio devem atualizar sua documentação específica, sem reescrever regras visuais globais para reproduzir limitações temporárias.
