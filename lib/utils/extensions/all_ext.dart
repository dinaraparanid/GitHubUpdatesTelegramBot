extension HighOrderFunctions<T, R> on T {
  R let(final R Function(T it) func) => func(this);

  T also(final R Function(T it) func) {
    func(this);
    return this;
  }

  T? takeIf(final bool Function(T it) func) => func(this) ? this : null;
}