import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/proveedor.dart';
import '../repositories/proveedor_repository.dart';

/// Use case para obtener la lista de proveedores
@injectable
class GetProveedoresUseCase {
  final ProveedorRepository _repository;

  GetProveedoresUseCase(this._repository);

  /// Obtiene la lista de proveedores de una empresa
  Future<Resource<List<Proveedor>>> call({
    required String empresaId,
    bool includeInactive = false,
  }) async {
    return await _repository.getProveedores(
      empresaId: empresaId,
      includeInactive: includeInactive,
    );
  }
}
