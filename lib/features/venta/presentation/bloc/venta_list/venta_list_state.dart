import 'package:equatable/equatable.dart';
import '../../../domain/entities/venta.dart';
import '../../../domain/entities/ventas_page.dart';

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

  /// Canal aplicado (server-side): POS | ONLINE | COTIZACION | null=todos.
  final String? filtroCanal;

  /// Paginación por cursor.
  final bool hasMore;
  final bool isLoadingMore;

  /// Agregado por estado sobre TODO el set filtrado (chip del total y
  /// conteos de anuladas/borradores exactos aunque haya páginas sin cargar).
  final List<VentasResumenEstado> resumen;

  const VentaListLoaded({
    required this.ventas,
    this.filtroEstado,
    this.filtroSedeId,
    this.filtroFechaDesde,
    this.filtroFechaHasta,
    this.filtroCanal,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.resumen = const [],
  });

  VentaListLoaded copyWith({
    List<Venta>? ventas,
    bool? hasMore,
    bool? isLoadingMore,
    List<VentasResumenEstado>? resumen,
  }) {
    return VentaListLoaded(
      ventas: ventas ?? this.ventas,
      filtroEstado: filtroEstado,
      filtroSedeId: filtroSedeId,
      filtroFechaDesde: filtroFechaDesde,
      filtroFechaHasta: filtroFechaHasta,
      filtroCanal: filtroCanal,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      resumen: resumen ?? this.resumen,
    );
  }

  @override
  List<Object?> get props => [
        ventas,
        filtroEstado,
        filtroSedeId,
        filtroFechaDesde,
        filtroFechaHasta,
        filtroCanal,
        hasMore,
        isLoadingMore,
        resumen,
      ];
}

class VentaListError extends VentaListState {
  final String message;

  const VentaListError(this.message);

  @override
  List<Object?> get props => [message];
}
