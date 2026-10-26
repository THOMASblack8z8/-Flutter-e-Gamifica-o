import 'package:flutter/foundation.dart';

/// Avisa as telas que o progresso do usuário mudou (missão concluída,
/// perfil editado) para que recarreguem seus dados do Supabase.
///
/// Uso: telas chamam `ProgressNotifier.instance.addListener(_load)` e,
/// depois de uma alteração, alguém chama `ProgressNotifier.instance.changed()`.
class ProgressNotifier extends ChangeNotifier {
  ProgressNotifier._();

  static final ProgressNotifier instance = ProgressNotifier._();

  void changed() => notifyListeners();
}
