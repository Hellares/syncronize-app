import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/caja.dart';
import '../repositories/caja_repository.dart';

@injectable
class GetHistorialUseCase {
  final CajaRepository _repository;

  GetHistorialUseCase(this._repository);

  Future<Resource<List<Caja>>> call({
    String? sedeId,
    String? fechaDesde,
    String? fechaHasta,
  }) {
    return _repository.getHistorial(
      sedeId: sedeId,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
  }
}
