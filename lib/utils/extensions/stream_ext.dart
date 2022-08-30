import 'dart:math' as math;

import '/utils/extensions/iterable_ext.dart';
import '../pair.dart';

extension NumStreamExt<T extends num> on Stream<T> {
  Future get max => reduce(math.max);
  Future get min => reduce(math.min);

  Future? get maxOrNull async => await isEmpty ? null : reduce(math.max);
  Future? get minOrNull async => await isEmpty ? null : reduce(math.min);
}

extension StreamExt<T> on Stream<T> {
  Future<List<Pair<T, S>>> zip<S>(final Iterable<S> stream) async {
    final firstList = await toList();
    final secondList = stream.toList();

    return List.generate(math.min(firstList.length, secondList.length), (index) =>
      Pair(firstList[index], secondList[index])
    );
  }

  Future<List<Pair<T, S>>> zipWithStream<S>(final Stream<S> stream) async {
    final firstList = await toList();
    final secondList = await stream.toList();

    return List.generate(math.min(firstList.length, secondList.length), (index) =>
      Pair(firstList[index], secondList[index])
    );
  }

  Future<List<Pair<T, int>>> enumerate() async {
    final list = await toList();
    return list.zip(Iterable.generate(list.length, (ind) => ind));
  }

  Future<List<T>> whereAsync(Future<bool> Function(T) test) async =>
      await (await toList()).whereAsync(test);
}

extension ZippedIterExt<F, S> on Stream<Pair<F, S>> {
  Future<Pair<List<F>, List<S>>> unzip() async {
    final len = await length;
    final List<F?> firstList = List.filled(len, null);
    final List<S?> secondList = List.filled(len, null);

    await forEach((pair) {
      firstList.add(pair.first);
      secondList.add(pair.second);
    });

    return Pair(firstList.cast(), secondList.cast());
  }
}