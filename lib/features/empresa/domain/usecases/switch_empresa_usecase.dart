import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/empresa_repository.dart';

/// Use case para cambiar la empresa activa (switch tenant)
@lazySingleton
class SwitchEmpresaUseCase {
  final EmpresaRepository _repository;

  SwitchEmpresaUseCase(this._repository);

  /// Ejecuta el use case
  ///
  /// Parámetros:
  /// - [empresaId]: ID de la nueva empresa a seleccionar
  /// - [subdominio]: Subdominio de la empresa (opcional)
  ///
  /// Retorna [Resource<void>] indicando si fue exitoso
  Future<Resource<void>> call({
    required String empresaId,
    String? subdominio,
  }) async {
    return await _repository.switchEmpresa(empresaId, subdominio);
  }
}
