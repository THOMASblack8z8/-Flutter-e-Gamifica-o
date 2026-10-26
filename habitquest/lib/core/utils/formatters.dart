/// Formata uma data no padrão brasileiro (dd/mm/aaaa), no fuso local.
String formatDate(DateTime date) {
  final local = date.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year}';
}

/// Verifica se uma data (em qualquer fuso) cai no dia de hoje, no fuso local.
bool isToday(DateTime date) {
  final local = date.toLocal();
  final now = DateTime.now();
  return local.year == now.year && local.month == now.month && local.day == now.day;
}
