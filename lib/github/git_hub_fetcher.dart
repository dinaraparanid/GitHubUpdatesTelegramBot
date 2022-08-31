import 'package:github/github.dart';

import '/constants.dart';
import '/db/developer.dart';
import '/utils/extensions/iterable_ext.dart';
import '/utils/extensions/stream_ext.dart';
import '/utils/extensions/string_ext.dart';

class GitHubFetcher {
  GitHubFetcher._();

  static final _instance = GitHubFetcher._();
  static GitHubFetcher get instance => _instance;

  final _github = GitHub(auth: Authentication.withToken(githubBotsToken));

  String getDevName(final String url) => url.removeFirst('https://github.com/');

  Stream<Repository> getDevProjects(final String url) {
    final name = url.removeFirst('https://github.com/');
    return _github.repositories.listUserRepositories(name);
  }

  Future<Repository> getProject(final String url) {
    final data = url.removeFirst('https://github.com/').split('/');
    final owner = data.first;
    final name = data.last;
    return _github.repositories.getRepository(RepositorySlug(owner, name));
  }

  Future<List<Release>> checkForDevUpdates(final Developer developer) async {
    final now = DateTime.now();
    final tenMinutes = Duration(minutes: 10);

    return (await (await (_github.repositories.listUserRepositories(developer.name))
        .map((repository) async => await _github.repositories.listReleases(repository.slug()).toList())
        .whereAsync((releases) async => (await releases).isNotEmpty))
        .foldAsync(<Release>[], (final List<Release> previous, element) async => previous..addAll(await element)))
        .where((release) => (release.publishedAt?.difference(now).abs() ?? tenMinutes) < tenMinutes)
        .toList(growable: false);
  }

  Stream<Contributor> getProjectContributors(final RepositorySlug slug) =>
      _github.repositories.listContributors(slug);
}