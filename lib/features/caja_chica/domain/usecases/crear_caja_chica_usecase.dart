import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/caja_chica.dart';
import '../repositories/caja_chica_repository.dart';

@injectable
class CrearCajaChicaUseCase {
  final CajaChicaRepository _repository;

  CrearCajaChicaUseCase(this._repository);

  Future<Resource<CajaChica>> call({
    required String sedeId,
    required String nombre,
    required double fondoFijo,
    double? umbralAlerta,
    required String responsableId,
  }) {
    return _repository.crearCajaChica(
      sedeId: sedeId,
      nombre: nombre,
      fondoFijo: fondoFijo,
      umbralAlerta: umbralAlerta,
      responsableId: responsableId,
    );
  }
}
