import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/utils/bloc_form_item.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/auth_methods_response.dart';
import '../../../domain/entities/set_password_response.dart';
import '../../../domain/usecases/check_auth_methods_usecase.dart';
import '../../../domain/usecases/set_password_usecase.dart';
import '../auth/auth_bloc.dart';

part 'account_security_state.dart';

@injectable
class AccountSecurityCubit extends Cubit<AccountSecurityState> {
  final CheckAuthMethodsUseCase checkAuthMethodsUseCase;
  final SetPasswordUseCase setPasswordUseCase;
  final AuthBloc authBloc;

  AccountSecurityCubit(
    this.checkAuthMethodsUseCase,
    this.setPasswordUseCase,
    this.authBloc,
  ) : super(const AccountSecurityState());

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
}
