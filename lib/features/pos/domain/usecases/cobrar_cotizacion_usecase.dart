import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../../venta/domain/entities/venta.dart';
import '../repositories/pos_repository.dart';

@injectable
class CobrarCotizacionUseCase {
  final PosRepository _repository;

  CobrarCotizacionUseCase(this._repository);

  Future<Resource<Venta>> call({
    required String cotizacionId,
    required Map<String, dynamic> data,
  }) {
    return _repository.cobrarCotizacion(cotizacionId: cotizacionId, data: data);
  }
}
