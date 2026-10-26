import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/achievement.dart';

/// Catálogo de conquistas combinado com o que o usuário já desbloqueou.
/// O desbloqueio é feito somente pelo banco (função award_achievements).
class AchievementService {
  AchievementService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Achievement>> getAchievementsWithStatus() async {
    final results = await Future.wait([
      _client.from('achievements').select().order('sort_order'),
      _client.from('user_achievements').select('achievement_id, unlocked_at'),
    ]);

    final unlocked = <String, DateTime>{
      for (final row in results[1])
        row['achievement_id'] as String: DateTime.parse(row['unlocked_at'] as String),
    };

    return results[0]
        .map((row) => Achievement.fromMap(row, unlockedAt: unlocked[row['id']]))
        .toList();
  }
}
