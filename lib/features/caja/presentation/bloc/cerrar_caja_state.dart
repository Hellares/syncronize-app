import 'package:equatable/equatable.dart';
import '../../domain/entities/caja.dart';

/// Estados del CerrarCajaCubit — dedicado al flujo de cierre. No se
/// confunde con la noción de "caja activa del usuario actual"; sirve
/// tanto para cierre propio (cajero) como ajeno (admin sobre caja del
/// cajero desde el monitor).
abstract class CerrarCajaState extends Equatable {
  const CerrarCajaState();

  @override
  List<Object?> get props => [];
}

class CerrarCajaInitial extends CerrarCajaState {
  const CerrarCajaInitial();
}

class CerrarCajaSubmitting extends CerrarCajaState {
  const CerrarCajaSubmitting();
}

/// Cierre exitoso. Lleva la caja con su `cierre` adjunto para que la
/// UI pueda disparar auto-impresión del resumen antes de hacer pop.
class CerrarCajaSuccess extends CerrarCajaState {
  final Caja caja;

  const CerrarCajaSuccess(this.caja);

  @override
  List<Object?> get props => [caja];
}

class CerrarCajaError extends CerrarCajaState {
  final String message;

  const CerrarCajaError(this.message);

  @override
  List<Object?> get props => [message];
}
