import 'package:teledart/model.dart';

extension MsgExt on TeleDartMessage {
  void sendTODO() => reply('Not yet implemented...');
  void sendUnknownCommand() => reply('Unknown command, please, try again...');
}