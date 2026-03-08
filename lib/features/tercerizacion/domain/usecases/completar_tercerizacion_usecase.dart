import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/tercerizacion.dart';
import '../repositories/tercerizacion_repository.dart';

@injectable
class CompletarTercerizacionUseCase {
  final TercerizacionRepository _repository;

  CompletarTercerizacionUseCase(this._repository);

  Future<Resource<TercerizacionServicio>> call({
    required String id,
    required double precioB2B,
    String? metodoPagoB2B,
    String? notasDestino,
  }) async {
    return await _repository.completar(
      id: id,
      precioB2B: precioB2B,
      metodoPagoB2B: metodoPagoB2B,
      notasDestino: notasDestino,
    );
  }
}
