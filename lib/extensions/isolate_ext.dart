import 'dart:isolate';

class IsolateExt {
  IsolateExt._();

  static Future<T> getFromBackground<T>(final T Function(SendPort sendPort) action) async {
    final port = ReceivePort();
    await Isolate.spawn(action, port.sendPort);
    return await port.first;
  }

  static Future<T> getFromBackgroundAsync<T>(final Future<T> Function(SendPort sendPort) action) async {
    final port = ReceivePort();
    await Isolate.spawn(action, port.sendPort);
    return await port.first;
  }

  static Future<void> runOnBackground<T>(final void Function(SendPort sendPort) action) async {
    final port = ReceivePort();
    await Isolate.spawn(action, port.sendPort);
    await port.first;
  }

  static Future<void> runOnBackgroundAsync<T>(final Future<void> Function(SendPort sendPort) action) async {
    final port = ReceivePort();
    await Isolate.spawn(action, port.sendPort);
    await port.first;
  }
}