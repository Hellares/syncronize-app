import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/cuenta_por_pagar.dart';
import '../repositories/cuentas_pagar_repository.dart';

@injectable
class GetDetalleCuentaPagarUseCase {
  final CuentasPagarRepository _repository;
  GetDetalleCuentaPagarUseCase(this._repository);

  Future<Resource<CuentaPagarDetalle>> call(String compraId) {
    return _repository.getDetalle(compraId);
  }
}
