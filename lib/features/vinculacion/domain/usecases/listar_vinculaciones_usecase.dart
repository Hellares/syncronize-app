import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/vinculacion.dart';
import '../repositories/vinculacion_repository.dart';

@injectable
class ListarVinculacionesUseCase {
  final VinculacionRepository _repository;

  ListarVinculacionesUseCase(this._repository);

  Future<Resource<VinculacionesPaginadas>> call({
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
