class Follower {
  final int telegramId;
  final int? followingDevId;
  Follower(this.telegramId, [this.followingDevId]);

  @override
  operator ==(final Object other) =>
      identical(this, other) ||
      other is Follower &&
          runtimeType == other.runtimeType &&
          followingDevId == other.followingDevId;

  @override
  get hashCode => followingDevId.hashCode;

  @override
  toString() => 'Follower{telegramId: $telegramId, followingDevId: $followingDevId}';
}