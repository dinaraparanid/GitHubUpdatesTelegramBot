extension MapExt<K, V> on Map<K, V> {
  Map<K, V> addIf(final K key, final V value, { required bool Function() test }) {
    if (test()) {
      update(key, (v) => value, ifAbsent: () => value);
    }

    return this;
  }
}

extension MapStringKeyExt<V> on Map<String, V> {
  Map<String, String> get requestMap =>
      map((key, value) => MapEntry(key, value.toString()));
}