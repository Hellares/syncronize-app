import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/cuentas_cobrar_repository.dart';

@injectable
class RegistrarAbonoCuentaCobrarUseCase {
  final CuentasCobrarRepository _repository;
  RegistrarAbonoCuentaCobrarUseCase(this._repository);

  Future<Resource<void>> call(
    String ventaId, {
    required String metodoPago,
    required double monto,
    String? referencia,
  }) {
    return _repository.registrarAbono(
      ventaId,
      metodoPago: metodoPago,
      monto: monto,
      referencia: referencia,
    );
  }
}
