import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../features/producto/data/cache/variante_imagenes_local_store.dart';
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

/// Un producto nuevo fue creado en la empresa. El listener debe
/// refrescar el catálogo para incluirlo.
class RealtimeProductoCreado extends RealtimeEvent {
  final String empresaId;
  final String? productoId;
  const RealtimeProductoCreado({
    required this.empresaId,
    this.productoId,
  });
}

/// Un producto cambió de forma estructural (nombre/desc/categoría/marca/
/// isActive/delete/restore/variantes/combo/bulk). El listener debe hacer
/// fetch full para que el backend re-aplique filtros (isActive, deletedAt,
/// etc.) y el catálogo del cliente quede coherente. Si `productoId` es
/// null el cambio es masivo (bulk upload, importación, etc.).
class RealtimeProductoActualizado extends RealtimeEvent {
  final String empresaId;
  final String? productoId;
  const RealtimeProductoActualizado({
    required this.empresaId,
    this.productoId,
  });
}

/// Un cliente de la empresa cambió: creado, asociado, datos de la Persona
/// compartida actualizados (posiblemente por OTRA empresa o por el propio
/// cliente desde su portal), desactivado o eliminado. El listener debe
/// disparar un delta-sync del catálogo local de clientes.
class RealtimeClienteCambiado extends RealtimeEvent {
  final String empresaId;
  final String? clienteEmpresaId;
  final String? personaId;
  const RealtimeClienteCambiado({
    required this.empresaId,
    this.clienteEmpresaId,
    this.personaId,
  });
}

/// Señal sintética emitida desde el propio cliente — NO viene de FCM
/// externo. Disparada por:
/// - Timer.periodic cada 5 min mientras la app está en foreground.
/// - `AppLifecycleState.resumed` (volver del background).
///
/// Cubre los casos donde un FCM real se perdió (battery saver agresivo
/// de Xiaomi/Huawei, doze mode, red intermitente). Los listeners la
/// procesan igual que cualquier `RealtimeEvent` y disparan una
/// revalidación silenciosa con syncDeltas (~1 KB).
class RealtimeHeartbeat extends RealtimeEvent {
  final String empresaId;
  const RealtimeHeartbeat(this.empresaId);
}

/// Las imágenes de un producto fueron modificadas (upload/delete). El
/// listener debe refrescar el catálogo — la URL puede ser nueva o
/// haber desaparecido.
class RealtimeImagenCambiada extends RealtimeEvent {
  final String empresaId;
  final String? productoId;
  final String? varianteId;
  const RealtimeImagenCambiada({
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
  final VarianteImagenesLocalStore _varianteImagenesStore;

  final _eventsController = StreamController<RealtimeEvent>.broadcast();
  Stream<RealtimeEvent> get events => _eventsController.stream;

  String? _topicSuscrito;

  // ─────────────────────────────────────────────────────────────────
  // Heartbeat polling de respaldo (defensa contra FCM perdidos)
  // ─────────────────────────────────────────────────────────────────
  //
  // Algunos OEMs Android (Xiaomi, Huawei, OPPO, Vivo) tienen battery
  // savers agresivos que matan FCM background. También doze mode y
  // red intermitente pueden hacer que mensajes se pierdan. Como
  // respaldo, emitimos un `RealtimeHeartbeat` periódico al stream
  // para forzar revalidación silenciosa.
  //
  // Los listeners (productos_page, ProductoSelectorView) ya reaccionan
  // a cualquier `RealtimeEvent` con syncDeltas — el heartbeat se
  // procesa igual. Si FCM funciona normal, el heartbeat se skipea
  // (ver `_minGapBetweenEmits`).

  Timer? _heartbeatTimer;
  String? _heartbeatEmpresaId;

  /// Timestamp del último evento emitido al stream (real o sintético).
  /// Sirve para evitar revalidación redundante: si llegó un FCM real
  /// hace <4 min, el heartbeat skipa.
  DateTime _lastEmitAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Estado del lifecycle de la app. Solo emitimos heartbeats cuando
  /// la app está en foreground — sino es trabajo inútil.
  bool _appIsForeground = true;

  /// Instante en que la app fue a background. Permite calcular cuánto
  /// tiempo estuvo fuera y forzar el heartbeat al volver si superó el
  /// umbral, ignorando `_minGapBetweenEmits` (que fue diseñado para
  /// evitar duplicados timer/FCM, no para bloquear revalidación post-
  /// background).
  DateTime? _pausedAt;

  static const Duration _resumeSyncThreshold = Duration(minutes: 1);

  /// Cada cuánto disparar el heartbeat. 5 min cubre la mayoría de
  /// huecos de FCM sin saturar al backend (~12 req/hora/cajero;
  /// con 200 cajeros = 40 req/min total, mayormente skipped).
  static const Duration _heartbeatInterval = Duration(minutes: 5);

  /// Gap mínimo entre emits — evita doble revalidación cuando el
  /// timer y un resume del lifecycle coinciden, o cuando llegó un
  /// FCM real recientemente.
  static const Duration _minGapBetweenEmits = Duration(minutes: 4);

  RealtimeSyncService(this._nivelCacheService, this._varianteImagenesStore);

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
      _startHeartbeat(empresaId);
    } catch (e) {
      debugPrint('[Realtime] Error binding to $topic: $e');
    }
  }

  /// Desuscribe del topic actual. Llamar en logout o cambio de empresa.
  Future<void> unbind() async {
    _stopHeartbeat();
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

  /// Arranca el timer del heartbeat para la empresa actual. Idempotente
  /// — si ya había uno corriendo lo reemplaza (por si bind se llama
  /// de nuevo con otra empresa, ej. switch-tenant).
  void _startHeartbeat(String empresaId) {
    _heartbeatTimer?.cancel();
    _heartbeatEmpresaId = empresaId;
    _heartbeatTimer =
        Timer.periodic(_heartbeatInterval, (_) => _tryEmitHeartbeat());
    debugPrint('[Realtime] Heartbeat started for empresa: $empresaId');
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _heartbeatEmpresaId = null;
  }

  /// Emite un `RealtimeHeartbeat` al stream si:
  /// - hay empresa bindeada,
  /// - la app está en foreground,
  /// - pasó suficiente tiempo desde el último evento.
  /// Devuelve `true` si efectivamente emitió, `false` si skipeó.
  bool _tryEmitHeartbeat() {
    if (!_appIsForeground) return false;
    final empresaId = _heartbeatEmpresaId;
    if (empresaId == null) return false;
    final now = DateTime.now();
    if (now.difference(_lastEmitAt) < _minGapBetweenEmits) {
      // FCM real o heartbeat reciente — no es necesario revalidar.
      return false;
    }
    _lastEmitAt = now;
    _eventsController.add(RealtimeHeartbeat(empresaId));
    debugPrint('[Realtime] Heartbeat emitted for empresa: $empresaId');
    return true;
  }

  /// Notifica al servicio el estado del lifecycle de la app. Llamado
  /// desde el `WidgetsBindingObserver` en main. En background no
  /// emitimos heartbeats (nadie está mirando + ahorro de batería).
  void setAppForeground(bool isForeground) {
    _appIsForeground = isForeground;
    if (!isForeground) {
      _pausedAt = DateTime.now();
    }
  }

  /// Disparar un heartbeat inmediato — usado cuando la app vuelve del
  /// background. Si estuvo fuera > [_resumeSyncThreshold], fuerza el
  /// heartbeat ignorando `_minGapBetweenEmits` (cubre FCM perdidos por
  /// battery saver / doze mode / red intermitente durante el background).
  void triggerResumeRefresh() {
    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (pausedAt != null) {
      final backgroundDuration = DateTime.now().difference(pausedAt);
      if (backgroundDuration > _resumeSyncThreshold) {
        _lastEmitAt = DateTime.fromMillisecondsSinceEpoch(0);
        debugPrint(
          '[Realtime] App was in background for '
          '${backgroundDuration.inSeconds}s — forcing sync',
        );
      }
    }
    _tryEmitHeartbeat();
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

    // Registrar el evento real para que el heartbeat skip cuando
    // FCM está funcionando normal.
    _lastEmitAt = DateTime.now();

    switch (tipo) {
      case 'PRECIO_CAMBIADO':
        if (productoId != null) _nivelCacheService.invalidate(productoId);
        if (varianteId != null) _nivelCacheService.invalidateVariante(varianteId);
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
        if (varianteId != null) _nivelCacheService.invalidateVariante(varianteId);
        _eventsController.add(RealtimeNivelesCambiados(
          empresaId: empresaId,
          productoId: productoId,
          varianteId: varianteId,
        ));
        break;

      case 'IMAGEN_CAMBIADA':
        // Invalidar el cache en disco de variantes-completas del producto
        // para que el detalle vuelva a fetchear las imágenes nuevas.
        if (productoId != null) {
          unawaited(_varianteImagenesStore.invalidate(
            empresaId: empresaId,
            productoId: productoId,
          ));
        }
        _eventsController.add(RealtimeImagenCambiada(
          empresaId: empresaId,
          productoId: productoId,
          varianteId: varianteId,
        ));
        break;

      case 'CLIENTE_CAMBIADO':
        _eventsController.add(RealtimeClienteCambiado(
          empresaId: empresaId,
          clienteEmpresaId: _stringOrNull(data['clienteEmpresaId']),
          personaId: _stringOrNull(data['personaId']),
        ));
        break;

      case 'PRODUCTO_CREADO':
        _eventsController.add(RealtimeProductoCreado(
          empresaId: empresaId,
          productoId: productoId,
        ));
        break;

      case 'PRODUCTO_ACTUALIZADO':
        if (productoId != null) {
          unawaited(_varianteImagenesStore.invalidate(
            empresaId: empresaId,
            productoId: productoId,
          ));
        }
        _eventsController.add(RealtimeProductoActualizado(
          empresaId: empresaId,
          productoId: productoId,
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
