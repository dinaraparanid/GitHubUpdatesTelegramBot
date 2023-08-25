extension StringExt on String {
  String removeAll(final Pattern pattern) => replaceAll(pattern, '');
  String removeFirst(final Pattern pattern) => replaceFirst(pattern, '');
  String takeIfNotEmptyOrNone() => isEmpty ? 'None' : this;
  String get borderedByTelegramLen => length > 4096 ? '${substring(0, 4096 - 3)}...' : this;

  String get trimmedIndent => splitMapJoin(
    RegExp(r'^', multiLine: true),
    onMatch: (_) => '\n',
    onNonMatch: (n) => n.trim(),
  );
}