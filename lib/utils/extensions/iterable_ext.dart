import 'dart:math' as math;

extension NumIterExt<T extends num> on Iterable<T> {
  T get max => reduce(math.max);
  T get min => reduce(math.min);

  T? get maxOrNull => isEmpty ? null : reduce(math.max);
  T? get minOrNull => isEmpty ? null : reduce(math.min);
}

extension IterExt<T> on Iterable<T> {
  List<(T, S)> zip<S>(final Iterable<S> iterable) {
    final firstIter = iterator;
    final secondIter = iterable.iterator;

    return List.generate(math.min(length, iterable.length), (index) {
      firstIter.moveNext();
      secondIter.moveNext();
      return (firstIter.current, secondIter.current);
    });
  }

  List<(T, int)> enumerate() => zip(Iterable.generate(length, (ind) => ind));

  Future<List<T>> whereAsync(Future<bool> Function(T element) test) async {
    final result = <T>[];

    for (final elem in this) {
      if (await test(elem)) {
        result.add(elem);
      }
    }

    return result;
  }

  Future<R> foldAsync<R>(R initialValue, Future<R> Function(R previous, T element) combine) async {
    var result = initialValue;

    for (final elem in this) {
      result = await combine(result, elem);
    }

    return result;
  }

  Future<List<R>> mapAsync<R>(Future<R> Function(T element) toElement) async {
    var result = <R>[];

    for (final elem in this) {
      result.add(await toElement(elem));
    }

    return result;
  }
}

extension ZippedIterExt<F, S> on Iterable<(F, S)> {
  (List<F>, List<S>) unzip() {
    final List<F?> firstList = List.filled(length, null);
    final List<S?> secondList = List.filled(length, null);

    forEach((pair) {
      final (f, s) = pair;
      firstList.add(f);
      secondList.add(s);
    });

    return (firstList.cast(), secondList.cast());
  }
}