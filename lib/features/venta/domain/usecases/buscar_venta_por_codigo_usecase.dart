import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/venta.dart';
import '../repositories/venta_repository.dart';

@injectable
class BuscarVentaPorCodigoUseCase {
  final VentaRepository _repository;
  BuscarVentaPorCodigoUseCase(this._repository);

  Future<Resource<Venta?>> call({required String codigo}) {
    return _repository.buscarPorCodigo(codigo: codigo);
  }
}
