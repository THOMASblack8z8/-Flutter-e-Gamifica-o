import '../core/utils/level_rules.dart';

/// Linha da tabela `profiles`.
class Profile {
  const Profile({
    required this.id,
    required this.displayName,
    required this.heroClass,
    required this.totalXp,
    required this.level,
    required this.coins,
    required this.createdAt,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
  final String heroClass;
  final int totalXp;
  final int level;
  final int coins;
  final DateTime createdAt;

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      displayName: map['display_name'] as String,
      avatarUrl: map['avatar_url'] as String?,
      heroClass: (map['hero_class'] as String?) ?? 'guerreiro',
      totalXp: (map['total_xp'] as num?)?.toInt() ?? 0,
      level: (map['level'] as num?)?.toInt() ?? 1,
      coins: (map['coins'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Progresso dentro do nível atual (para a barra de XP).
  LevelProgress get progress => LevelRules.progressFor(totalXp);
}
