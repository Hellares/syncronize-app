# Sistema de Sanitización de Logs

## 🔒 Descripción General

El sistema de sanitización de logs protege información sensible como tokens, contraseñas y claves API antes de que sean registradas en los logs de la aplicación.

## ⚡ Características

### Datos Sensibles Protegidos

#### Headers HTTP
- `Authorization`
- `X-API-Key`
- `Cookie` / `Set-Cookie`
- `X-Auth-Token`

#### Campos de Body
- `password`, `currentPassword`, `newPassword`, `confirmPassword`
- `accessToken`, `refreshToken`, `token`
- `apiKey`, `secret`, `privateKey`
- `clientSecret`, `resetToken`, `verificationToken`

#### Patrones Detectados
- **JWT Tokens**: `eyJ...` (formato estándar de 3 partes)
- **Bearer Tokens**: `Bearer <token>`
- **API Keys**: Strings alfanuméricos largos (32+ caracteres)

### Texto de Reemplazo
Todos los datos sensibles se reemplazan con: `***REDACTED***`

---

## 🛠️ Implementación

### 1. LogSanitizer (Core)
**Ubicación**: `lib/core/utils/log_sanitizer.dart`

Utilidad central que proporciona métodos para sanitizar diferentes tipos de datos:

```dart
// Sanitizar headers HTTP
final sanitizedHeaders = LogSanitizer.sanitizeHeaders(headers);

// Sanitizar body de request/response
final sanitizedBody = LogSanitizer.sanitizeBody(data);

// Sanitizar URLs (query params)
final sanitizedUrl = LogSanitizer.sanitizeUrl(url);

// Sanitizar mensajes de error
final sanitizedMessage = LogSanitizer.sanitizeErrorMessage(message);

// Sanitizar query params
final sanitizedParams = LogSanitizer.sanitizeQueryParams(params);
```

**Características**:
- ✅ Sanitización recursiva de Maps y Lists
- ✅ Detección de patrones JWT, Bearer tokens y API keys
- ✅ Protección de campos sensibles por nombre
- ✅ Sanitización de URLs con query params

---

### 2. SanitizedLoggingInterceptor
**Ubicación**: `lib/core/network/interceptors/sanitized_logging_interceptor.dart`

Interceptor de Dio que reemplaza a `TalkerDioLogger` con sanitización integrada.

**Funciones**:
- ✅ Loguea todas las peticiones HTTP con datos sanitizados
- ✅ Loguea todas las respuestas HTTP con datos sanitizados
- ✅ Loguea todos los errores HTTP con datos sanitizados
- ✅ Emojis visuales según código de estado (✅ 2xx, ⚠️ 4xx, ❌ 5xx)
- ✅ Trunca bodies largos (> 1000 caracteres)

**Ejemplo de Log Sanitizado**:
```
┌─────────────────────────────────────────────────────────────
│ 🌐 REQUEST
│ POST https://api.example.com/auth/login
│ Headers:
│   Authorization: ***REDACTED***
│   Content-Type: application/json
│ Body: {email: user@example.com, password: ***REDACTED***}
└─────────────────────────────────────────────────────────────
```

---

### 3. ErrorInterceptor Mejorado
**Ubicación**: `lib/core/network/interceptors/error_interceptor.dart`

Interceptor de errores que sanitiza todos los mensajes de error antes de lanzar excepciones.

**Mejoras**:
- ✅ Sanitiza el `data` de la respuesta de error
- ✅ Sanitiza los mensajes de error
- ✅ Sanitiza excepciones generales
- ✅ Previene la exposición de tokens en stack traces

---

### 4. LoggerService Mejorado
**Ubicación**: `lib/core/services/logger_service.dart`

Servicio de logging con sanitización automática en todos los métodos.

**Métodos Sanitizados**:
```dart
loggerService.debug('Message with token: Bearer abc123');
// Output: Message with token: Bearer ***REDACTED***

loggerService.error('Error', exception: 'Invalid token: eyJ...');
// Output: Error, Exception: Invalid token: ***REDACTED***

loggerService.logAction('login', data: {'password': '123456'});
// Output: USER ACTION: login | Data: {password: ***REDACTED***}

loggerService.logApiCall('POST', '/auth/login', params: {'token': 'abc'});
// Output: API: POST /auth/login | Params: {token: ***REDACTED***}
```

---

## 🔧 Configuración

### Activación/Desactivación
La sanitización de logs está vinculada a la configuración de logging:

```dart
// lib/config/environment/env_config.dart
class EnvConfig {
  static bool enablePrettyLogger = true; // Activa logging sanitizado
}
```

### Integración en DioClient
**Ubicación**: `lib/core/network/dio_client.dart`

```dart
_dio.interceptors.addAll([
  // Logging sanitizado (reemplaza TalkerDioLogger)
  if (EnvConfig.enablePrettyLogger) sanitizedLoggingInterceptor,
  refreshTokenInterceptor,
  authInterceptor,
  errorInterceptor,
]);
```

---

## 🧪 Ejemplos de Uso

### Ejemplo 1: Login Request
**Antes** (SIN sanitización):
```
POST /auth/login
Body: {
  email: "user@example.com",
  password: "MySecretPassword123!"
}
Response: {
  accessToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  refreshToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  user: {...}
}
```

**Después** (CON sanitización):
```
POST /auth/login
Body: {
  email: "user@example.com",
  password: "***REDACTED***"
}
Response: {
  accessToken: "***REDACTED***",
  refreshToken: "***REDACTED***",
  user: {...}
}
```

### Ejemplo 2: Authenticated Request
**Antes**:
```
GET /api/users/profile
Headers:
  Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Después**:
```
GET /api/users/profile
Headers:
  Authorization: ***REDACTED***
```

### Ejemplo 3: Error con Token
**Antes**:
```
Error: Invalid token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Después**:
```
Error: Invalid token: ***REDACTED***
```

---

## 🔐 Seguridad

### Beneficios de Seguridad

1. **Prevención de Exposición de Tokens**
   - Tokens de acceso y refresh nunca aparecen en logs
   - Protege contra lectura de logs por desarrolladores no autorizados

2. **Protección de Contraseñas**
   - Contraseñas nunca se loguean en texto plano
   - Incluye todas las variantes (current, new, confirm)

3. **Seguridad en Debugging**
   - Los desarrolladores pueden debuggear sin riesgo de ver credenciales
   - Los logs pueden compartirse de forma segura con soporte técnico

4. **Cumplimiento de Normativas**
   - Ayuda a cumplir con GDPR, PCI DSS y otras regulaciones
   - Reduce el riesgo de exposición de PII (Personally Identifiable Information)

### Limitaciones

⚠️ **Nota Importante**: Esta sanitización protege los logs, pero NO protege:
- Memoria en tiempo de ejecución
- Network traffic (usa HTTPS + Certificate Pinning para esto)
- Almacenamiento local (usa FlutterSecureStorage)
- Debugging via breakpoints

---

## 📋 Checklist de Verificación

Antes de desplegar a producción, verifica:

- [ ] `EnvConfig.enablePrettyLogger` configurado correctamente
- [ ] No hay usos directos de `TalkerDioLogger`
- [ ] `SanitizedLoggingInterceptor` está registrado en DI
- [ ] Todos los logs manuales usan `LoggerService`
- [ ] ErrorInterceptor importa `LogSanitizer`
- [ ] Ningún `print()` o `debugPrint()` loguea datos sensibles
- [ ] Logs de producción no muestran tokens en stack traces

---

## 🧩 Extensión del Sistema

### Añadir Nuevos Campos Sensibles

Edita `LogSanitizer`:

```dart
// lib/core/utils/log_sanitizer.dart
static const List<String> _sensitiveFields = [
  'password',
  'accessToken',
  // Añade tu campo aquí
  'customSecretField',
  'internalApiKey',
];
```

### Añadir Nuevos Patrones

```dart
static String _sanitizeString(String value) {
  // Añade tu patrón aquí
  final customPattern = RegExp(r'SECRET-[A-Z0-9]{16}');
  sanitized = sanitized.replaceAll(customPattern, _redactedText);

  return sanitized;
}
```

---

## 🎯 Mejores Prácticas

1. **Siempre usa LoggerService**
   ```dart
   // ✅ Correcto
   loggerService.debug('Token received');

   // ❌ Incorrecto
   print('Token: $token');
   ```

2. **No loguees objetos completos sin sanitizar**
   ```dart
   // ✅ Correcto
   loggerService.info('User logged in: ${user.email}');

   // ❌ Incorrecto (podría contener tokens)
   loggerService.info('User: ${user.toString()}');
   ```

3. **Usa niveles de log apropiados**
   ```dart
   // Desarrollo
   loggerService.debug('Detailed debugging info');

   // Producción
   loggerService.info('User action completed');
   loggerService.error('Critical error occurred');
   ```

4. **No dependas solo de sanitización**
   - Usa HTTPS siempre
   - Implementa Certificate Pinning
   - Usa FlutterSecureStorage para tokens
   - Habilita ProGuard/Obfuscation en release builds

---

## 📚 Referencias

- [OWASP Logging Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html)
- [Flutter Security Best Practices](https://flutter.dev/docs/deployment/security)
- [Dio Interceptors Documentation](https://pub.dev/packages/dio#interceptors)

---

## 📞 Soporte

Si encuentras información sensible en los logs después de esta implementación:

1. Identifica el origen (¿LoggerService? ¿Interceptor? ¿Otro?)
2. Añade el campo/patrón a `LogSanitizer`
3. Reporta el issue al equipo de seguridad
4. Rota las credenciales expuestas inmediatamente

---

**Última actualización**: 2025-11-25
**Versión**: 1.0.0
**Autor**: Sistema de Sanitización de Logs
