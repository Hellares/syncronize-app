import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/incidencia_item_request.dart';
import '../entities/transferencia_incidencia.dart';
import '../repositories/producto_repository.dart';

@injectable
class ResolverIncidenciaUseCase {
  final ProductoRepository _repository;

  ResolverIncidenciaUseCase(this._repository);

  Future<Resource<TransferenciaIncidencia>> call({
    required String incidenciaId,
    required String empresaId,
    required ResolverIncidenciaRequest request,
  }) async {
    return await _repository.resolverIncidencia(
      incidenciaId: incidenciaId,
      empresaId: empresaId,
      request: request.toJson(),
    );
  }
}
