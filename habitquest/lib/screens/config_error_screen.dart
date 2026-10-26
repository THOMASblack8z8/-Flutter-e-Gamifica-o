import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_logo.dart';

/// App mínimo exibido quando a URL/chave do Supabase não foram configuradas.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key, this.details});

  final String? details;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HabitQuest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: AppLogo(size: 64)),
                      const SizedBox(height: 24),
                      const Text(
                        'Configuração do Supabase necessária',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '1. Copie env/supabase.example.json para env/supabase.json.\n'
                        '2. Preencha SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY com os dados do seu projeto '
                        '(Project Settings > API Keys). Use apenas a chave pública.\n'
                        '3. Execute: flutter run --dart-define-from-file=env/supabase.json',
                        style: TextStyle(color: AppColors.textSecondary, height: 1.6),
                      ),
                      if (details != null) ...[
                        const SizedBox(height: 16),
                        Text('Detalhes: $details', style: const TextStyle(color: AppColors.error)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
