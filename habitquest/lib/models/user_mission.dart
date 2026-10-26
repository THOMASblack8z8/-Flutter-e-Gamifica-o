import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Status de uma missão para o usuário autenticado.
/// `available` não existe no banco: significa "ainda não há registro".
enum MissionStatus {
  available('Disponível', Icons.radio_button_unchecked_rounded, AppColors.electricBlue),
  inProgress('Em andamento', Icons.timelapse_rounded, AppColors.warning),
  completed('Concluída', Icons.check_circle_rounded, AppColors.success);

  const MissionStatus(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  static MissionStatus fromDb(String? value) => switch (value) {
        'in_progress' => MissionStatus.inProgress,
        'completed' => MissionStatus.completed,
        _ => MissionStatus.available,
      };
}

/// Linha da tabela `user_missions`.
class UserMission {
  const UserMission({
    required this.id,
    required this.missionId,
    required this.status,
    required this.startedAt,
    required this.xpAwarded,
    required this.coinsAwarded,
    this.completedAt,
  });

  final String id;
  final String missionId;
  final MissionStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int xpAwarded;
  final int coinsAwarded;

  factory UserMission.fromMap(Map<String, dynamic> map) {
    final completedAt = map['completed_at'] as String?;
    return UserMission(
      id: map['id'] as String,
      missionId: map['mission_id'] as String,
      status: MissionStatus.fromDb(map['status'] as String?),
      startedAt: DateTime.parse(map['started_at'] as String),
      completedAt: completedAt == null ? null : DateTime.parse(completedAt),
      xpAwarded: (map['xp_awarded'] as num?)?.toInt() ?? 0,
      coinsAwarded: (map['coins_awarded'] as num?)?.toInt() ?? 0,
    );
  }
}
