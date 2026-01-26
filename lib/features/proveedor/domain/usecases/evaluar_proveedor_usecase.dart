import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/proveedor_evaluacion.dart';
import '../repositories/proveedor_repository.dart';

/// Use case para evaluar un proveedor
@injectable
class EvaluarProveedorUseCase {
  final ProveedorRepository _repository;

  EvaluarProveedorUseCase(this._repository);

  /// Registra una evaluación del proveedor
  Future<Resource<ProveedorEvaluacion>> call({
    required String empresaId,
    required String proveedorId,
    required Map<String, dynamic> data,
  }) async {
    return await _repository.evaluarProveedor(
      empresaId: empresaId,
      proveedorId: proveedorId,
      data: data,
    );
  }
}
