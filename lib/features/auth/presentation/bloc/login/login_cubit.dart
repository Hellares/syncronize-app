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
