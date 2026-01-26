import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/proveedor.dart';
import '../repositories/proveedor_repository.dart';

/// Use case para crear un nuevo proveedor
@injectable
class CrearProveedorUseCase {
  final ProveedorRepository _repository;

  CrearProveedorUseCase(this._repository);

  /// Crea un nuevo proveedor
  Future<Resource<Proveedor>> call({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    return await _repository.crearProveedor(
      empresaId: empresaId,
      data: data,
    );
  }
}
