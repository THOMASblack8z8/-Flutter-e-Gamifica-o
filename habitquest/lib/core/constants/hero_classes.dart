import 'package:flutter/material.dart';

/// Classes de herói que o usuário pode escolher no perfil.
/// As chaves são as mesmas aceitas pela coluna profiles.hero_class.
class HeroClass {
  const HeroClass({
    required this.key,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String key;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
}

class HeroClasses {
  HeroClasses._();

  static const all = [
    HeroClass(
      key: 'guerreiro',
      label: 'Guerreiro',
      description: 'Enfrenta as tarefas de frente.',
      icon: Icons.shield_rounded,
      color: Color(0xFF8B5CF6),
    ),
    HeroClass(
      key: 'mago',
      label: 'Mago',
      description: 'Transforma estudo em poder.',
      icon: Icons.auto_fix_high_rounded,
      color: Color(0xFF3B82F6),
    ),
    HeroClass(
      key: 'arqueiro',
      label: 'Arqueiro',
      description: 'Mira nas metas com precisão.',
      icon: Icons.gps_fixed_rounded,
      color: Color(0xFF22D3EE),
    ),
    HeroClass(
      key: 'guardiao',
      label: 'Guardião',
      description: 'Protege a própria rotina.',
      icon: Icons.security_rounded,
      color: Color(0xFFC084FC),
    ),
  ];

  static HeroClass of(String key) => all.firstWhere((c) => c.key == key, orElse: () => all.first);
}
