import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/utils/bloc_form_item.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/auth_methods_response.dart';
import '../../../domain/entities/set_password_response.dart';
import '../../../domain/usecases/check_auth_methods_usecase.dart';
import '../../../domain/usecases/resend_verification_email_usecase.dart';
import '../../../domain/usecases/set_password_usecase.dart';
import '../../../domain/usecases/update_email_usecase.dart';
import '../auth/auth_bloc.dart';

part 'account_security_state.dart';

@injectable
class AccountSecurityCubit extends Cubit<AccountSecurityState> {
  final CheckAuthMethodsUseCase checkAuthMethodsUseCase;
  final SetPasswordUseCase setPasswordUseCase;
  final UpdateEmailUseCase updateEmailUseCase;
  final ResendVerificationEmailUseCase resendVerificationEmailUseCase;
  final AuthBloc authBloc;

  Timer? _cooldownTimer;

  AccountSecurityCubit(
    this.checkAuthMethodsUseCase,
    this.setPasswordUseCase,
    this.updateEmailUseCase,
    this.resendVerificationEmailUseCase,
    this.authBloc,
  ) : super(const AccountSecurityState());

  @override
  Future<void> close() {
    _cooldownTimer?.cancel();
    return super.close();
  }

  /// Inicializa la página cargando los métodos de autenticación disponibles
  Future<void> init() async {
   
    final authState = authBloc.state;
    
    if (authState is! Authenticated) {
      
      emit(state.copyWith(
        setPasswordResponse: Error('Usuario no autenticado'),
      ));
      return;
    }


    emit(state.copyWith(isLoadingMethods: true));

    // Solo verificar métodos de autenticación si el usuario tiene email
    if (authState.user.email == null) {
      emit(state.copyWith(
        isLoadingMethods: false,
        availableMethods: null,
      ));
      return;
    }

    final result = await checkAuthMethodsUseCase(authState.user.email!);


    if (result is Success<AuthMethodsResponse>) {

      emit(state.copyWith(
        availableMethods: result.data,
        isLoadingMethods: false,
        setPasswordResponse: null,
      ));
    } else if (result is Error) {

      // Intentar una vez más después de un breve delay (retry)
      await Future.delayed(const Duration(milliseconds: 500));
      final retryResult = await checkAuthMethodsUseCase(authState.user.email!);
      
      if (retryResult is Success<AuthMethodsResponse>) {
        emit(state.copyWith(
          availableMethods: retryResult.data,
          isLoadingMethods: false,
          setPasswordResponse: null,
        ));
      } else {
        emit(state.copyWith(
          isLoadingMethods: false,
          setPasswordResponse: Error((result as Error).message),
        ));
      }
    }
  }

  /// Actualiza el campo de contraseña
  void passwordChanged(String value) {
    final trimmedValue = value.trim();

    // Validación de contraseña
    String? error;
    if (trimmedValue.isEmpty) {
      error = 'La contraseña es requerida';
    } else if (trimmedValue.length < 8) {
      error = 'La contraseña debe tener al menos 8 caracteres';
    } else if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(trimmedValue)) {
      error = 'Debe incluir mayúscula, minúscula y número';
    }

    emit(state.copyWith(
      password: state.password.copyWith(value: trimmedValue, error: error),
      setPasswordResponse: null,
    ));

    // Re-validar confirmación si ya tiene valor
    if (state.confirmPassword.value.isNotEmpty) {
      _validateConfirmPassword();
    }
  }

  /// Actualiza el campo de confirmación de contraseña
  void confirmPasswordChanged(String value) {
    final trimmedValue = value.trim();
    emit(state.copyWith(
      confirmPassword: state.confirmPassword.copyWith(value: trimmedValue),
      setPasswordResponse: null,
    ));
    _validateConfirmPassword();
  }

  /// Valida que las contraseñas coincidan
  void _validateConfirmPassword() {
    String? error;
    if (state.confirmPassword.value.isEmpty) {
      error = 'Debes confirmar la contraseña';
    } else if (state.password.value != state.confirmPassword.value) {
      error = 'Las contraseñas no coinciden';
    }

    emit(state.copyWith(
      confirmPassword: state.confirmPassword.copyWith(error: error),
    ));
  }

  /// Establece la contraseña para el usuario actual
  Future<void> setPassword() async {
    // Forzar validación
    emit(state.copyWith(submitAttempt: true));
    emit(state.copyWith(submitAttempt: false));

    // Validar campos
    passwordChanged(state.password.value);
    _validateConfirmPassword();

    if (state.password.error != null || state.confirmPassword.error != null) {
      return;
    }

    if (state.password.value.isEmpty || state.confirmPassword.value.isEmpty) {
      return;
    }

    emit(state.copyWith(setPasswordResponse: Loading()));

    final result = await setPasswordUseCase(state.password.value);

    if (result is Success<SetPasswordResponse>) {
      emit(state.copyWith(
        setPasswordResponse: Success(result.data),
        password: const BlocFormItem(value: '', error: null),
        confirmPassword: const BlocFormItem(value: '', error: null),
      ));

      // Recargar métodos disponibles
      await init();
    } else if (result is Error) {
      emit(state.copyWith(
        setPasswordResponse: Error((result as Error).message),
      ));
    }
  }

  /// Agrega o cambia el email del usuario actual. Después de éxito,
  /// dispara `CheckAuthStatusEvent` para que el `AuthBloc` rehidrate
  /// `user.email` con `emailVerificado=false` y la card del dashboard
  /// refleje el cambio.
  Future<void> updateEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      emit(state.copyWith(
        updateEmailResponse: Error('El email es requerido'),
      ));
      return;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!emailRegex.hasMatch(trimmed)) {
      emit(state.copyWith(
        updateEmailResponse: Error('Email inválido'),
      ));
      return;
    }

    emit(state.copyWith(updateEmailResponse: Loading()));

    final result = await updateEmailUseCase(trimmed);

    if (result is Success) {
      emit(state.copyWith(updateEmailResponse: Success(null)));
      // El backend acaba de generar un token; el usuario debe esperar 60s
      // antes de solicitar un reenvío.
      _startResendCooldown(60);
      // Refrescar el usuario en el AuthBloc para que el resto de la app
      // vea el email actualizado y `emailVerificado=false`.
      authBloc.add(const CheckAuthStatusEvent());
      // Recargar métodos disponibles (puede impactar `availableMethods`).
      await init();
    } else if (result is Error) {
      emit(state.copyWith(
        updateEmailResponse: Error((result as Error).message),
      ));
    }
  }

  /// Reenviar correo de verificación al email actual del usuario. Útil
  /// cuando el correo no llegó (spam, demora SMTP) o expiró el token.
  /// El backend aplica cooldown de 60s desde el último envío y devuelve
  /// 400 con segundos restantes si se intenta antes.
  Future<void> resendVerificationEmail() async {
    final authState = authBloc.state;
    if (authState is! Authenticated) {
      emit(state.copyWith(
        resendVerificationResponse: Error('Usuario no autenticado'),
      ));
      return;
    }
    final email = authState.user.email;
    if (email == null || email.isEmpty) {
      emit(state.copyWith(
        resendVerificationResponse: Error('Tu cuenta no tiene email asociado'),
      ));
      return;
    }
    if (state.resendCooldownSeconds > 0) {
      // Defensivo: el botón ya debería estar deshabilitado.
      return;
    }

    emit(state.copyWith(resendVerificationResponse: Loading()));

    final result = await resendVerificationEmailUseCase(
      ResendVerificationEmailParams(email: email),
    );

    if (result is Success) {
      emit(state.copyWith(resendVerificationResponse: Success(null)));
      _startResendCooldown(60);
    } else if (result is Error) {
      emit(state.copyWith(
        resendVerificationResponse: Error(result.message),
      ));
    }
  }

  void _startResendCooldown(int seconds) {
    _cooldownTimer?.cancel();
    emit(state.copyWith(resendCooldownSeconds: seconds));
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.resendCooldownSeconds - 1;
      if (remaining <= 0) {
        timer.cancel();
        emit(state.copyWith(resendCooldownSeconds: 0));
      } else {
        emit(state.copyWith(resendCooldownSeconds: remaining));
      }
    });
  }
}
