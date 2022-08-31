import 'dart:isolate';

class IsolateExt {
  IsolateExt._();

  static Future<void> runOnBackground<T>(
      final ReceivePort port,
      final void Function(SendPort sendPort) action
  ) async => await Isolate.spawn(action, port.sendPort);

  static Future<void> runOnBackgroundAsync<T>(
      final ReceivePort port,
      final Future<void> Function(SendPort sendPort) action
  ) async => await Isolate.spawn(action, port.sendPort);
}