import 'dart:math' as math;

extension NumIterExt<T extends num> on Iterable<T> {
  T get max => reduce(math.max);
  T get min => reduce(math.min);

  T? get maxOrNull => isEmpty ? null : reduce(math.max);
  T? get minOrNull => isEmpty ? null : reduce(math.min);
}