import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/aviso_mantenimiento.dart';
import '../repositories/aviso_mantenimiento_repository.dart';

@injectable
class UpdateEstadoAvisoUseCase {
  final AvisoMantenimientoRepository _repository;

  UpdateEstadoAvisoUseCase(this._repository);

  Future<Resource<AvisoMantenimiento>> call(
    String id, {
    required String nuevoEstado,
    String? notas,
  }) {
    return _repository.updateEstado(id, nuevoEstado: nuevoEstado, notas: notas);
  }
}
