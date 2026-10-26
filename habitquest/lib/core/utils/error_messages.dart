import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Converte exceções técnicas em mensagens amigáveis em português.
String friendlyError(Object error) {
  if (error is AuthRetryableFetchException) return _networkMessage;
  if (error is AuthException) return _authMessage(error);
  if (error is PostgrestException) return _databaseMessage(error);
  if (error is TimeoutException) {
    return 'A conexão demorou demais para responder. Tente novamente.';
  }
  if (_looksLikeNetworkError(error.toString())) return _networkMessage;
  return 'Algo deu errado. Tente novamente em instantes.';
}

const _networkMessage = 'Sem conexão com o servidor. Verifique sua internet e tente novamente.';

String _authMessage(AuthException error) {
  final code = error.code ?? '';
  final message = error.message.toLowerCase();

  if (code == 'invalid_credentials' || message.contains('invalid login credentials')) {
    return 'E-mail ou senha incorretos.';
  }
  if (code == 'email_not_confirmed' || message.contains('email not confirmed')) {
    return 'Confirme seu e-mail pelo link que enviamos antes de entrar.';
  }
  if (code == 'user_already_exists' || message.contains('already registered')) {
    return 'Já existe uma conta com este e-mail.';
  }
  if (code == 'weak_password' || message.contains('password should be')) {
    return 'A senha é muito fraca. Use pelo menos 6 caracteres.';
  }
  if (code == 'email_address_invalid' || message.contains('invalid format')) {
    return 'Informe um e-mail válido.';
  }
  if (error.statusCode == '429' || code.contains('rate_limit')) {
    return 'Muitas tentativas seguidas. Aguarde alguns minutos e tente de novo.';
  }
  if (code == 'session_not_found' || code == 'refresh_token_not_found') {
    return 'Sua sessão expirou. Entre novamente.';
  }
  if (_looksLikeNetworkError(message)) return _networkMessage;
  return 'Não foi possível concluir a autenticação. Tente novamente.';
}

String _databaseMessage(PostgrestException error) {
  final message = error.message;
  if (message.contains('MISSION_NOT_FOUND')) {
    return 'Missão não encontrada ou indisponível no momento.';
  }
  if (message.contains('NOT_AUTHENTICATED') || message.contains('PROFILE_NOT_FOUND')) {
    return 'Sua sessão expirou. Entre novamente.';
  }
  if (error.code == '42501' || message.toLowerCase().contains('permission denied')) {
    return 'Você não tem permissão para realizar esta ação.';
  }
  if (error.code == '23514') {
    return 'Algum dado informado é inválido. Confira os campos.';
  }
  if (error.code == 'PGRST202' || error.code == '42P01' || error.code == 'PGRST205') {
    return 'O banco de dados ainda não foi configurado. Execute o script supabase/schema.sql.';
  }
  if (_looksLikeNetworkError(message)) return _networkMessage;
  return 'Não foi possível acessar os dados agora. Tente novamente.';
}

bool _looksLikeNetworkError(String text) {
  final lower = text.toLowerCase();
  return lower.contains('socketexception') ||
      lower.contains('clientexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('failed to fetch') ||
      lower.contains('connection refused') ||
      lower.contains('connection closed') ||
      lower.contains('network is unreachable') ||
      lower.contains('xmlhttprequest');
}
