import 'package:equatable/equatable.dart';
import '../../../domain/entities/politica_descuento.dart';

/// Estados para el formulario de política de descuento
abstract class PoliticaFormState extends Equatable {
  const PoliticaFormState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class PoliticaFormInitial extends PoliticaFormState {
  const PoliticaFormInitial();
}

/// Estado de carga (enviando formulario)
class PoliticaFormLoading extends PoliticaFormState {
  const PoliticaFormLoading();
}

/// Estado de éxito al crear
class PoliticaFormCreateSuccess extends PoliticaFormState {
  final PoliticaDescuento politica;

  const PoliticaFormCreateSuccess(this.politica);

  @override
  List<Object?> get props => [politica];
}

/// Estado de éxito al cargar política para edición
class PoliticaFormLoadSuccess extends PoliticaFormState {
  final PoliticaDescuento politica;

  const PoliticaFormLoadSuccess(this.politica);

  @override
  List<Object?> get props => [politica];
}

/// Estado de éxito al actualizar
class PoliticaFormUpdateSuccess extends PoliticaFormState {
  final PoliticaDescuento politica;

  const PoliticaFormUpdateSuccess(this.politica);

  @override
  List<Object?> get props => [politica];
}

/// Estado de error
class PoliticaFormError extends PoliticaFormState {
  final String message;
  final String? errorCode;

  const PoliticaFormError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}
