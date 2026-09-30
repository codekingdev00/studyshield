import 'package:flutter/services.dart';

/// Bridges to Android's screen-pinning (Lock Task Mode) API so the device
/// stays on this app — home, recents and other apps are blocked — until
/// [stop] is called.
class LockTaskService {
  LockTaskService._();
  static const _channel = MethodChannel('studyfocus/lock_task');

  static Future<bool> start() async {
    try {
      return await _channel.invokeMethod<bool>('startLock') ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> stop() async {
    try {
      return await _channel.invokeMethod<bool>('stopLock') ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> isLocked() async {
    try {
      return await _channel.invokeMethod<bool>('isLocked') ?? false;
    } on PlatformException {
      return false;
    }
  }
}
