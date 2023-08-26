**GitHub Updates Telegram Bot**
-------------------------------

## **Developer**
[Paranid5](https://github.com/dinaraparanid)

## **About Bot**

Telegram bot that tracks GitHub developers' updates.
It helps to track new projects and releases of the developers that you want to follow

### **Preview**

<img src="https://i.ibb.co/vPP3STy/2023-08-26-23-14-36.png" width="300">
<img src="https://i.ibb.co/R3Sb5GH/2023-08-26-23-15-37.png" width="300">
<img src="https://i.ibb.co/8YszrHS/2023-08-26-23-17-58.png" width="300">
<img src="https://i.ibb.co/1L0tVJw/2023-08-27-00-13-21.png" width="300">

## **Current status**
**V 1.0.0**

### **Requests**
You can control it with the following commands:

<ul>
    <li>
        <b><i>/follow</i> https://github.com/{your_developer}</b> - 
        Starts tracking for the new releases of the developer. You will receive the message about the updates
    </li>
    <li>
        <b><i>/unfollow</i> https://github.com/{your_developer}</b> - 
        Stops tracking for the developer
    </li>
    <li>
        <b><i>/projects</i> https://github.com/{your_developer}</b> - 
        Shows all public repositories of the developer and their last releases (if there are any)
    </li>
    <li>
        <b><i>/project_info</i> https://github.com/{your_developer}/{his_project}</b> - 
        Shows the detailed information about the repository (description, license, last update, contributors, etc.)
    </li>
</ul>

## **Setup**

Firstly, you should add next code to /lib/constants.dart:

```dart
final githubBotsToken = '<YOUR_GITHUB_TOKEN>';
final botToken = '<TELEGRAM_BOT_TOKEN>';
```

Then, bot can be deployed with docker:

```shell
docker build -t gh_bot .
docker run gh_bot
```

## **Stack**

<ul>
    <li>Dart 3.1</li>
    <li>teledart</li>
    <li>http</li>
    <li>sqlite3</li>
    <li>github</li>
    <li>dartz</li>
</ul>