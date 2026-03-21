import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/cuenta_por_cobrar.dart';
import '../repositories/cuentas_cobrar_repository.dart';

@injectable
class GetResumenCuentasCobrarUseCase {
  final CuentasCobrarRepository _repository;
  GetResumenCuentasCobrarUseCase(this._repository);

  Future<Resource<ResumenCuentasCobrar>> call() {
    return _repository.getResumen();
  }
}
