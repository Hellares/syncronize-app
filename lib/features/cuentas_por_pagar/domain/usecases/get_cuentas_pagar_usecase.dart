import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/cuenta_por_pagar.dart';
import '../repositories/cuentas_pagar_repository.dart';

@injectable
class GetCuentasPagarUseCase {
  final CuentasPagarRepository _repository;
  GetCuentasPagarUseCase(this._repository);

  Future<Resource<List<CuentaPorPagar>>> call({String? estado}) {
    return _repository.listar(estado: estado);
  }
}
