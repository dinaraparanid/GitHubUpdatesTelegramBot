import 'dart:async';
import 'dart:isolate';

import 'package:github/github.dart';
import 'package:teledart/model.dart';
import 'package:teledart/teledart.dart';

import '/db/developer.dart';
import '/db/follower.dart';
import '/db/followers_dao.dart';
import '/github/git_hub_fetcher.dart';
import '/utils/extensions/all_ext.dart';
import '/utils/extensions/isolate_ext.dart';
import '/utils/extensions/iterable_ext.dart';
import '/utils/extensions/stream_ext.dart';
import '/utils/extensions/string_ext.dart';
import '/utils/pair.dart';

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
          await projects.foldAsync(
            '',
            (final String previous, pair) async =>
              '$previous${await pair.first}${pair.second != projects.length - 1 ? '----------------------------------------' : ''}\n'
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

  Future<void> launchFollowing() async {
    final fiveMinutes = Duration(minutes: 5);

    int follower = 0;
    var releasesInfo = '';

    final port = ReceivePort().also((port) => port.listen((message) {
      final releases = message as List<Pair<int, String>>;

      for (final pair in releases) {
        follower = pair.first;
        releasesInfo = pair.second;

        releasesInfo.borderedByTelegramLen
            .takeIf((it) => it.isNotEmpty)
            ?.let((it) => sendMessage(follower, it, disable_web_page_preview: true));
      }
    }));

    while (true) {
      await IsolateExt.runOnBackgroundAsync<List<Pair<int, String>>>(port, _getNewReleases);
      await Future.delayed(fiveMinutes);
    }
  }
}

Future<void> _getNewReleases(final SendPort port) async {
  final result = <Pair<int, String>>[];

  final followersWithDevs = (await FollowersDao.instance).getFollowersWithDevs().entries;

  for (final entry in followersWithDevs) {
    final follower = entry.key;
    final devs = entry.value;

    final releases = await devs.foldAsync(
        <Release>[],
        (final List<Release> prev, dev) async =>
          prev..addAll(await GitHubFetcher.instance.checkForDevUpdates(dev))
    );

    final responses = await releases.mapAsync((release) async => '''New release: ${release.htmlUrl?.removeFirst('https://github.com/').split('/')[1] ?? ''} ${release.name ?? 'Unknown release'}
${release.htmlUrl ?? release.url ?? release.uploadUrl ?? 'No url'}
Created at: ${release.publishedAt ?? 'Unknown'}
Is prerelease: ${release.isPrerelease ?? 'Unknown'}
Description: ${release.description ?? 'No description provided...'}
''');

    final enumerated = responses.enumerate();

    final followerWithReleases = Pair(
      follower,
      await enumerated.foldAsync(
        '',
        (final String previous, pair) async =>
          '$previous${pair.first}${pair.second != enumerated.length - 1 ? '----------------------------------------\n' : ''}'
      )
    );

    result.add(followerWithReleases);
  }

  port.send(result);
}