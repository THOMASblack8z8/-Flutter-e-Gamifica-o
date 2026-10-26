-- =====================================================================
-- HabitQuest — Script completo do banco de dados (Supabase / PostgreSQL)
-- =====================================================================
-- Como usar: Supabase > SQL Editor > New query > cole TODO este arquivo
-- e clique em "Run". O script é idempotente: pode ser executado de novo
-- sem duplicar dados nem quebrar o que já existe.
--
-- Decisões principais:
--   * A pontuação OFICIAL fica em profiles.total_xp.
--     Ela só é alterada pela função complete_mission() e sempre
--     corresponde a SUM(user_missions.xp_awarded) do usuário.
--   * Regra de nível: para passar do nível N para N+1 são necessários
--     100 * N de XP. XP total para alcançar o nível N = 50 * N * (N - 1).
--       Nível 1 = 0 XP | Nível 2 = 100 | Nível 3 = 300 | Nível 4 = 600 | Nível 5 = 1000
--   * O cliente (Flutter) NUNCA envia quanto XP ganhou; ele apenas pede
--     "concluir a missão X". O banco lê a recompensa oficial em missions.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. TABELAS
-- ---------------------------------------------------------------------

-- Perfil público mínimo de cada usuário (1:1 com auth.users).
create table if not exists public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  display_name text not null
               check (char_length(btrim(display_name)) between 2 and 40),
  avatar_url   text
               check (avatar_url is null or char_length(avatar_url) <= 500),
  hero_class   text not null default 'guerreiro'
               check (hero_class in ('guerreiro', 'mago', 'arqueiro', 'guardiao')),
  total_xp     integer not null default 0 check (total_xp >= 0),
  level        integer not null default 1 check (level >= 1),
  coins        integer not null default 0 check (coins >= 0),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- Catálogo de missões.
create table if not exists public.missions (
  id          uuid primary key default gen_random_uuid(),
  title       text not null unique check (char_length(title) between 3 and 80),
  description text not null,
  rules       text not null,
  category    text not null
              check (category in ('estudos', 'organizacao', 'habitos', 'movimento', 'bem_estar')),
  xp_reward   integer not null check (xp_reward between 1 and 1000),
  coin_reward integer not null default 0 check (coin_reward >= 0),
  difficulty  text not null default 'facil'
              check (difficulty in ('facil', 'media', 'dificil')),
  is_active   boolean not null default true,
  created_at  timestamptz not null default now()
);

-- Participação/conclusão de missões por usuário.
create table if not exists public.user_missions (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.profiles (id) on delete cascade,
  mission_id    uuid not null references public.missions (id) on delete restrict,
  status        text not null default 'in_progress'
                check (status in ('in_progress', 'completed')),
  started_at    timestamptz not null default now(),
  completed_at  timestamptz,
  xp_awarded    integer not null default 0 check (xp_awarded >= 0),
  coins_awarded integer not null default 0 check (coins_awarded >= 0),
  -- Cada missão concede recompensa no máximo UMA vez por usuário.
  constraint user_missions_user_mission_key unique (user_id, mission_id),
  -- "completed" sempre tem data de conclusão, e vice-versa.
  constraint user_missions_completed_consistency
    check ((status = 'completed') = (completed_at is not null))
);

-- Catálogo de conquistas.
create table if not exists public.achievements (
  id             uuid primary key default gen_random_uuid(),
  code           text not null unique,
  name           text not null,
  description    text not null,
  icon           text not null,
  criteria_type  text not null
                 check (criteria_type in ('missions_completed', 'distinct_categories', 'level_reached', 'total_xp')),
  criteria_value integer not null check (criteria_value > 0),
  sort_order     integer not null default 0,
  created_at     timestamptz not null default now()
);

-- Conquistas desbloqueadas por usuário.
create table if not exists public.user_achievements (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references public.profiles (id) on delete cascade,
  achievement_id uuid not null references public.achievements (id) on delete restrict,
  unlocked_at    timestamptz not null default now(),
  constraint user_achievements_user_achievement_key unique (user_id, achievement_id)
);


-- ---------------------------------------------------------------------
-- 2. ÍNDICES
-- ---------------------------------------------------------------------
create index if not exists user_missions_user_status_idx on public.user_missions (user_id, status);
create index if not exists user_missions_mission_idx     on public.user_missions (mission_id);
create index if not exists user_achievements_user_idx    on public.user_achievements (user_id);
create index if not exists user_achievements_ach_idx     on public.user_achievements (achievement_id);
create index if not exists missions_active_category_idx  on public.missions (is_active, category);
-- Índice usado pela ordenação do ranking.
create index if not exists profiles_ranking_idx
  on public.profiles (total_xp desc, level desc, created_at asc, id asc);


-- ---------------------------------------------------------------------
-- 3. FUNÇÕES AUXILIARES E GATILHOS
-- ---------------------------------------------------------------------

-- Nível a partir do XP total (mesma regra usada no Flutter para exibição).
create or replace function public.level_for_xp(p_xp integer)
returns integer
language sql
immutable
set search_path = ''
as $$
  select greatest(1, floor((1 + sqrt(1 + 8 * greatest(coalesce(p_xp, 0), 0) / 100.0)) / 2)::integer);
$$;

-- Mantém updated_at atualizado.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Cria o perfil automaticamente quando um usuário se cadastra no Supabase Auth.
-- O nome vem dos metadados enviados no signUp (data: {display_name: ...}).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_name text;
begin
  v_name := left(btrim(coalesce(new.raw_user_meta_data ->> 'display_name', '')), 40);
  if char_length(v_name) < 2 then
    v_name := 'Herói';  -- nunca usa o e-mail como nome público
  end if;

  insert into public.profiles (id, display_name)
  values (new.id, v_name)
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Cria perfis para usuários que já existiam antes deste script.
insert into public.profiles (id, display_name)
select u.id,
       case when char_length(btrim(coalesce(u.raw_user_meta_data ->> 'display_name', ''))) >= 2
            then left(btrim(u.raw_user_meta_data ->> 'display_name'), 40)
            else 'Herói' end
from auth.users u
on conflict (id) do nothing;


-- ---------------------------------------------------------------------
-- 4. ROW LEVEL SECURITY (RLS) E PERMISSÕES
-- ---------------------------------------------------------------------
alter table public.profiles          enable row level security;
alter table public.missions          enable row level security;
alter table public.user_missions     enable row level security;
alter table public.achievements      enable row level security;
alter table public.user_achievements enable row level security;

-- Começa sem nenhuma permissão e libera só o necessário (menor privilégio).
revoke all on public.profiles, public.missions, public.user_missions,
              public.achievements, public.user_achievements
  from anon, authenticated;

grant select on public.profiles, public.missions, public.user_missions,
                public.achievements, public.user_achievements
  to authenticated;

-- O usuário só pode alterar estes campos do PRÓPRIO perfil.
-- total_xp, level e coins NÃO estão na lista: não podem ser alterados pelo app.
grant update (display_name, avatar_url, hero_class) on public.profiles to authenticated;

-- profiles: cada usuário lê e edita apenas a própria linha.
-- (O ranking público é servido pela função get_leaderboard, com campos mínimos.)
drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles
  for select to authenticated
  using ((select auth.uid()) = id);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- missions: usuários autenticados veem apenas missões ativas.
drop policy if exists missions_select_active on public.missions;
create policy missions_select_active on public.missions
  for select to authenticated
  using (is_active);

-- user_missions: só os próprios registros. Sem INSERT/UPDATE/DELETE para o app;
-- registros são criados apenas pelas funções start_mission/complete_mission.
drop policy if exists user_missions_select_own on public.user_missions;
create policy user_missions_select_own on public.user_missions
  for select to authenticated
  using ((select auth.uid()) = user_id);

-- achievements: catálogo legível por usuários autenticados.
drop policy if exists achievements_select_all on public.achievements;
create policy achievements_select_all on public.achievements
  for select to authenticated
  using (true);

-- user_achievements: só as próprias conquistas. Inserção apenas pelo servidor.
drop policy if exists user_achievements_select_own on public.user_achievements;
create policy user_achievements_select_own on public.user_achievements
  for select to authenticated
  using ((select auth.uid()) = user_id);


-- ---------------------------------------------------------------------
-- 5. FUNÇÕES PROTEGIDAS (RPC)
-- ---------------------------------------------------------------------

-- Verifica e registra conquistas de um usuário. Uso INTERNO
-- (chamada por complete_mission); o app não pode executá-la.
create or replace function public.award_achievements(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_completed  integer;
  v_categories integer;
  v_level      integer;
  v_xp         integer;
  v_result     jsonb;
begin
  select count(*), count(distinct m.category)
    into v_completed, v_categories
    from public.user_missions um
    join public.missions m on m.id = um.mission_id
   where um.user_id = p_user_id
     and um.status = 'completed';

  select p.level, p.total_xp into v_level, v_xp
    from public.profiles p
   where p.id = p_user_id;

  with eligible as (
    select a.id
      from public.achievements a
     where (a.criteria_type = 'missions_completed'  and v_completed  >= a.criteria_value)
        or (a.criteria_type = 'distinct_categories' and v_categories >= a.criteria_value)
        or (a.criteria_type = 'level_reached'       and v_level      >= a.criteria_value)
        or (a.criteria_type = 'total_xp'            and v_xp         >= a.criteria_value)
  ),
  inserted as (
    insert into public.user_achievements (user_id, achievement_id)
    select p_user_id, e.id from eligible e
    on conflict (user_id, achievement_id) do nothing
    returning achievement_id
  )
  select coalesce(
           jsonb_agg(jsonb_build_object('id', a.id, 'name', a.name, 'icon', a.icon)
                     order by a.sort_order),
           '[]'::jsonb)
    into v_result
    from inserted i
    join public.achievements a on a.id = i.achievement_id;

  return v_result;
end;
$$;

-- Marca uma missão como "em andamento" (não concede XP).
create or replace function public.start_mission(p_mission_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid    uuid := auth.uid();
  v_status text;
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;

  if not exists (select 1 from public.missions m where m.id = p_mission_id and m.is_active) then
    raise exception 'MISSION_NOT_FOUND' using errcode = 'P0002';
  end if;

  insert into public.user_missions (user_id, mission_id, status)
  values (v_uid, p_mission_id, 'in_progress')
  on conflict (user_id, mission_id) do nothing;

  select um.status into v_status
    from public.user_missions um
   where um.user_id = v_uid and um.mission_id = p_mission_id;

  return jsonb_build_object('status', v_status);
end;
$$;

-- Conclui uma missão de forma ATÔMICA e SEGURA.
--   1. identifica o usuário por auth.uid()
--   2. valida a missão (existe e está ativa)
--   3. lê a recompensa oficial na tabela missions
--   4. impede segunda recompensa (UNIQUE + ON CONFLICT ... WHERE)
--   5. registra a conclusão
--   6. atualiza XP, moedas e nível na mesma transação
--   7. verifica conquistas
--   8. devolve um JSON com o resultado
create or replace function public.complete_mission(p_mission_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid          uuid := auth.uid();
  v_mission      public.missions%rowtype;
  v_profile      public.profiles%rowtype;
  v_row_id       uuid;
  v_old_level    integer;
  v_achievements jsonb := '[]'::jsonb;
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;

  select * into v_mission from public.missions m where m.id = p_mission_id;
  if not found or not v_mission.is_active then
    raise exception 'MISSION_NOT_FOUND' using errcode = 'P0002';
  end if;

  -- Trava a linha do perfil: conclusões simultâneas do mesmo usuário
  -- passam a ser processadas uma de cada vez.
  select * into v_profile from public.profiles p where p.id = v_uid for update;
  if not found then
    raise exception 'PROFILE_NOT_FOUND' using errcode = 'P0002';
  end if;

  insert into public.user_missions
    (user_id, mission_id, status, started_at, completed_at, xp_awarded, coins_awarded)
  values
    (v_uid, p_mission_id, 'completed', now(), now(), v_mission.xp_reward, v_mission.coin_reward)
  on conflict (user_id, mission_id) do update
     set status        = 'completed',
         completed_at  = now(),
         xp_awarded    = excluded.xp_awarded,
         coins_awarded = excluded.coins_awarded
   where public.user_missions.status <> 'completed'
  returning id into v_row_id;

  -- Nenhuma linha inserida/atualizada => a missão já estava concluída.
  if v_row_id is null then
    return jsonb_build_object(
      'status', 'already_completed',
      'xp_awarded', 0,
      'coins_awarded', 0,
      'total_xp', v_profile.total_xp,
      'level', v_profile.level,
      'coins', v_profile.coins,
      'leveled_up', false,
      'new_achievements', '[]'::jsonb
    );
  end if;

  v_old_level := v_profile.level;

  update public.profiles p
     set total_xp = p.total_xp + v_mission.xp_reward,
         coins    = p.coins + v_mission.coin_reward,
         level    = public.level_for_xp(p.total_xp + v_mission.xp_reward)
   where p.id = v_uid
  returning * into v_profile;

  v_achievements := public.award_achievements(v_uid);

  return jsonb_build_object(
    'status', 'completed',
    'xp_awarded', v_mission.xp_reward,
    'coins_awarded', v_mission.coin_reward,
    'total_xp', v_profile.total_xp,
    'level', v_profile.level,
    'coins', v_profile.coins,
    'leveled_up', v_profile.level > v_old_level,
    'new_achievements', v_achievements
  );
end;
$$;

-- Ranking público: apenas campos mínimos (nunca e-mail ou dados privados).
-- Desempate: XP desc, nível desc, data de cadastro asc (quem chegou antes), id.
create or replace function public.get_leaderboard(p_limit integer default 50)
returns table (
  rank_position      bigint,
  display_name       text,
  avatar_url         text,
  hero_class         text,
  level              integer,
  total_xp           integer,
  missions_completed bigint,
  is_me              boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  with ranked as (
    select p.id, p.display_name, p.avatar_url, p.hero_class, p.level, p.total_xp,
           row_number() over (order by p.total_xp desc, p.level desc, p.created_at asc, p.id asc) as pos
      from public.profiles p
  )
  select r.pos,
         r.display_name,
         r.avatar_url,
         r.hero_class,
         r.level,
         r.total_xp,
         (select count(*) from public.user_missions um
           where um.user_id = r.id and um.status = 'completed'),
         r.id = (select auth.uid())
    from ranked r
   where (select auth.uid()) is not null
   order by r.pos
   limit least(greatest(coalesce(p_limit, 50), 1), 100);
$$;

-- Posição do usuário autenticado no ranking (mesma regra de ordenação).
create or replace function public.get_my_rank()
returns table (
  rank_position      bigint,
  display_name       text,
  avatar_url         text,
  hero_class         text,
  level              integer,
  total_xp           integer,
  missions_completed bigint,
  is_me              boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  with ranked as (
    select p.id, p.display_name, p.avatar_url, p.hero_class, p.level, p.total_xp,
           row_number() over (order by p.total_xp desc, p.level desc, p.created_at asc, p.id asc) as pos
      from public.profiles p
  )
  select r.pos, r.display_name, r.avatar_url, r.hero_class, r.level, r.total_xp,
         (select count(*) from public.user_missions um
           where um.user_id = r.id and um.status = 'completed'),
         true
    from ranked r
   where r.id = (select auth.uid());
$$;

-- Permissões de execução: só usuários autenticados, e só nas RPCs públicas.
revoke all on function public.level_for_xp(integer)      from public, anon;
revoke all on function public.set_updated_at()           from public, anon, authenticated;
revoke all on function public.handle_new_user()          from public, anon, authenticated;
revoke all on function public.award_achievements(uuid)   from public, anon, authenticated;
revoke all on function public.start_mission(uuid)        from public, anon;
revoke all on function public.complete_mission(uuid)     from public, anon;
revoke all on function public.get_leaderboard(integer)   from public, anon;
revoke all on function public.get_my_rank()              from public, anon;

grant execute on function public.level_for_xp(integer)    to authenticated;
grant execute on function public.start_mission(uuid)      to authenticated;
grant execute on function public.complete_mission(uuid)   to authenticated;
grant execute on function public.get_leaderboard(integer) to authenticated;
grant execute on function public.get_my_rank()            to authenticated;


-- ---------------------------------------------------------------------
-- 6. DADOS INICIAIS (catálogo de missões e conquistas)
-- ---------------------------------------------------------------------
insert into public.missions (title, description, rules, category, xp_reward, coin_reward, difficulty) values
  ('Sessão de estudo focada',
   'Estude um conteúdo da escola por 25 minutos sem distrações e faça uma pausa curta no final.',
   'Separe o material, desligue as notificações e estude por 25 minutos seguidos. Conclua depois da pausa.',
   'estudos', 50, 5, 'media'),
  ('Revisar as anotações da aula',
   'Releia as anotações de uma aula recente e destaque os pontos mais importantes.',
   'Escolha uma matéria, revise as anotações e marque ao menos três ideias principais.',
   'estudos', 35, 3, 'facil'),
  ('Ler um capítulo',
   'Leia um capítulo de um livro, apostila ou material de estudo do seu interesse.',
   'Leia o capítulo inteiro e escreva uma frase resumindo o que aprendeu.',
   'estudos', 40, 4, 'media'),
  ('Projeto de estudo semanal',
   'Avance em um trabalho ou projeto escolar em uma sessão planejada.',
   'Defina uma meta pequena para o projeto, trabalhe nela por pelo menos 45 minutos e anote o próximo passo.',
   'estudos', 120, 12, 'dificil'),
  ('Organizar as tarefas do dia',
   'Liste as tarefas do dia e defina quais são as prioridades.',
   'Escreva sua lista de tarefas e marque as três mais importantes.',
   'organizacao', 25, 2, 'facil'),
  ('Planejar a semana',
   'Monte um plano simples com compromissos, estudos e momentos de descanso da semana.',
   'Registre os compromissos da semana em uma agenda ou caderno, incluindo pausas e lazer.',
   'organizacao', 60, 6, 'media'),
  ('Organizar o espaço de estudos',
   'Deixe sua mesa ou espaço de estudos limpo e pronto para usar.',
   'Guarde o que não for necessário, separe o material de estudo e deixe o ambiente arejado.',
   'organizacao', 35, 3, 'facil'),
  ('Beber água ao longo do dia',
   'Mantenha uma garrafa de água por perto e lembre-se de se hidratar.',
   'Tenha uma garrafa de água ao alcance durante o dia e beba sempre que sentir sede.',
   'habitos', 25, 2, 'facil'),
  ('Preparar a mochila na noite anterior',
   'Separe o material do dia seguinte antes de dormir para começar o dia com calma.',
   'Confira o horário de amanhã e coloque na mochila tudo o que vai precisar.',
   'habitos', 25, 2, 'facil'),
  ('Dormir no horário planejado',
   'Defina um horário para dormir e prepare-se para descansar bem.',
   'Escolha um horário realista, afaste as telas 30 minutos antes e vá dormir nesse horário.',
   'habitos', 40, 4, 'media'),
  ('Caminhada leve',
   'Faça uma caminhada leve de cerca de 15 minutos, no seu ritmo.',
   'Caminhe por aproximadamente 15 minutos em um local seguro. Respeite seus limites.',
   'movimento', 35, 3, 'facil'),
  ('Alongamento de 10 minutos',
   'Faça alongamentos simples para relaxar o corpo depois de ficar muito tempo sentado.',
   'Faça movimentos suaves por cerca de 10 minutos, sem forçar e sem sentir dor.',
   'movimento', 25, 2, 'facil'),
  ('Fazer uma pausa para descanso',
   'Faça uma pausa consciente longe das telas para recarregar as energias.',
   'Pare por 10 minutos: respire fundo, alongue-se ou apenas descanse sem telas.',
   'bem_estar', 20, 2, 'facil'),
  ('Atividade de lazer saudável',
   'Reserve um tempo para algo de que você goste: música, desenho, jogo de tabuleiro ou conversa.',
   'Dedique pelo menos 20 minutos a uma atividade de lazer que faça bem a você.',
   'bem_estar', 30, 3, 'facil'),
  ('Três coisas boas do dia',
   'Anote três coisas boas que aconteceram hoje, por menores que sejam.',
   'Escreva três acontecimentos positivos do dia em um caderno ou no celular.',
   'bem_estar', 25, 2, 'facil'),
  ('Conversar com alguém querido',
   'Reserve um momento para conversar com um amigo ou familiar.',
   'Converse com alguém de quem você gosta por pelo menos 10 minutos, pessoalmente ou por chamada.',
   'bem_estar', 30, 3, 'facil')
on conflict (title) do nothing;

insert into public.achievements (code, name, description, icon, criteria_type, criteria_value, sort_order) values
  ('first_quest',     'Primeira Jornada',     'Conclua sua primeira missão.',                        'flag',          'missions_completed',  1,  1),
  ('consistency',     'Consistência',         'Conclua cinco missões.',                              'repeat',        'missions_completed',  5,  2),
  ('dedication',      'Dedicação',            'Conclua dez missões.',                                'shield',        'missions_completed', 10,  3),
  ('explorer',        'Explorador',           'Conclua missões de três categorias diferentes.',     'explore',       'distinct_categories', 3,  4),
  ('full_adventurer', 'Aventureiro Completo', 'Conclua missões de todas as cinco categorias.',      'public',        'distinct_categories', 5,  5),
  ('evolution',       'Evolução',             'Alcance o nível 3.',                                  'trending_up',   'level_reached',       3,  6),
  ('veteran',         'Veterano',             'Alcance o nível 4.',                                  'military_tech', 'level_reached',       4,  7),
  ('xp_500',          'Mestre da Rotina',     'Acumule 500 XP.',                                     'auto_awesome',  'total_xp',          500,  8)
on conflict (code) do nothing;

-- Fim do script.
