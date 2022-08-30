import 'package:github/github.dart';
import 'package:teledart/model.dart';
import 'package:teledart/teledart.dart';

import '/db/developer.dart';
import '/db/follower.dart';
import '/db/followers_dao.dart';
import '/github/git_hub_fetcher.dart';
import '/utils/extensions/all_ext.dart';
import '/utils/extensions/isolate_ext.dart';
import '/utils/extensions/stream_ext.dart';
import '/utils/extensions/string_ext.dart';

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

  String? _getDevUrlOrSendError(
      final TeleDartMessage message,
      { required final String command }
  ) {
    final devUrl = message.text!.removeFirst('/$command').trim();

    if (devUrl.isEmpty) {
      message.reply(
          'Incorrect input. Please, use this pattern: /$command https://github.com/dinaraparanid'
      );

      return null;
    }

    return devUrl;
  }

  Future<String?> _getDevNameOrSendError(
      final TeleDartMessage message,
      { required final String command }
  ) async {
    final devUrl = _getDevUrlOrSendError(message, command: command);

    if (devUrl == null) {
      return null;
    }

    return GitHubFetcher.instance.getDevName(devUrl);
  }

  Future<Follower?> startFollowing(final TeleDartMessage message) async {
    final devName = await _getDevNameOrSendError(message, command: 'follow');

    if (devName == null) {
      return null;
    }

    final followerId = message.from!.id;
    final follower = (await FollowersDao.instance)
        .startFollowing(followerId, Developer(devName));

    message.reply(follower == null ? 'You are already following this dev' : 'Success!');
    return follower;
  }

  Future<Follower?> unfollow(final TeleDartMessage message) async {
    final devName = await _getDevNameOrSendError(message, command: 'unfollow');

    if (devName == null) {
      return null;
    }

    final followerId = message.from!.id;
    final oldFollower = Follower(followerId, Developer(devName));
    final follower = (await FollowersDao.instance).unfollow(oldFollower);

    message.reply(follower == null ? 'You are not following this dev' : 'Stopped following');
    return follower;
  }

  Future<bool> showProjects(final TeleDartMessage message) async {
    final devUrl = _getDevUrlOrSendError(message, command: 'projects');

    if (devUrl == null) {
      return false;
    }

    await (await GitHubFetcher
        .instance
        .getDevProjects(devUrl)
        .map((repository) async =>
    '''Title: ${repository.name}
Url: ${repository.htmlUrl}
Description: ${repository.description.takeIfNotEmptyOrNone()}
'''
        )
        .asBroadcastStream()
        .enumerate())
        .let((projects) async {
          await projects.fold(
            Future(() => ''),
            (final Future<String> previous, element) async {
              final pair = element;
              return '${await previous}${await pair.first}${pair.second != projects.length - 1 ? '----------------------------------------' : ''}\n';
            }
          ).then((response) => message.reply(
              response.length > 4096 ? '${response.substring(0, 4096 - 3)}...' : response,
              disable_web_page_preview: true,
          ));
        });

    return true;
  }

  Future<bool> showProjectInfo(final TeleDartMessage message) async {
    final projectUrl = message.text!.removeFirst('/project_info').trim();

    if (projectUrl.isEmpty) {
      message.reply(
          'Incorrect input. Please, use this pattern: /project_info https://github.com/dinaraparanid/GitHubUpdatesTelegramBot'
      );

      return false;
    }

    final repository = await GitHubFetcher.instance.getProject(projectUrl);

    final response = '''Title: ${repository.name}
Url: ${repository.htmlUrl}
Description: ${repository.description.takeIfNotEmptyOrNone()}
Homepage: ${repository.homepage.takeIfNotEmptyOrNone()}
License: ${repository.license?.name ?? 'None'}
Contributors: 
  ${
        await GitHubFetcher
            .instance
            .getProjectContributors(repository.slug())
            .map((contributor) => '${contributor.login ?? 'Unknown contributor'} ${contributor.htmlUrl ?? ''}')
            .join('\n')
    }
Last update: ${repository.updatedAt ?? 'Unknown'}
Stars: ${repository.stargazersCount}
Is private: ${repository.isPrivate}
''';
    
    message.reply(response, disable_web_page_preview: true);
    return true;
  }

  Future<void> launchFollowing() async =>
    IsolateExt.runOnBackground((sendPort) async {
      (await FollowersDao.instance)
          .getFollowersWithDevs()
          .forEach((follower, devs) {
            devs.fold(
                Future(() => List<Future<Release>>.empty()),
                (final Future<List<Future<Release>>> prev, dev) async =>
                (await prev)..addAll(await GitHubFetcher.instance.checkForDevUpdates(dev))
            );

            // TODO
          })                                                         ;
    });
}