import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/categories.dart';
import '../../core/router/app_router.dart';
import '../../core/state/progress_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../models/mission.dart';
import '../../models/user_mission.dart';
import '../../services/mission_service.dart';
import '../../widgets/mission_card.dart';
import '../../widgets/state_views.dart';

/// Lista de missões com filtros por categoria e status.
class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsData {
  const _MissionsData(this.missions, this.userMissions);

  final List<Mission> missions;
  final Map<String, UserMission> userMissions;

  MissionStatus statusOf(Mission mission) => userMissions[mission.id]?.status ?? MissionStatus.available;
}

class _MissionsScreenState extends State<MissionsScreen> {
  final _missionService = MissionService();

  Future<_MissionsData>? _future;
  String? _categoryFilter; // null = todas
  MissionStatus? _statusFilter; // null = todos

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

  Future<_MissionsData> _fetch() async {
    final results = await Future.wait<Object>([
      _missionService.getActiveMissions(),
      _missionService.getMyUserMissions(),
    ]);
    return _MissionsData(results[0] as List<Mission>, results[1] as Map<String, UserMission>);
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
      appBar: AppBar(title: const Text('Missões')),
      body: FutureContent<_MissionsData>(
        future: _future,
        onRetry: _load,
        loadingMessage: 'Buscando missões...',
        builder: (context, data) {
          if (data.missions.isEmpty) {
            return const EmptyView(
              icon: Icons.map_outlined,
              title: 'Nenhuma missão disponível',
              message: 'Ainda não há missões ativas cadastradas no banco.',
            );
          }

          final filtered = data.missions.where((mission) {
            final categoryOk = _categoryFilter == null || mission.category == _categoryFilter;
            final statusOk = _statusFilter == null || data.statusOf(mission) == _statusFilter;
            return categoryOk && statusOk;
          }).toList();
          final completed = data.missions.where((m) => data.statusOf(m) == MissionStatus.completed).length;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Text(
                  '$completed de ${data.missions.length} missões concluídas',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                _FilterRow(
                  children: [
                    _filterChip(
                      label: 'Todas',
                      selected: _categoryFilter == null,
                      onSelected: () => setState(() => _categoryFilter = null),
                    ),
                    for (final category in Categories.all)
                      _filterChip(
                        label: category.label,
                        icon: category.icon,
                        color: category.color,
                        selected: _categoryFilter == category.key,
                        onSelected: () => setState(() => _categoryFilter = category.key),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _FilterRow(
                  children: [
                    _filterChip(
                      label: 'Qualquer status',
                      selected: _statusFilter == null,
                      onSelected: () => setState(() => _statusFilter = null),
                    ),
                    for (final status in MissionStatus.values)
                      _filterChip(
                        label: status.label,
                        icon: status.icon,
                        color: status.color,
                        selected: _statusFilter == status,
                        onSelected: () => setState(() => _statusFilter = status),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  EmptyView(
                    icon: Icons.filter_alt_off_rounded,
                    title: 'Nenhuma missão encontrada',
                    message: 'Não há missões com os filtros selecionados.',
                    action: OutlinedButton(
                      onPressed: () => setState(() {
                        _categoryFilter = null;
                        _statusFilter = null;
                      }),
                      child: const Text('Limpar filtros'),
                    ),
                  )
                else
                  for (final mission in filtered)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MissionCard(
                        mission: mission,
                        status: data.statusOf(mission),
                        onTap: () => context.push(AppRoutes.missionDetails(mission.id)),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
    IconData? icon,
    Color color = AppColors.lilac,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        avatar: icon == null ? null : Icon(icon, size: 16, color: color),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: children),
    );
  }
}
