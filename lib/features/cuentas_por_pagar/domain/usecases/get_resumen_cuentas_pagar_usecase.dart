import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/cuenta_por_pagar.dart';
import '../repositories/cuentas_pagar_repository.dart';

@injectable
class GetResumenCuentasPagarUseCase {
  final CuentasPagarRepository _repository;
  GetResumenCuentasPagarUseCase(this._repository);

  Future<Resource<ResumenCuentasPagar>> call() {
    return _repository.getResumen();
  }
}
