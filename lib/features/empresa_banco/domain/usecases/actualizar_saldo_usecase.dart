import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/empresa_banco.dart';
import '../repositories/empresa_banco_repository.dart';

@injectable
class ActualizarSaldoUseCase {
  final EmpresaBancoRepository _repository;

  ActualizarSaldoUseCase(this._repository);

  Future<Resource<EmpresaBanco>> call({
    required String id,
    required double saldo,
  }) {
    return _repository.actualizarSaldo(id: id, saldo: saldo);
  }
}
