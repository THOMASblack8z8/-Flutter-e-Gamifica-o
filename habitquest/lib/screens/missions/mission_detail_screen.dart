import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/categories.dart';
import '../../core/router/app_router.dart';
import '../../core/state/progress_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_messages.dart';
import '../../core/utils/formatters.dart';
import '../../models/mission.dart';
import '../../models/user_mission.dart';
import '../../services/auth_service.dart';
import '../../services/mission_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_button.dart';
import '../../widgets/celebration_dialog.dart';
import '../../widgets/info_chip.dart';
import '../../widgets/state_views.dart';

/// Detalhes de uma missão. Recebe o id pela rota /missions/:id.
class MissionDetailScreen extends StatefulWidget {
  const MissionDetailScreen({super.key, required this.missionId});

  final String missionId;

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _DetailData {
  const _DetailData(this.mission, this.userMission);

  /// `null` quando a missão não existe ou está inativa.
  final Mission? mission;
  final UserMission? userMission;

  MissionStatus get status => userMission?.status ?? MissionStatus.available;
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  final _missionService = MissionService();
  final _authService = AuthService();

  Future<_DetailData>? _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = _fetch();
    });
  }

  Future<_DetailData> _fetch() async {
    final results = await Future.wait<Object?>([
      _missionService.getMission(widget.missionId),
      _missionService.getMyUserMission(widget.missionId),
    ]);
    return _DetailData(results[0] as Mission?, results[1] as UserMission?);
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.missions);
    }
  }

  void _showMessage(String text, {bool error = false, VoidCallback? retry}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        backgroundColor: error ? AppColors.error.withValues(alpha: 0.9) : null,
        action: retry == null ? null : SnackBarAction(label: 'Tentar novamente', onPressed: retry),
      ));
  }

  Future<void> _start(Mission mission) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _missionService.startMission(mission.id);
      ProgressNotifier.instance.changed();
      _load();
      _showMessage('Missão iniciada! Boa jornada.');
    } catch (error) {
      _showMessage(friendlyError(error), error: true, retry: () => _start(mission));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _complete(Mission mission) async {
    if (_busy) return;

    // 1. Verifica se o usuário está autenticado.
    if (_authService.currentUser == null) {
      _showMessage('Sua sessão expirou. Entre novamente.', error: true);
      return;
    }

    setState(() => _busy = true);
    try {
      // 2-4. O banco valida, impede duplicidade e concede o XP oficial.
      final result = await _missionService.completeMission(mission.id);
      if (!mounted) return;

      if (result.alreadyCompleted) {
        _showMessage('Esta missão já foi concluída. Nenhum XP extra foi concedido.');
      } else {
        // 6. Confirmação visual.
        await showCelebrationDialog(context, result: result, missionTitle: mission.title);
      }

      // 5. Atualiza Home, Perfil, Conquistas, Ranking e esta tela.
      ProgressNotifier.instance.changed();
      _load();
    } catch (error) {
      _showMessage(friendlyError(error), error: true, retry: () => _complete(mission));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Detalhes da missão'),
          leading: IconButton(
            tooltip: 'Voltar',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _goBack,
          ),
        ),
        body: FutureContent<_DetailData>(
          future: _future,
          onRetry: _load,
          loadingMessage: 'Abrindo missão...',
          builder: (context, data) {
            final mission = data.mission;
            if (mission == null) {
              return EmptyView(
                icon: Icons.search_off_rounded,
                title: 'Missão não encontrada',
                message: 'Esta missão não existe ou não está mais disponível.',
                action: FilledButton(onPressed: _goBack, child: const Text('Voltar às missões')),
              );
            }
            return _DetailBody(
              mission: mission,
              data: data,
              busy: _busy,
              onStart: () => _start(mission),
              onComplete: () => _complete(mission),
            );
          },
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.mission,
    required this.data,
    required this.busy,
    required this.onStart,
    required this.onComplete,
  });

  final Mission mission;
  final _DetailData data;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final category = Categories.of(mission.category);
    final status = data.status;
    final userMission = data.userMission;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              // Cabeçalho.
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: category.color.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: category.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: category.color),
                            boxShadow: [BoxShadow(color: category.color.withValues(alpha: 0.4), blurRadius: 16)],
                          ),
                          child: Icon(category.icon, color: category.color, size: 34),
                        ),
                        const Spacer(),
                        InfoChip(label: status.label, icon: status.icon, color: status.color, filled: true),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(mission.title, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        InfoChip(label: category.label, icon: category.icon, color: category.color),
                        InfoChip(
                          label: 'Dificuldade: ${Difficulties.label(mission.difficulty)}',
                          icon: Icons.star_rounded,
                          color: AppColors.lilac,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Recompensa.
              Row(
                children: [
                  Expanded(
                    child: _RewardTile(
                      icon: Icons.bolt_rounded,
                      color: AppColors.lilac,
                      value: '+${mission.xpReward} XP',
                      label: 'Experiência',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RewardTile(
                      icon: Icons.paid_rounded,
                      color: AppColors.gold,
                      value: '+${mission.coinReward}',
                      label: 'Moedas',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const _SectionLabel('Descrição'),
              Text(mission.description, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 20),

              const _SectionLabel('Regras de conclusão'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RuleLine(icon: Icons.flag_rounded, text: mission.rules),
                    const SizedBox(height: 10),
                    const _RuleLine(
                      icon: Icons.verified_user_rounded,
                      text: 'A recompensa é concedida uma única vez por herói e validada pelo servidor.',
                    ),
                    const SizedBox(height: 10),
                    const _RuleLine(
                      icon: Icons.favorite_rounded,
                      text: 'Respeite seus limites. Descansar também faz parte da jornada.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const _SectionLabel('Status'),
              _StatusInfo(status: status, userMission: userMission),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _Actions(status: status, busy: busy, onStart: onStart, onComplete: onComplete),
          ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.status, required this.busy, required this.onStart, required this.onComplete});

  final MissionStatus status;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    if (status == MissionStatus.completed) {
      return const AppButton(label: 'Missão concluída', icon: Icons.check_circle_rounded, onPressed: null);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status == MissionStatus.available) ...[
          AppButton(
            label: 'Iniciar missão',
            icon: Icons.play_arrow_rounded,
            variant: AppButtonVariant.secondary,
            onPressed: busy ? null : onStart,
          ),
          const SizedBox(height: 10),
        ],
        AppButton(
          label: 'Concluir missão',
          icon: Icons.task_alt_rounded,
          loading: busy,
          onPressed: onComplete,
        ),
      ],
    );
  }
}

class _StatusInfo extends StatelessWidget {
  const _StatusInfo({required this.status, required this.userMission});

  final MissionStatus status;
  final UserMission? userMission;

  @override
  Widget build(BuildContext context) {
    final text = switch (status) {
      MissionStatus.completed =>
        'Concluída em ${formatDate(userMission!.completedAt!)}. '
            'Você recebeu ${userMission!.xpAwarded} XP e ${userMission!.coinsAwarded} moedas.',
      MissionStatus.inProgress =>
        'Em andamento desde ${formatDate(userMission!.startedAt)}. Quando terminar, toque em "Concluir missão".',
      MissionStatus.available => 'Missão disponível. Realize a atividade e depois marque como concluída.',
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(status.icon, color: status.color),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({required this.icon, required this.color, required this.value, required this.label});

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.lilac),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}
