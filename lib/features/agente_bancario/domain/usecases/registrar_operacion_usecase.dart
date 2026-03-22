import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/agente_bancario.dart';
import '../repositories/agente_bancario_repository.dart';

@injectable
class RegistrarOperacionUseCase {
  final AgenteBancarioRepository _repository;
  RegistrarOperacionUseCase(this._repository);

  Future<Resource<OperacionAgente>> call(
      String agenteId, Map<String, dynamic> data) {
    return _repository.registrarOperacion(agenteId, data);
  }
}
