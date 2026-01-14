import 'package:injectable/injectable.dart';
import '../entities/unidad_medida.dart';
import '../repositories/unidad_medida_repository.dart';

/// UseCase para obtener las unidades de medida activadas por una empresa
@injectable
class GetUnidadesEmpresaUseCase {
  final UnidadMedidaRepository _repository;

  GetUnidadesEmpresaUseCase(this._repository);

  /// Obtiene las unidades de medida activadas para una empresa
  ///
  /// [empresaId] - ID de la empresa
  Future<List<EmpresaUnidadMedida>> call(String empresaId) async {
    return await _repository.getUnidadesEmpresa(empresaId);
  }
}
