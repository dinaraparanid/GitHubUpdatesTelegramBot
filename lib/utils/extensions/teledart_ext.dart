import 'dart:isolate';

import 'package:dartz/dartz.dart';
import 'package:git_hub_update_telegram_bot/utils/extensions/stream_ext.dart';
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
import '/utils/extensions/string_ext.dart';
import '/utils/extensions/teledart_msg_ext.dart';

extension TeleDartExt on TeleDart {
  Future<void> login(final TeleDartMessage message) async {
    (await FollowersDao.instance)
        .addNewUserOrIgnore(Follower(message.from!.id));

    message.reply(
        message.from!.let((user) =>
          'Hello, ${user.first_name} ${user.last_name ?? ''}'
        )
    );

    await Future.delayed(Duration(seconds: 1));
    message.sendHelp();
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

    final projectsOrErr = await GitHubFetcher.instance.getDevProjects(devUrl);

    switch (projectsOrErr) {
      case Right(value: NotFound(message: final String msg)):
        message.reply(msg);
        return false;

      case Left(value: final reps):
        final projects = await reps
            .map((repository) async =>
              '''
              Title: ${repository.name}
              Url: ${repository.htmlUrl}
              Description: ${repository.description.takeIfNotEmptyOrNone()}
              '''.trimmedIndent
            )
            .asBroadcastStream()
            .enumerate();

        await projects
            .foldAsync(
              '', (final String previous, pair) async {
                final (f, s) = pair;
                return '$previous${await f}${s != projects.length - 1 ? '----------------------------------------' : ''}\n';
              }
            )
            .then((response) => message.reply(
              response.length > 4096 ? '${response.substring(0, 4096 - 3)}...' : response,
              disable_web_page_preview: true,
            ));

        return true;
    }

    return false;
  }

  Future<bool> showProjectInfo(final TeleDartMessage message) async {
    final projectUrl = message.text!.removeFirst('/project_info').trim();

    if (projectUrl.isEmpty) {
      message.reply(
          'Incorrect input. Please, use this pattern: /project_info https://github.com/dinaraparanid/GitHubUpdatesTelegramBot'
      );

      return false;
    }

    final repositoryOrErr = await GitHubFetcher.instance.getProject(projectUrl);

    switch (repositoryOrErr) {
      case Right(value: GitHubError(message: final String msg)):
        message.reply(msg);
        return false;

      case Left(value: final repository):
        final response = '''
        Title: ${repository.name}
        Url: ${repository.htmlUrl}
        Description: ${repository.description.takeIfNotEmptyOrNone()}
        Homepage: ${repository.homepage.takeIfNotEmptyOrNone()}
        License: ${repository.license?.name ?? 'None'}
        Contributors: ${
            await GitHubFetcher
                .instance
                .getProjectContributors(repository.slug())
                .map((contributor) => '${contributor.login ?? 'Unknown contributor'} ${contributor.htmlUrl ?? ''}')
                .join('\n')
        }
        Last update: ${repository.updatedAt ?? 'Unknown'}
        Stars: ${repository.stargazersCount}
        Last release: ${(await GitHubFetcher.instance.getLastRelease(repository.slug()))?.htmlUrl ?? 'None'}
        '''.trimmedIndent;

        message.reply(response, disable_web_page_preview: true);
        return true;
    }

    return false;
  }

  Future<void> launchFollowing() async {
    final fiveMinutes = Duration(minutes: 5);

    final port = ReceivePort().also((port) => port.listen((message) {
      final releases = message as List<(int, String)>;

      for (final (follower, releasesInfo) in releases) {
        releasesInfo.borderedByTelegramLen
            .takeIf((it) => it.isNotEmpty)
            ?.let((it) => sendMessage(follower, it, disable_web_page_preview: true));
      }
    }));

    while (true) {
      await IsolateExt.runOnBackgroundAsync<List<(int, String)>>(port, _getNewReleases);
      await Future.delayed(fiveMinutes);
    }
  }
}

Future<void> _getNewReleases(final SendPort port) async {
  final result = <(int, String)>[];
  final followersWithDevs = (await FollowersDao.instance).getFollowersWithDevs().entries;

  for (final entry in followersWithDevs) {
    final follower = entry.key;
    final devs = entry.value;

    final releases = await devs.foldAsync(
        <Release>[],
        (final List<Release> prev, dev) async =>
          prev..addAll(await GitHubFetcher.instance.checkForDevUpdates(devName: dev.name))
    );

    final responses = await releases.mapAsync((release) async =>
      '''
      New release: ${release.htmlUrl?.removeFirst('https://github.com/').split('/')[1] ?? ''} ${release.name ?? 'Unknown release'}
      ${release.htmlUrl ?? release.url ?? release.uploadUrl ?? 'No url'}
      Created at: ${release.publishedAt ?? 'Unknown'}
      Is pre-release: ${release.isPrerelease ?? 'Unknown'}
      Description: ${release.description ?? 'No description provided...'}
      '''.trimmedIndent
    );

    final enumerated = responses.enumerate();

    final releasesMsg = await enumerated.foldAsync(
        '', (final String previous, pair) async {
          final (f, s) = pair;
          return '$previous$f${s != enumerated.length - 1 ? '----------------------------------------\n' : ''}';
        }
    );

    result.add((follower, releasesMsg));
  }

  port.send(result);
}