import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:injectable/injectable.dart';

/// Identificador estable del dispositivo. En Android usa ANDROID_ID, que
/// **persiste entre reinstalaciones** del app (solo cambia con factory reset),
/// por eso sirve para restaurar la config de impresoras al reinstalar.
@lazySingleton
class DeviceIdService {
  final DeviceInfoPlugin _info = DeviceInfoPlugin();
  String? _cached;

  Future<String> getDeviceId() async {
    if (_cached != null) return _cached!;
    try {
      if (Platform.isAndroid) {
        final a = await _info.androidInfo;
        _cached = a.id; // ANDROID_ID
      } else if (Platform.isIOS) {
        final i = await _info.iosInfo;
        _cached = i.identifierForVendor ?? 'ios-unknown';
      } else {
        _cached = 'desktop';
      }
    } catch (_) {
      _cached = 'unknown';
    }
    return _cached ?? 'unknown';
  }
}
