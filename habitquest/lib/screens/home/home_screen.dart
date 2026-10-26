import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/state/progress_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/achievement.dart';
import '../../models/mission.dart';
import '../../models/profile.dart';
import '../../models/user_mission.dart';
import '../../services/achievement_service.dart';
import '../../services/mission_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/achievement_badge.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/hero_header.dart';
import '../../widgets/mission_card.dart';
import '../../widgets/section_title.dart';
import '../../widgets/stat_tile.dart';
import '../../widgets/state_views.dart';

/// Painel do Herói: todos os números vêm do Supabase.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeData {
  const _HomeData({
    required this.profile,
    required this.missions,
    required this.userMissions,
    required this.achievements,
  });

  final Profile profile;
  final List<Mission> missions;
  final Map<String, UserMission> userMissions;
  final List<Achievement> achievements;

  MissionStatus statusOf(Mission mission) => userMissions[mission.id]?.status ?? MissionStatus.available;

  /// Conclusões de missões que ainda estão ativas no catálogo.
  int get completedCount => missions.where((m) => statusOf(m) == MissionStatus.completed).length;

  int get completedToday => userMissions.values
      .where((um) => um.status == MissionStatus.completed && um.completedAt != null && isToday(um.completedAt!))
      .length;

  /// Missões ainda não concluídas, com as "em andamento" primeiro.
  List<Mission> get pendingMissions {
    final pending = missions.where((m) => statusOf(m) != MissionStatus.completed).toList();
    pending.sort((a, b) {
      final aStarted = statusOf(a) == MissionStatus.inProgress ? 0 : 1;
      final bStarted = statusOf(b) == MissionStatus.inProgress ? 0 : 1;
      return aStarted.compareTo(bStarted);
    });
    return pending;
  }

  List<Achievement> get recentAchievements {
    final unlocked = achievements.where((a) => a.isUnlocked).toList()
      ..sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!));
    return unlocked.take(4).toList();
  }
}

class _HomeScreenState extends State<HomeScreen> {
  final _profileService = ProfileService();
  final _missionService = MissionService();
  final _achievementService = AchievementService();

  Future<_HomeData>? _future;

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
      _future = _fetch();
    });
  }

  Future<_HomeData> _fetch() async {
    final results = await Future.wait<Object>([
      _profileService.getMyProfile(),
      _missionService.getActiveMissions(),
      _missionService.getMyUserMissions(),
      _achievementService.getAchievementsWithStatus(),
    ]);
    return _HomeData(
      profile: results[0] as Profile,
      missions: results[1] as List<Mission>,
      userMissions: results[2] as Map<String, UserMission>,
      achievements: results[3] as List<Achievement>,
    );
  }

  Future<void> _refresh() async {
    _load();
    try {
      await _future;
    } catch (_) {
      // O erro é exibido pelo FutureContent.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: FutureContent<_HomeData>(
          future: _future,
          onRetry: _load,
          loadingMessage: 'Carregando seu herói...',
          builder: (context, data) => RefreshIndicator(
            onRefresh: _refresh,
            child: _HomeContent(data: data),
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.data});

  final _HomeData data;

  @override
  Widget build(BuildContext context) {
    final total = data.missions.length;
    final completed = data.completedCount;
    final percent = total == 0 ? 0 : (completed * 100 / total).round();
    final pending = data.pendingMissions.take(3).toList();
    final recent = data.recentAchievements;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Row(
          children: [
            const AppLogo(size: 28, showName: false),
            const SizedBox(width: 10),
            Text('HabitQuest', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            IconButton(
              tooltip: 'Ranking',
              onPressed: () => context.go(AppRoutes.ranking),
              icon: const Icon(Icons.leaderboard_rounded, color: AppColors.lilac),
            ),
            IconButton(
              tooltip: 'Perfil',
              onPressed: () => context.go(AppRoutes.profile),
              icon: const Icon(Icons.person_rounded, color: AppColors.lilac),
            ),
          ],
        ),
        const SizedBox(height: 12),
        HeroHeader(profile: data.profile, onAvatarTap: () => context.go(AppRoutes.profile)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.today_rounded,
                value: '${data.completedToday}',
                label: 'Concluídas hoje',
                color: AppColors.electricBlue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                icon: Icons.task_alt_rounded,
                value: '$completed/$total',
                label: 'Missões concluídas',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                icon: Icons.donut_large_rounded,
                value: '$percent%',
                label: 'Progresso geral',
                color: AppColors.lilac,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SectionTitle(
          title: 'Próximas missões',
          actionLabel: 'Ver todas',
          onAction: () => context.go(AppRoutes.missions),
        ),
        const SizedBox(height: 8),
        if (total == 0)
          const _InfoCard(
            icon: Icons.map_outlined,
            text: 'Ainda não há missões cadastradas. Elas aparecerão aqui assim que forem adicionadas.',
          )
        else if (pending.isEmpty)
          const _InfoCard(
            icon: Icons.celebration_rounded,
            text: 'Você concluiu todas as missões disponíveis! Novas missões aparecerão aqui.',
          )
        else
          for (final mission in pending)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MissionCard(
                mission: mission,
                status: data.statusOf(mission),
                compact: true,
                onTap: () => context.push(AppRoutes.missionDetails(mission.id)),
              ),
            ),
        const SizedBox(height: 16),
        SectionTitle(
          title: 'Conquistas recentes',
          actionLabel: 'Ver todas',
          onAction: () => context.go(AppRoutes.achievements),
        ),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          const _InfoCard(
            icon: Icons.emoji_events_outlined,
            text: 'Conclua sua primeira missão para desbloquear a conquista "Primeira Jornada".',
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final achievement in recent)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AchievementBadge(
                      name: achievement.name,
                      description: achievement.description,
                      iconKey: achievement.icon,
                      unlocked: true,
                      compact: true,
                      size: 64,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.lilac),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
