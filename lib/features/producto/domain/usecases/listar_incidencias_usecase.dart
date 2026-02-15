import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/transferencia_incidencia.dart';
import '../repositories/producto_repository.dart';

@injectable
class ListarIncidenciasUseCase {
  final ProductoRepository _repository;

  ListarIncidenciasUseCase(this._repository);

  Future<Resource<List<TransferenciaIncidencia>>> call({
    required String empresaId,
    bool? resuelto,
    String? tipo,
    String? sedeId,
    String? transferenciaId,
  }) async {
    return await _repository.listarIncidencias(
      empresaId: empresaId,
      resuelto: resuelto,
      tipo: tipo,
      sedeId: sedeId,
      transferenciaId: transferenciaId,
    );
  }
}
