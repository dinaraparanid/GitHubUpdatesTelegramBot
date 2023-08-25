import 'dart:math' as math;

import '/utils/extensions/iterable_ext.dart';

extension NumStreamExt<T extends num> on Stream<T> {
  Future get max => reduce(math.max);
  Future get min => reduce(math.min);

  Future? get maxOrNull async => await isEmpty ? null : reduce(math.max);
  Future? get minOrNull async => await isEmpty ? null : reduce(math.min);
}

extension StreamExt<T> on Stream<T> {
  Future<List<(T, S)>> zip<S>(final Iterable<S> stream) async {
    final firstList = await toList();
    final secondList = stream.toList();

    return List.generate(math.min(firstList.length, secondList.length), (index) =>
      (firstList[index], secondList[index])
    );
  }

  Future<List<(T, S)>> zipWithStream<S>(final Stream<S> stream) async {
    final firstList = await toList();
    final secondList = await stream.toList();

    return List.generate(math.min(firstList.length, secondList.length), (index) =>
      (firstList[index], secondList[index])
    );
  }

  Future<List<(T, int)>> enumerate() async {
    final list = await toList();
    return list.zip(Iterable.generate(list.length, (ind) => ind));
  }

  Future<List<T>> whereAsync(Future<bool> Function(T) test) async =>
      await (await toList()).whereAsync(test);

  Future<R> foldAsync<R>(R initialValue, Future<R> Function(R previous, T element) combine) async =>
      await (await toList()).foldAsync(initialValue, combine);

  Future<List<R>> mapAsync<R>(Future<R> Function(T element) toElement) async =>
      await (await toList()).mapAsync(toElement);
}

extension ZippedIterExt<F, S> on Stream<(F, S)> {
  Future<(List<F>, List<S>)> unzip() async {
    final len = await length;
    final List<F?> firstList = List.filled(len, null);
    final List<S?> secondList = List.filled(len, null);

    await forEach((pair) {
      final (f, s) = pair;
      firstList.add(f);
      secondList.add(s);
    });

    return (firstList.cast<F>(), secondList.cast<S>());
  }
}