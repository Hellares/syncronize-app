import 'package:equatable/equatable.dart';
import '../../domain/entities/tipo_cambio.dart';

abstract class TipoCambioState extends Equatable {
  const TipoCambioState();
  @override
  List<Object?> get props => [];
}

class TipoCambioInitial extends TipoCambioState {
  const TipoCambioInitial();
}

class TipoCambioLoading extends TipoCambioState {
  const TipoCambioLoading();
}

class TipoCambioLoaded extends TipoCambioState {
  final TipoCambio? tipoCambioHoy;
  final List<TipoCambio> historial;
  final ConfiguracionMoneda? configuracion;

  const TipoCambioLoaded({
    this.tipoCambioHoy,
    this.historial = const [],
    this.configuracion,
  });

  @override
  List<Object?> get props => [tipoCambioHoy, historial, configuracion];
}

class TipoCambioError extends TipoCambioState {
  final String message;
  const TipoCambioError(this.message);
  @override
  List<Object?> get props => [message];
}
