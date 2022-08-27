import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';

import 'constants.dart';
import '/extensions/teledart_ext.dart';
import 'extensions/teledart_msg_ext.dart';

class Bot {
  Bot._();
  late final TeleDart _teledart;
  static Bot? _instance;

  static Future<Bot> get _newInstance async {
    final instance = Bot._();
    final username = (await Telegram(botToken).getMe()).username!;
    instance._teledart = TeleDart(botToken, Event(username));
    instance._teledart.start();
    instance._setCommands();
    return instance;
  }

  void _setCommands() {
    _teledart
        .onCommand('start')
        .listen(_teledart.login);

    _teledart
      .onCommand('follow')
      .listen(_teledart.startFollowing);

    _teledart
        .onCommand('unfollow')
        .listen((message) => message.sendTODO()); // TODO: unfollow the dev

    _teledart
        .onCommand('projects')
        .listen((message) => message.sendTODO()); // TODO: show all dev's projects

    _teledart
        .onCommand('project_info')
        .listen((message) => message.sendTODO()); // TODO: show project info

    final notCommandsRegex = RegExp('^(?!start|follow|unfollow|projects|project_info).*\$');

    _teledart
      .onMessage(entityType: 'bot_command', keyword: notCommandsRegex)
        .listen((message) => message.sendUnknownCommand());

    _teledart
        .onMessage(keyword: notCommandsRegex)
        .listen((message) => message.sendUnknownCommand());
  }

  static Future<void> start() async => _instance ??= await _newInstance;
}