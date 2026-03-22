import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/agente_bancario.dart';
import '../repositories/agente_bancario_repository.dart';

@injectable
class CrearAgenteUseCase {
  final AgenteBancarioRepository _repository;
  CrearAgenteUseCase(this._repository);

  Future<Resource<AgenteBancario>> call(
      String sedeId, Map<String, dynamic> data) {
    return _repository.crear(sedeId, data);
  }
}
