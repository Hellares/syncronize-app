import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../di/injection_container.dart';
import '../network/dio_client.dart';
import '../constants/api_constants.dart';
import '../services/push_notification_service.dart';

/// Widget de campana de notificaciones con badge de no leídas.
/// Se actualiza al recibir push y al navegar de vuelta de la page.
class NotificationBell extends StatefulWidget {
  final Color color;

  const NotificationBell({super.key, this.color = Colors.white});

  @override
  State<NotificationBell> createState() => NotificationBellState();
}

class NotificationBellState extends State<NotificationBell> with WidgetsBindingObserver {
  int _unreadCount = 0;

  /// Permite refrescar desde fuera (ej: después de marcar leída)
  static final refreshNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCount();

    // Escuchar cuando llega una push notification (foreground)
    PushNotificationService().onNotificationReceived = _onPushReceived;

    // Escuchar refresh externo
    refreshNotifier.addListener(_loadCount);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PushNotificationService().onNotificationReceived = null;
    refreshNotifier.removeListener(_loadCount);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refrescar cuando la app vuelve a foreground
    if (state == AppLifecycleState.resumed) {
      _loadCount();
    }
  }

  void _onPushReceived() {
    // Incrementar localmente para respuesta instantánea
    if (mounted) {
      setState(() => _unreadCount++);
    }
  }

  Future<void> _loadCount() async {
    try {
      final dio = locator<DioClient>();
      final response = await dio.get(
        '${ApiConstants.notificaciones}/no-leidas/count',
      );
      if (!mounted) return;
      final count = (response.data as Map<String, dynamic>)['count'] as int? ?? 0;
      setState(() => _unreadCount = count);
    } catch (e) {
      debugPrint('[NotificationBell] Error loading count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_outlined, size: 20, color: widget.color),
          if (_unreadCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  _unreadCount > 99 ? '99+' : '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: () async {
        await context.push('/empresa/notificaciones');
        if (mounted) _loadCount();
      },
      tooltip: 'Notificaciones',
    );
  }
}
