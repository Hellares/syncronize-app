import 'package:equatable/equatable.dart';
import '../../../../empresa/domain/entities/sede.dart';

/// Estados del formulario de sede
abstract class SedeFormState extends Equatable {
  const SedeFormState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class SedeFormInitial extends SedeFormState {
  const SedeFormInitial();
}

/// Estado de carga (obteniendo datos de sede para editar)
class SedeFormLoading extends SedeFormState {
  const SedeFormLoading();
}

/// Estado listo con datos de sede (para edición)
class SedeFormReady extends SedeFormState {
  final Sede? sede; // null si es creación, con datos si es edición

  const SedeFormReady({this.sede});

  @override
  List<Object?> get props => [sede];
}

/// Estado de envío (guardando cambios)
class SedeFormSubmitting extends SedeFormState {
  const SedeFormSubmitting();
}

/// Estado de éxito al guardar
class SedeFormSuccess extends SedeFormState {
  final Sede sede;
  final bool isEdit;

  const SedeFormSuccess(this.sede, {required this.isEdit});

  @override
  List<Object?> get props => [sede, isEdit];
}

/// Estado de error
class SedeFormError extends SedeFormState {
  final String message;
  final String? errorCode;

  const SedeFormError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}
