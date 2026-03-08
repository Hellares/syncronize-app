import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/aviso_mantenimiento.dart';
import '../repositories/aviso_mantenimiento_repository.dart';

@injectable
class GetAvisoResumenUseCase {
  final AvisoMantenimientoRepository _repository;

  GetAvisoResumenUseCase(this._repository);

  Future<Resource<AvisoResumen>> call() {
    return _repository.getResumen();
  }
}
