extension StringExt on String {
  String removeAll(final Pattern pattern) => replaceAll(pattern, '');
  String removeFirst(final Pattern pattern) => replaceFirst(pattern, '');
}