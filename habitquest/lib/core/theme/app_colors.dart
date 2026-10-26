import 'package:flutter/material.dart';

/// Paleta do HabitQuest: azul-marinho profundo com destaques em
/// violeta, azul elétrico e lilás.
class AppColors {
  AppColors._();

  static const background = Color(0xFF0B1026);
  static const backgroundDeep = Color(0xFF070A1A);
  static const surface = Color(0xFF151B3D);
  static const surfaceAlt = Color(0xFF1E2452);
  static const cardTop = Color(0xFF2A1F5C);
  static const cardBottom = Color(0xFF1B2A6B);

  static const violet = Color(0xFF8B5CF6);
  static const electricBlue = Color(0xFF3B82F6);
  static const lilac = Color(0xFFC4B5FD);
  static const gold = Color(0xFFFBBF24);
  static const success = Color(0xFF34D399);
  static const warning = Color(0xFFFBBF24);
  static const error = Color(0xFFF87171);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB8BCD9);
  static const textMuted = Color(0xFF8C91B5);
  static const border = Color(0x33C4B5FD);
  static const locked = Color(0xFF3A3F63);

  static const primaryGradient = LinearGradient(
    colors: [violet, electricBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cardGradient = LinearGradient(
    colors: [cardTop, cardBottom],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
