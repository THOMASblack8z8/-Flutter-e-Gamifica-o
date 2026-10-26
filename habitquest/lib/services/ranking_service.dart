import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ranking_entry.dart';

/// Ranking calculado no banco a partir de profiles.total_xp.
/// Desempate: XP, nível, data de cadastro (mais antigo primeiro).
class RankingService {
  RankingService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<RankingEntry>> getLeaderboard({int limit = 50}) async {
    final data = await _client.rpc('get_leaderboard', params: {'p_limit': limit});
    return (data as List<dynamic>)
        .map((row) => RankingEntry.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  /// Posição do usuário autenticado (mesmo fora do top exibido).
  Future<RankingEntry?> getMyRank() async {
    final data = await _client.rpc('get_my_rank') as List<dynamic>;
    if (data.isEmpty) return null;
    return RankingEntry.fromMap(Map<String, dynamic>.from(data.first as Map));
  }
}
