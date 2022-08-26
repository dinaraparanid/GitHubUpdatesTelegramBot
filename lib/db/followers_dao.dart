import 'package:git_hub_update_telegram_bot/db/developer.dart';
import 'package:git_hub_update_telegram_bot/db/follower.dart';
import 'package:git_hub_update_telegram_bot/extensions/all_ext.dart';
import 'package:sqflite/sqflite.dart';

class FollowersDao {
  FollowersDao._();

  static const _databaseName = 'followers.db';
  static const _followersTableName = 'FOLLOWERS';
  static const _devsTableName = 'DEVELOPERS';

  static FollowersDao? _instance;
  late final Database _database;
  late final int _version;

  static Future<FollowersDao> get _newInstance async =>
      FollowersDao._().also((dao) async =>
        dao._database = await openDatabase(
            _databaseName,
            onCreate: (db, i) async {
              dao._version = i;
              await db.initDB();
            }
        )
      );

  static get instance async => _instance ??= await _newInstance;

  Future<bool> isUserExists(final Follower user) async =>
      (await _database.query(
          _followersTableName,
          columns: ['telegram_id'],
          where: 'telegram_id = ?',
          whereArgs: [user.telegramId]
      )).isNotEmpty;

  Future<void> addNewUser(final Follower user) async =>
      await _database.insert(
        _followersTableName,
        { 'telegram_id': user.telegramId, 'following_dev_id': null },
        conflictAlgorithm: ConflictAlgorithm.ignore
      );

  Future<bool> addNewDevOrIgnore(final Developer dev) async =>
      (await _database.insert(_devsTableName, { 'id': dev.id })) != 0;

  Future<void> loginUser(final Follower user) async {
    if (!(await isUserExists(user))) {
      await addNewUser(user);
    }
  }
  
  Future<Follower> startFollowing(
      final Follower follower,
      final Developer dev
  ) async {
    await addNewDevOrIgnore(dev);

    await _database.insert(
      _followersTableName,
      { 'telegram_id': follower.telegramId, 'following_dev_id': dev.id },
    );

    return Follower(follower.telegramId, dev.id);
  }

  Future<Follower> unfollow(final Follower follower) async {
    await _database.delete(
      _followersTableName,
      where: 'telegram_id = ? AND following_dev_id = ?',
      whereArgs: [follower.telegramId, follower.followingDevId]
    );

    return Follower(follower.telegramId, null);
  }
}

extension _FollowersDBExt on Database {
  Future<void> initDB() async {
    await execute('CREATE TABLE DEVELOPERS (id INTEGER NOT NULL PRIMARY KEY);');

    await execute('''
      CREATE TABLE FOLLOWERS (
        telegram_id INTEGER NOT NULL,
        FOREIGN KEY(following_dev_id) REFERENCES DEVELOPERS(id) ON DELETE CASCADE ON UPDATE CASCADE
      );
    ''');
  }
}