/// Linha da tabela `missions` (catálogo de missões).
class Mission {
  const Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.rules,
    required this.category,
    required this.xpReward,
    required this.coinReward,
    required this.difficulty,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String rules;
  final String category;
  final int xpReward;
  final int coinReward;
  final String difficulty;
  final bool isActive;
  final DateTime createdAt;

  factory Mission.fromMap(Map<String, dynamic> map) {
    return Mission(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      rules: map['rules'] as String,
      category: map['category'] as String,
      xpReward: (map['xp_reward'] as num).toInt(),
      coinReward: (map['coin_reward'] as num?)?.toInt() ?? 0,
      difficulty: map['difficulty'] as String,
      isActive: map['is_active'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
