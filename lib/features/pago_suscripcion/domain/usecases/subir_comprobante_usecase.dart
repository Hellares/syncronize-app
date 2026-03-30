import 'dart:io';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/pago_suscripcion_repository.dart';

@injectable
class SubirComprobantePagoUseCase {
  final PagoSuscripcionRepository _repository;

  SubirComprobantePagoUseCase(this._repository);

  Future<Resource<String>> call({
    required String pagoId,
    required File file,
  }) {
    return _repository.subirComprobante(pagoId, file);
  }
}
