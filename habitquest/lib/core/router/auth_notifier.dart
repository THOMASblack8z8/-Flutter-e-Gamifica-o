import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Observa o estado de autenticação do Supabase e avisa o GoRouter
/// (via `refreshListenable`) sempre que o usuário entra ou sai.
class AuthNotifier extends ChangeNotifier {
  AuthNotifier._() {
    _session = _client.auth.currentSession;
    _subscription = _client.auth.onAuthStateChange.listen((data) {
      _session = data.session;
      notifyListeners();
    });
  }

  static final AuthNotifier instance = AuthNotifier._();

  SupabaseClient get _client => Supabase.instance.client;

  late final StreamSubscription<AuthState> _subscription;
  Session? _session;
  bool _startupDone = false;

  bool get isLoggedIn => _session != null;

  /// Enquanto `false`, o roteador mantém o usuário na Splash,
  /// evitando redirecionamentos antes de a sessão ser verificada.
  bool get startupDone => _startupDone;

  /// Chamado pela Splash: verifica a sessão salva e libera a navegação.
  Future<void> completeStartup({Duration minDuration = const Duration(milliseconds: 1500)}) async {
    if (_startupDone) return;
    final minimumWait = Future<void>.delayed(minDuration);

    final saved = _client.auth.currentSession;
    if (saved != null && saved.isExpired) {
      try {
        await _client.auth.refreshSession();
      } catch (_) {
        // Sem internet: mantém a sessão local. Se o token for inválido,
        // o próprio Supabase encerra a sessão e o listener acima avisa o app.
      }
    }

    await minimumWait;
    _session = _client.auth.currentSession;
    _startupDone = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
