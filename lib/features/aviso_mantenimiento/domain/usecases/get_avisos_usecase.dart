import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/aviso_mantenimiento.dart';
import '../repositories/aviso_mantenimiento_repository.dart';

@injectable
class GetAvisosUseCase {
  final AvisoMantenimientoRepository _repository;

  GetAvisosUseCase(this._repository);

  Future<Resource<List<AvisoMantenimiento>>> call({
    String? estado,
    String? clienteId,
    String? tipoServicio,
    String? cursor,
    int limit = 20,
  }) {
    return _repository.getAvisos(
      estado: estado,
      clienteId: clienteId,
      tipoServicio: tipoServicio,
      cursor: cursor,
      limit: limit,
    );
  }
}
