import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/empresa_context.dart';
import '../repositories/empresa_repository.dart';

/// Use case para obtener el contexto completo de una empresa
@lazySingleton
class GetEmpresaContextUseCase {
  final EmpresaRepository _repository;

  GetEmpresaContextUseCase(this._repository);

  /// Ejecuta el use case
  ///
  /// Parámetros:
  /// - [empresaId]: ID de la empresa
  ///
  /// Retorna [Resource<EmpresaContext>] con el contexto de la empresa
  Future<Resource<EmpresaContext>> call(String empresaId) async {
    return await _repository.getEmpresaContext(empresaId);
  }
}
