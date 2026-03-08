import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/directorio_empresa.dart';
import '../repositories/tercerizacion_repository.dart';

@injectable
class BuscarEmpresasUseCase {
  final TercerizacionRepository _repository;

  BuscarEmpresasUseCase(this._repository);

  Future<Resource<DirectorioPaginado>> call({
    required String empresaId,
    String? search,
    String? tipoServicio,
    String? departamento,
    String? distrito,
    int page = 1,
    int limit = 20,
  }) async {
    return await _repository.buscarEmpresas(
      empresaId: empresaId,
      search: search,
      tipoServicio: tipoServicio,
      departamento: departamento,
      distrito: distrito,
      page: page,
      limit: limit,
    );
  }
}
