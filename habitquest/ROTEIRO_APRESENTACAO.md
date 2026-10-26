# Roteiro de apresentação — HabitQuest (≈ 8 minutos)

## Antes de começar (checklist)

- [ ] `schema.sql` executado no Supabase e **Confirm email** desativado.
- [ ] `env/supabase.json` preenchido com a URL e a chave pública.
- [ ] App aberto com `flutter run -d chrome --dart-define-from-file=env/supabase.json`.
- [ ] Um segundo usuário já cadastrado com algumas missões concluídas (para o ranking ter disputa).
- [ ] Painel do Supabase aberto em outra aba (Table Editor e SQL Editor).
- [ ] Um e-mail novo separado para o cadastro ao vivo.

## Demonstração

| # | Ação | O que falar |
|---|---|---|
| 1 | **Abrir o app** | A Splash verifica a sessão salva antes de decidir a rota. Sem sessão, o GoRouter manda para o Login. |
| 2 | **Cadastrar** um usuário (nome, e-mail, senha, confirmação) | Mostrar a validação (ex.: senhas diferentes). A senha fica só no Supabase Auth; um gatilho cria o perfil. |
| 3 | **Fazer login** (ou mostrar que o cadastro já entrou) | O `AuthNotifier` escuta o Supabase e o GoRouter redireciona sozinho. |
| 4 | **Home e Missões** | Painel do herói com nível, XP, barra e moedas: tudo vem do banco. Na aba Missões, usar os filtros de categoria e status. |
| 5 | **Abrir uma missão e concluir** | A rota é `/missions/:id`. O botão chama a função `complete_mission`: o app não envia quanto XP ganhou. |
| 6 | **Mostrar o XP atualizado** | Animação de +XP, barra atualizada na Home. Abrir a mesma missão: "Concluída", sem nova recompensa. |
| 7 | **Conquistas** | "Primeira Jornada" desbloqueada pelo banco; as outras continuam bloqueadas com o critério visível. |
| 8 | **Ranking** | Ordenado pelo XP real (`get_leaderboard`), com a posição do usuário em destaque. Sem e-mails. |
| 9 | **Perfil e logout** | Estatísticas e progresso por categoria; editar nome/classe; **Sair** → volta ao Login. |
| 10 | **Explicação técnica** | Ver abaixo. |

## Explicação técnica (passo 10, ≈ 2 minutos)

1. **Tabelas:** `profiles` (1:1 com o usuário), `missions` (catálogo), `user_missions` (conclusões,
   `UNIQUE(user_id, mission_id)`), `achievements` (catálogo) e `user_achievements` (desbloqueios).
2. **Proteção das rotas:** o `redirect` do GoRouter bloqueia rotas internas sem sessão e reage ao login/logout.
   Isso é só a interface.
3. **RLS:** a segurança real fica no banco. Cada usuário lê só os próprios dados, e o app só pode alterar
   nome, classe e avatar. XP, nível e moedas só mudam dentro de `complete_mission`.
4. **Prova ao vivo (opcional):** no SQL Editor, executar o **Bloco 2** de `supabase/testes_rls.sql`,
   que tenta mudar o próprio XP. O resultado é *permission denied for table profiles*.

## Perguntas prováveis

- **E se o usuário clicar duas vezes em concluir?** O botão é desabilitado durante a chamada, mas a garantia
  real é do banco: a restrição `UNIQUE` e o `ON CONFLICT ... WHERE status <> 'completed'` impedem um segundo XP.
- **E se alguém chamar a API direto, sem o app?** O RLS e as permissões valem para qualquer cliente.
  A chave pública não dá acesso a nada além do que as políticas permitem.
- **Onde está a pontuação oficial?** Em `profiles.total_xp`, sempre igual à soma de `user_missions.xp_awarded`.
- **Como o nível é calculado?** Nível N exige 50 × N × (N − 1) XP no total (0, 100, 300, 600, 1000…).
