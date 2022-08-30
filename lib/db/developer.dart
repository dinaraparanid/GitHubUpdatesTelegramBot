class Developer {
  final String name;
  Developer(this.name);

  @override
  operator ==(final Object other) =>
      identical(this, other) ||
      other is Developer && runtimeType == other.runtimeType && name == other.name;

  @override
  get hashCode => name.hashCode;

  @override
  toString() => 'Developer{name: $name}';
}