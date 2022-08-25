import 'dart:collection';
import 'dart:convert' as convert;

import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

import 'commands.dart';
import 'constants.dart';
import 'extensions/iterable_ext.dart';
import 'extensions/map_ext.dart';

class Bot {
  Bot._();
  static final _instance = Bot._();
  factory Bot() => _instance;

  final http.Client _client = RetryClient(http.Client());

  final Map<String, Command> _messages = HashMap.of({
    "/start" : Command.start,
    "/follow" : Command.follow,
    "/unfollow" : Command.unfollow,
    "/projects" : Command.projects,
    "/project_info" : Command.projectInfo
  });

  int getLastUpdateID(final List updates) =>
      (List.from(updates.map((update) => update["update_id"]), growable: false).whereType<int>()).max;

  Future<Map<String, dynamic>> getUpdates(final int? lastUpdateID) async {
    final response = await _client.get(Uri.https(
        botsUrl,
        '$botToken/getUpdates',
        {'timeout': '100'}.addIf(
            'offset',
            lastUpdateID.toString(),
            test: () => lastUpdateID != null
        ).requestMap
    ));

    return convert.jsonDecode(response.body);
  }

  Future<void> sendHello({
    required final String firstName,
    required final String lastName,
    required final int chatId
  }) async => await _client.get(Uri.https(
      botsUrl,
      '$botToken/sendMessage',
      {
        'text': 'Hello, $firstName $lastName!',
        'chat_id': chatId
      }.requestMap
  ));

  Future<void> sendUnknownCommand({required final int chatId}) async =>
      await _client.get(Uri.https(
        botsUrl,
        '$botToken/sendMessage',
        {
          'text': 'Unknown command, please, try again...',
          'chat_id': chatId
        }.requestMap,
  ));

  Future<void> sendTODO({required final int chatId}) async =>
      await _client.get(Uri.https(
          botsUrl,
          '$botToken/sendMessage',
          {
            'text': 'Not yet implemented...',
            'chat_id': chatId
          }.requestMap
      ));

  Future<void> echoAll(final List updates) async =>
      updates.forEach((update) {
        final message = update['message'];

        if (message == null) {
          return;
        }

        final text = message['text'];

        if (text == null) {
          return;
        }

        final chatId = message['chat']['id'];

        switch (_messages[text]) {

          case Command.start:
            sendHello(
                firstName: message['from']['first_name'],
                lastName: message['from']['last_name'],
                chatId: chatId
            );
            break;

          case Command.follow:
            // TODO: follow the dev.
            sendTODO(chatId: chatId);
            break;

          case Command.unfollow:
            // TODO: unfollow the dev.
            sendTODO(chatId: chatId);
            break;

          case Command.projects:
            // TODO: show all dev's projects.
            sendTODO(chatId: chatId);
            break;

          case Command.projectInfo:
            // TODO: show project's info.
            sendTODO(chatId: chatId);
            break;

          default:
            sendUnknownCommand(chatId: chatId);
            break;
        }
      });

  Future<void> start() async {
    int? lastUpdateId;

    try {
      while (true) {
        final updatesResult = await getUpdates(lastUpdateId);

        if (updatesResult['ok']) {
          final List updates = updatesResult['result'];

          if (updates.isNotEmpty) {
           lastUpdateId = getLastUpdateID(updates) + 1;
            echoAll(updates);
          }
        }
      }
    } finally {
      _client.close();
    }
  }
}