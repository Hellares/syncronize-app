import 'package:equatable/equatable.dart';
import '../../../domain/entities/cotizacion.dart';

/// Estados para el formulario de cotizacion
abstract class CotizacionFormState extends Equatable {
  const CotizacionFormState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial del formulario
class CotizacionFormInitial extends CotizacionFormState {
  const CotizacionFormInitial();
}

/// Estado de carga (creando/actualizando)
class CotizacionFormLoading extends CotizacionFormState {
  const CotizacionFormLoading();
}

/// Cotizacion creada/actualizada exitosamente
class CotizacionFormSuccess extends CotizacionFormState {
  final Cotizacion cotizacion;
  final String message;

  const CotizacionFormSuccess({
    required this.cotizacion,
    required this.message,
  });

  @override
  List<Object?> get props => [cotizacion, message];
}

/// Error en el formulario
class CotizacionFormError extends CotizacionFormState {
  final String message;

  const CotizacionFormError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Estado de cambio de estado exitoso
class CotizacionEstadoUpdated extends CotizacionFormState {
  final Cotizacion cotizacion;

  const CotizacionEstadoUpdated(this.cotizacion);

  @override
  List<Object?> get props => [cotizacion];
}

/// Cotizacion eliminada exitosamente
class CotizacionFormDeleted extends CotizacionFormState {
  final String message;

  const CotizacionFormDeleted({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Resultado de validacion de compatibilidad
class CotizacionCompatibilidadResult extends CotizacionFormState {
  final bool compatible;
  final List<Map<String, dynamic>> conflictos;

  const CotizacionCompatibilidadResult({
    required this.compatible,
    required this.conflictos,
  });

  @override
  List<Object?> get props => [compatible, conflictos];
}
