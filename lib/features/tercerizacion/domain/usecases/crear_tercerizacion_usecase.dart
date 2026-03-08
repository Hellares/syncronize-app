import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/tercerizacion.dart';
import '../repositories/tercerizacion_repository.dart';

@injectable
class CrearTercerizacionUseCase {
  final TercerizacionRepository _repository;

  CrearTercerizacionUseCase(this._repository);

  Future<Resource<TercerizacionServicio>> call({
    required String empresaDestinoId,
    required String ordenOrigenId,
    String? notasOrigen,
    String? descripcionProblema,
    List<String>? sintomas,
  }) async {
    return await _repository.crear(
      empresaDestinoId: empresaDestinoId,
      ordenOrigenId: ordenOrigenId,
      notasOrigen: notasOrigen,
      descripcionProblema: descripcionProblema,
      sintomas: sintomas,
    );
  }
}
