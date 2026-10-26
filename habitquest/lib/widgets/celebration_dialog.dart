import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/completion_result.dart';
import 'achievement_badge.dart';

/// Animação de recompensa exibida após concluir uma missão.
/// (É um diálogo, não uma tela; por isso não passa pelo GoRouter.)
Future<void> showCelebrationDialog(
  BuildContext context, {
  required CompletionResult result,
  required String missionTitle,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fechar',
    barrierColor: Colors.black.withValues(alpha: 0.7),
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (context, _, _) => _CelebrationContent(result: result, missionTitle: missionTitle),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: Tween(begin: 0.8, end: 1.0).animate(curved), child: child),
      );
    },
  );
}

class _CelebrationContent extends StatelessWidget {
  const _CelebrationContent({required this.result, required this.missionTitle});

  final CompletionResult result;
  final String missionTitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.lilac.withValues(alpha: 0.6)),
              boxShadow: [BoxShadow(color: AppColors.violet.withValues(alpha: 0.5), blurRadius: 40)],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: [BoxShadow(color: AppColors.violet.withValues(alpha: 0.7), blurRadius: 24)],
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text('Missão concluída!', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(missionTitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 20),
                  // Contador animado de XP.
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: result.xpAwarded),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOut,
                    builder: (context, value, _) => Text(
                      '+$value XP',
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.lilac),
                    ),
                  ),
                  if (result.coinsAwarded > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.paid_rounded, color: AppColors.gold, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '+${result.coinsAwarded} moedas',
                          style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  if (result.leveledUp) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.gold),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.keyboard_double_arrow_up_rounded, color: AppColors.gold),
                          const SizedBox(width: 6),
                          Text(
                            'Você subiu para o nível ${result.level}!',
                            style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (result.newAchievements.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Conquista desbloqueada!',
                      style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final achievement in result.newAchievements)
                          AchievementBadge(
                            name: achievement.name,
                            description: 'Nova conquista',
                            iconKey: achievement.icon,
                            unlocked: true,
                            compact: true,
                            size: 60,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Continuar jornada', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
