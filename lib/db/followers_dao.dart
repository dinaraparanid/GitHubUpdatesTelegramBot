import 'dart:io';

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

  bool isUserExists(final Follower user) =>
      _database
          .select(
            'SELECT telegram_id FROM $_followersTableName WHERE telegram_id = ?',
            [user.telegramId]
          )
          .isNotEmpty;

  void addNewUser(final Follower user) =>
      _database.execute(
          'INSERT INTO $_followersTableName (telegram_id, following_dev_id) VALUES (?, ?)',
          [user.telegramId, null]
      );

  void addNewDevOrIgnore(final Developer dev) =>
      _database.execute(
          'INSERT INTO $_devsTableName (id) VALUES (?)',
          [dev.id]
      );

  void loginUser(final Follower user) {
    if (!(isUserExists(user))) {
      addNewUser(user);
    }
  }

  Follower startFollowing(
      final int followerTelegramId,
      final Developer dev
  ) {
    addNewDevOrIgnore(dev);

    _database.execute(
        'INSERT INTO $_followersTableName (telegram_id, following_dev_id) VALUES (?, ?)',
        [followerTelegramId, dev.id]
    );

    return Follower(followerTelegramId, dev.id);
  }

  Follower unfollow(final Follower follower) {
    _database.execute(
        'DELETE FROM $_followersTableName WHERE telegram_id = ? AND following_dev_id = ?',
        [follower.telegramId, follower.followingDevId]
    );

    return Follower(follower.telegramId, null);
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