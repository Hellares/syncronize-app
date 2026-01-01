# Solución: Persistencia de Sesión

## 🐛 Problema Original

Cuando un usuario iniciaba sesión y cerraba la app (sin hacer logout), al volver a abrirla tenía que iniciar sesión nuevamente. La sesión NO se mantenía persistente.

## 🔍 Causa Raíz

El `AuthBloc` verificaba si había tokens guardados (`isAuthenticated`), pero NO estaba obteniendo ni restaurando los datos del usuario guardados. Por lo tanto:

1. ✅ Los tokens se guardaban correctamente en `SecureStorage`
2. ✅ `isAuthenticated()` devolvía `true`
3. ❌ Pero el `AuthBloc` no tenía el objeto `User`
4. ❌ Emitía `Unauthenticated()` en lugar de `Authenticated(user)`

### Código Problemático (antes):

```dart
Future<void> _onCheckAuthStatus(...) async {
  emit(AuthLoading());

  final isAuthenticated = await checkAuthStatus();

  // ❌ Solo emitía Authenticated si venía un user en el evento
  if (isAuthenticated && event.user != null) {
    emit(Authenticated(user: event.user!));
  } else {
    emit(Unauthenticated()); // ❌ Siempre llegaba aquí al inicio
  }
}
```

## ✅ Solución Implementada

### 1. Nuevo Caso de Uso: `GetLocalUserUseCase`

**Archivo:** `lib/features/auth/domain/usecases/get_local_user_usecase.dart`

```dart
@injectable
class GetLocalUserUseCase implements UseCase<User?, NoParams> {
  final AuthRepository repository;

  GetLocalUserUseCase(this.repository);

  @override
  Future<Resource<User?>> call(NoParams params) async {
    final isAuth = await repository.isAuthenticated();

    if (!isAuth) {
      return Success(null);
    }

    // Obtener perfil del servidor (actualiza cache local)
    try {
      return await repository.getProfile();
    } catch (e) {
      return Success(null);
    }
  }
}
```

**Qué hace:**
- Verifica si hay sesión guardada
- Si hay sesión, obtiene el perfil del servidor
- Esto refresca el token automáticamente si está por vencer (gracias al interceptor)
- Si falla, devuelve `null` y el usuario tendrá que hacer login

### 2. AuthBloc Actualizado

**Archivo:** `lib/features/auth/presentation/bloc/auth/auth_bloc.dart`

```dart
@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final CheckAuthStatusUseCase checkAuthStatus;
  final GetLocalUserUseCase getLocalUser; // ✅ Nuevo
  final LogoutUseCase logout;

  AuthBloc({
    required this.checkAuthStatus,
    required this.getLocalUser, // ✅ Nuevo
    required this.logout,
  }) : super(AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<UserLoggedInEvent>(_onUserLoggedIn);
    on<LogoutRequestedEvent>(_onLogoutRequested);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // Si viene un usuario en el evento, usarlo
    if (event.user != null) {
      emit(Authenticated(user: event.user!));
      return;
    }

    // ✅ Verificar si hay sesión guardada
    final isAuthenticated = await checkAuthStatus();

    if (isAuthenticated) {
      // ✅ Obtener el usuario del servidor
      final userResult = await getLocalUser(const NoParams());

      if (userResult is Success<User?>) {
        final user = (userResult as Success<User?>).data;
        if (user != null) {
          emit(Authenticated(user: user)); // ✅ Restaura sesión
        } else {
          emit(Unauthenticated());
        }
      } else {
        emit(Unauthenticated());
      }
    } else {
      emit(Unauthenticated());
    }
  }
}
```

## 🔄 Flujo Completo

### Al Iniciar Sesión

```
Usuario hace login
    ↓
LoginUseCase ejecuta
    ↓
Backend responde con tokens + user
    ↓
AuthRepository guarda:
  • accessToken → SecureStorage
  • refreshToken → SecureStorage
  • userId, email, nombres, apellidos → LocalStorage
  • isLoggedIn: true → LocalStorage
    ↓
AuthBloc emite: Authenticated(user)
    ↓
Usuario ve la app autenticado
```

### Al Cerrar y Volver a Abrir la App

```
App inicia
    ↓
AppInitializer carga dependencias
    ↓
AuthBloc se crea (bloc_provider.dart:19)
    ↓
Se dispara: CheckAuthStatusEvent() automáticamente
    ↓
AuthBloc._onCheckAuthStatus ejecuta:
    1. checkAuthStatus() → verifica tokens en storage
       ✅ isLoggedIn: true
       ✅ accessToken existe
       ✅ refreshToken existe

    2. getLocalUser() → llama a repository.getProfile()
       • Interceptor agrega token automáticamente
       • Backend valida token
       • Si token expiró:
         → RefreshTokenInterceptor lo refresca
         → Reintenta el request
       • Devuelve datos actualizados del usuario

    3. emit(Authenticated(user)) ✅
    ↓
Usuario ve la app autenticado (SIN tener que hacer login)
    ↓
Drawer muestra sus datos
Marketplace tiene todas las funciones disponibles
```

### Al Hacer Logout

```
Usuario toca "Cerrar Sesión"
    ↓
AuthBloc.LogoutRequestedEvent
    ↓
LogoutUseCase ejecuta
    ↓
AuthRepository.logout():
  • Llama al backend para invalidar sesión
  • Limpia SecureStorage (tokens)
  • Limpia LocalStorage (user info)
  • isLoggedIn: false
    ↓
AuthBloc emite: Unauthenticated()
    ↓
AppRouter redirige a /marketplace
Usuario ve versión guest
```

## 🔐 Seguridad

### ¿Es seguro obtener el perfil del servidor cada vez?

**SÍ**, y es RECOMENDADO por estas razones:

1. **Validación del token**: El backend valida que el token sea válido
2. **Refresh automático**: Si el token expiró, se refresca automáticamente
3. **Datos actualizados**: El usuario ve información actualizada
4. **Detección de sesiones inválidas**: Si el backend revocó la sesión, se detecta inmediatamente

### ¿Qué pasa si no hay internet?

El `getLocalUser` intenta obtener el perfil del servidor, pero si falla:
- Devuelve `null`
- El AuthBloc emite `Unauthenticated()`
- El usuario tendrá que hacer login cuando tenga conexión

**Alternativa (más permisiva)**: Podrías modificar `GetLocalUserUseCase` para devolver el usuario guardado en cache si falla la petición:

```dart
@override
Future<Resource<User?>> call(NoParams params) async {
  final isAuth = await repository.isAuthenticated();

  if (!isAuth) {
    return Success(null);
  }

  try {
    // Intentar obtener del servidor
    return await repository.getProfile();
  } catch (e) {
    // Si falla, obtener del cache local
    final cachedUser = await _localDataSource.getUserInfo();
    return Success(cachedUser?.toEntity());
  }
}
```

## 🧪 Cómo Probar

### Test 1: Persistencia básica
1. Abre la app
2. Inicia sesión
3. Verifica que veas tus datos en el drawer
4. Cierra la app completamente (mata el proceso)
5. Vuelve a abrir la app
6. ✅ Deberías ver tus datos sin tener que hacer login

### Test 2: Token expirado
1. Inicia sesión
2. En el backend, reduce el tiempo de expiración del token a 10 segundos
3. Espera 15 segundos
4. Cierra y abre la app
5. ✅ Debería refrescar automáticamente el token
6. ✅ Deberías ver tus datos

### Test 3: Logout
1. Inicia sesión
2. Haz logout
3. Cierra y abre la app
4. ✅ Deberías ver la versión guest del marketplace

### Test 4: Sin internet
1. Inicia sesión
2. Desactiva internet/WiFi
3. Cierra y abre la app
4. ❌ No podrás restaurar sesión (por seguridad)
5. Activa internet
6. Haz login de nuevo
7. ✅ Funciona normalmente

## 📊 Resumen de Cambios

| Archivo | Cambio | Estado |
|---------|--------|--------|
| `get_local_user_usecase.dart` | Creado nuevo caso de uso | ✅ |
| `auth_bloc.dart` | Agregado `getLocalUser` y lógica de restauración | ✅ |
| `injection_container` | Regenerado con `build_runner` | ✅ |

## 🎯 Resultado Final

Ahora tu app funciona como cualquier app moderna:
- ✅ **MercadoLibre**: Cierras y abres, sigues logueado
- ✅ **WhatsApp**: No te pide login cada vez
- ✅ **Instagram**: Mantiene tu sesión
- ✅ **Tu App**: Mantiene la sesión persistente

## ⚠️ Notas Importantes

1. **Tokens se guardan en SecureStorage**: Están cifrados y protegidos
2. **Validación en backend**: Siempre valida tokens en el servidor
3. **Refresh automático**: El interceptor maneja tokens expirados
4. **Logout limpia todo**: No quedan datos sensibles

## 🚀 Próximos Pasos Opcionales

1. **Agregar "Recordarme"**: Checkbox para sesiones más largas
2. **Biometría**: Login con huella/Face ID
3. **Múltiples cuentas**: Cambiar entre cuentas sin logout
4. **Modo offline**: Cache más agresivo para funcionar sin internet

---

**¡Problema resuelto!** Ahora tu sesión se mantiene persistente correctamente.
