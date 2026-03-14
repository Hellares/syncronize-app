import '../../../../core/utils/resource.dart';
import '../entities/cliente_empresa.dart';

abstract class ClienteEmpresaRepository {
  Future<Resource<ClientesEmpresaPaginados>> getClientesEmpresa({
    required String empresaId,
    String? search,
    int page = 1,
    int limit = 20,
  });

  Future<Resource<ClienteEmpresa>> crearClienteEmpresa({
    required String empresaId,
    required String razonSocial,
    required String numeroDocumento,
    String? nombreComercial,
    String tipoDocumento = 'RUC',
    String? email,
    String? telefono,
    String? direccion,
    String? estadoContribuyente,
    String? condicionContribuyente,
    String? ubigeo,
    String? departamento,
    String? provincia,
    String? distrito,
    List<Map<String, dynamic>>? contactos,
  });
}
