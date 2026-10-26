/// Configuração externa do Supabase.
///
/// Os valores NÃO ficam no código: são passados na execução com
///   flutter run --dart-define-from-file=env/supabase.json
///
/// Use apenas a URL do projeto e a chave PÚBLICA (publishable `sb_publishable_...`
/// ou a chave legada `anon`). Nunca coloque a chave secreta `service_role`
/// no aplicativo.
class AppConfig {
  AppConfig._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Falso quando o app foi executado sem o arquivo de configuração
  /// ou ainda com os placeholders do arquivo de exemplo.
  static bool get isConfigured =>
      supabaseUrl.startsWith('https://') &&
      supabasePublishableKey.isNotEmpty &&
      !supabaseUrl.contains('SEU-PROJETO') &&
      !supabasePublishableKey.contains('SUA-CHAVE');
}
