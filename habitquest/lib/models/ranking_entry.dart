/// Linha retornada pelas funções `get_leaderboard` e `get_my_rank`.
/// Contém apenas dados públicos mínimos (sem e-mail ou id do usuário).
class RankingEntry {
  const RankingEntry({
    required this.position,
    required this.displayName,
    required this.heroClass,
    required this.level,
    required this.totalXp,
    required this.missionsCompleted,
    required this.isMe,
    this.avatarUrl,
  });

  final int position;
  final String displayName;
  final String? avatarUrl;
  final String heroClass;
  final int level;
  final int totalXp;
  final int missionsCompleted;
  final bool isMe;

  factory RankingEntry.fromMap(Map<String, dynamic> map) {
    return RankingEntry(
      position: (map['rank_position'] as num).toInt(),
      displayName: map['display_name'] as String,
      avatarUrl: map['avatar_url'] as String?,
      heroClass: (map['hero_class'] as String?) ?? 'guerreiro',
      level: (map['level'] as num).toInt(),
      totalXp: (map['total_xp'] as num).toInt(),
      missionsCompleted: (map['missions_completed'] as num?)?.toInt() ?? 0,
      isMe: map['is_me'] as bool? ?? false,
    );
  }
}
