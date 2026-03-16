import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/venta.dart';
import '../repositories/venta_repository.dart';

@injectable
class AnularVentaUseCase {
  final VentaRepository _repository;

  AnularVentaUseCase(this._repository);

  Future<Resource<Venta>> call({required String ventaId}) {
    return _repository.anularVenta(ventaId: ventaId);
  }
}
