import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/empresa_banco.dart';
import '../repositories/empresa_banco_repository.dart';

@injectable
class MarcarPrincipalUseCase {
  final EmpresaBancoRepository _repository;

  MarcarPrincipalUseCase(this._repository);

  Future<Resource<EmpresaBanco>> call({required String id}) {
    return _repository.marcarPrincipal(id: id);
  }
}
