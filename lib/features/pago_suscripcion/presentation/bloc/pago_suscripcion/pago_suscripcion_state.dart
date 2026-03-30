part of 'pago_suscripcion_cubit.dart';

abstract class PagoSuscripcionState extends Equatable {
  const PagoSuscripcionState();

  @override
  List<Object?> get props => [];
}

class PagoSuscripcionInitial extends PagoSuscripcionState {
  const PagoSuscripcionInitial();
}

class PagoSuscripcionLoading extends PagoSuscripcionState {
  const PagoSuscripcionLoading();
}

class PagoSuscripcionCreated extends PagoSuscripcionState {
  final PagoSuscripcion pago;

  const PagoSuscripcionCreated(this.pago);

  @override
  List<Object?> get props => [pago];
}

class PagoSuscripcionUploadingComprobante extends PagoSuscripcionState {
  const PagoSuscripcionUploadingComprobante();
}

class PagoSuscripcionComprobanteUploaded extends PagoSuscripcionState {
  final String url;

  const PagoSuscripcionComprobanteUploaded(this.url);

  @override
  List<Object?> get props => [url];
}

class PagoSuscripcionError extends PagoSuscripcionState {
  final String message;

  const PagoSuscripcionError(this.message);

  @override
  List<Object?> get props => [message];
}
