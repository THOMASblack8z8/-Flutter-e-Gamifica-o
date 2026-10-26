// Valida supabase/schema.sql num PostgreSQL real (PGlite) com um "stub" do Supabase.
import { PGlite } from '@electric-sql/pglite';
import { readFileSync } from 'node:fs';

const schema = readFileSync(process.argv[2], 'utf8');
const db = new PGlite();
let failures = 0;

function check(name, ok, detail = '') {
  if (!ok) failures++;
  console.log(`${ok ? 'PASS' : 'FAIL'} - ${name}${detail ? '  -> ' + detail : ''}`);
}
const rows = async (sql, params) => (await db.query(sql, params)).rows;
async function expectError(name, sql, pattern) {
  try {
    await db.exec(sql);
    check(name, false, 'nenhum erro (deveria falhar)');
  } catch (e) {
    check(name, pattern.test(e.message), e.message);
  }
}

// --- Stub mínimo do ambiente Supabase -------------------------------------
await db.exec(`
  create role anon nologin;
  create role authenticated nologin;
  create role service_role nologin bypassrls;
  create schema auth;
  create table auth.users (id uuid primary key, email text, raw_user_meta_data jsonb);
  create function auth.uid() returns uuid language sql stable as $$
    select coalesce(nullif(current_setting('request.jwt.claim.sub', true), ''),
                    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub'))::uuid
  $$;
  grant usage on schema public, auth to anon, authenticated;
  grant execute on function auth.uid() to anon, authenticated;
  -- O Supabase concede tudo por padrão em public; o script precisa revogar.
  alter default privileges in schema public grant all on tables to anon, authenticated;
  alter default privileges in schema public grant all on functions to anon, authenticated;
`);

const asAdmin = () => db.exec(`reset role; select set_config('request.jwt.claims', '', false);`);
const asUser = (uid) =>
  db.exec(`reset role; select set_config('request.jwt.claims', '{"sub":"${uid}","role":"authenticated"}', false); set role authenticated;`);
const asAnon = () => db.exec(`reset role; select set_config('request.jwt.claims', '', false); set role anon;`);

// --- 1. Script executa e é idempotente ------------------------------------
await db.exec(schema);
await db.exec(schema);
check('schema.sql executa duas vezes sem erro (idempotente)', true);
check('16 missões iniciais', (await rows('select count(*)::int c from public.missions'))[0].c === 16);
check('8 conquistas iniciais', (await rows('select count(*)::int c from public.achievements'))[0].c === 8);
const rls = await rows(`select relname, relrowsecurity from pg_class where relnamespace = 'public'::regnamespace and relkind = 'r'`);
check('RLS ativo nas 5 tabelas', rls.length === 5 && rls.every((r) => r.relrowsecurity), JSON.stringify(rls.map((r) => r.relname)));

// --- 2. Cadastro cria perfil pelo gatilho ---------------------------------
const A = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const B = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const C = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
await db.exec(`insert into auth.users values ('${A}', 'ana@exemplo.com', '{"display_name":"Ana"}')`);
await db.exec(`insert into auth.users values ('${B}', 'bruno@exemplo.com', '{"display_name":"Bruno"}')`);
const profs = await rows('select id, display_name, total_xp, level from public.profiles order by display_name');
check('gatilho cria perfis com display_name', profs.length === 2 && profs[0].display_name === 'Ana', JSON.stringify(profs));
await db.exec(`insert into auth.users values ('dddddddd-dddd-4ddd-8ddd-dddddddddddd', 'semnome@exemplo.com', '{}')`);
const noName = await rows(`select display_name from public.profiles where id = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd'`);
check('sem nome: usa "Herói" (nunca o e-mail)', noName[0].display_name === 'Herói');
await db.exec(`delete from auth.users where id = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd'`);
check('excluir usuário remove o perfil (cascade)', (await rows('select count(*)::int c from public.profiles'))[0].c === 2);

const missions = await rows('select id, title, xp_reward, coin_reward, category from public.missions order by title');
const m1 = missions[0];
const m2 = missions[1];

// --- 3. Usuário A ---------------------------------------------------------
await asUser(A);
check('A vê as 16 missões ativas', (await rows('select count(*)::int c from public.missions'))[0].c === 16);
check('A vê só o próprio perfil', (await rows('select id from public.profiles')).length === 1);

const r1 = (await rows(`select public.complete_mission('${m1.id}') r`))[0].r;
check('1ª conclusão concede o XP oficial da missão', r1.status === 'completed' && r1.xp_awarded === m1.xp_reward, JSON.stringify(r1));
check('1ª conclusão desbloqueia "Primeira Jornada"', r1.new_achievements.some((a) => a.name === 'Primeira Jornada'));

const r2 = (await rows(`select public.complete_mission('${m1.id}') r`))[0].r;
check('2ª conclusão da mesma missão NÃO concede XP', r2.status === 'already_completed' && r2.xp_awarded === 0 && r2.total_xp === m1.xp_reward, JSON.stringify(r2));
check('total_xp continua igual após repetição', (await rows('select total_xp from public.profiles'))[0].total_xp === m1.xp_reward);
check('só 1 registro em user_missions para a missão', (await rows(`select count(*)::int c from public.user_missions where mission_id = '${m1.id}'`))[0].c === 1);

await expectError('A não altera o próprio total_xp', `update public.profiles set total_xp = 99999 where id = '${A}'`, /permission denied/);
await expectError('A não altera o próprio level', `update public.profiles set level = 99 where id = '${A}'`, /permission denied/);
await expectError('A não altera as próprias moedas', `update public.profiles set coins = 99999 where id = '${A}'`, /permission denied/);
await expectError('A não insere conclusão diretamente', `insert into public.user_missions (user_id, mission_id, status, completed_at, xp_awarded) values ('${A}', '${m2.id}', 'completed', now(), 1000)`, /permission denied/);
await expectError('A não insere conclusão em nome de B', `insert into public.user_missions (user_id, mission_id) values ('${B}', '${m2.id}')`, /permission denied/);
await expectError('A não altera xp_awarded', `update public.user_missions set xp_awarded = 999`, /permission denied/);
await expectError('A não apaga conclusões', `delete from public.user_missions`, /permission denied/);
await expectError('A não insere conquista diretamente', `insert into public.user_achievements (user_id, achievement_id) select '${A}', id from public.achievements`, /permission denied/);
await expectError('A não executa award_achievements', `select public.award_achievements('${A}')`, /permission denied/);
await expectError('A não altera o catálogo de missões', `update public.missions set xp_reward = 1000`, /permission denied/);
await expectError('A não insere missões', `insert into public.missions (title, description, rules, category, xp_reward) values ('Hack', 'x', 'x', 'estudos', 1000)`, /permission denied/);
await expectError('missão inexistente retorna MISSION_NOT_FOUND', `select public.complete_mission('00000000-0000-4000-8000-000000000000')`, /MISSION_NOT_FOUND/);

const upd = await db.query(`update public.profiles set display_name = 'Ana Lima', hero_class = 'mago' where id = '${A}' returning display_name`);
check('A edita nome e classe do próprio perfil', upd.rows.length === 1 && upd.rows[0].display_name === 'Ana Lima');
const updB = await db.query(`update public.profiles set display_name = 'Hackeado' where id = '${B}'`);
check('A não edita o perfil de B (0 linhas)', (updB.affectedRows ?? 0) === 0);
await expectError('nome inválido é recusado pelo CHECK', `update public.profiles set display_name = 'x' where id = '${A}'`, /check constraint/);

const s = (await rows(`select public.start_mission('${m2.id}') r`))[0].r;
check('start_mission marca "in_progress"', s.status === 'in_progress');
const r3 = (await rows(`select public.complete_mission('${m2.id}') r`))[0].r;
check('missão iniciada pode ser concluída', r3.status === 'completed' && r3.xp_awarded === m2.xp_reward);

// --- 4. Missão inativa ----------------------------------------------------
const last = missions[missions.length - 1];
await asAdmin();
await db.exec(`update public.missions set is_active = false where id = '${last.id}'`);
await asUser(A);
check('missão inativa some da lista', (await rows('select count(*)::int c from public.missions'))[0].c === 15);
await expectError('missão inativa não pode ser concluída', `select public.complete_mission('${last.id}')`, /MISSION_NOT_FOUND/);
await asAdmin();
await db.exec(`update public.missions set is_active = true where id = '${last.id}'`);

// --- 5. Usuário B (isolamento) -------------------------------------------
await asUser(B);
check('B não vê as conclusões de A', (await rows('select count(*)::int c from public.user_missions'))[0].c === 0);
check('B não vê as conquistas de A', (await rows('select count(*)::int c from public.user_achievements'))[0].c === 0);
check('B não lê o perfil de A', (await rows(`select * from public.profiles where id = '${A}'`)).length === 0);
const rb = (await rows(`select public.complete_mission('${m1.id}') r`))[0].r;
check('B também pode concluir a mesma missão (1 vez por usuário)', rb.status === 'completed');

const board = await rows('select * from public.get_leaderboard(50)');
check('ranking lista os 2 heróis', board.length === 2, JSON.stringify(board));
check('ranking ordenado por XP (Ana em 1º)', board[0].display_name === 'Ana Lima' && Number(board[0].rank_position) === 1);
check('ranking marca is_me corretamente para B', board[1].is_me === true && board[0].is_me === false);
check('ranking não expõe e-mail nem id', !Object.keys(board[0]).some((k) => /email|^id$|user_id/.test(k)), Object.keys(board[0]).join(','));
const meB = await rows('select * from public.get_my_rank()');
check('get_my_rank retorna a posição de B (#2)', Number(meB[0].rank_position) === 2);

// --- 6. Desempate determinístico ------------------------------------------
await asAdmin();
await db.exec(`insert into auth.users values ('${C}', 'carla@exemplo.com', '{"display_name":"Carla"}')`);
await asUser(C);
await db.exec(`select public.complete_mission('${m1.id}')`);
const tie = await rows('select display_name, total_xp from public.get_leaderboard(50)');
check('empate de XP/nível: quem se cadastrou antes fica à frente', tie[1].display_name === 'Bruno' && tie[2].display_name === 'Carla', JSON.stringify(tie));

// --- 7. Anônimo ----------------------------------------------------------
await asAnon();
await expectError('anônimo não lê missões', 'select * from public.missions', /permission denied/);
await expectError('anônimo não lê perfis', 'select * from public.profiles', /permission denied/);
await expectError('anônimo não conclui missões', `select public.complete_mission('${m1.id}')`, /permission denied/);
await expectError('anônimo não consulta o ranking', 'select * from public.get_leaderboard(10)', /permission denied/);

// --- 8. Progressão completa ----------------------------------------------
await asUser(A);
for (const m of missions) await db.exec(`select public.complete_mission('${m.id}')`);
const pa = (await rows('select total_xp, level, coins from public.profiles'))[0];
const totalXp = missions.reduce((s, m) => s + m.xp_reward, 0);
const totalCoins = missions.reduce((s, m) => s + m.coin_reward, 0);
check(`todas as missões: ${totalXp} XP, nível 4`, pa.total_xp === totalXp && pa.level === 4, JSON.stringify(pa));
check('moedas somadas corretamente', pa.coins === totalCoins);
const ach = (await rows('select count(*)::int c from public.user_achievements'))[0].c;
check('todas as 8 conquistas alcançáveis e desbloqueadas', ach === 8, `desbloqueadas: ${ach}`);

// --- 9. Consistência e regra de nível ------------------------------------
await asAdmin();
const incons = await rows(`
  select p.display_name, p.total_xp, coalesce(sum(um.xp_awarded), 0)::int as soma
    from public.profiles p left join public.user_missions um on um.user_id = p.id
   group by p.id having p.total_xp <> coalesce(sum(um.xp_awarded), 0)`);
check('total_xp = soma de xp_awarded para todos', incons.length === 0, JSON.stringify(incons));
const lv = await rows(`select x, public.level_for_xp(x) l from unnest(array[0,99,100,299,300,599,600,999,1000]) x`);
check('level_for_xp igual à regra do Flutter', JSON.stringify(lv.map((r) => r.l)) === JSON.stringify([1, 1, 2, 2, 3, 3, 4, 4, 5]), JSON.stringify(lv));

console.log(`\n${failures === 0 ? 'TODOS OS TESTES PASSARAM' : failures + ' FALHA(S)'}`);
process.exit(failures === 0 ? 0 : 1);
