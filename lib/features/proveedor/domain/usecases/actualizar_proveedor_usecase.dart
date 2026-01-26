import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/proveedor.dart';
import '../repositories/proveedor_repository.dart';

/// Use case para actualizar un proveedor
@injectable
class ActualizarProveedorUseCase {
  final ProveedorRepository _repository;

  ActualizarProveedorUseCase(this._repository);

  /// Actualiza los datos de un proveedor
  Future<Resource<Proveedor>> call({
    required String empresaId,
    required String proveedorId,
    required Map<String, dynamic> data,
  }) async {
    return await _repository.actualizarProveedor(
      empresaId: empresaId,
      proveedorId: proveedorId,
      data: data,
    );
  }
}
