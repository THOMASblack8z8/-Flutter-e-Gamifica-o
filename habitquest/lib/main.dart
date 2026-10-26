import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'screens/config_error_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sem URL/chave configuradas, mostra instruções em vez de travar.
  if (!AppConfig.isConfigured) {
    runApp(const ConfigErrorApp());
    return;
  }

  try {
    // O cliente do Supabase é inicializado UMA única vez, aqui.
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
    );
  } catch (error) {
    runApp(ConfigErrorApp(details: error.toString()));
    return;
  }

  runApp(const HabitQuestApp());
}
