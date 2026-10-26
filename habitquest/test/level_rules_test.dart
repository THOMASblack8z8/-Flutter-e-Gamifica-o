import 'package:flutter_test/flutter_test.dart';
import 'package:habitquest/core/utils/level_rules.dart';

void main() {
  group('LevelRules', () {
    test('XP total exigido por nível segue 50 * N * (N - 1)', () {
      expect(LevelRules.totalXpForLevel(1), 0);
      expect(LevelRules.totalXpForLevel(2), 100);
      expect(LevelRules.totalXpForLevel(3), 300);
      expect(LevelRules.totalXpForLevel(4), 600);
      expect(LevelRules.totalXpForLevel(5), 1000);
    });

    test('nível calculado a partir do XP, inclusive nos limites', () {
      expect(LevelRules.levelForXp(0), 1);
      expect(LevelRules.levelForXp(99), 1);
      expect(LevelRules.levelForXp(100), 2);
      expect(LevelRules.levelForXp(299), 2);
      expect(LevelRules.levelForXp(300), 3);
      expect(LevelRules.levelForXp(620), 4);
      expect(LevelRules.levelForXp(1000), 5);
    });

    test('progresso dentro do nível', () {
      final progress = LevelRules.progressFor(350);
      expect(progress.level, 3);
      expect(progress.xpIntoLevel, 50);
      expect(progress.xpForThisLevel, 300);
      expect(progress.xpToNextLevel, 250);
      expect(progress.fraction, closeTo(1 / 6, 0.0001));
    });

    test('XP negativo é tratado como zero', () {
      expect(LevelRules.progressFor(-10).level, 1);
      expect(LevelRules.progressFor(-10).xpIntoLevel, 0);
    });
  });
}
