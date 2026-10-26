import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/completion_result.dart';
import '../models/mission.dart';
import '../models/user_mission.dart';

/// Consulta de missões e operações protegidas de início/conclusão.
class MissionService {
  MissionService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Missões ativas do catálogo (o RLS já filtra apenas as ativas).
  Future<List<Mission>> getActiveMissions() async {
    final data = await _client
        .from('missions')
        .select()
        .eq('is_active', true)
        .order('category')
        .order('xp_reward');
    return data.map(Mission.fromMap).toList();
  }

  /// Uma missão específica, ou `null` se não existir / estiver inativa.
  Future<Mission?> getMission(String id) async {
    final data = await _client.from('missions').select().eq('id', id).maybeSingle();
    return data == null ? null : Mission.fromMap(data);
  }

  /// Registros de missões do usuário autenticado, indexados pelo id da missão.
  /// O RLS garante que só os registros do próprio usuário são retornados.
  Future<Map<String, UserMission>> getMyUserMissions() async {
    final data = await _client.from('user_missions').select();
    final list = data.map(UserMission.fromMap);
    return {for (final item in list) item.missionId: item};
  }

  Future<UserMission?> getMyUserMission(String missionId) async {
    final data =
        await _client.from('user_missions').select().eq('mission_id', missionId).maybeSingle();
    return data == null ? null : UserMission.fromMap(data);
  }

  /// Marca a missão como "em andamento" (não concede XP).
  Future<void> startMission(String missionId) async {
    await _client.rpc('start_mission', params: {'p_mission_id': missionId});
  }

  /// Pede ao banco para concluir a missão. O app NÃO envia quantidade de XP:
  /// a função `complete_mission` lê a recompensa oficial, impede duplicidade
  /// e atualiza XP, nível, moedas e conquistas numa única transação.
  Future<CompletionResult> completeMission(String missionId) async {
    final data = await _client.rpc('complete_mission', params: {'p_mission_id': missionId});
    return CompletionResult.fromMap(Map<String, dynamic>.from(data as Map));
  }
}
