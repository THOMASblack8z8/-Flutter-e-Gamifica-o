/// Validações dos formulários (executadas antes de enviar ao Supabase).
class Validators {
  Validators._();

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Informe seu e-mail.';
    if (!_emailRegex.hasMatch(text)) return 'Informe um e-mail válido.';
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Informe sua senha.';
    if (text.length < 6) return 'A senha deve ter pelo menos 6 caracteres.';
    return null;
  }

  static String? displayName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Informe um nome de exibição.';
    if (text.length < 2) return 'O nome deve ter pelo menos 2 caracteres.';
    if (text.length > 40) return 'O nome deve ter no máximo 40 caracteres.';
    return null;
  }

  static String? optionalUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http') || uri.host.isEmpty) {
      return 'Informe um link começando com https://';
    }
    if (text.length > 500) return 'O link é muito longo.';
    return null;
  }
}
