import 'dart:io';

import 'package:git_hub_update_telegram_bot/utils/extensions/all_ext.dart';
import 'package:sqlite3/sqlite3.dart';

import '/db/developer.dart';
import '/db/follower.dart';

const _databaseName = 'followers.db';
const _devsTableName = 'Developers';
const _followersTableName = 'Followers';

class FollowersDao {
  FollowersDao._();

  static FollowersDao? _instance;
  late final Database _database;
  late final int _version;

  static Future<FollowersDao> get _newInstance async {
    final instance = FollowersDao._();
    final dbFile = File(_databaseName);

    final isDbExists = await dbFile.exists();

    if (!isDbExists) {
      await dbFile.create();
    }

    instance._database = sqlite3.open(_databaseName);

    if (!isDbExists) {
      instance._database.initDB();
    }

    return instance;
  }

  static Future<FollowersDao> get instance async =>
      _instance ??= await _newInstance;

  bool _isUserExists(final int userId) =>
      _database
          .select(
            'SELECT telegram_id FROM $_followersTableName WHERE telegram_id = ?',
            [userId]
          )
          .isNotEmpty;

  bool _isFollowerExists(final Follower follower) =>
      _database
          .select(
            'SELECT telegram_id FROM $_followersTableName WHERE telegram_id = ? AND following_dev = ?',
            [follower.telegramId, follower.followingDev?.name]
          )
          .isNotEmpty;

  Follower? _deleteNullFollower(final int followerId) {
    if (_isUserExists(followerId)) {
      _database.execute(
          'DELETE FROM $_followersTableName WHERE telegram_id = ? AND following_dev IS NULL',
          [followerId]
      );
      return Follower(followerId, null);
    } else {
      return null;
    }
  }

  bool addNewUserOrIgnore(final Follower user, { final bool isNullFollowerDelete = true }) {
    if (isNullFollowerDelete) {
      _deleteNullFollower(user.telegramId);
    }

    if (!_isFollowerExists(user)) {
      _database.execute(
          'INSERT INTO $_followersTableName (telegram_id, following_dev) VALUES (?, ?)',
          [user.telegramId, user.followingDev?.name]
      );

      return true;
    } else {
      return false;
    }
  }

  void addNewDevOrIgnore(final Developer dev) {
    try {
      _database.execute(
          'INSERT INTO $_devsTableName (name) VALUES (?)',
          [dev.name]
      );
    } catch(ignored) {
      // already exists
    }
  }

  void loginUser(final Follower user) {
    if (!(_isUserExists(user.telegramId))) {
      addNewUserOrIgnore(user);
    }
  }

  Follower? startFollowing(
      final int followerTelegramId,
      final Developer dev
  ) {
    addNewDevOrIgnore(dev);
    return Follower(followerTelegramId, dev).takeIf(addNewUserOrIgnore);
  }

  Follower? unfollow(final Follower follower) {
    if (_isFollowerExists(follower)) {
      _database.execute(
          'DELETE FROM $_followersTableName WHERE telegram_id = ? AND following_dev = ?',
          [follower.telegramId, follower.followingDev?.name]
      );
      return Follower(follower.telegramId, null);
    } else {
      return null;
    }
  }

  Map<int, List<Developer>> getFollowersWithDevs() {
    final dict = <int, List<Developer>> {};

    _database
        .select(
        '''
          SELECT fl.telegram_id as follower, dev.name as dev
          FROM $_followersTableName fl, $_devsTableName dev
          WHERE dev.name = fl.following_dev
        '''
        )
        .toList(growable: false)
        .forEach((followerWithDev) {
          final followerId = followerWithDev['follower'] as int;
          final dev = followerWithDev['dev'] as String;

          dict.update(
              followerId,
              (value) => value..add(Developer(dev)),
              ifAbsent: () => List.empty(growable: true)
          );
        });

    return dict;
  }
}

extension _FollowersDBExt on Database {
  Future<void> initDB() async => execute('''
      PRAGMA foreign_keys = ON;
      CREATE TABLE $_devsTableName (id INTEGER NOT NULL PRIMARY KEY);
      CREATE TABLE $_followersTableName (
        telegram_id INTEGER NOT NULL,
        following_dev_id INTEGER NULLABLE,
        FOREIGN KEY (following_dev_id) REFERENCES $_devsTableName (id) ON UPDATE CASCADE ON DELETE CASCADE
      );
  ''');
}