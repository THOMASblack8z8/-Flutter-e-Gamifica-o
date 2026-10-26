import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../widgets/app_background.dart';
import '../widgets/state_views.dart';

/// Exibida quando o endereço acessado não existe.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: EmptyView(
          icon: Icons.explore_off_rounded,
          title: 'Caminho não encontrado',
          message: 'Esta página não existe no mapa do HabitQuest.',
          action: FilledButton.icon(
            onPressed: () => context.go(AppRoutes.home),
            icon: const Icon(Icons.home_rounded),
            label: const Text('Voltar ao início'),
          ),
        ),
      ),
    );
  }
}
