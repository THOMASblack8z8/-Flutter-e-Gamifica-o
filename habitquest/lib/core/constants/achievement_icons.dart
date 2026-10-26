import 'package:flutter/material.dart';

/// Converte o identificador salvo em achievements.icon em um ícone do Flutter.
IconData achievementIcon(String key) => switch (key) {
      'flag' => Icons.flag_rounded,
      'repeat' => Icons.repeat_rounded,
      'shield' => Icons.shield_rounded,
      'explore' => Icons.explore_rounded,
      'public' => Icons.public_rounded,
      'trending_up' => Icons.trending_up_rounded,
      'military_tech' => Icons.military_tech_rounded,
      'auto_awesome' => Icons.auto_awesome_rounded,
      _ => Icons.emoji_events_rounded,
    };
