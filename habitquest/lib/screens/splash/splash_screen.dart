import 'package:flutter/material.dart';

import '../../core/router/auth_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_logo.dart';

/// Tela inicial: mostra a marca enquanto a sessão é verificada.
/// Quando a verificação termina, o GoRouter redireciona para Login ou Home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    AuthNotifier.instance.completeStartup();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) => Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: Transform.scale(scale: 0.7 + 0.3 * value, child: child),
                  ),
                  child: const AppLogo(size: 110),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sua rotina se transforma em uma jornada de evolução.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Preparando sua jornada...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
