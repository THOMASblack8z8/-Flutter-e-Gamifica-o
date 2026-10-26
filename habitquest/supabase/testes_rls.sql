-- =====================================================================
-- HabitQuest — Testes manuais de RLS e pontuação no SQL Editor do Supabase
-- =====================================================================
-- Pré-requisito: cadastre DOIS usuários pelo aplicativo e troque os
-- e-mails abaixo pelos e-mails usados (usuario.a@... e usuario.b@...).
--
-- IMPORTANTE: execute UM BLOCO POR VEZ (selecione o bloco e clique em Run).
-- Os blocos terminam com ROLLBACK, então NÃO alteram os dados reais.
-- Para simular um usuário, o bloco define o "JWT" (request.jwt.claims)
-- e troca o papel para "authenticated" — exatamente como o app faz.
-- =====================================================================


-- ---------------------------------------------------------------------
-- BLOCO 1 — Conclusão concede XP uma única vez
-- Esperado: 1ª chamada "completed"; 2ª chamada "already_completed" com xp 0.
-- ---------------------------------------------------------------------
begin;
select set_config('request.jwt.claims',
  json_build_object('sub', (select id from auth.users where email = 'usuario.a@exemplo.com'),
                    'role', 'authenticated')::text, true);
set local role authenticated;

select public.complete_mission((select id from public.missions where title = 'Organizar as tarefas do dia')) as primeira;
select public.complete_mission((select id from public.missions where title = 'Organizar as tarefas do dia')) as segunda;
select display_name, total_xp, level, coins from public.profiles;
rollback;


-- ---------------------------------------------------------------------
-- BLOCO 2 — Usuário não altera a própria pontuação
-- Esperado: ERRO "permission denied for table profiles".
-- ---------------------------------------------------------------------
begin;
select set_config('request.jwt.claims',
  json_build_object('sub', (select id from auth.users where email = 'usuario.a@exemplo.com'),
                    'role', 'authenticated')::text, true);
set local role authenticated;

update public.profiles set total_xp = 99999;
rollback;


-- ---------------------------------------------------------------------
-- BLOCO 3 — Usuário não insere conclusão diretamente (nem em nome de outro)
-- Esperado: ERRO "permission denied for table user_missions".
-- ---------------------------------------------------------------------
begin;
select set_config('request.jwt.claims',
  json_build_object('sub', (select id from auth.users where email = 'usuario.a@exemplo.com'),
                    'role', 'authenticated')::text, true);
set local role authenticated;

insert into public.user_missions (user_id, mission_id, status, completed_at, xp_awarded)
select (select auth.uid()), id, 'completed', now(), 1000 from public.missions limit 1;
rollback;


-- ---------------------------------------------------------------------
-- BLOCO 4 — Usuário B não enxerga dados privados do usuário A
-- Esperado: B vê apenas o PRÓPRIO perfil e as PRÓPRIAS conclusões.
-- ---------------------------------------------------------------------
begin;
select set_config('request.jwt.claims',
  json_build_object('sub', (select id from auth.users where email = 'usuario.b@exemplo.com'),
                    'role', 'authenticated')::text, true);
set local role authenticated;

select count(*) as perfis_visiveis from public.profiles;            -- esperado: 1
select count(*) as conclusoes_de_outros from public.user_missions
 where user_id <> (select auth.uid());                              -- esperado: 0
rollback;


-- ---------------------------------------------------------------------
-- BLOCO 5 — Ranking só com dados públicos mínimos
-- Esperado: posição, nome, avatar, classe, nível, XP, missões, is_me.
-- Nenhuma coluna de e-mail ou id.
-- ---------------------------------------------------------------------
begin;
select set_config('request.jwt.claims',
  json_build_object('sub', (select id from auth.users where email = 'usuario.b@exemplo.com'),
                    'role', 'authenticated')::text, true);
set local role authenticated;

select * from public.get_leaderboard(50);
select * from public.get_my_rank();
rollback;


-- ---------------------------------------------------------------------
-- BLOCO 6 — Consistência da pontuação (executar como administrador)
-- Esperado: nenhuma linha (total_xp sempre igual à soma das recompensas).
-- ---------------------------------------------------------------------
select p.display_name, p.total_xp, coalesce(sum(um.xp_awarded), 0) as soma_recompensas
  from public.profiles p
  left join public.user_missions um on um.user_id = p.id
 group by p.id
having p.total_xp <> coalesce(sum(um.xp_awarded), 0);
