import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/empresa_context_model.dart';
import '../models/empresa_list_item_model.dart';
import '../models/configuracion_empresa_model.dart';
import '../models/personalizacion_empresa_model.dart';

/// Data source remoto para operaciones de empresa
@lazySingleton
class EmpresaRemoteDataSource {
  final DioClient _dioClient;

  EmpresaRemoteDataSource(this._dioClient);

  /// Obtiene la lista de empresas del usuario
  ///
  /// GET /api/empresas
  Future<List<EmpresaListItemModel>> getUserEmpresas() async {
    final response = await _dioClient.get(ApiConstants.empresas);

    if (response.data is! List) {
      throw Exception('Respuesta inválida del servidor');
    }

    return (response.data as List)
        .map((json) => EmpresaListItemModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene el contexto completo de una empresa desde el backend
  ///
  /// GET /api/empresas/:empresaId/context
  Future<EmpresaContextModel> getEmpresaContext(String empresaId) async {
    final response = await _dioClient.get(
      '${ApiConstants.empresas}/$empresaId/context',
    );

    return EmpresaContextModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Cambia la empresa activa (switch tenant)
  ///
  /// POST /api/auth/switch-tenant
  Future<void> switchEmpresa({
    required String empresaId,
    String? subdominioEmpresa,
  }) async {
    await _dioClient.post(
      '/auth/switch-tenant',
      data: {
        'empresaId': empresaId,
        if (subdominioEmpresa != null) 'subdominioEmpresa': subdominioEmpresa,
      },
    );
  }

  /// Obtiene la personalización de la empresa
  ///
  /// GET /api/empresas/:empresaId/personalizacion
  Future<PersonalizacionEmpresaModel> getPersonalizacion(String empresaId) async {
    final response = await _dioClient.get(
      '${ApiConstants.empresas}/$empresaId/personalizacion',
    );

    return PersonalizacionEmpresaModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Actualiza la personalización de la empresa
  ///
  /// PUT /api/empresas/:empresaId/personalizacion
  Future<PersonalizacionEmpresaModel> updatePersonalizacion({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dioClient.put(
      '${ApiConstants.empresas}/$empresaId/personalizacion',
      data: data,
    );

    return PersonalizacionEmpresaModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Actualiza datos generales de la empresa
  ///
  /// PUT /api/empresas/:empresaId
  Future<void> updateEmpresa({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    await _dioClient.put(
      '${ApiConstants.empresas}/$empresaId',
      data: data,
    );
  }

  /// Actualiza el logo de la empresa
  ///
  /// PUT /api/empresas/:empresaId
  Future<void> updateEmpresaLogo({
    required String empresaId,
    required String logoUrl,
  }) async {
    await _dioClient.put(
      '${ApiConstants.empresas}/$empresaId',
      data: {'logo': logoUrl},
    );
  }

  /// Obtiene la configuración fiscal/operativa de la empresa
  ///
  /// GET /api/empresas/:empresaId/configuracion
  Future<ConfiguracionEmpresaModel> getConfiguracion(String empresaId) async {
    final response = await _dioClient.get(
      '${ApiConstants.empresas}/$empresaId/configuracion',
    );

    return ConfiguracionEmpresaModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Actualiza la configuración fiscal/operativa de la empresa
  ///
  /// PUT /api/empresas/:empresaId/configuracion
  Future<ConfiguracionEmpresaModel> updateConfiguracion({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dioClient.put(
      '${ApiConstants.empresas}/$empresaId/configuracion',
      data: data,
    );

    return ConfiguracionEmpresaModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Obtiene la configuración de integración Yape (secretos enmascarados)
  ///
  /// GET /api/empresas/:empresaId/integracion-yape
  Future<Map<String, dynamic>> getIntegracionYape(String empresaId) async {
    final response = await _dioClient.get(
      '${ApiConstants.empresas}/$empresaId/integracion-yape',
    );
    return response.data as Map<String, dynamic>;
  }

  /// Crea/actualiza la integración Yape de la empresa
  ///
  /// PUT /api/empresas/:empresaId/integracion-yape
  Future<Map<String, dynamic>> updateIntegracionYape({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dioClient.put(
      '${ApiConstants.empresas}/$empresaId/integracion-yape',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Prueba la conexión con api-yape (cobro de prueba que se cancela)
  ///
  /// POST /api/empresas/:empresaId/integracion-yape/probar
  Future<Map<String, dynamic>> probarIntegracionYape(String empresaId) async {
    final response = await _dioClient.post(
      '${ApiConstants.empresas}/$empresaId/integracion-yape/probar',
    );
    return response.data as Map<String, dynamic>;
  }

  // ── Agente IA vendedor por WhatsApp ──

  /// Config del agente IA (API key del proveedor propio enmascarada)
  ///
  /// GET /api/empresas/:empresaId/agente-ia
  Future<Map<String, dynamic>> getAgenteIa(String empresaId) async {
    final response = await _dioClient.get(
      '${ApiConstants.empresas}/$empresaId/agente-ia',
    );
    return response.data as Map<String, dynamic>;
  }

  /// Crea/actualiza la config del agente IA de la empresa
  ///
  /// PUT /api/empresas/:empresaId/agente-ia
  Future<Map<String, dynamic>> updateAgenteIa({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dioClient.put(
      '${ApiConstants.empresas}/$empresaId/agente-ia',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  // ── WhatsApp de la empresa (Evolution API) ──

  /// Config + estado vivo de la vinculación de WhatsApp
  ///
  /// GET /api/empresas/:empresaId/whatsapp
  Future<Map<String, dynamic>> getWhatsapp(String empresaId) async {
    final response = await _dioClient.get(
      '${ApiConstants.empresas}/$empresaId/whatsapp',
    );
    return response.data as Map<String, dynamic>;
  }

  /// ¿El sistema puede escribirle al cliente por su cuenta?
  ///
  /// Liviano y sin permiso de administrador, al revés que [getWhatsapp]: lo
  /// consulta quien atiende una orden para saber si el mensaje sale desde el
  /// sistema o hay que abrir WhatsApp.
  ///
  /// GET /api/empresas/:empresaId/whatsapp/estado
  Future<Map<String, dynamic>> getEstadoEnvioWhatsapp(String empresaId) async {
    final response = await _dioClient.get(
      '${ApiConstants.empresas}/$empresaId/whatsapp/estado',
    );
    return response.data as Map<String, dynamic>;
  }

  /// Manda un mensaje de texto desde el número de la empresa.
  /// Falla con 400 si la vinculación no está conectada.
  ///
  /// POST /api/empresas/:empresaId/whatsapp/enviar
  Future<void> enviarMensajeWhatsapp({
    required String empresaId,
    required String numero,
    required String mensaje,
  }) async {
    await _dioClient.post(
      '${ApiConstants.empresas}/$empresaId/whatsapp/enviar',
      data: {'numero': numero, 'mensaje': mensaje},
    );
  }

  /// Manda una imagen con su texto desde el número de la empresa.
  ///
  /// La imagen va en base64 SIN el prefijo `data:` y NO se guarda: viaja
  /// directo al proveedor. Redimensionarla es responsabilidad del que la
  /// elige.
  ///
  /// POST /api/empresas/:empresaId/whatsapp/enviar-imagen
  Future<void> enviarImagenWhatsapp({
    required String empresaId,
    required String numero,
    required String base64,
    String? caption,
    String mimetype = 'image/jpeg',
  }) async {
    await _dioClient.post(
      '${ApiConstants.empresas}/$empresaId/whatsapp/enviar-imagen',
      data: {
        'numero': numero,
        'base64': base64,
        if (caption != null && caption.isNotEmpty) 'caption': caption,
        'mimetype': mimetype,
      },
    );
  }

  /// Crea la instancia y devuelve el QR para escanear
  /// (estado, qrBase64 data-uri, pairingCode)
  ///
  /// POST /api/empresas/:empresaId/whatsapp/vincular
  Future<Map<String, dynamic>> vincularWhatsapp(String empresaId) async {
    final response = await _dioClient.post(
      '${ApiConstants.empresas}/$empresaId/whatsapp/vincular',
    );
    return response.data as Map<String, dynamic>;
  }

  /// Actualiza plantilla y/o habilitado ('' en plantilla = default)
  ///
  /// PUT /api/empresas/:empresaId/whatsapp
  Future<Map<String, dynamic>> updateWhatsapp({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dioClient.put(
      '${ApiConstants.empresas}/$empresaId/whatsapp',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Desvincula el WhatsApp (cierra la sesión en Evolution)
  ///
  /// DELETE /api/empresas/:empresaId/whatsapp
  Future<void> desvincularWhatsapp(String empresaId) async {
    await _dioClient.delete('${ApiConstants.empresas}/$empresaId/whatsapp');
  }

  /// Obtiene informacion de limites del plan (uso de storage, etc.)
  Future<Map<String, dynamic>?> getPlanLimitsInfo(String empresaId) async {
    try {
      final response = await _dioClient.get(
        '/producto-atributo-plantillas/limits-info',
      );
      return response.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}
