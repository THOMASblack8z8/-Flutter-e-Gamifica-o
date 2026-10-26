/// Conquista do catálogo (`achievements`) com o status do usuário
/// (vindo de `user_achievements`).
class Achievement {
  const Achievement({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.icon,
    required this.criteriaType,
    required this.criteriaValue,
    required this.sortOrder,
    this.unlockedAt,
  });

  final String id;
  final String code;
  final String name;
  final String description;
  final String icon;
  final String criteriaType;
  final int criteriaValue;
  final int sortOrder;

  /// Data de desbloqueio; `null` quando ainda está bloqueada.
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;

  factory Achievement.fromMap(Map<String, dynamic> map, {DateTime? unlockedAt}) {
    return Achievement(
      id: map['id'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      icon: map['icon'] as String,
      criteriaType: map['criteria_type'] as String,
      criteriaValue: (map['criteria_value'] as num).toInt(),
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      unlockedAt: unlockedAt,
    );
  }

  /// Descrição legível do critério de desbloqueio.
  String get criteriaLabel => switch (criteriaType) {
        'missions_completed' =>
          criteriaValue == 1 ? 'Concluir 1 missão' : 'Concluir $criteriaValue missões',
        'distinct_categories' => 'Missões em $criteriaValue categorias',
        'level_reached' => 'Alcançar o nível $criteriaValue',
        'total_xp' => 'Acumular $criteriaValue XP',
        _ => 'Critério especial',
      };
}
