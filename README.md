# HabitQuest

> **Sua rotina se transforma em uma jornada de evolução.**

HabitQuest é um aplicativo de evolução pessoal gamificado com elementos de RPG. O usuário tem um herói
que evolui conforme conclui missões ligadas a estudos, organização, hábitos, movimento e bem-estar.
Cada missão concluída concede **XP** e **moedas** (uma única vez), faz o herói subir de **nível**,
desbloqueia **conquistas** e atualiza o **ranking** — tudo persistido e validado no Supabase.

Projeto desenvolvido como atividade escolar prática.

### Rodando em 1 minuto

Com o Flutter instalado e o banco já criado no Supabase (veja [Configurando o Supabase](#configurando-o-supabase)):

```bash
cd habitquest
flutter pub get
flutter run -d chrome --dart-define-from-file=env/supabase.json
```

O arquivo `env/supabase.json` precisa existir com a URL e a chave pública do projeto Supabase
(modelo em `env/supabase.example.json`). Sem ele, o app abre uma tela explicando como configurar.

---

## Sumário

1. [Objetivo](#objetivo)
2. [Tecnologias](#tecnologias)
3. [Funcionalidades](#funcionalidades)
4. [Estrutura de pastas](#estrutura-de-pastas)
5. [Pré-requisitos](#pré-requisitos)
6. [Configurando o Supabase](#configurando-o-supabase)
7. [Configurando a URL e a chave pública](#configurando-a-url-e-a-chave-pública)
8. [Instalando e executando](#instalando-e-executando)
9. [Como testar](#como-testar)
10. [Como funciona por dentro](#como-funciona-por-dentro)
11. [Problemas comuns](#problemas-comuns)
12. [Histórico de correções](#histórico-de-correções)
13. [Entrega (GitHub e ZIP)](#entrega-github-e-zip)
14. [Integrantes e apresentação](#integrantes-e-apresentação)

---

## Objetivo

Demonstrar, em um app Flutter real e executável:

- autenticação com **Supabase Auth** (cadastro, login e logout);
- persistência em **PostgreSQL** (Supabase) com **Row Level Security (RLS)**;
- navegação com **GoRouter**, incluindo **proteção de rotas**;
- **widgets personalizados e parametrizados**;
- uma regra de pontuação **segura**, em que o aplicativo não consegue alterar a própria pontuação.

## Tecnologias

| Camada | Tecnologia |
|---|---|
| Aplicativo | Flutter 3.38 / Dart 3.10 (null-safe) |
| Navegação | `go_router` 17 |
| Backend | Supabase (`supabase_flutter` 2.18): Auth + PostgreSQL + RPC |
| Segurança | RLS, permissões por coluna, funções `SECURITY DEFINER` |
| Testes | `flutter_test` (regras e widgets) e PGlite (PostgreSQL real em WebAssembly) para o banco |

## Funcionalidades

- **Splash**: logotipo animado, verificação da sessão salva e redirecionamento para Login ou Home.
- **Cadastro e login**: validação de campos, mensagens em português para credenciais inválidas,
  falta de conexão, e-mail já cadastrado e **confirmação de e-mail** (quando o Supabase exige).
- **Home (Painel do Herói)**: saudação, herói ilustrado, nível, XP, barra de progresso, moedas,
  missões concluídas hoje, progresso geral, próximas missões e conquistas recentes.
- **Missões**: lista do banco com **filtros por categoria e status** (Disponível, Em andamento, Concluída).
- **Detalhes da missão** (`/missions/:id`): descrição, categoria, dificuldade, recompensa, regras e status;
  botões **Iniciar** e **Concluir**; animação de **+XP**, aviso de **subida de nível** e de **conquista nova**.
- **Conquistas**: coleção de medalhas (bloqueadas/desbloqueadas) com critérios reais.
- **Ranking**: posições calculadas no banco, destaque para o usuário atual e desempate documentado.
- **Herói/Perfil**: estatísticas, progresso por categoria, conquistas, edição de nome/classe/imagem e logout.
- Estados de **carregamento, vazio, erro e "Tentar novamente"** em todas as telas que consultam dados.

### Widgets personalizados (requisito da atividade)

| Widget | Parâmetros | Onde é usado |
|---|---|---|
| `MissionCard` (`lib/widgets/mission_card.dart`) | `mission`, `status`, `onTap`, `compact` | Home, Missões |
| `XpProgressBar` (`lib/widgets/xp_progress_bar.dart`) | `level`, `currentXp`, `requiredXp`, `showLabels`, `height` | Home (via `HeroHeader`), Perfil |
| `AchievementBadge` (`lib/widgets/achievement_badge.dart`) | `name`, `description`, `iconKey`, `unlocked`, `criteria`, `unlockedAt`, `compact`, `size` | Conquistas, Home, Perfil, animação de conclusão |

Também foram criados: `HeroHeader`, `HeroAvatar` (herói desenhado com `CustomPainter`), `AppLogo`,
`AppButton`, `StatTile`, `InfoChip`, `SectionTitle`, `LoadingView`, `ErrorView`, `EmptyView` e `FutureContent`.

## Estrutura de pastas

```
habitquest/
├─ lib/
│  ├─ main.dart                  # lê a configuração e inicializa o Supabase (uma vez)
│  ├─ app.dart                   # MaterialApp.router + tema
│  ├─ core/
│  │  ├─ config/app_config.dart  # SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY (dart-define)
│  │  ├─ router/                 # app_router.dart (rotas + proteção) e auth_notifier.dart
│  │  ├─ state/progress_notifier.dart  # avisa as telas para recarregarem após uma conclusão
│  │  ├─ theme/                  # cores e tema escuro
│  │  ├─ constants/              # categorias, classes de herói, ícones de conquistas
│  │  └─ utils/                  # regra de níveis, validações, mensagens de erro, datas
│  ├─ models/                    # profile, mission, user_mission, achievement, ranking_entry, completion_result
│  ├─ services/                  # auth, profile, mission, achievement, ranking (acesso ao Supabase)
│  ├─ widgets/                   # componentes reutilizáveis
│  └─ screens/                   # splash, auth, home, missions, achievements, ranking, profile
├─ supabase/
│  ├─ schema.sql                 # script completo do banco (tabelas, RLS, funções, dados iniciais)
│  ├─ testes_rls.sql             # testes manuais para o SQL Editor do Supabase
│  └─ tests/                     # teste automatizado do schema (PGlite)
├─ env/supabase.example.json     # modelo de configuração (o arquivo real NÃO vai para o Git)
├─ scripts/gerar_zip.ps1 | .sh   # gera o ZIP de entrega (lib/ + pubspec.yaml)
├─ test/                         # testes Flutter
├─ ROTEIRO_APRESENTACAO.md
└─ pubspec.yaml
```

## Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.38 ou superior (`flutter --version`).
- Google Chrome (para rodar na web) **ou** um emulador/celular Android.
- Uma conta gratuita no [Supabase](https://supabase.com).
- (Opcional) Node.js 18+ para rodar o teste automatizado do banco.

## Configurando o Supabase

1. Acesse <https://supabase.com/dashboard> e clique em **New project**.
   Dê o nome `habitquest`, defina uma senha para o banco e escolha a região **South America (São Paulo)**.
   Aguarde a criação (1 a 2 minutos).
2. Vá em **SQL Editor → New query**, cole **todo** o conteúdo de [`supabase/schema.sql`](supabase/schema.sql)
   e clique em **Run**. Deve aparecer *Success. No rows returned*.
   O script é idempotente: pode ser executado novamente sem duplicar dados.
3. Confira em **Table Editor** que existem as tabelas `profiles`, `missions`, `user_missions`,
   `achievements` e `user_achievements`, com 16 missões e 8 conquistas.
4. **Confirmação de e-mail** (recomendado para a apresentação): em
   **Authentication → Sign In / Providers → Email**, desative **Confirm email**.
   Assim o cadastro já entra no app. Se preferir manter a confirmação, o app avisa o usuário para
   confirmar o e-mail antes de entrar. (O envio de e-mails do plano gratuito tem limite por hora.)

## Configurando a URL e a chave pública

1. No painel do Supabase, abra **Project Settings → API Keys** (ou **Connect**) e copie:
   - a **Project URL** (`https://xxxx.supabase.co`);
   - a **Publishable key** (`sb_publishable_...`) — a chave legada **anon** também funciona.
2. Copie o arquivo de exemplo:

   ```bash
   cp env/supabase.example.json env/supabase.json
   ```

   No Windows (PowerShell): `Copy-Item env/supabase.example.json env/supabase.json`
3. Edite `env/supabase.json` com os seus valores:

   ```json
   {
     "SUPABASE_URL": "https://xxxx.supabase.co",
     "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_..."
   }
   ```

> **Nunca** use a chave `service_role` / *secret* no aplicativo, no GitHub ou no ZIP.
> O arquivo `env/supabase.json` já está no `.gitignore`.

Se o app for executado sem esse arquivo, ele mostra uma tela explicando como configurar.

## Instalando e executando

```bash
flutter pub get
```

Na web (Chrome):

```bash
flutter run -d chrome --dart-define-from-file=env/supabase.json
```

No Android (emulador ou celular conectado):

```bash
flutter run --dart-define-from-file=env/supabase.json
```

Análise estática e testes:

```bash
flutter analyze
```

```bash
flutter test
```

Teste automatizado do banco (opcional, precisa de Node.js):

```bash
cd supabase/tests && npm install && npm test
```

## Como testar

| # | Teste | Resultado esperado |
|---|---|---|
| 1 | Abrir o app sem estar logado e tentar acessar `/#/home` | Redireciona para o Login |
| 2 | Cadastrar um usuário | Perfil criado automaticamente; entra na Home (ou pede confirmação de e-mail) |
| 3 | Login com senha errada | "E-mail ou senha incorretos." |
| 4 | Abrir uma missão e tocar em **Concluir missão** | Animação de +XP; Home, nível, conquistas e ranking atualizados |
| 5 | Abrir a mesma missão de novo | Status "Concluída" e botão desabilitado; o banco recusa nova recompensa |
| 6 | Logado, acessar `/#/login` | Redireciona para a Home |
| 7 | Cadastrar um segundo usuário e concluir missões | Ranking mostra os dois, ordenados pelo XP real |
| 8 | Desligar a internet e puxar para atualizar | Mensagem de falta de conexão e botão "Tentar novamente" |
| 9 | Logout no Perfil | Volta para o Login; rotas internas ficam bloqueadas |
| 10 | Rodar os blocos de [`supabase/testes_rls.sql`](supabase/testes_rls.sql) | Tentativas de fraude retornam *permission denied* |

## Como funciona por dentro

### Autenticação e rotas

- O `Supabase.initialize` é chamado **uma vez** em `main.dart`. A sessão fica salva no dispositivo.
- `AuthNotifier` escuta `onAuthStateChange` e é o `refreshListenable` do GoRouter: login e logout
  disparam o `redirect` automaticamente.
- Regras do `redirect` (`lib/core/router/app_router.dart`):
  1. enquanto a sessão não foi verificada, o usuário fica na **Splash**;
  2. sem sessão, qualquer rota interna leva ao **Login**;
  3. com sessão, Login/Cadastro levam à **Home**.
- A área interna usa `StatefulShellRoute` (barra inferior com 5 abas). Detalhes da missão (`/missions/:id`)
  e edição de perfil (`/profile/edit`) abrem em tela cheia com `context.push`.
- Todas as navegações entre telas usam GoRouter (sem `Navigator.push`/`MaterialPageRoute`).
- **A proteção de rotas é só da interface.** A proteção real dos dados é o **RLS** no banco.

### Tabelas

| Tabela | Conteúdo | Relacionamento |
|---|---|---|
| `profiles` | nome, classe, avatar, `total_xp`, `level`, `coins` | 1:1 com `auth.users` (cascade) |
| `missions` | catálogo: título, descrição, regras, categoria, XP, moedas, dificuldade, ativa | — |
| `user_missions` | status, datas e XP concedido por usuário/missão | N:N usuários × missões, `UNIQUE(user_id, mission_id)` |
| `achievements` | catálogo de conquistas e critérios | — |
| `user_achievements` | conquistas desbloqueadas | N:N usuários × conquistas, `UNIQUE(user_id, achievement_id)` |

O perfil é criado pelo gatilho `handle_new_user` quando alguém se cadastra no Supabase Auth.
As senhas ficam **somente** no Supabase Auth.

### RLS e permissões (menor privilégio)

| Tabela | O app pode ler | O app pode escrever |
|---|---|---|
| `profiles` | só o próprio perfil | só `display_name`, `hero_class`, `avatar_url` do próprio perfil |
| `missions` | missões ativas | nada |
| `user_missions` | só as próprias | nada (apenas via função) |
| `achievements` | todas | nada |
| `user_achievements` | só as próprias | nada (apenas via função) |

Usuários anônimos não acessam nenhuma tabela nem função.

### Pontuação segura

O aplicativo **nunca envia quantidade de XP**. Ele chama `complete_mission(p_mission_id)`, uma função
`SECURITY DEFINER` com `search_path` vazio, executável apenas pelo papel `authenticated`, que:

1. identifica o usuário por `auth.uid()`;
2. valida se a missão existe e está ativa;
3. lê a recompensa oficial em `missions`;
4. trava a linha do perfil (`FOR UPDATE`) para processar chamadas simultâneas uma de cada vez;
5. faz `INSERT ... ON CONFLICT (user_id, mission_id) DO UPDATE ... WHERE status <> 'completed'`.
   Se a missão já estava concluída, nada é alterado e a função devolve `already_completed`;
6. soma XP e moedas e recalcula o nível **na mesma transação**;
7. chama `award_achievements` (função interna, o app não consegue executá-la);
8. devolve um JSON com XP ganho, novo total, nível, se subiu de nível e as conquistas novas.

**Fonte oficial da pontuação:** `profiles.total_xp`. Ele só muda dentro de `complete_mission` e é sempre
igual a `SUM(user_missions.xp_awarded)` do usuário (o bloco 6 de `testes_rls.sql` confere isso).

### Regra de níveis

Para passar do nível N para o N+1 são necessários **100 × N XP**.
XP total para alcançar o nível N = **50 × N × (N − 1)**.

| Nível | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| XP total | 0 | 100 | 300 | 600 | 1000 |

A mesma regra existe em SQL (`level_for_xp`, que define o nível oficial) e em Dart (`LevelRules`,
usada só para desenhar a barra de progresso). As 16 missões iniciais somam 620 XP, então é possível chegar
ao nível 4 e desbloquear todas as 8 conquistas.

### Ranking

`get_leaderboard(p_limit)` e `get_my_rank()` são calculados no banco a partir de `profiles.total_xp` e
devolvem só posição, nome de exibição, avatar, classe, nível, XP e quantidade de missões — **sem e-mail nem id**.
Desempate: maior XP → maior nível → cadastro mais antigo → id.

### Missões recorrentes (evolução futura)

Hoje cada missão rende recompensa **uma única vez** por usuário (`UNIQUE(user_id, mission_id)`).
Para missões diárias, seria preciso adicionar uma coluna de período (ex.: `cycle_date`) e trocar a
restrição por `UNIQUE(user_id, mission_id, cycle_date)`, mantendo a validação dentro de `complete_mission`.

## Verificação realizada

| Verificação | Resultado |
|---|---|
| `flutter pub get` | OK |
| `flutter analyze` | *No issues found!* |
| `flutter test` | 8 testes passando (regras de nível e os três widgets personalizados) |
| `flutter run -d chrome` com Supabase real | App conecta ao banco; Home, Missões e Perfil carregam os dados do usuário |
| `flutter build web --release` | Compilação concluída |
| `supabase/tests` (PostgreSQL 17 via PGlite, com simulação de `auth.uid()` e dos papéis do Supabase) | 50 verificações passando: script idempotente, RLS nas 5 tabelas, XP sem duplicidade, bloqueio de alteração de XP/nível/moedas, isolamento entre usuários, bloqueio de anônimos, ranking sem dados privados, desempate e consistência do XP |

Ainda precisa ser testado manualmente no projeto Supabase real: o cadastro, o login e o logout pelo app, o
e-mail de confirmação (se estiver ativado) e os blocos de `supabase/testes_rls.sql`. O teste com PGlite usa
uma única conexão; a proteção contra chamadas **simultâneas** vem da trava `FOR UPDATE` e da restrição `UNIQUE`.

## Problemas comuns

| Sintoma | Causa e solução |
|---|---|
| Tela pedindo para configurar o Supabase | Falta o `env/supabase.json` ou o `--dart-define-from-file=env/supabase.json` no comando. |
| `Failed to bind web development server ... port` | Outro `flutter run` ainda ocupa a porta. Feche-o ou use outra: `--web-port 8082`. |
| "E-mail ou senha incorretos" logo após cadastrar | **Confirm email** está ativo no Supabase: confirme pelo e-mail ou desative a opção. |
| `permission denied` ao acessar as tabelas pela API sem login | Esperado: o RLS bloqueia usuários anônimos. |
| O app fechou sozinho ("Application finished") | A janela do Chrome aberta pelo Flutter foi fechada. Rode o comando de novo. |

## Histórico de correções

- **Tela vermelha "setState() callback argument returned a Future"** em Home, Missões, Detalhe da missão,
  Conquistas, Ranking e Herói. O código usava `setState(() => _future = _fetch())`; a arrow function
  devolvia o `Future` da atribuição, o que o Flutter proíbe. Trocado por `setState(() { _future = _fetch(); })`.
- **Quadros de estatística do Herói** enormes no PC e com *BOTTOM OVERFLOWED* no celular. A grade usava
  `childAspectRatio` (altura proporcional à largura). Agora usa `mainAxisExtent` (altura fixa) em
  `profile_screen.dart` e na escolha de classe em `edit_profile_screen.dart`; a legenda do `StatTile`
  ficou com uma linha.

## Entrega (GitHub e ZIP)

### Publicar no GitHub

1. Crie um repositório **público** vazio em <https://github.com/new> (ex.: `habitquest`).
2. Na pasta do projeto:

   ```bash
   git remote add origin https://github.com/SEU-USUARIO/habitquest.git
   ```

   ```bash
   git push -u origin main
   ```

Antes de publicar, confirme que `env/supabase.json` **não** aparece em `git status`.

### Gerar o ZIP (somente `lib/` e `pubspec.yaml`)

Windows:

```bash
powershell -ExecutionPolicy Bypass -File scripts/gerar_zip.ps1
```

Linux/macOS:

```bash
sh scripts/gerar_zip.sh
```

O arquivo `habitquest_entrega.zip` é criado na raiz do projeto, sem `.dart_tool`, `build`, `.git` nem credenciais.

## Integrantes e apresentação

- **Integrantes:** _preencher_
- **Turma / curso:** _preencher_
- **Data da apresentação:** _preencher_

O passo a passo da demonstração está em [`ROTEIRO_APRESENTACAO.md`](ROTEIRO_APRESENTACAO.md).
