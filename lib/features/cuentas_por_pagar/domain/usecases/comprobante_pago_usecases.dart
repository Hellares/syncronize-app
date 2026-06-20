import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/cuentas_pagar_repository.dart';

/// Sube un comprobante a S3 sin asociarlo a un pago (flujo "subir al pagar").
@injectable
class SubirComprobantePagoUseCase {
  final CuentasPagarRepository _repository;
  SubirComprobantePagoUseCase(this._repository);

  Future<Resource<String>> call(String filePath) => _repository.subirComprobante(filePath);
}

/// Adjunta un comprobante a un pago ya registrado (flujo del ícono en el historial).
@injectable
class AdjuntarComprobantePagoUseCase {
  final CuentasPagarRepository _repository;
  AdjuntarComprobantePagoUseCase(this._repository);

  Future<Resource<String>> call(String pagoId, String filePath) =>
      _repository.adjuntarComprobantePago(pagoId, filePath);
}
