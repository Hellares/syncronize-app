import 'package:equatable/equatable.dart';
import '../../../domain/entities/compra_analytics.dart';

abstract class GastosFacturaState extends Equatable {
  const GastosFacturaState();

  @override
  List<Object?> get props => [];
}

class GastosFacturaInitial extends GastosFacturaState {
  const GastosFacturaInitial();
}

class GastosFacturaLoading extends GastosFacturaState {
  const GastosFacturaLoading();
}

class GastosFacturaLoaded extends GastosFacturaState {
  final GastosFacturaReporte reporte;

  const GastosFacturaLoaded(this.reporte);

  @override
  List<Object?> get props => [reporte];
}

class GastosFacturaError extends GastosFacturaState {
  final String message;

  const GastosFacturaError(this.message);

  @override
  List<Object?> get props => [message];
}
