import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/compra_repository.dart';

@injectable
class ExportComprasPorProductoUseCase {
  final CompraRepository _repository;

  ExportComprasPorProductoUseCase(this._repository);

  Future<Resource<List<int>>> call({
    required String empresaId,
    required String fechaInicio,
    required String fechaFin,
    String? sedeId,
    void Function(int, int)? onReceiveProgress,
  }) async {
    return await _repository.exportComprasPorProducto(
      empresaId: empresaId,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      sedeId: sedeId,
      onReceiveProgress: onReceiveProgress,
    );
  }
}

@injectable
class ExportComprasPorProveedorUseCase {
  final CompraRepository _repository;

  ExportComprasPorProveedorUseCase(this._repository);

  Future<Resource<List<int>>> call({
    required String empresaId,
    required String fechaInicio,
    required String fechaFin,
    String? sedeId,
    void Function(int, int)? onReceiveProgress,
  }) async {
    return await _repository.exportComprasPorProveedor(
      empresaId: empresaId,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      sedeId: sedeId,
      onReceiveProgress: onReceiveProgress,
    );
  }
}
