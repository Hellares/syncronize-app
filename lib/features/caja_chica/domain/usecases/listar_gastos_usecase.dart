import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/gasto_caja_chica.dart';
import '../repositories/caja_chica_repository.dart';

@injectable
class ListarGastosUseCase {
  final CajaChicaRepository _repository;

  ListarGastosUseCase(this._repository);

  Future<Resource<List<GastoCajaChica>>> call({
    required String cajaChicaId,
    bool? pendientes,
  }) {
    return _repository.listarGastos(
      cajaChicaId: cajaChicaId,
      pendientes: pendientes,
    );
  }
}
