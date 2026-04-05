import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/venta.dart';
import '../repositories/venta_repository.dart';

@injectable
class ConfirmarVentaUseCase {
  final VentaRepository _repository;

  ConfirmarVentaUseCase(this._repository);

  Future<Resource<Venta>> call({required String ventaId}) {
    return _repository.confirmarVenta(ventaId: ventaId);
  }
}
