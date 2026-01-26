import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/proveedor.dart';
import '../repositories/proveedor_repository.dart';

/// Use case para obtener un proveedor específico
@injectable
class GetProveedorUseCase {
  final ProveedorRepository _repository;

  GetProveedorUseCase(this._repository);

  /// Obtiene un proveedor por su ID
  Future<Resource<Proveedor>> call({
    required String empresaId,
    required String proveedorId,
  }) async {
    return await _repository.getProveedor(
      empresaId: empresaId,
      proveedorId: proveedorId,
    );
  }
}
