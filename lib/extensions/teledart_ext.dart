import 'package:teledart/model.dart';
import 'package:teledart/teledart.dart';

import '/db/developer.dart';
import '/db/follower.dart';
import '/db/followers_dao.dart';
import '/extensions/all_ext.dart';
import '/extensions/string_ext.dart';
import '/github/git_hub_fetcher.dart';

extension TeleDartExt on TeleDart {
  Future<void> login(final TeleDartMessage message) async {
    message.reply(
        message.from!.let((user) =>
          'Hello, ${user.first_name} ${user.last_name ?? ''}'
        )
    );

    (await FollowersDao.instance)
        .addNewUserOrIgnore(Follower(message.from!.id));
  }

  Future<int?> _getDevIdOrSendError(
      final TeleDartMessage message,
      {
        required final String command,
        required final String patter
      }
  ) async {
    final devUrl = message.text!.removeFirst('/$command').trim();

    if (devUrl.isEmpty) {
      message.reply(
          'Incorrect input. Please, use this pattern: $patter'
      );

      return null;
    }

    final devId = await GitHubFetcher.instance.getDevId(devUrl);

    if (devId == null) {
      message.reply("Developer is not found. Please, try again...");
    }

    return devId;
  }

  Future<Follower?> startFollowing(final TeleDartMessage message) async {
    final devId = await _getDevIdOrSendError(
        message,
        command: 'follow',
        patter: '/follow https://github.com/dinaraparanid'
    );

    if (devId == null) {
      return null;
    }

    final followerId = message.from!.id;
    final follower = (await FollowersDao.instance)
        .startFollowing(followerId, Developer(devId));

    message.reply(follower == null ? 'You are already following this dev' : 'Success!');
    return follower;
  }

  Future<Follower?> unfollow(final TeleDartMessage message) async {
    final devId = await _getDevIdOrSendError(
        message,
        command: 'unfollow',
        patter: '/unfollow https://github.com/dinaraparanid'
    );

    if (devId == null) {
      return null;
    }

    final followerId = message.from!.id;
    final oldFollower = Follower(followerId, devId);
    final follower = (await FollowersDao.instance).unfollow(oldFollower);

    message.reply(follower == null ? 'You are not following this dev' : 'Stopped following');
    return follower;
  }
}