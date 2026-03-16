import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/venta.dart';
import '../repositories/venta_repository.dart';

@injectable
class GetVentaUseCase {
  final VentaRepository _repository;

  GetVentaUseCase(this._repository);

  Future<Resource<Venta>> call({required String ventaId}) {
    return _repository.getVenta(ventaId: ventaId);
  }
}
