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

  const VentaListLoaded({
    required this.ventas,
    this.filtroEstado,
    this.filtroSedeId,
  });

  @override
  List<Object?> get props => [ventas, filtroEstado, filtroSedeId];
}

class VentaListError extends VentaListState {
  final String message;

  const VentaListError(this.message);

  @override
  List<Object?> get props => [message];
}
