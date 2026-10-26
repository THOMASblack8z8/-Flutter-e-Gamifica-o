import 'package:flutter/material.dart';

import '../../core/state/progress_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../models/ranking_entry.dart';
import '../../services/ranking_service.dart';
import '../../widgets/hero_avatar.dart';
import '../../widgets/state_views.dart';

/// Ranking calculado no banco a partir da pontuação persistida.
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingData {
  const _RankingData(this.entries, this.me);

  final List<RankingEntry> entries;
  final RankingEntry? me;
}

class _RankingScreenState extends State<RankingScreen> {
  final _rankingService = RankingService();
  Future<_RankingData>? _future;

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

  Future<_RankingData> _fetch() async {
    final results = await Future.wait<Object?>([
      _rankingService.getLeaderboard(limit: 50),
      _rankingService.getMyRank(),
    ]);
    return _RankingData(results[0] as List<RankingEntry>, results[1] as RankingEntry?);
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
      appBar: AppBar(title: const Text('Ranking dos Heróis')),
      body: FutureContent<_RankingData>(
        future: _future,
        onRetry: _load,
        loadingMessage: 'Consultando o ranking...',
        builder: (context, data) {
          if (data.entries.isEmpty) {
            return const EmptyView(
              icon: Icons.leaderboard_outlined,
              title: 'Ranking vazio',
              message: 'Ainda não há heróis no ranking.',
            );
          }
          final me = data.me;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                if (me != null) _MyPositionCard(me: me, total: data.entries.length),
                const SizedBox(height: 12),
                const Text(
                  'Ordenado por XP total. Empates: maior nível e, depois, quem entrou primeiro.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                for (final entry in data.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RankingTile(entry: entry),
                  ),
                if (data.entries.length < 2)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Você é o único herói por enquanto. Convide colegas para criar uma conta e disputar o topo!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
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

class _MyPositionCard extends StatelessWidget {
  const _MyPositionCard({required this.me, required this.total});

  final RankingEntry me;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.violet.withValues(alpha: 0.4), blurRadius: 20)],
      ),
      child: Row(
        children: [
          Text(
            '#${me.position}',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sua posição', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                Text(
                  '${me.totalXp} XP · Nível ${me.level}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const Icon(Icons.military_tech_rounded, color: Colors.white, size: 36),
        ],
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  const _RankingTile({required this.entry});

  final RankingEntry entry;

  static const _medalColors = {1: AppColors.gold, 2: Color(0xFFCBD5E1), 3: Color(0xFFD97706)};

  @override
  Widget build(BuildContext context) {
    final medal = _medalColors[entry.position];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: entry.isMe ? AppColors.cardGradient : null,
        color: entry.isMe ? null : AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: entry.isMe ? AppColors.lilac : (medal?.withValues(alpha: 0.6) ?? AppColors.border),
          width: entry.isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: medal != null
                ? Icon(Icons.workspace_premium_rounded, color: medal, size: 30)
                : Text(
                    '${entry.position}º',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                  ),
          ),
          const SizedBox(width: 8),
          HeroAvatar(
            heroClass: entry.heroClass,
            level: entry.level,
            avatarUrl: entry.avatarUrl,
            size: 48,
            showLevel: false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.isMe ? '${entry.displayName} (você)' : entry.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                Text(
                  'Nível ${entry.level} · ${entry.missionsCompleted} missões',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '${entry.totalXp} XP',
            style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.lilac, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
