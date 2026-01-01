# 📝 Guía de Logging con Talker

Esta guía explica cómo usar el sistema de logging implementado en la aplicación.

## 🎯 ¿Qué es Talker?

Talker es un sistema de logging avanzado para Flutter que proporciona:
- ✅ Logs con colores y estructura
- ✅ UI integrada para ver logs en la app
- ✅ Captura automática de errores de BLoC
- ✅ Logs de HTTP automáticos
- ✅ Diferentes niveles (debug, info, warning, error, critical)
- ✅ Export de logs para soporte

## 📦 Componentes Implementados

### 1. LoggerService
Servicio centralizado para logging en toda la app.

### 2. TalkerDioLogger
Captura automáticamente todos los requests/responses HTTP.

### 3. TalkerBlocObserver
Captura automáticamente todos los eventos y estados de BLoC/Cubit.

---

## 🔧 Uso Básico

### 1. Inyectar LoggerService

```dart
class MiWidget extends StatelessWidget {
  final LoggerService logger;

  const MiWidget({required this.logger});

  @override
  Widget build(BuildContext context) {
    logger.info('Widget construido');
    return Container();
  }
}
```

### 2. En Cubits/BLoCs

```dart
@injectable
class LoginCubit extends Cubit<LoginState> {
  final LoggerService _logger;
  final LoginUseCase _loginUseCase;

  LoginCubit(this._logger, this._loginUseCase) : super(LoginInitial());

  Future<void> login(String email, String password) async {
    _logger.info('Iniciando login', tag: 'LoginCubit');

    emit(LoginLoading());

    try {
      final result = await _loginUseCase(
        LoginParams(email: email, password: password),
      );

      result.when(
        success: (authResponse) {
          _logger.info('Login exitoso: ${authResponse.user.email}', tag: 'LoginCubit');
          emit(LoginSuccess(authResponse));
        },
        error: (message, code, statusCode, details) {
          _logger.error(
            'Error en login: $message',
            tag: 'LoginCubit',
            exception: Exception(message),
          );
          emit(LoginError(message));
        },
      );
    } catch (e, stackTrace) {
      _logger.critical(
        'Error crítico en login',
        tag: 'LoginCubit',
        exception: e,
        stackTrace: stackTrace,
      );
      emit(LoginError(e.toString()));
    }
  }
}
```

### 3. En Repositories

```dart
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final LoggerService logger;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.logger,
  });

  @override
  Future<Resource<AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    logger.info('Intentando login para: $email', tag: 'AuthRepository');

    if (!await networkInfo.isConnected) {
      logger.warning('No hay conexión a internet', tag: 'AuthRepository');
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }

    try {
      final result = await remoteDataSource.login(
        email: email,
        password: password,
      );

      logger.info('Login exitoso, guardando tokens', tag: 'AuthRepository');
      await localDataSource.saveTokens(/* ... */);

      return Success(result.toEntity());
    } on ServerException catch (e) {
      logger.error(
        'Error del servidor en login',
        tag: 'AuthRepository',
        exception: e,
      );
      return Error(e.message, errorCode: 'SERVER_ERROR');
    }
  }
}
```

---

## 📊 Niveles de Log

### debug 🔍
Para información de desarrollo, solo visible en debug mode.

```dart
logger.debug('Usuario navegó a la pantalla de perfil');
logger.debug('Cache actualizado con 150 items');
```

### info ℹ️
Información general del flujo de la aplicación.

```dart
logger.info('Usuario inició sesión exitosamente');
logger.info('Datos sincronizados con el servidor');
```

### warning ⚠️
Advertencias que no son críticas pero requieren atención.

```dart
logger.warning('Token a punto de expirar, refrescando');
logger.warning('Cache lleno, limpiando items antiguos');
```

### error ❌
Errores que requieren atención pero la app puede continuar.

```dart
logger.error(
  'Error al cargar perfil de usuario',
  exception: e,
  tag: 'ProfileScreen',
);
```

### critical 🔥
Errores críticos que afectan funcionalidad principal.

```dart
logger.critical(
  'Error al guardar tokens de autenticación',
  exception: e,
  stackTrace: stackTrace,
  tag: 'AuthRepository',
);
```

---

## 🎨 Métodos Especiales

### logAction - Acciones de Usuario
Para rastrear acciones específicas del usuario (útil para analytics).

```dart
logger.logAction('click_login_button', data: {
  'email': email,
  'timestamp': DateTime.now().toIso8601String(),
});

logger.logAction('purchase_completed', data: {
  'product_id': productId,
  'amount': amount,
});
```

### logNavigation - Navegación
Para rastrear navegación entre pantallas.

```dart
logger.logNavigation('/home');
logger.logNavigation('/profile', params: {'userId': '123'});
```

### logApiCall - Llamadas API
Complementario a TalkerDioLogger, para logs adicionales.

```dart
logger.logApiCall('GET', '/api/users', params: {'page': 1});
```

### logStateChange - Cambios de Estado
Para rastrear cambios de estado importantes.

```dart
logger.logStateChange(
  'AuthState',
  previous: 'Unauthenticated',
  current: 'Authenticated',
);
```

### logLifecycle - Ciclo de Vida
Para eventos del ciclo de vida de widgets.

```dart
@override
void initState() {
  super.initState();
  logger.logLifecycle('initState', screen: 'LoginPage');
}

@override
void dispose() {
  logger.logLifecycle('dispose', screen: 'LoginPage');
  super.dispose();
}
```

---

## 👁️ Ver Logs en la App (Talker Screen)

### Opción 1: Agregar un botón en Settings

```dart
import 'package:talker_flutter/talker_flutter.dart';

class SettingsPage extends StatelessWidget {
  final LoggerService logger;

  const SettingsPage({required this.logger});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          // Otros settings...

          ListTile(
            leading: Icon(Icons.bug_report),
            title: Text('Ver Logs de Debug'),
            subtitle: Text('Solo para desarrollo'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TalkerScreen(
                    talker: logger.talker,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

### Opción 2: Shake detector (agitar el teléfono)

Agregar al `pubspec.yaml`:
```yaml
dependencies:
  shake: ^2.2.0
```

En `main.dart`:
```dart
import 'package:shake/shake.dart';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ShakeDetector detector;

  @override
  void initState() {
    super.initState();

    // Solo en debug mode
    if (kDebugMode) {
      detector = ShakeDetector.autoStart(
        onPhoneShake: () {
          final logger = locator<LoggerService>();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TalkerScreen(talker: logger.talker),
            ),
          );
        },
      );
    }
  }

  // resto del código...
}
```

---

## 📤 Exportar Logs

### Para enviar a soporte técnico

```dart
Future<void> exportarLogs() async {
  final logger = locator<LoggerService>();
  final logsText = logger.getAllLogs();

  // Guardar en archivo
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/logs_${DateTime.now().millisecondsSinceEpoch}.txt');
  await file.writeAsString(logsText);

  // Compartir
  await Share.shareFiles([file.path], text: 'Logs de la aplicación');
}
```

### Limpiar historial de logs

```dart
logger.clearLogs();
```

---

## 🔍 Logs Automáticos

### HTTP Requests (TalkerDioLogger)
Todos los requests HTTP se loguean automáticamente:

```
🌐 [HTTP-REQUEST] POST https://api.example.com/auth/login
  Headers: {Content-Type: application/json}
  Body: {"email": "user@example.com", "password": "***"}

✅ [HTTP-RESPONSE] 200 POST https://api.example.com/auth/login
  Response: {"user": {...}, "accessToken": "***"}
```

### BLoC Events & States (TalkerBlocObserver)
Todos los eventos y estados se loguean automáticamente:

```
📦 [BLOC-CREATE] LoginCubit created
📨 [BLOC-EVENT] LoginCubit | LoginButtonPressed
📊 [BLOC-TRANSITION] LoginCubit
  Event: LoginButtonPressed
  State: LoginInitial → LoginLoading
📊 [BLOC-TRANSITION] LoginCubit
  Event: LoginButtonPressed
  State: LoginLoading → LoginSuccess
```

---

## ⚙️ Configuración

### Cambiar nivel de log en producción

En `logger_service.dart`, ajustar:

```dart
logger: TalkerLogger(
  settings: TalkerLoggerSettings(
    enableColors: true,
    level: kDebugMode ? LogLevel.debug : LogLevel.warning, // Solo warnings y errors en producción
  ),
),
```

### Deshabilitar logs en producción

```dart
settings: TalkerSettings(
  enabled: kDebugMode, // Solo en debug
  useConsoleLogs: kDebugMode,
  useHistory: true,
  maxHistoryItems: 500,
),
```

---

## 📋 Buenas Prácticas

### ✅ DO

```dart
// Usa tags para identificar el origen
logger.info('Login exitoso', tag: 'AuthService');

// Incluye contexto útil
logger.error('Error al guardar', exception: e, tag: 'Database');

// Usa el nivel apropiado
logger.debug('Cache hit'); // Solo debug
logger.critical('Database corrupted'); // Crítico
```

### ❌ DON'T

```dart
// No uses print() directo
print('Usuario logueado'); // ❌

// No loguees información sensible
logger.info('Password: 123456'); // ❌

// No loguees TODO en producción
if (!kDebugMode) return; // ❌ Usa niveles apropiados
logger.debug('Esto solo se muestra en debug'); // ✅
```

---

## 🎯 Ejemplos Reales

### Login completo con logs

```dart
Future<void> login(String email, String password) async {
  logger.logAction('login_attempt', data: {'email': email});
  logger.info('Iniciando proceso de login', tag: 'LoginCubit');

  emit(LoginLoading());

  try {
    final result = await _loginUseCase(
      LoginParams(email: email, password: password),
    );

    result.when(
      success: (authResponse) {
        logger.info(
          'Login exitoso para: ${authResponse.user.email}',
          tag: 'LoginCubit',
        );
        logger.logAction('login_success', data: {
          'userId': authResponse.user.id,
          'email': authResponse.user.email,
        });
        emit(LoginSuccess(authResponse));
      },
      error: (message, code, statusCode, details) {
        logger.error(
          'Error en login: $message (code: $code)',
          tag: 'LoginCubit',
          exception: Exception(message),
        );
        logger.logAction('login_failed', data: {
          'error_code': code,
          'email': email,
        });
        emit(LoginError(message));
      },
    );
  } catch (e, stackTrace) {
    logger.critical(
      'Error crítico en login',
      tag: 'LoginCubit',
      exception: e,
      stackTrace: stackTrace,
    );
    emit(LoginError('Error inesperado'));
  }
}
```

---

## 🔗 Integración con Crashlytics/Sentry

Para enviar logs críticos a servicios externos:

```dart
@override
void critical(
  String message, {
  String? tag,
  Object? exception,
  StackTrace? stackTrace,
}) {
  _talker.critical(message, exception, stackTrace);

  // Enviar a Crashlytics
  FirebaseCrashlytics.instance.log(message);
  if (exception != null && stackTrace != null) {
    FirebaseCrashlytics.instance.recordError(exception, stackTrace);
  }
}
```

---

## 📱 Resultado

Con este sistema de logging tendrás:
- ✅ Logs automáticos de HTTP, BLoC, navegación
- ✅ UI integrada para debugging
- ✅ Export de logs para soporte
- ✅ Analytics de acciones de usuario
- ✅ Detección de errores críticos
- ✅ Mejor debuggability en desarrollo y producción
