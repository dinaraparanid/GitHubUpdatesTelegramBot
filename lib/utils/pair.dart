class Pair<F, S> {
  F first;
  S second;
  Pair(this.first, this.second);

  @override
  operator ==(final Object other) =>
      identical(this, other) ||
      other is Pair &&
          runtimeType == other.runtimeType &&
          first == other.first &&
          second == other.second;

  @override
  get hashCode => Object.hashAll([first, second]);

  @override
  toString() => 'Pair{first: $first second: $second}';
}