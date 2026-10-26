import 'package:flutter/material.dart';

/// Metadados visuais de uma categoria de missão.
/// As chaves (`key`) são as mesmas aceitas pela coluna missions.category.
class MissionCategory {
  const MissionCategory({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String key;
  final String label;
  final IconData icon;
  final Color color;
}

class Categories {
  Categories._();

  static const estudos = MissionCategory(
    key: 'estudos',
    label: 'Estudos',
    icon: Icons.menu_book_rounded,
    color: Color(0xFF60A5FA),
  );
  static const organizacao = MissionCategory(
    key: 'organizacao',
    label: 'Organização',
    icon: Icons.checklist_rounded,
    color: Color(0xFFA78BFA),
  );
  static const habitos = MissionCategory(
    key: 'habitos',
    label: 'Hábitos',
    icon: Icons.autorenew_rounded,
    color: Color(0xFF34D399),
  );
  static const movimento = MissionCategory(
    key: 'movimento',
    label: 'Movimento',
    icon: Icons.directions_walk_rounded,
    color: Color(0xFF22D3EE),
  );
  static const bemEstar = MissionCategory(
    key: 'bem_estar',
    label: 'Bem-estar',
    icon: Icons.spa_rounded,
    color: Color(0xFFF472B6),
  );

  static const all = [estudos, organizacao, habitos, movimento, bemEstar];

  static MissionCategory of(String key) =>
      all.firstWhere((c) => c.key == key, orElse: () => organizacao);
}

/// Rótulos de dificuldade (coluna missions.difficulty).
class Difficulties {
  Difficulties._();

  static String label(String key) => switch (key) {
        'facil' => 'Fácil',
        'media' => 'Média',
        'dificil' => 'Difícil',
        _ => key,
      };

  /// Quantidade de "estrelas" exibidas para a dificuldade.
  static int stars(String key) => switch (key) {
        'facil' => 1,
        'media' => 2,
        'dificil' => 3,
        _ => 1,
      };
}
