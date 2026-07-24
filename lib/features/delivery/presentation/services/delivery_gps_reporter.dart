import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/datasources/delivery_remote_datasource.dart';

/// Reporta la posición del repartidor mientras su entrega va EN_CAMINO.
///
/// - Solo corre con una entrega activa (la página lo enciende al marcar
///   "en camino" y lo apaga al entregar / salir de la pantalla).
/// - En Android usa foreground service con notificación visible
///   ("Entrega en curso") → sigue reportando con la pantalla apagada.
/// - Best-effort total: sin permiso o sin señal simplemente no reporta;
///   jamás rompe el flujo de la entrega.
class DeliveryGpsReporter {
  final DeliveryRemoteDataSource _dataSource;

  StreamSubscription<Position>? _sub;
  String? _deliveryId;
  String? _empresaId;

  DeliveryGpsReporter(this._dataSource);

  bool get activo => _sub != null;

  /// Arranca (o mantiene) el reporteo para ESTA entrega. Idempotente.
  Future<void> asegurar({
    required String empresaId,
    required String deliveryId,
  }) async {
    if (_sub != null && _deliveryId == deliveryId) return;
    await detener();

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      return; // sin permiso → sin GPS, la entrega sigue normal
    }

    _deliveryId = deliveryId;
    _empresaId = empresaId;

    final settings = defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 15, // metros — parado no spamea
            intervalDuration: const Duration(seconds: 12),
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'Entrega en curso 🛵',
              notificationText:
                  'Compartiendo tu ubicación con el cliente hasta entregar',
              enableWakeLock: true,
            ),
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 15,
          );

    _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (pos) {
        final id = _deliveryId;
        final emp = _empresaId;
        if (id == null || emp == null) return;
        _dataSource
            .reportarPosicion(id, emp, pos.latitude, pos.longitude)
            .catchError((_) {}); // red intermitente = se pierde un punto, ok
      },
      onError: (_) {}, // GPS apagado / sin señal → silencioso
    );
  }

  Future<void> detener() async {
    await _sub?.cancel();
    _sub = null;
    _deliveryId = null;
    _empresaId = null;
  }
}
