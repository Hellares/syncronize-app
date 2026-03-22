import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/agente_bancario.dart';
import '../repositories/agente_bancario_repository.dart';

@injectable
class GetResumenAgentesUseCase {
  final AgenteBancarioRepository _repository;
  GetResumenAgentesUseCase(this._repository);

  Future<Resource<ResumenAgentes>> call({String? sedeId}) {
    return _repository.getResumen(sedeId: sedeId);
  }
}
