import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/categories.dart';
import '../../core/constants/hero_classes.dart';
import '../../core/router/app_router.dart';
import '../../core/state/progress_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_messages.dart';
import '../../core/utils/formatters.dart';
import '../../models/achievement.dart';
import '../../models/mission.dart';
import '../../models/profile.dart';
import '../../models/user_mission.dart';
import '../../services/achievement_service.dart';
import '../../services/auth_service.dart';
import '../../services/mission_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/achievement_badge.dart';
import '../../widgets/app_button.dart';
import '../../widgets/hero_avatar.dart';
import '../../widgets/section_title.dart';
import '../../widgets/stat_tile.dart';
import '../../widgets/state_views.dart';
import '../../widgets/xp_progress_bar.dart';

/// Tela do Herói (perfil): dados, estatísticas, conquistas e logout.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileData {
  const _ProfileData(this.profile, this.missions, this.userMissions, this.achievements);

  final Profile profile;
  final List<Mission> missions;
  final Map<String, UserMission> userMissions;
  final List<Achievement> achievements;

  int get completedCount => userMissions.values.where((um) => um.status == MissionStatus.completed).length;

  /// Missões concluídas / total, por categoria.
  Map<String, (int, int)> get byCategory {
    final result = <String, (int, int)>{};
    for (final category in Categories.all) {
      final inCategory = missions.where((m) => m.category == category.key);
      final done = inCategory.where((m) => userMissions[m.id]?.status == MissionStatus.completed).length;
      result[category.key] = (done, inCategory.length);
    }
    return result;
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService();
  final _missionService = MissionService();
  final _achievementService = AchievementService();
  final _authService = AuthService();

  Future<_ProfileData>? _future;
  bool _signingOut = false;

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

  Future<_ProfileData> _fetch() async {
    final results = await Future.wait<Object>([
      _profileService.getMyProfile(),
      _missionService.getActiveMissions(),
      _missionService.getMyUserMissions(),
      _achievementService.getAchievementsWithStatus(),
    ]);
    return _ProfileData(
      results[0] as Profile,
      results[1] as List<Mission>,
      results[2] as Map<String, UserMission>,
      results[3] as List<Achievement>,
    );
  }

  Future<void> _refresh() async {
    _load();
    try {
      await _future;
    } catch (_) {}
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text('Seu progresso fica salvo. Você pode entrar novamente quando quiser.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Sair')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _signingOut = true);
    try {
      await _authService.signOut();
      // O GoRouter detecta o logout e volta para o Login.
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Meu Herói'),
        actions: [
          IconButton(
            tooltip: 'Editar perfil',
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => context.push(AppRoutes.editProfile),
          ),
        ],
      ),
      body: FutureContent<_ProfileData>(
        future: _future,
        onRetry: _load,
        loadingMessage: 'Carregando perfil...',
        builder: (context, data) {
          final profile = data.profile;
          final heroClass = HeroClasses.of(profile.heroClass);
          final progress = profile.progress;
          final unlocked = data.achievements.where((a) => a.isUnlocked).toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Center(
                  child: HeroAvatar(
                    heroClass: profile.heroClass,
                    level: profile.level,
                    avatarUrl: profile.avatarUrl,
                    size: 150,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  profile.displayName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(heroClass.icon, color: heroClass.color, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${heroClass.label} · ${heroClass.description}',
                      style: const TextStyle(color: AppColors.lilac, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Herói desde ${formatDate(profile.createdAt)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.cardGradient,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: XpProgressBar(
                    level: profile.level,
                    currentXp: progress.xpIntoLevel,
                    requiredXp: progress.xpForThisLevel,
                    height: 14,
                  ),
                ),
                const SizedBox(height: 16),
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  // Altura fixa: com proporção, os quadros ficam enormes no PC e cortados no celular.
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 112,
                  ),
                  children: [
                    StatTile(icon: Icons.bolt_rounded, value: '${profile.totalXp}', label: 'XP acumulado'),
                    StatTile(
                      icon: Icons.paid_rounded,
                      value: '${profile.coins}',
                      label: 'Moedas',
                      color: AppColors.gold,
                    ),
                    StatTile(
                      icon: Icons.task_alt_rounded,
                      value: '${data.completedCount}',
                      label: 'Missões concluídas',
                      color: AppColors.success,
                    ),
                    StatTile(
                      icon: Icons.emoji_events_rounded,
                      value: '${unlocked.length}/${data.achievements.length}',
                      label: 'Conquistas',
                      color: AppColors.electricBlue,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const SectionTitle(title: 'Missões por categoria'),
                const SizedBox(height: 8),
                for (final category in Categories.all)
                  _CategoryProgress(
                    category: category,
                    done: data.byCategory[category.key]!.$1,
                    total: data.byCategory[category.key]!.$2,
                  ),
                const SizedBox(height: 16),
                const SectionTitle(title: 'Conquistas desbloqueadas'),
                const SizedBox(height: 8),
                if (unlocked.isEmpty)
                  Text(
                    'Nenhuma conquista ainda. Conclua missões para desbloquear medalhas!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children: [
                      for (final achievement in unlocked)
                        AchievementBadge(
                          name: achievement.name,
                          description: achievement.description,
                          iconKey: achievement.icon,
                          unlocked: true,
                          compact: true,
                          size: 56,
                        ),
                    ],
                  ),
                const SizedBox(height: 28),
                AppButton(
                  label: 'Editar perfil',
                  icon: Icons.edit_rounded,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.push(AppRoutes.editProfile),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Sair',
                  icon: Icons.logout_rounded,
                  variant: AppButtonVariant.danger,
                  loading: _signingOut,
                  onPressed: _confirmSignOut,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryProgress extends StatelessWidget {
  const _CategoryProgress({required this.category, required this.done, required this.total});

  final MissionCategory category;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(category.icon, color: category.color, size: 20),
          const SizedBox(width: 10),
          SizedBox(
            width: 96,
            child: Text(category.label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : done / total,
                minHeight: 8,
                backgroundColor: AppColors.backgroundDeep,
                color: category.color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('$done/$total', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
