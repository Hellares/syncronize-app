import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/empresa_banco_repository.dart';

@injectable
class EliminarCuentaBancariaUseCase {
  final EmpresaBancoRepository _repository;

  EliminarCuentaBancariaUseCase(this._repository);

  Future<Resource<void>> call({required String id}) {
    return _repository.eliminar(id: id);
  }
}
