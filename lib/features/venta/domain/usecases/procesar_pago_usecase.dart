import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/venta.dart';
import '../repositories/venta_repository.dart';

@injectable
class ProcesarPagoUseCase {
  final VentaRepository _repository;

  ProcesarPagoUseCase(this._repository);

  Future<Resource<Venta>> call({
    required String ventaId,
    required Map<String, dynamic> data,
  }) {
    return _repository.procesarPago(ventaId: ventaId, data: data);
  }
}
