import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/error_messages.dart';

/// Mostra carregamento, erro (com "Tentar novamente") ou o conteúdo
/// de uma consulta ao Supabase. Ao recarregar, mantém os dados anteriores
/// na tela até a nova resposta chegar.
class FutureContent<T> extends StatelessWidget {
  const FutureContent({
    super.key,
    required this.future,
    required this.builder,
    required this.onRetry,
    this.loadingMessage = 'Carregando...',
  });

  final Future<T>? future;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback onRetry;
  final String loadingMessage;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError && snapshot.connectionState == ConnectionState.done) {
          return ErrorView(message: friendlyError(snapshot.error!), onRetry: onRetry);
        }
        if (!snapshot.hasData) return LoadingView(message: loadingMessage);
        return builder(context, snapshot.data as T);
      },
    );
  }
}

/// Estado de carregamento padrão.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = 'Carregando...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Estado de erro com botão "Tentar novamente".
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return _MessageView(
      icon: Icons.cloud_off_rounded,
      iconColor: AppColors.error,
      title: 'Ops! Algo deu errado',
      message: message,
      action: onRetry == null
          ? null
          : FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
    );
  }
}

/// Estado vazio (nenhum dado para mostrar).
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_rounded,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return _MessageView(icon: icon, iconColor: AppColors.lilac, title: title, message: message, action: action);
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
