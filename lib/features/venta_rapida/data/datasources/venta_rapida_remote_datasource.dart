import 'package:injectable/injectable.dart';

import '../../../../core/network/dio_client.dart';
import '../../../venta/data/models/venta_model.dart';

/// Datasource del flujo Venta Rápida.
/// Encapsula los endpoints HTTP que necesita el módulo:
///   - POST /ventas/cobrar (mismo endpoint que el POS, payload distinto)
///   - GET  /clientes/generico (resuelve el id de CLIENTES VARIOS)
///   - GET  /clientes/por-dni/:dni (resuelve cliente por DNI usando RENIEC)
@lazySingleton
class VentaRapidaRemoteDataSource {
  final DioClient _dioClient;

  VentaRapidaRemoteDataSource(this._dioClient);

  /// Crea y cobra la venta en una sola operación.
  Future<VentaModel> cobrar(Map<String, dynamic> data) async {
    final response = await _dioClient.post('/ventas/cobrar', data: data);
    return VentaModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Genera un cobro Yape/Plin (monto único) para una venta ya creada.
  /// Devuelve { habilitado, payAmount?, chargeId? }.
  Future<Map<String, dynamic>> cobroYape(String ventaId) async {
    final response = await _dioClient.post('/ventas/$ventaId/cobro-yape');
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Registra un pago en una venta existente (fallback manual con el screenshot).
  Future<VentaModel> registrarPago(
      String ventaId, Map<String, dynamic> data) async {
    final response = await _dioClient.post('/ventas/$ventaId/pago', data: data);
    return VentaModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Resuelve el id del EmpresaPersona "CLIENTES VARIOS" para la empresa
  /// actual (el backend lo crea si no existe).
  /// Devuelve solo el `id`. El resto de campos (`nombres`, `apellidos`, `dni`)
  /// se ignoran porque el cubit ya conoce los valores fijos.
  Future<String> obtenerClienteGenericoId() async {
    final response = await _dioClient.get('/clientes/generico');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final id = data['id'] ?? (data['data'] is Map ? data['data']['id'] : null);
      if (id is String && id.isNotEmpty) return id;
    }
    throw StateError('Respuesta inválida de /clientes/generico');
  }

  /// Busca un cliente por DNI vía RENIEC (con caché interna y BD local).
  /// Backend hace upsert de Persona + EmpresaPersona y devuelve los datos
  /// listos para vincular como `clienteId` en la venta.
  Future<Map<String, dynamic>> buscarClientePorDni(String dni) async {
    final response = await _dioClient.get('/clientes/por-dni/$dni');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final body = data['data'] is Map ? data['data'] as Map<String, dynamic> : data;
      if (body['clienteEmpresaId'] is String) return body;
    }
    throw StateError('Respuesta inválida de /clientes/por-dni');
  }

  /// Busca un cliente empresa por RUC vía SUNAT (con caché interna).
  /// Backend hace upsert de ClienteEmpresa y devuelve los datos listos para
  /// vincular como `clienteEmpresaId` en la venta (B2B).
  Future<Map<String, dynamic>> buscarClientePorRuc(String ruc) async {
    final response = await _dioClient.get('/clientes/por-ruc/$ruc');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final body = data['data'] is Map ? data['data'] as Map<String, dynamic> : data;
      if (body['clienteEmpresaId'] is String) return body;
    }
    throw StateError('Respuesta inválida de /clientes/por-ruc');
  }

  /// Órdenes de servicio cobrables desde VR (REPARADO/LISTO_ENTREGA con
  /// saldo pendiente > 0 y sin venta vinculada).
  Future<List<Map<String, dynamic>>> getOrdenesCobrables({String? search}) async {
    final response = await _dioClient.get(
      '/ordenes-servicio/cobrables',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final data = response.data;
    final list = data is List ? data : (data is Map ? data['data'] : null);
    if (list is List) {
      return list
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    throw StateError('Respuesta inválida de /ordenes-servicio/cobrables');
  }
}
