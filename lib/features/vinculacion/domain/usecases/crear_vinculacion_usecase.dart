import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/vinculacion.dart';
import '../repositories/vinculacion_repository.dart';

@injectable
class CrearVinculacionUseCase {
  final VinculacionRepository _repository;

  CrearVinculacionUseCase(this._repository);

  Future<Resource<VinculacionEmpresa>> call({
    String? clienteEmpresaId,
    String? ruc,
    String? mensaje,
  }) async {
    return await _repository.crear(
      clienteEmpresaId: clienteEmpresaId,
      ruc: ruc,
      mensaje: mensaje,
    );
  }
}
