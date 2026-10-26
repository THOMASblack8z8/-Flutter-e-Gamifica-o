import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

/// Leitura e edição do perfil do usuário autenticado.
class ProfileService {
  ProfileService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Sessão expirada', code: 'session_not_found');
    return user.id;
  }

  Future<Profile> getMyProfile() async {
    final data = await _client.from('profiles').select().eq('id', _userId).single();
    return Profile.fromMap(data);
  }

  /// Atualiza apenas os campos permitidos pelo banco
  /// (display_name, hero_class e avatar_url). XP, nível e moedas
  /// não podem ser alterados pelo aplicativo.
  Future<Profile> updateProfile({
    required String displayName,
    required String heroClass,
    String? avatarUrl,
  }) async {
    final cleanUrl = avatarUrl?.trim();
    final data = await _client
        .from('profiles')
        .update({
          'display_name': displayName.trim(),
          'hero_class': heroClass,
          'avatar_url': (cleanUrl == null || cleanUrl.isEmpty) ? null : cleanUrl,
        })
        .eq('id', _userId)
        .select()
        .single();
    return Profile.fromMap(data);
  }
}
