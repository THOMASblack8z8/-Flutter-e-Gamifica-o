/// Resultado devolvido pela função `complete_mission` do banco.
class CompletionResult {
  const CompletionResult({
    required this.alreadyCompleted,
    required this.xpAwarded,
    required this.coinsAwarded,
    required this.totalXp,
    required this.level,
    required this.coins,
    required this.leveledUp,
    required this.newAchievements,
  });

  /// `true` quando a missão já tinha sido concluída antes (nenhum XP concedido).
  final bool alreadyCompleted;
  final int xpAwarded;
  final int coinsAwarded;
  final int totalXp;
  final int level;
  final int coins;
  final bool leveledUp;
  final List<UnlockedAchievement> newAchievements;

  factory CompletionResult.fromMap(Map<String, dynamic> map) {
    final achievements = (map['new_achievements'] as List<dynamic>? ?? [])
        .map((item) => UnlockedAchievement.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
    return CompletionResult(
      alreadyCompleted: map['status'] == 'already_completed',
      xpAwarded: (map['xp_awarded'] as num?)?.toInt() ?? 0,
      coinsAwarded: (map['coins_awarded'] as num?)?.toInt() ?? 0,
      totalXp: (map['total_xp'] as num?)?.toInt() ?? 0,
      level: (map['level'] as num?)?.toInt() ?? 1,
      coins: (map['coins'] as num?)?.toInt() ?? 0,
      leveledUp: map['leveled_up'] as bool? ?? false,
      newAchievements: achievements,
    );
  }
}

/// Conquista recém-desbloqueada (nome e ícone para a animação).
class UnlockedAchievement {
  const UnlockedAchievement({required this.name, required this.icon});

  final String name;
  final String icon;

  factory UnlockedAchievement.fromMap(Map<String, dynamic> map) {
    return UnlockedAchievement(name: map['name'] as String, icon: map['icon'] as String);
  }
}
