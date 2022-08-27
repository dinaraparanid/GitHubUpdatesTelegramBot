import 'package:github/github.dart';
import '/extensions/string_ext.dart';

class GitHubFetcher {
  GitHubFetcher._();

  static final _instance = GitHubFetcher._();
  static GitHubFetcher get instance => _instance;

  final _github = GitHub();

  Future<int?> getDevId(final String url) async {
    final name = url.removeFirst('https://github.com/');
    return (await _github.users.getUser(name)).id;
  }
}