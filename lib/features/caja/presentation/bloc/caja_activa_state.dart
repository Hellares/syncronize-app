import 'package:equatable/equatable.dart';
import '../../domain/entities/caja.dart';

abstract class CajaActivaState extends Equatable {
  const CajaActivaState();

  @override
  List<Object?> get props => [];
}

class CajaActivaInitial extends CajaActivaState {
  const CajaActivaInitial();
}

class CajaActivaLoading extends CajaActivaState {
  const CajaActivaLoading();
}

class CajaActivaAbierta extends CajaActivaState {
  final Caja caja;

  const CajaActivaAbierta(this.caja);

  @override
  List<Object?> get props => [caja];
}

class CajaActivaSinCaja extends CajaActivaState {
  const CajaActivaSinCaja();
}

/// Emitido inmediatamente despues de cerrar caja con exito. Lleva la
/// caja recien cerrada con su `cierre` adjunto para que la UI pueda
/// disparar la auto-impresion del resumen antes de pasar a
/// `CajaActivaSinCaja`. Es un estado transitorio (~1 frame).
class CajaActivaRecienCerrada extends CajaActivaState {
  final Caja caja;

  const CajaActivaRecienCerrada(this.caja);

  @override
  List<Object?> get props => [caja];
}

class CajaActivaError extends CajaActivaState {
  final String message;

  const CajaActivaError(this.message);

  @override
  List<Object?> get props => [message];
}
