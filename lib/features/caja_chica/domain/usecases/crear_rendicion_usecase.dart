import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/rendicion_caja_chica.dart';
import '../repositories/caja_chica_repository.dart';

@injectable
class CrearRendicionUseCase {
  final CajaChicaRepository _repository;

  CrearRendicionUseCase(this._repository);

  Future<Resource<RendicionCajaChica>> call({
    required String cajaChicaId,
    required List<String> gastoIds,
    String? observaciones,
  }) {
    return _repository.crearRendicion(
      cajaChicaId: cajaChicaId,
      gastoIds: gastoIds,
      observaciones: observaciones,
    );
  }
}
