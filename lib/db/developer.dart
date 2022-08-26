class Developer {
  final int id;
  Developer(this.id);

  @override
  operator ==(final Object other) =>
      identical(this, other) ||
      other is Developer && runtimeType == other.runtimeType && id == other.id;

  @override
  get hashCode => id.hashCode;

  @override
  toString() => 'Developer{id: $id}';
}