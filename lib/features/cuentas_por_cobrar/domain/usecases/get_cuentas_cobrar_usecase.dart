import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/cuenta_por_cobrar.dart';
import '../repositories/cuentas_cobrar_repository.dart';

@injectable
class GetCuentasCobrarUseCase {
  final CuentasCobrarRepository _repository;
  GetCuentasCobrarUseCase(this._repository);

  Future<Resource<List<CuentaPorCobrar>>> call({String? estado, String? sedeId}) {
    return _repository.listar(estado: estado, sedeId: sedeId);
  }
}
