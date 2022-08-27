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
        .addNewUser(Follower(message.from!.id));
  }

  Future<Follower?> startFollowing(final TeleDartMessage message) async {
    final devUrl = message.text!.removeFirst('/follow').trim();

    if (devUrl.isEmpty) {
      message.reply(
          'Incorrect input. Please, use this pattern: /follow https://github.com/dinaraparanid'
      );

      return null;
    }

    final devId = await GitHubFetcher.instance.getDevId(devUrl);

    if (devId == null) {
      message.reply("Developer is not found. Please, try again...");
      return null;
    }

    final followerId = message.from!.id;
    final follower =  (await FollowersDao.instance)
        .startFollowing(followerId, Developer(devId));

    message.reply('Success!');
    return follower;
  }
}