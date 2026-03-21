import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/rendicion_caja_chica.dart';
import '../repositories/caja_chica_repository.dart';

@injectable
class ListarRendicionesUseCase {
  final CajaChicaRepository _repository;

  ListarRendicionesUseCase(this._repository);

  Future<Resource<List<RendicionCajaChica>>> call({
    String? cajaChicaId,
    String? estado,
  }) {
    return _repository.listarRendiciones(
      cajaChicaId: cajaChicaId,
      estado: estado,
    );
  }
}
