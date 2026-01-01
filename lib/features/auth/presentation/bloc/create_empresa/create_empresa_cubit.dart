import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/usecases/create_empresa_usecase.dart';
import '../../../domain/entities/rubro_empresa.dart';
import '../../../../../core/utils/resource.dart';
import '../../../../../core/utils/bloc_form_item.dart';

part 'create_empresa_state.dart';

/// Cubit para manejar el formulario y lógica de crear empresa
@injectable
class CreateEmpresaCubit extends Cubit<CreateEmpresaState> {
  final CreateEmpresaUseCase createEmpresaUseCase;

  CreateEmpresaCubit({required this.createEmpresaUseCase})
      : super(const CreateEmpresaState());

  /// Actualizar nombre
  void nombreChanged(String value) {
    emit(state.copyWith(
      nombre: BlocFormItem(value: value, error: _validateNombre(value)),
      response: null,
    ));
  }

  /// Actualizar RUC
  void rucChanged(String value) {
    emit(state.copyWith(
      ruc: BlocFormItem(value: value, error: _validateRuc(value)),
      response: null,
    ));
  }

  /// Actualizar descripción
  void descripcionChanged(String value) {
    emit(state.copyWith(
      descripcion: BlocFormItem(value: value, error: null),
      response: null,
    ));
  }

  /// Actualizar teléfono
  void telefonoChanged(String value) {
    emit(state.copyWith(
      telefono: BlocFormItem(value: value, error: _validateTelefono(value)),
      response: null,
    ));
  }

  /// Actualizar email
  void emailChanged(String value) {
    emit(state.copyWith(
      email: BlocFormItem(value: value, error: _validateEmail(value)),
      response: null,
    ));
  }

  /// Actualizar web
  void webChanged(String value) {
    emit(state.copyWith(
      web: BlocFormItem(value: value, error: _validateWeb(value)),
      response: null,
    ));
  }

  /// Actualizar subdominio
  void subdominioChanged(String value) {
    emit(state.copyWith(
      subdominio: BlocFormItem(value: value, error: _validateSubdominio(value)),
      response: null,
    ));
  }

  /// Actualizar rubro
  void rubroChanged(String value) {
    emit(state.copyWith(
      rubro: BlocFormItem(value: value, error: _validateRubro(value)),
      response: null,
    ));
  }

  /// Validaciones
  String? _validateNombre(String value) {
    if (value.isEmpty) return 'El nombre de la empresa es requerido';
    if (value.length < 3) return 'Mínimo 3 caracteres';
    if (value.length > 100) return 'Máximo 100 caracteres';
    return null;
  }

  String? _validateRuc(String value) {
    if (value.isEmpty) return null; // Es opcional
    if (value.length != 11) return 'El RUC debe tener 11 dígitos';
    if (!RegExp(r'^\d+$').hasMatch(value)) return 'Solo números';
    return null;
  }

  String? _validateTelefono(String value) {
    if (value.isEmpty) return null; // Es opcional
    if (value.length < 9) return 'Teléfono inválido';
    if (value.length > 20) return 'Teléfono muy largo';
    return null;
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) return null; // Es opcional
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Email inválido';
    return null;
  }

  String? _validateWeb(String value) {
    if (value.isEmpty) return null; // Es opcional
    if (value.length > 255) return 'URL muy larga';
    return null;
  }

  String? _validateSubdominio(String value) {
    if (value.isEmpty) return null; // Es opcional
    // Validar formato de subdominio (lowercase, alphanumeric, hyphens)
    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(value)) {
      return 'Solo minúsculas, números y guiones';
    }
    if (value.length < 3) return 'Mínimo 3 caracteres';
    if (value.length > 50) return 'Máximo 50 caracteres';
    return null;
  }

  String? _validateRubro(String value) {
    if (value.isEmpty) return 'El rubro es requerido';
    // Verificar que el valor sea uno de los valores del enum RubroEmpresa
    try {
      RubroEmpresa.fromString(value);
      return null;
    } catch (_) {
      return 'Rubro no válido';
    }
  }

  /// Validar formulario completo
  bool _isFormValid() {
    return _validateNombre(state.nombre.value) == null &&
        _validateRuc(state.ruc.value) == null &&
        _validateTelefono(state.telefono.value) == null &&
        _validateEmail(state.email.value) == null &&
        _validateWeb(state.web.value) == null &&
        _validateSubdominio(state.subdominio.value) == null &&
        _validateRubro(state.rubro.value) == null;
  }

  /// Crear empresa
  Future<void> createEmpresa() async {
    // Validar formulario
    if (!_isFormValid()) {
      emit(state.copyWith(
        nombre: state.nombre.copyWith(error: _validateNombre(state.nombre.value)),
        ruc: state.ruc.copyWith(error: _validateRuc(state.ruc.value)),
        telefono: state.telefono.copyWith(error: _validateTelefono(state.telefono.value)),
        email: state.email.copyWith(error: _validateEmail(state.email.value)),
        web: state.web.copyWith(error: _validateWeb(state.web.value)),
        subdominio: state.subdominio.copyWith(error: _validateSubdominio(state.subdominio.value)),
        rubro: state.rubro.copyWith(error: _validateRubro(state.rubro.value)),
      ));
      return;
    }

    // Emitir Loading
    emit(state.copyWith(response: Loading()));

    final params = CreateEmpresaParams(
      nombre: state.nombre.value.trim(),
      rubro: RubroEmpresa.fromString(state.rubro.value.trim()),
      ruc: state.ruc.value.trim().isEmpty ? null : state.ruc.value.trim(),
      descripcion: state.descripcion.value.trim().isEmpty
          ? null
          : state.descripcion.value.trim(),
      telefono: state.telefono.value.trim().isEmpty
          ? null
          : state.telefono.value.trim(),
      email: state.email.value.trim().isEmpty ? null : state.email.value.trim(),
      web: state.web.value.trim().isEmpty ? null : state.web.value.trim(),
      subdominio: state.subdominio.value.trim().isEmpty
          ? null
          : state.subdominio.value.trim(),
    );

    final result = await createEmpresaUseCase(params);

    // Actualizar estado con resultado
    emit(state.copyWith(response: result));
  }

  /// Resetear formulario
  void reset() {
    emit(const CreateEmpresaState());
  }
}
