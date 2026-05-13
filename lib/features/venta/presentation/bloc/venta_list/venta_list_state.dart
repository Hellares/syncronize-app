import 'package:equatable/equatable.dart';
import '../../../domain/entities/venta.dart';

abstract class VentaListState extends Equatable {
  const VentaListState();

  @override
  List<Object?> get props => [];
}

class VentaListInitial extends VentaListState {
  const VentaListInitial();
}

class VentaListLoading extends VentaListState {
  const VentaListLoading();
}

class VentaListLoaded extends VentaListState {
  final List<Venta> ventas;
  final EstadoVenta? filtroEstado;
  final String? filtroSedeId;
  /// Rango de fechas aplicado al listado. La página los lee para
  /// pintar el rango activo en `CustomDate` y mostrar el chip
  /// "Limpiar fechas". Backend recibe ISO UTC en `fechaDesde`/`fechaHasta`,
  /// acá los exponemos como `DateTime?` locales para la UI.
  final DateTime? filtroFechaDesde;
  final DateTime? filtroFechaHasta;

  const VentaListLoaded({
    required this.ventas,
    this.filtroEstado,
    this.filtroSedeId,
    this.filtroFechaDesde,
    this.filtroFechaHasta,
  });

  @override
  List<Object?> get props => [
        ventas,
        filtroEstado,
        filtroSedeId,
        filtroFechaDesde,
        filtroFechaHasta,
      ];
}

class VentaListError extends VentaListState {
  final String message;

  const VentaListError(this.message);

  @override
  List<Object?> get props => [message];
}
