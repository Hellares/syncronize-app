import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/empresa_banco.dart';
import '../repositories/empresa_banco_repository.dart';

@injectable
class GetCuentasBancariasUseCase {
  final EmpresaBancoRepository _repository;

  GetCuentasBancariasUseCase(this._repository);

  Future<Resource<List<EmpresaBanco>>> call() {
    return _repository.listar();
  }
}
