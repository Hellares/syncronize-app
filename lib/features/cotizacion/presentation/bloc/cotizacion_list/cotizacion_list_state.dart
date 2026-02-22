import 'package:equatable/equatable.dart';
import '../../../domain/entities/cotizacion.dart';

/// Estados para la lista de cotizaciones
abstract class CotizacionListState extends Equatable {
  const CotizacionListState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class CotizacionListInitial extends CotizacionListState {
  const CotizacionListInitial();
}

/// Estado de carga
class CotizacionListLoading extends CotizacionListState {
  const CotizacionListLoading();
}

/// Estado con datos cargados
class CotizacionListLoaded extends CotizacionListState {
  final List<Cotizacion> cotizaciones;
  final EstadoCotizacion? filtroEstado;
  final String? filtroSedeId;

  const CotizacionListLoaded({
    required this.cotizaciones,
    this.filtroEstado,
    this.filtroSedeId,
  });

  @override
  List<Object?> get props => [cotizaciones, filtroEstado, filtroSedeId];
}

/// Estado de error
class CotizacionListError extends CotizacionListState {
  final String message;

  const CotizacionListError(this.message);

  @override
  List<Object?> get props => [message];
}
