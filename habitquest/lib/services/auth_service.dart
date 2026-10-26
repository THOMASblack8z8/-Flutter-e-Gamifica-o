import 'package:supabase_flutter/supabase_flutter.dart';

/// Cadastro, login e logout com o Supabase Auth.
/// As senhas nunca são salvas em tabelas próprias.
class AuthService {
  AuthService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email.trim(), password: password);
  }

  /// Cria a conta. O nome vai nos metadados e o gatilho `handle_new_user`
  /// do banco cria o perfil automaticamente.
  ///
  /// Retorna `true` quando o Supabase exige confirmação do e-mail
  /// (o usuário foi criado, mas ainda não há sessão ativa).
  Future<bool> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': displayName.trim()},
    );
    return response.session == null;
  }

  Future<void> signOut() => _client.auth.signOut();
}
