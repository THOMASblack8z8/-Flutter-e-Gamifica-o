/// Regra de níveis do HabitQuest (idêntica à função SQL `level_for_xp`).
///
/// Para passar do nível N para o N+1 são necessários 100 * N de XP.
/// XP total para alcançar o nível N = 50 * N * (N - 1):
///   Nível 1 = 0 | Nível 2 = 100 | Nível 3 = 300 | Nível 4 = 600 | Nível 5 = 1000
///
/// O nível OFICIAL é calculado e salvo pelo banco. Esta classe é usada
/// apenas para exibir a barra de progresso de forma consistente.
class LevelRules {
  LevelRules._();

  /// XP total necessário para alcançar [level].
  static int totalXpForLevel(int level) => level <= 1 ? 0 : 50 * level * (level - 1);

  /// XP necessário para sair de [level] e chegar ao próximo nível.
  static int xpToAdvanceFrom(int level) => 100 * level;

  /// Nível correspondente a um total de XP.
  static int levelForXp(int totalXp) {
    var level = 1;
    while (totalXpForLevel(level + 1) <= totalXp) {
      level++;
    }
    return level;
  }

  static LevelProgress progressFor(int totalXp) {
    final xp = totalXp < 0 ? 0 : totalXp;
    final level = levelForXp(xp);
    return LevelProgress(
      level: level,
      totalXp: xp,
      levelStartXp: totalXpForLevel(level),
      nextLevelXp: totalXpForLevel(level + 1),
    );
  }
}

/// Situação do usuário dentro do nível atual.
class LevelProgress {
  const LevelProgress({
    required this.level,
    required this.totalXp,
    required this.levelStartXp,
    required this.nextLevelXp,
  });

  final int level;
  final int totalXp;
  final int levelStartXp;
  final int nextLevelXp;

  /// XP ganho desde o início do nível atual.
  int get xpIntoLevel => totalXp - levelStartXp;

  /// XP que o nível atual exige no total.
  int get xpForThisLevel => nextLevelXp - levelStartXp;

  /// Quanto falta para o próximo nível.
  int get xpToNextLevel => nextLevelXp - totalXp;

  double get fraction => xpForThisLevel == 0 ? 1 : xpIntoLevel / xpForThisLevel;
}
