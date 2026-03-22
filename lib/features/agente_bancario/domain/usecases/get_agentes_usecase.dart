import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/agente_bancario.dart';
import '../repositories/agente_bancario_repository.dart';

@injectable
class GetAgentesUseCase {
  final AgenteBancarioRepository _repository;
  GetAgentesUseCase(this._repository);

  Future<Resource<List<AgenteBancario>>> call({String? sedeId}) {
    return _repository.getAgentes(sedeId: sedeId);
  }
}
