import '/db/developer.dart';

class Follower {
  final int telegramId;
  final Developer? followingDev;

  Follower(this.telegramId, [this.followingDev]);
  Follower.byDevName(final int telegramId, final String followingDevName) :
        this(telegramId, Developer(followingDevName));

  @override
  operator ==(final Object other) =>
      identical(this, other) ||
      other is Follower &&
          runtimeType == other.runtimeType &&
          telegramId == other.telegramId &&
          followingDev == other.followingDev;

  @override
  get hashCode => Object.hashAll([telegramId, followingDev]);

  @override
  toString() => 'Follower{telegramId: $telegramId, followingDev: $followingDev}';
}