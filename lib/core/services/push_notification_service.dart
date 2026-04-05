import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/api_constants.dart';
import '../di/injection_container.dart';
import '../network/dio_client.dart';

/// Handler de mensajes en background — debe ser top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message: ${message.messageId}');
}

/// Servicio centralizado de push notifications
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Mensaje pendiente de cuando la app se abrió desde una notificación (terminated)
  Map<String, dynamic>? _pendingNotificationData;

  /// Callback para cuando se obtiene/refresca el token
  void Function(String token)? onTokenRefresh;

  /// Callback para cuando el usuario toca una notificación
  void Function(Map<String, dynamic> data)? _onNotificationTapped;
  set onNotificationTapped(void Function(Map<String, dynamic> data)? callback) {
    _onNotificationTapped = callback;
    // Si hay un mensaje pendiente (app abierta desde terminated), procesarlo ahora
    if (callback != null && _pendingNotificationData != null) {
      callback(_pendingNotificationData!);
      _pendingNotificationData = null;
    }
  }

  /// Callback para cuando se recibe una notificación (foreground)
  void Function()? onNotificationReceived;

  /// Callback para cuando se recibe un mensaje de servicio/cita (foreground)
  void Function()? onMensajeReceived;

  /// Canal de notificaciones Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'syncronize_default',
    'Notificaciones',
    description: 'Notificaciones de Syncronize',
    importance: Importance.high,
  );

  /// Inicializa todo el sistema de notificaciones
  Future<void> initialize() async {
    // 1. Registrar handler de background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Crear canal de notificaciones en Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 3. Inicializar local notifications
    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // 4. Solicitar permisos
    await requestPermission();

    // 5. Obtener token FCM
    await _getToken();

    // 6. Escuchar refresh de token (NO registrar en backend aquí,
    // eso se hace desde main.dart cuando el AuthBloc emite Authenticated)
    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      debugPrint('[FCM] Token refreshed: ${token.substring(0, 20)}...');
      onTokenRefresh?.call(token);
    });

    // 7. Escuchar mensajes en foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 8. Escuchar tap en notificación (app en background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // 9. Verificar si la app se abrió desde una notificación (app terminated)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }

    debugPrint('[FCM] Push notification service initialized');
  }

  /// Solicitar permisos de notificación
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');
    return granted;
  }

  /// Obtener el token FCM actual
  Future<String?> _getToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        debugPrint('[FCM] Token: ${_fcmToken!.substring(0, 20)}...');
        onTokenRefresh?.call(_fcmToken!);
      }
      return _fcmToken;
    } catch (e) {
      debugPrint('[FCM] Error getting token: $e');
      return null;
    }
  }

  /// Manejar mensaje cuando la app está en foreground
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.messageId}');

    // Notificar a la campana para actualizar badge
    onNotificationReceived?.call();

    // Si es un mensaje, refrescar el widget de mensajes
    if (message.data['tipo'] == 'MENSAJE') {
      onMensajeReceived?.call();
    }

    final notification = message.notification;
    if (notification == null) return;

    // Mostrar como local notification (FCM no muestra automáticamente en foreground)
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          color: const Color(0xFF1565C0),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Manejar tap en notificación
  void _handleMessageTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.data}');
    if (_onNotificationTapped != null) {
      _onNotificationTapped!(message.data);
    } else {
      // Guardar para cuando se conecte el callback (app terminated)
      _pendingNotificationData = Map<String, dynamic>.from(message.data);
    }
  }

  /// Manejar tap en local notification
  void _onNotificationResponse(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        if (_onNotificationTapped != null) {
          _onNotificationTapped!(data);
        } else {
          _pendingNotificationData = data;
        }
      } catch (e) {
        debugPrint('[FCM] Error parsing notification payload: $e');
      }
    }
  }

  /// Registrar el token FCM en el backend (llamar después del login)
  Future<void> registerTokenWithBackend() async {
    if (_fcmToken == null) return;
    try {
      final dio = locator<DioClient>();
      await dio.post(
        '${ApiConstants.notificaciones}/dispositivos',
        data: {
          'fcmToken': _fcmToken,
          'platform': Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web'),
        },
      );
      debugPrint('[FCM] Token registered with backend');
    } catch (e) {
      debugPrint('[FCM] Error registering token with backend: $e');
    }
  }

  /// Desregistrar el token FCM del backend (llamar en logout)
  Future<void> unregisterTokenFromBackend() async {
    if (_fcmToken == null) return;
    try {
      final dio = locator<DioClient>();
      await dio.delete(
        '${ApiConstants.notificaciones}/dispositivos',
        data: {'fcmToken': _fcmToken},
      );
      debugPrint('[FCM] Token unregistered from backend');
    } catch (e) {
      debugPrint('[FCM] Error unregistering token: $e');
    }
  }

  /// Suscribirse a un topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('[FCM] Subscribed to topic: $topic');
  }

  /// Desuscribirse de un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('[FCM] Unsubscribed from topic: $topic');
  }
}
