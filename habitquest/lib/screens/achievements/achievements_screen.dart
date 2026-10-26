import 'package:flutter/material.dart';

import '../../core/state/progress_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../models/achievement.dart';
import '../../services/achievement_service.dart';
import '../../widgets/achievement_badge.dart';
import '../../widgets/state_views.dart';

/// Coleção de conquistas (desbloqueadas e bloqueadas) vinda do banco.
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final _achievementService = AchievementService();
  Future<List<Achievement>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
    ProgressNotifier.instance.addListener(_load);
  }

  @override
  void dispose() {
    ProgressNotifier.instance.removeListener(_load);
    super.dispose();
  }

  void _load() {
    setState(() {
      _future = _achievementService.getAchievementsWithStatus();
    });
  }

  Future<void> _refresh() async {
    _load();
    try {
      await _future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Conquistas')),
      body: FutureContent<List<Achievement>>(
        future: _future,
        onRetry: _load,
        loadingMessage: 'Abrindo a sala de troféus...',
        builder: (context, achievements) {
          if (achievements.isEmpty) {
            return const EmptyView(
              icon: Icons.emoji_events_outlined,
              title: 'Nenhuma conquista cadastrada',
              message: 'O catálogo de conquistas ainda está vazio.',
            );
          }
          final unlocked = achievements.where((a) => a.isUnlocked).length;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverToBoxAdapter(
                    child: _CollectionSummary(unlocked: unlocked, total: achievements.length),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisExtent: 236,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      childCount: achievements.length,
                      (context, index) {
                        final achievement = achievements[index];
                        return AchievementBadge(
                          name: achievement.name,
                          description: achievement.description,
                          iconKey: achievement.icon,
                          unlocked: achievement.isUnlocked,
                          criteria: achievement.criteriaLabel,
                          unlockedAt: achievement.unlockedAt,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CollectionSummary extends StatelessWidget {
  const _CollectionSummary({required this.unlocked, required this.total});

  final int unlocked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : unlocked / total;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lilac.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$unlocked de $total desbloqueadas', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: fraction),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: AppColors.backgroundDeep,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
