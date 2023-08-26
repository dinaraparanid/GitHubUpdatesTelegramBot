import 'package:dartz/dartz.dart';
import 'package:git_hub_update_telegram_bot/utils/extensions/all_ext.dart';
import 'package:github/github.dart';

import '/constants.dart';
import '/utils/extensions/iterable_ext.dart';
import '/utils/extensions/stream_ext.dart';
import '/utils/extensions/string_ext.dart';

final class GitHubFetcher {
  GitHubFetcher._();

  static final _instance = GitHubFetcher._();
  static GitHubFetcher get instance => _instance;

  final _github = GitHub(auth: Authentication.withToken(githubBotsToken));

  String getDevName(final String url) => url.removeFirst('https://github.com/');

  Future<bool> isDevExists(final String developerName) {
    return _github.users.isUser(developerName);
  }

  NotFound get _developerNotFoundError =>
      NotFound(_github, "Developer is not found");

  NotFound _repositoryNotFoundError(final String repo) =>
    NotFound(_github, 'Repository `$repo` is not found');

  NotFound _noRepositoriesError(final String devName) =>
      NotFound(_github, 'Developer `$devName` does not have any repositories');

  Future<Either<Stream<Repository>, GitHubError>> getDevProjects(final String url) async {
    final name = getDevName(url);

    if (!await isDevExists(name)) {
      return Right(_developerNotFoundError);
    }

    try {
      final reps = _github.repositories.listUserRepositories(name);
      return Left(reps);
    } on Exception {
      return Right(_noRepositoriesError(name));
    }
  }

  Future<Either<Repository, GitHubError>> getProject(final String url) async {
    final data = url.removeFirst('https://github.com/').split('/');
    final owner = data.first;
    final repo = data.last;

    if (!await isDevExists(owner)) {
      return Right(_developerNotFoundError);
    }

    try {
      return Left(
          await _github
              .repositories
              .getRepository(RepositorySlug(owner, repo)
          )
      );
    } on GitHubError {
      return Right(_repositoryNotFoundError(repo));
    }
  }

  Future<List<Release>> checkForDevUpdates({required final String devName}) async {
    final now = DateTime.now();
    final tenMinutes = Duration(minutes: 10);
    
    print(devName);

    return (await (await (_github.repositories.listUserRepositories(devName))
        .map((repository) async => await _github.repositories.listReleases(repository.slug()).toList())
        .whereAsync((releases) async => (await releases).isNotEmpty))
        .foldAsync(<Release>[], (final List<Release> previous, element) async => previous..addAll(await element)))
        .where((release) => (release.publishedAt?.difference(now).abs() ?? tenMinutes) < tenMinutes)
        .toList(growable: false);
  }

  Stream<Contributor> getProjectContributors(final RepositorySlug slug) =>
      _github.repositories.listContributors(slug);

  Future<Release?> getLastRelease(final RepositorySlug slug) async {
    final nullTime = DateTime.fromMicrosecondsSinceEpoch(0);

    return (await _github.repositories.listReleases(slug).toList())
        .takeIf((it) => it.isNotEmpty)
        ?.also((it) => it.sort((r1, r2) => r1.publishedAt?.compareTo(r2.publishedAt ?? nullTime) ?? 0))
        .last;
  }
}