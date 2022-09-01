import 'package:teledart/model.dart';

extension MsgExt on TeleDartMessage {
  void sendTODO() => reply('Not yet implemented...');
  void sendUnknownCommand() => reply('Unknown command, please, try again...');

  void sendHelp() => reply('''I can help you to track new projects and releases of the developers that you want to follow.

You can control me with the following commands:

/follow https://github.com/your_developer - Starts tracking for the new releases of the developer. You will receive the message about the updates

/unfollow https://github.com/your_developer - Stops tracking for the developer

/projects https://github.com/your_developer - Shows all public repositories of the developer and their last releases (if there are any)

/project_info https://github.com/your_developer/his_project - Shows the detailed information about the repository (description, license, last update, contributors, etc.)

If you have any difficulties or you've found a bug, please, contact the developer: https://t.me/paranid5
  ''', disable_web_page_preview: true);
}