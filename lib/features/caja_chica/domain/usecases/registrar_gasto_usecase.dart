import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/gasto_caja_chica.dart';
import '../repositories/caja_chica_repository.dart';

@injectable
class RegistrarGastoUseCase {
  final CajaChicaRepository _repository;

  RegistrarGastoUseCase(this._repository);

  Future<Resource<GastoCajaChica>> call({
    required String cajaChicaId,
    required double monto,
    required String descripcion,
    required String categoriaGastoId,
    String? comprobanteUrl,
  }) {
    return _repository.registrarGasto(
      cajaChicaId: cajaChicaId,
      monto: monto,
      descripcion: descripcion,
      categoriaGastoId: categoriaGastoId,
      comprobanteUrl: comprobanteUrl,
    );
  }
}
