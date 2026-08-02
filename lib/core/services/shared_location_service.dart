import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

/// Recibe ubicaciones compartidas desde otras apps — el caso real es el
/// cliente que manda su ubicación por WhatsApp y el usuario toca
/// **Compartir → Syncronize** para armar el delivery en ese punto exacto.
///
/// Devuelve el texto **crudo** que compartió la otra app (normalmente un
/// enlace de Google Maps); resolverlo a coordenadas es responsabilidad de
/// quien consume, porque el formato acortado `maps.app.goo.gl` necesita
/// seguir la redirección en el backend.
///
/// El lado nativo vive en `MainActivity.kt`. Solo Android: iOS necesitaría
/// un Share Extension aparte, que no está implementado.
@lazySingleton
class SharedLocationService {
  static const MethodChannel _channel = MethodChannel(
    'com.syncronize.app/shared_location',
  );

  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  /// Ubicaciones compartidas mientras la app está abierta.
  ///
  /// El caso de app cerrada NO pasa por acá — ese se lee una sola vez con
  /// [consumeInitial], porque el share llega antes de que exista un
  /// suscriptor y un broadcast stream descarta lo que emite sin oyentes.
  Stream<String> get stream => _controller.stream;

  /// Engancha el canal nativo. Llamar una vez al arrancar la app.
  void init() {
    if (!Platform.isAndroid) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSharedText') {
        final text = call.arguments as String?;
        if (text != null && text.isNotEmpty && !_controller.isClosed) {
          _controller.add(text);
        }
      }
    });
  }

  /// Ubicación que abrió la app estando cerrada, o `null` si arrancó normal.
  ///
  /// El nativo la descarta al entregarla, así que una segunda llamada
  /// devuelve `null` — es a propósito: evita reabrir el picker cada vez que
  /// la app vuelve a foreground.
  Future<String?> consumeInitial() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('getInitialSharedText');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      // El canal no existe (build viejo sin el MainActivity nuevo).
      return null;
    }
  }

  @disposeMethod
  void dispose() {
    _controller.close();
  }
}
