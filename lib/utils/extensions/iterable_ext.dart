import 'dart:math' as math;

import '../pair.dart';

extension NumIterExt<T extends num> on Iterable<T> {
  T get max => reduce(math.max);
  T get min => reduce(math.min);

  T? get maxOrNull => isEmpty ? null : reduce(math.max);
  T? get minOrNull => isEmpty ? null : reduce(math.min);
}

extension IterExt<T> on Iterable<T> {
  List<Pair<T, S>> zip<S>(final Iterable<S> iterable) {
    final firstIter = iterator;
    final secondIter = iterable.iterator;

    return List.generate(math.min(length, iterable.length), (index) {
      firstIter.moveNext();
      secondIter.moveNext();
      return Pair(firstIter.current, secondIter.current);
    });
  }

  List<Pair<T, int>> enumerate() => zip(Iterable.generate(length, (ind) => ind));

  Future<List<T>> whereAsync(Future<bool> Function(T element) test) async {
    final result = <T>[];
    final list = toList(growable: false);

    for (final elem in list) {
      if (await test(elem)) {
        result.add(elem);
      }
    }

    return result;
  }
}

extension ZippedIterExt<F, S> on Iterable<Pair<F, S>> {
  Pair<List<F>, List<S>> unzip() {
    final List<F?> firstList = List.filled(length, null);
    final List<S?> secondList = List.filled(length, null);

    forEach((pair) {
      firstList.add(pair.first);
      secondList.add(pair.second);
    });

    return Pair(firstList.cast(), secondList.cast());
  }
}