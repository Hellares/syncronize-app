import 'package:equatable/equatable.dart';
import '../../../venta/domain/entities/venta.dart';
import '../../domain/entities/cobrar_cotizacion_data.dart';

sealed class CobrarPosState extends Equatable {
  const CobrarPosState();
}

final class CobrarPosInitial extends CobrarPosState {
  const CobrarPosInitial();
  @override
  List<Object?> get props => [];
}

final class CobrarPosLoading extends CobrarPosState {
  const CobrarPosLoading();
  @override
  List<Object?> get props => [];
}

final class CobrarPosLoaded extends CobrarPosState {
  final CobrarCotizacionData data;
  const CobrarPosLoaded(this.data);
  @override
  List<Object?> get props => [data];
}

final class CobrarPosProcesando extends CobrarPosState {
  const CobrarPosProcesando();
  @override
  List<Object?> get props => [];
}

final class CobrarPosCobrado extends CobrarPosState {
  final Venta venta;
  const CobrarPosCobrado(this.venta);
  @override
  List<Object?> get props => [venta];
}

final class CobrarPosError extends CobrarPosState {
  final String message;
  const CobrarPosError(this.message);
  @override
  List<Object?> get props => [message];
}
