import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/incidencia_item_request.dart';
import '../repositories/producto_repository.dart';

@injectable
class RecibirTransferenciaConIncidenciasUseCase {
  final ProductoRepository _repository;

  RecibirTransferenciaConIncidenciasUseCase(this._repository);

  Future<Resource<Map<String, dynamic>>> call({
    required String transferenciaId,
    required String empresaId,
    required RecibirTransferenciaConIncidenciasRequest request,
  }) async {
    return await _repository.recibirTransferenciaConIncidencias(
      transferenciaId: transferenciaId,
      empresaId: empresaId,
      request: request.toJson(),
    );
  }
}
