import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/tercerizacion.dart';
import '../repositories/tercerizacion_repository.dart';

@injectable
class ListarTercerizacionesUseCase {
  final TercerizacionRepository _repository;

  ListarTercerizacionesUseCase(this._repository);

  Future<Resource<TercerizacionesPaginadas>> call({
    required String empresaId,
    String? tipo,
    String? estado,
    int page = 1,
    int limit = 20,
  }) async {
    return await _repository.listar(
      empresaId: empresaId,
      tipo: tipo,
      estado: estado,
      page: page,
      limit: limit,
    );
  }
}
