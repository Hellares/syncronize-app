// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:equatable/equatable.dart';
// import 'package:injectable/injectable.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import '../../../domain/usecases/login_usecase.dart';
// import '../../../domain/usecases/google_sign_in_usecase.dart';
// import '../../../../../core/utils/resource.dart';
// import '../../../../../core/utils/bloc_form_item.dart';

// part 'login_state.dart';

// /// Cubit para manejar el formulario y lógica de login
// @injectable
// class LoginCubit extends Cubit<LoginState> {
//   final LoginUseCase loginUseCase;
//   final GoogleSignInUseCase googleSignInUseCase;

//   // Configurar Google Sign-In con el Web Client ID para obtener ID tokens
//   final GoogleSignIn _googleSignIn = GoogleSignIn(
//     scopes: ['email', 'profile'],
//     // IMPORTANTE: Este debe ser el Web Client ID, no el Android Client ID
//     serverClientId: '453248870302-lber3ndgufr3pioeprk6b5d1vhbk8fbi.apps.googleusercontent.com',
//   );

//   LoginCubit({
//     required this.loginUseCase,
//     required this.googleSignInUseCase,
//   }) : super(const LoginState());

//   /// Actualizar email
//   void emailChanged(String value) {
//     emit(state.copyWith(
//       email: BlocFormItem(
//         value: value,
//         error: _validateEmail(value),
//       ),
//       response: null, // Limpiar respuesta anterior
//     ));
//   }

//   /// Actualizar password
//   void passwordChanged(String value) {
//     emit(state.copyWith(
//       password: BlocFormItem(
//         value: value,
//         error: _validatePassword(value),
//       ),
//       response: null,
//     ));
//   }

//   /// Validar email
//   String? _validateEmail(String value) {
//     if (value.isEmpty) {
//       return 'El email es requerido';
//     }
//     final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
//     if (!emailRegex.hasMatch(value)) {
//       return 'Email inválido';
//     }
//     return null;
//   }

//   /// Validar password (sincronizado con backend)
//   String? _validatePassword(String value) {
//     if (value.isEmpty) {
//       return 'La contraseña es requerida';
//     }
//     if (value.length < 8) {
//       return 'La contraseña debe tener al menos 8 caracteres';
//     }
//     // Validar que contenga al menos una mayúscula
//     if (!RegExp(r'[A-Z]').hasMatch(value)) {
//       return 'La contraseña debe contener al menos una mayúscula';
//     }
//     // Validar que contenga al menos una minúscula
//     if (!RegExp(r'[a-z]').hasMatch(value)) {
//       return 'La contraseña debe contener al menos una minúscula';
//     }
//     // Validar que contenga al menos un número
//     if (!RegExp(r'\d').hasMatch(value)) {
//       return 'La contraseña debe contener al menos un número';
//     }
//     // Validar que contenga al menos un carácter especial
//     if (!RegExp(r'[@$!%*?&_\-#^()+={}\[\]:;"' r"'<>,.\/\\|~`]").hasMatch(value)) {
//       return 'La contraseña debe contener al menos un carácter especial';
//     }
//     return null;
//   }

//   /// Validar formulario completo
//   bool _isFormValid() {
//     return _validateEmail(state.email.value) == null &&
//         _validatePassword(state.password.value) == null;
//   }

//   /// Login
//   Future<void> login() async {
//     // Validar formulario
//     if (!_isFormValid()) {
//       emit(state.copyWith(
//         email: state.email.copyWith(
//           error: _validateEmail(state.email.value),
//         ),
//         password: state.password.copyWith(
//           error: _validatePassword(state.password.value),
//         ),
//       ));
//       return;
//     }

//     // Emitir Loading
//     emit(state.copyWith(response: Loading()));

//     final params = LoginParams(
//       email: state.email.value.trim(),
//       password: state.password.value,
//       loginMode: 'marketplace', // Siempre iniciar en marketplace
//     );

//     final result = await loginUseCase(params);

//     // Actualizar estado con resultado
//     emit(state.copyWith(response: result));
//   }

//   /// Login con empresa seleccionada (segundo paso del flujo)
//   Future<void> loginWithCompany({
//     required String email,
//     required String password,
//     required String subdominio,
//   }) async {
//     // Emitir Loading
//     emit(state.copyWith(response: Loading()));

//     final params = LoginParams(
//       email: email.trim(),
//       password: password,
//       subdominioEmpresa: subdominio,
//     );

//     final result = await loginUseCase(params);

//     // Actualizar estado con resultado
//     emit(state.copyWith(response: result));
//   }

//   /// Login con modo seleccionado (marketplace o management)
//   Future<void> loginWithMode({
//     required String email,
//     required String password,
//     required String loginMode,
//     String? subdominioEmpresa,
//   }) async {
//     // Emitir Loading
//     emit(state.copyWith(response: Loading()));

//     final params = LoginParams(
//       email: email.trim(),
//       password: password,
//       loginMode: loginMode,
//       subdominioEmpresa: subdominioEmpresa,
//     );

//     final result = await loginUseCase(params);

//     // Actualizar estado con resultado
//     emit(state.copyWith(response: result));
//   }

//   /// Sign in con Google (primer paso - sin empresa)
//   Future<void> signInWithGoogle() async {
//     try {
//       // Emitir Loading
//       emit(state.copyWith(response: Loading()));

//       // OPCIONAL: Descomentar para siempre mostrar selector de cuentas
//       // await _googleSignIn.signOut();

//       // Iniciar el flujo de Google Sign-In
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

//       if (googleUser == null) {
//         // El usuario canceló el sign-in
//         emit(state.copyWith(
//           response: Error('Inicio de sesión cancelado'),
//         ));
//         return;
//       }

//       // Obtener los detalles de autenticación
//       final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

//       // Verificar que tengamos el ID token
//       if (googleAuth.idToken == null) {
//         emit(state.copyWith(
//           response: Error('No se pudo obtener el token de Google'),
//         ));
//         return;
//       }

//       // Guardar el ID token temporalmente para el segundo paso (si es necesario)
//       final idToken = googleAuth.idToken!;

//       // Llamar al use case con el ID token y modo marketplace por defecto
//       final params = GoogleSignInParams(
//         idToken: idToken,
//         loginMode: 'marketplace', // Siempre iniciar en marketplace
//       );
//       final result = await googleSignInUseCase(params);

//       // Actualizar estado con resultado y guardar el token
//       emit(state.copyWith(
//         response: result,
//         googleIdToken: idToken, // Guardar para usar en selección de empresa
//       ));
//     } catch (e) {
//       emit(state.copyWith(
//         response: Error('Error al iniciar sesión con Google: ${e.toString()}'),
//       ));
//     }
//   }

//   /// Sign in con Google con empresa seleccionada (segundo paso del flujo)
//   Future<void> signInWithGoogleAndCompany({
//     required String subdominio,
//   }) async {
//     // Verificar que tengamos el Google ID Token
//     if (state.googleIdToken == null) {
//       emit(state.copyWith(
//         response: Error('Token de Google no disponible. Inicia sesión nuevamente.'),
//       ));
//       return;
//     }

//     // Emitir Loading
//     emit(state.copyWith(response: Loading()));

//     // Llamar al use case con el ID token y el subdominio de la empresa
//     final params = GoogleSignInParams(
//       idToken: state.googleIdToken!,
//       subdominioEmpresa: subdominio,
//     );
//     final result = await googleSignInUseCase(params);

//     // Actualizar estado con resultado
//     emit(state.copyWith(response: result));
//   }

//   /// Sign in con Google con modo seleccionado (marketplace o management)
//   Future<void> signInWithGoogleAndMode({
//     required String loginMode,
//     String? subdominioEmpresa,
//   }) async {
//     // Verificar que tengamos el Google ID Token
//     if (state.googleIdToken == null) {
//       emit(state.copyWith(
//         response: Error('Token de Google no disponible. Inicia sesión nuevamente.'),
//       ));
//       return;
//     }

//     // Emitir Loading
//     emit(state.copyWith(response: Loading()));

//     // Llamar al use case con el ID token, modo y opcionalmente subdominio
//     final params = GoogleSignInParams(
//       idToken: state.googleIdToken!,
//       loginMode: loginMode,
//       subdominioEmpresa: subdominioEmpresa,
//     );
//     final result = await googleSignInUseCase(params);

//     // Actualizar estado con resultado
//     emit(state.copyWith(response: result));
//   }

//   /// Cambiar cuenta de Google (cierra sesión de Google y vuelve a mostrar selector)
//   Future<void> changeGoogleAccount() async {
//     try {
//       // Cerrar sesión de Google (esto fuerza el selector de cuentas)
//       await _googleSignIn.signOut();

//       // Ahora iniciar sesión con Google de nuevo
//       await signInWithGoogle();
//     } catch (e) {
//       emit(state.copyWith(
//         response: Error('Error al cambiar cuenta de Google: ${e.toString()}'),
//       ));
//     }
//   }

//   /// Cerrar sesión de Google (útil cuando el usuario hace logout de la app)
//   Future<void> signOutGoogle() async {
//     try {
//       await _googleSignIn.signOut();
//     } catch (e) {
//       // Ignorar errores de Google Sign-Out
//     }
//   }

//   /// Resetear formulario
//   void reset() {
//     emit(const LoginState());
//   }
// }


import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../domain/usecases/login_usecase.dart';
import '../../../domain/usecases/google_sign_in_usecase.dart';
import '../../../domain/usecases/check_auth_methods_usecase.dart';
import '../../../domain/entities/auth_methods_response.dart';
import '../../../../../core/utils/resource.dart';
import '../../../../../core/utils/bloc_form_item.dart';

part 'login_state.dart';

@injectable
class LoginCubit extends Cubit<LoginState> {
  final LoginUseCase loginUseCase;
  final GoogleSignInUseCase googleSignInUseCase;
  final CheckAuthMethodsUseCase checkAuthMethodsUseCase;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '453248870302-lber3ndgufr3pioeprk6b5d1vhbk8fbi.apps.googleusercontent.com',
  );

  Timer? _debounceTimer;

  LoginCubit({
    required this.loginUseCase,
    required this.googleSignInUseCase,
    required this.checkAuthMethodsUseCase,
  }) : super(const LoginState());

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }

  // ---------------- UX PRO: onChanged no valida hasta submit ----------------
  void emailChanged(String value) {
    final v = value.trim();

    emit(state.copyWith(
      email: state.email.copyWith(
        value: v,
        // ✅ si ya intentó submit, revalida para que se quite al corregir
        error: state.submitAttempt ? _validateEmail(v) : null,
        clearError: !state.submitAttempt,
      ),
      response: null,
    ));

    // ✅ Verificar métodos disponibles si el email parece válido (con debounce)
    if (v.contains('@') && v.contains('.') && v.length > 5) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        checkAuthMethods();
      });
    } else {
      // Limpiar métodos si el email no es válido
      _debounceTimer?.cancel();
      emit(state.copyWith(clearAvailableMethods: true));
    }
  }

  void passwordChanged(String value) {
    emit(state.copyWith(
      password: state.password.copyWith(
        value: value,
        error: state.submitAttempt ? _validatePassword(value) : null,
        clearError: !state.submitAttempt,
      ),
      response: null,
    ));
  }

  // ---------------- VALIDACIONES ----------------
  String? _validateEmail(String value) {
    if (value.isEmpty) return 'Este campo es requerido';

    // Verificar si es un DNI (8 dígitos)
    final dniRegex = RegExp(r'^\d{8}$');
    if (dniRegex.hasMatch(value)) {
      return null; // DNI válido
    }

    // Si no es DNI, verificar que sea un email válido
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un email válido o DNI de 8 dígitos';
    }

    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return 'La contraseña es requerida';
    // Para login, solo verificar que no esté vacía
    // Las validaciones de complejidad se aplican en registro/cambio de contraseña
    return null;
  }

  bool _validateAndEmitErrors() {
    final emailErr = _validateEmail(state.email.value.trim());
    final passErr = _validatePassword(state.password.value);

    if (emailErr != null || passErr != null) {
      emit(state.copyWith(
        email: state.email.copyWith(error: emailErr),
        password: state.password.copyWith(error: passErr),
        response: null,
      ));
      return false;
    }

    // limpia errores si existían
    if (state.email.error != null || state.password.error != null) {
      emit(state.copyWith(
        email: state.email.copyWith(clearError: true),
        password: state.password.copyWith(clearError: true),
      ));
    }
    return true;
  }

  // ---------------- LOGIN NORMAL ----------------
  Future<void> login() async {
    // ✅ intent de submit (UX)
    emit(state.copyWith(submitAttempt: true));

    if (!_validateAndEmitErrors()) return;

    emit(state.copyWith(response: Loading()));

    final params = LoginParams(
      credencial: state.email.value.trim(),
      password: state.password.value,
      loginMode: 'marketplace',
    );

    final result = await loginUseCase(params);
    emit(state.copyWith(response: result));
  }

  Future<void> loginWithCompany({
    required String email,
    required String password,
    required String subdominio,
  }) async {
    emit(state.copyWith(response: Loading()));

    final params = LoginParams(
      credencial: email.trim(),
      password: password,
      subdominioEmpresa: subdominio,
    );

    final result = await loginUseCase(params);
    emit(state.copyWith(response: result));
  }

  Future<void> loginWithMode({
    required String email,
    required String password,
    required String loginMode,
    String? subdominioEmpresa,
  }) async {
    emit(state.copyWith(response: Loading()));

    final params = LoginParams(
      credencial: email.trim(),
      password: password,
      loginMode: loginMode,
      subdominioEmpresa: subdominioEmpresa,
    );

    final result = await loginUseCase(params);
    emit(state.copyWith(response: result));
  }

  // ---------------- GOOGLE HELPERS (robustos) ----------------
  Future<GoogleSignInAccount?> _signInGoogleInteractive() async {
    // Si quieres siempre mostrar selector:
    // await _googleSignIn.signOut();
    return _googleSignIn.signIn();
  }

  Future<String?> _getIdTokenFromAccount(GoogleSignInAccount account) async {
    final auth = await account.authentication;
    if (auth.idToken != null && auth.idToken!.isNotEmpty) return auth.idToken;

    // Fallback: a veces el plugin no trae idToken al primer intento.
    // Intentamos recuperar la sesión y volver a pedir authentication.
    final silent = await _googleSignIn.signInSilently();
    if (silent != null) {
      final auth2 = await silent.authentication;
      if (auth2.idToken != null && auth2.idToken!.isNotEmpty) return auth2.idToken;
    }

    return null;
  }

  // ---------------- GOOGLE SIGN-IN (PRIMER PASO) ----------------
  Future<void> signInWithGoogle() async {
    try {
      emit(state.copyWith(response: Loading(), clearGoogle: true));

      final googleUser = await _signInGoogleInteractive();

      if (googleUser == null) {
        emit(state.copyWith(response: Error('Inicio de sesión cancelado')));
        return;
      }

      final idToken = await _getIdTokenFromAccount(googleUser);
      if (idToken == null) {
        emit(state.copyWith(response: Error('No se pudo obtener el token de Google')));
        return;
      }

      final params = GoogleSignInParams(
        idToken: idToken,
        loginMode: 'marketplace',
      );

      final result = await googleSignInUseCase(params);

      // ✅ guarda token + email para el 2do paso (si backend pide empresa)
      emit(state.copyWith(
        response: result,
        googleIdToken: idToken,
        googleEmail: googleUser.email,
      ));
    } catch (e) {
      emit(state.copyWith(
        response: Error('Error al iniciar sesión con Google: ${e.toString()}'),
      ));
    }
  }

  // ---------------- GOOGLE (SEGUNDO PASO) ----------------
  Future<void> signInWithGoogleAndCompany({required String subdominio}) async {
    final token = state.googleIdToken;
    if (token == null || token.isEmpty) {
      emit(state.copyWith(
        response: Error('Token de Google no disponible. Inicia sesión nuevamente.'),
      ));
      return;
    }

    emit(state.copyWith(response: Loading()));

    final params = GoogleSignInParams(
      idToken: token,
      subdominioEmpresa: subdominio,
    );

    final result = await googleSignInUseCase(params);
    emit(state.copyWith(response: result));
  }

  Future<void> signInWithGoogleAndMode({
    required String loginMode,
    String? subdominioEmpresa,
  }) async {
    final token = state.googleIdToken;
    if (token == null || token.isEmpty) {
      emit(state.copyWith(
        response: Error('Token de Google no disponible. Inicia sesión nuevamente.'),
      ));
      return;
    }

    emit(state.copyWith(response: Loading()));

    final params = GoogleSignInParams(
      idToken: token,
      loginMode: loginMode,
      subdominioEmpresa: subdominioEmpresa,
    );

    final result = await googleSignInUseCase(params);
    emit(state.copyWith(response: result));
  }

  // ---------------- GOOGLE ACCOUNT MANAGEMENT ----------------
  Future<void> changeGoogleAccount() async {
    try {
      emit(state.copyWith(clearGoogle: true));
      await _googleSignIn.signOut();
      await signInWithGoogle();
    } catch (e) {
      emit(state.copyWith(
        response: Error('Error al cambiar cuenta de Google: ${e.toString()}'),
      ));
    }
  }

  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignorar
    } finally {
      // ✅ importante: limpiar token/email en state
      emit(state.copyWith(clearGoogle: true));
    }
  }

  // ---------------- MULTI-METHOD AUTH ----------------
  /// Verificar métodos de autenticación disponibles para el email ingresado
  Future<void> checkAuthMethods() async {
    final emailValue = state.email.value.trim();

    // No hacer la llamada si el email no tiene formato básico válido
    if (emailValue.isEmpty || !emailValue.contains('@')) {
      return;
    }

    emit(state.copyWith(isCheckingMethods: true, checkMethodsError: null));

    // Intentar hasta 2 veces con un pequeño delay entre intentos
    Resource<AuthMethodsResponse>? finalResult;
    for (int attempt = 1; attempt <= 2; attempt++) {
      final result = await checkAuthMethodsUseCase(emailValue);
      if (result is Success<AuthMethodsResponse>) {
        finalResult = result;
        break;
      }
      // Si es error y no es el último intento, esperar un poco antes de reintentar
      if (attempt < 2) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }

    if (finalResult != null && finalResult is Success<AuthMethodsResponse>) {
      emit(state.copyWith(
        availableMethods: finalResult.data,
        isCheckingMethods: false,
      ));
    } else {
      emit(state.copyWith(
        isCheckingMethods: false,
        checkMethodsError: finalResult is Error ? (finalResult as Error).message : 'Error al verificar métodos',
        // Si falla, mostrar todos los métodos por defecto (mejor UX)
        clearAvailableMethods: true,
      ));
    }
  }

  // ---------------- RESET ----------------
  void reset() {
    emit(const LoginState());
  }
}
