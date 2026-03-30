import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/pago_suscripcion.dart';
import '../repositories/pago_suscripcion_repository.dart';

@injectable
class SolicitarPagoUseCase {
  final PagoSuscripcionRepository _repository;

  SolicitarPagoUseCase(this._repository);

  Future<Resource<PagoSuscripcion>> call({
    required String planSuscripcionId,
    required String periodo,
    required String metodoPago,
  }) {
    return _repository.solicitarPago(
      planSuscripcionId: planSuscripcionId,
      periodo: periodo,
      metodoPago: metodoPago,
    );
  }
}
