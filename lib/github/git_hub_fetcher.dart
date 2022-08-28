import 'package:git_hub_update_telegram_bot/constants.dart';
import 'package:github/github.dart';
import '/utils/extensions/string_ext.dart';

class GitHubFetcher {
  GitHubFetcher._();

  static final _instance = GitHubFetcher._();
  static GitHubFetcher get instance => _instance;

  final _github = GitHub(auth: Authentication.withToken(githubBotsToken));

  Future<int?> getDevId(final String url) async {
    final name = url.removeFirst('https://github.com/');
    return (await _github.users.getUser(name)).publicReposCount;
  }

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

  Stream<Contributor> getProjectContributors(final RepositorySlug slug) =>
      _github.repositories.listContributors(slug);
}