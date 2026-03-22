import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/tipo_cambio.dart';
import '../repositories/tipo_cambio_repository.dart';

@injectable
class GetHistorialTipoCambioUseCase {
  final TipoCambioRepository _repository;
  GetHistorialTipoCambioUseCase(this._repository);

  Future<Resource<List<TipoCambio>>> call({
    String? fechaDesde,
    String? fechaHasta,
    int? limit,
  }) {
    return _repository.getHistorial(
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
      limit: limit,
    );
  }
}
