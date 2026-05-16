import 'package:equatable/equatable.dart';
import '../../domain/entities/dashboard_gastos.dart';
import '../../domain/entities/pago_gasto_recurrente.dart';

abstract class PagarGastoState extends Equatable {
  const PagarGastoState();
  @override
  List<Object?> get props => [];
}

class PagarGastoInitial extends PagarGastoState {
  const PagarGastoInitial();
}

class PagarGastoUploading extends PagarGastoState {
  const PagarGastoUploading();
}

class PagarGastoComprobanteSubido extends PagarGastoState {
  final ComprobanteUploadResult comprobante;
  const PagarGastoComprobanteSubido(this.comprobante);
  @override
  List<Object?> get props => [comprobante];
}

class PagarGastoEnviando extends PagarGastoState {
  const PagarGastoEnviando();
}

class PagarGastoOk extends PagarGastoState {
  final PagoGastoRecurrente pago;
  const PagarGastoOk(this.pago);
  @override
  List<Object?> get props => [pago];
}

class PagarGastoError extends PagarGastoState {
  final String message;
  const PagarGastoError(this.message);
  @override
  List<Object?> get props => [message];
}
