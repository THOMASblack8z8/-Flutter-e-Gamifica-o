import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/router/auth_notifier.dart';
import 'core/theme/app_theme.dart';

class HabitQuestApp extends StatefulWidget {
  const HabitQuestApp({super.key});

  @override
  State<HabitQuestApp> createState() => _HabitQuestAppState();
}

class _HabitQuestAppState extends State<HabitQuestApp> {
  late final GoRouter _router = createRouter(AuthNotifier.instance);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HabitQuest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}
