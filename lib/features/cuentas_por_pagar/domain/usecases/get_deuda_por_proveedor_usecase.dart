import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/cuenta_por_pagar.dart';
import '../repositories/cuentas_pagar_repository.dart';

/// Deuda agrupada por proveedor (vista "Por proveedor" de CxP).
@injectable
class GetDeudaPorProveedorUseCase {
  final CuentasPagarRepository _repository;
  GetDeudaPorProveedorUseCase(this._repository);

  Future<Resource<List<DeudaProveedor>>> call() => _repository.getPorProveedor();
}
