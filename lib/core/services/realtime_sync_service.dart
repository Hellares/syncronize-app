import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../features/producto/domain/services/precio_nivel_cache_service.dart';
import 'push_notification_service.dart';

/// Evento de sincronización en tiempo real recibido por FCM.
/// Las páginas relevantes (grilla de productos en POS) se suscriben al
/// stream del [RealtimeSyncService] para reaccionar (reload con debounce).
abstract class RealtimeEvent {
  const RealtimeEvent();
}

/// El precio base (o de oferta) de un producto/sede cambió.
class RealtimePrecioCambiado extends RealtimeEvent {
  final String empresaId;
  final String? productoId;
  final String? varianteId;
  final String? sedeId;
  const RealtimePrecioCambiado({
    required this.empresaId,
    this.productoId,
    this.varianteId,
    this.sedeId,
  });
}

/// El stock disponible de un producto/sede cambió (otra venta, ajuste,
/// transferencia, merma).
class RealtimeStockCambiado extends RealtimeEvent {
  final String empresaId;
  final String? productoId;
  final String? varianteId;
  final String? sedeId;
  const RealtimeStockCambiado({
    required this.empresaId,
    this.productoId,
    this.varianteId,
    this.sedeId,
  });
}

/// Los niveles de precio (Por Mayor, Distribuidor, etc.) de un producto
/// fueron modificados (create/update/delete).
class RealtimeNivelesCambiados extends RealtimeEvent {
  final String empresaId;
  final String? productoId;
  final String? varianteId;
  const RealtimeNivelesCambiados({
    required this.empresaId,
    this.productoId,
    this.varianteId,
  });
}

/// Coordina la sincronización en tiempo real entre el backend y la app
/// vía FCM data-only messages.
///
/// Flujo:
/// 1. Backend al detectar un cambio (precio/stock/nivel) emite mensaje
///    data-only al topic `empresa-${empresaId}` con priority high.
/// 2. [PushNotificationService] recibe el mensaje (foreground o
///    background) y delega al `onRealtimeData` callback.
/// 3. Este service parsea el `data['tipo']` y:
///    a. Invalida cache local relevante ([PrecioNivelCacheService] si
///       cambian precios o niveles).
///    b. Emite un evento al stream [events] para que páginas como la
///       grilla de Venta Rápida hagan `ProductoListCubit.reload()` con
///       debounce.
///
/// Vinculación al tenant:
/// - [bind] se llama cuando se carga `EmpresaContext` (después del
///   switch-tenant) — suscribe al topic correspondiente.
/// - [unbind] al hacer logout o cambiar de empresa.
///
/// Defensa en capas: este servicio es la capa 1 (UX visual). Si FCM
/// falla, las capas 2 (rechazo 409 server-side) y 3 (dialog amigable
/// del cliente) garantizan que no haya cobros incorrectos.
@lazySingleton
class RealtimeSyncService {
  final PrecioNivelCacheService _nivelCacheService;

  final _eventsController = StreamController<RealtimeEvent>.broadcast();
  Stream<RealtimeEvent> get events => _eventsController.stream;

  String? _topicSuscrito;

  RealtimeSyncService(this._nivelCacheService);

  /// Suscribe al topic FCM de la empresa actual. Llamar tras
  /// switch-tenant exitoso. Idempotente: si ya estaba suscrito al
  /// mismo topic, no hace nada.
  Future<void> bind(String empresaId) async {
    final topic = 'empresa-$empresaId';
    if (_topicSuscrito == topic) return;

    // Desuscribir el anterior si lo había (multi-empresa)
    if (_topicSuscrito != null) {
      try {
        await PushNotificationService()
            .unsubscribeFromTopic(_topicSuscrito!);
      } catch (_) {/* ignore */}
    }

    try {
      await PushNotificationService().subscribeToTopic(topic);
      _topicSuscrito = topic;
      debugPrint('[Realtime] Bound to topic: $topic');
    } catch (e) {
      debugPrint('[Realtime] Error binding to $topic: $e');
    }
  }

  /// Desuscribe del topic actual. Llamar en logout o cambio de empresa.
  Future<void> unbind() async {
    if (_topicSuscrito == null) return;
    try {
      await PushNotificationService().unsubscribeFromTopic(_topicSuscrito!);
      debugPrint('[Realtime] Unbound from topic: $_topicSuscrito');
    } catch (e) {
      debugPrint('[Realtime] Error unbinding: $e');
    } finally {
      _topicSuscrito = null;
    }
  }

  /// Punto de entrada desde [PushNotificationService]. Recibe el `data`
  /// del mensaje FCM y dispara la lógica según `data['tipo']`.
  ///
  /// Las claves del data vienen como String (limitación FCM). Los demás
  /// campos pueden venir vacíos: si no podemos resolver `productoId`
  /// igualmente emitimos el evento para que el listener decida.
  void handleRealtimeData(Map<String, dynamic> data) {
    final tipo = data['tipo']?.toString();
    if (tipo == null) return;

    final empresaId = data['empresaId']?.toString();
    if (empresaId == null || empresaId.isEmpty) return;

    final productoId = _stringOrNull(data['productoId']);
    final varianteId = _stringOrNull(data['varianteId']);
    final sedeId = _stringOrNull(data['sedeId']);

    switch (tipo) {
      case 'PRECIO_CAMBIADO':
        // Cuando cambia un precio, también los niveles cacheados podrían
        // estar obsoletos si el admin tocó la oferta o un nivel.
        // Invalidamos por las dudas.
        if (productoId != null) _nivelCacheService.invalidate(productoId);
        _eventsController.add(RealtimePrecioCambiado(
          empresaId: empresaId,
          productoId: productoId,
          varianteId: varianteId,
          sedeId: sedeId,
        ));
        break;

      case 'STOCK_CAMBIADO':
        _eventsController.add(RealtimeStockCambiado(
          empresaId: empresaId,
          productoId: productoId,
          varianteId: varianteId,
          sedeId: sedeId,
        ));
        break;

      case 'NIVELES_CAMBIADOS':
        if (productoId != null) _nivelCacheService.invalidate(productoId);
        _eventsController.add(RealtimeNivelesCambiados(
          empresaId: empresaId,
          productoId: productoId,
          varianteId: varianteId,
        ));
        break;
    }
  }

  String? _stringOrNull(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }
}
