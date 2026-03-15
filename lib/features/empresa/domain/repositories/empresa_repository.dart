import '../../../../core/utils/resource.dart';
import '../entities/empresa_context.dart';
import '../entities/empresa_list_item.dart';
import '../entities/configuracion_empresa.dart';
import '../entities/personalizacion_empresa.dart';

/// Repository interface para operaciones relacionadas con empresas
abstract class EmpresaRepository {
  /// Obtiene la lista de empresas del usuario
  Future<Resource<List<EmpresaListItem>>> getUserEmpresas();

  /// Obtiene el contexto completo de una empresa
  /// Incluye información, roles, sedes, permisos y estadísticas
  Future<Resource<EmpresaContext>> getEmpresaContext(String empresaId);

  /// Cambia la empresa activa del usuario (switch tenant)
  Future<Resource<void>> switchEmpresa(
    String empresaId,
    String? subdominio, {
    String? empresaNombre,
    String? empresaRole,
  });

  /// Obtiene la personalización de la empresa
  Future<Resource<PersonalizacionEmpresa>> getPersonalizacion(String empresaId);

  /// Actualiza la personalización de la empresa
  Future<Resource<PersonalizacionEmpresa>> updatePersonalizacion(
    String empresaId,
    PersonalizacionEmpresa personalizacion,
  );

  /// Obtiene la configuración fiscal/operativa de la empresa
  Future<Resource<ConfiguracionEmpresa>> getConfiguracion(String empresaId);

  /// Actualiza la configuración fiscal/operativa de la empresa
  Future<Resource<ConfiguracionEmpresa>> updateConfiguracion(
    String empresaId,
    ConfiguracionEmpresa configuracion,
  );
}
