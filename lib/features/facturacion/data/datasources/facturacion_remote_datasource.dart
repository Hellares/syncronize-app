import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/anulacion.dart';
import '../../domain/entities/crear_comunicacion_baja_request.dart';
import '../../domain/entities/crear_nota_request.dart';
import '../../domain/entities/crear_resumen_diario_request.dart';
import '../../domain/entities/tipo_nota.dart';
import '../models/comprobante_elegible_baja_model.dart';
import '../models/comunicacion_baja_model.dart';
import '../models/crear_nota_request_model.dart';
import '../models/motivo_nota_model.dart';
import '../models/nota_emitida_model.dart';
import '../models/resumen_diario_model.dart';

@lazySingleton
class FacturacionRemoteDatasource {
  final DioClient _dioClient;
  static const _basePath = '/sunat';

  FacturacionRemoteDatasource(this._dioClient);

  Future<List<MotivoNotaModel>> obtenerMotivosNota(TipoNota tipo) async {
    final response = await _dioClient.get(
      '$_basePath/catalogos/motivos-nota',
      queryParameters: {'tipo': tipo.backendValue},
    );
    final data = response.data as List;
    return data
        .map((e) => MotivoNotaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<NotaEmitidaModel> crearNotaCredito({
    required String comprobanteOrigenId,
    required CrearNotaRequest request,
  }) async {
    final response = await _dioClient.post(
      '$_basePath/comprobantes/$comprobanteOrigenId/nota-credito',
      data: CrearNotaRequestModel.toJson(request),
    );
    return NotaEmitidaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<NotaEmitidaModel> crearNotaDebito({
    required String comprobanteOrigenId,
    required CrearNotaRequest request,
  }) async {
    final response = await _dioClient.post(
      '$_basePath/comprobantes/$comprobanteOrigenId/nota-debito',
      data: CrearNotaRequestModel.toJson(request),
    );
    return NotaEmitidaModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Comunicaciones de Baja (RA) ──

  Future<ComunicacionBajaModel> crearComunicacionBaja(
      CrearComunicacionBajaRequest req) async {
    final body = <String, dynamic>{
      'sedeId': req.sedeId,
      'fechaReferencia': req.fechaReferencia,
      'motivoBaja': req.motivoBaja,
      'detalles': req.detalles
          .map((d) => {
                'comprobanteId': d.comprobanteId,
                'motivoEspecifico': d.motivoEspecifico,
              })
          .toList(),
    };
    final response =
        await _dioClient.post('$_basePath/comunicaciones-baja', data: body);
    return ComunicacionBajaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ComprobanteElegibleBajaModel>> obtenerElegiblesBaja({
    required String sedeId,
    required String fechaReferencia,
  }) async {
    final response = await _dioClient.get(
      '$_basePath/comunicaciones-baja/elegibles',
      queryParameters: {'sedeId': sedeId, 'fechaReferencia': fechaReferencia},
    );
    final list = response.data as List;
    return list
        .map((e) => ComprobanteElegibleBajaModel.fromJson(
            e as Map<String, dynamic>))
        .toList();
  }

  Future<ComunicacionBajaModel> consultarComunicacionBaja(String id) async {
    final response =
        await _dioClient.post('$_basePath/comunicaciones-baja/$id/consultar');
    return ComunicacionBajaModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Resúmenes Diarios (RC) — anulación de boletas ──

  Future<ResumenDiarioModel> crearResumenDiario(
      CrearResumenDiarioRequest req) async {
    final body = <String, dynamic>{
      'sedeId': req.sedeId,
      'motivoAnulacion': req.motivoAnulacion,
      'detalles': req.detalles
          .map((d) => {
                'comprobanteId': d.comprobanteId,
                'motivoEspecifico': d.motivoEspecifico,
              })
          .toList(),
    };
    final response =
        await _dioClient.post('$_basePath/resumenes-diarios', data: body);
    return ResumenDiarioModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ResumenDiarioModel> consultarResumenDiario(String id) async {
    final response =
        await _dioClient.post('$_basePath/resumenes-diarios/$id/consultar');
    return ResumenDiarioModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Listados paginados ──

  Future<AnulacionesPaginadas<ComunicacionBajaModel>> listarCDBs({
    String? estadoSunat,
    String? fechaDesde,
    String? fechaHasta,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dioClient.get(
      '$_basePath/comunicaciones-baja',
      queryParameters: {
        if (estadoSunat != null) 'estadoSunat': estadoSunat,
        if (fechaDesde != null) 'fechaDesde': fechaDesde,
        if (fechaHasta != null) 'fechaHasta': fechaHasta,
        'page': page,
        'limit': limit,
      },
    );
    final json = response.data as Map<String, dynamic>;
    final list = (json['data'] as List)
        .map((e) => ComunicacionBajaModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return AnulacionesPaginadas<ComunicacionBajaModel>(
      data: list,
      total: (json['total'] as num?)?.toInt() ?? list.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      page: (json['page'] as num?)?.toInt() ?? page,
    );
  }

  Future<AnulacionesPaginadas<ResumenDiarioModel>> listarRCs({
    String? estadoSunat,
    String? fechaDesde,
    String? fechaHasta,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dioClient.get(
      '$_basePath/resumenes-diarios',
      queryParameters: {
        if (estadoSunat != null) 'estadoSunat': estadoSunat,
        if (fechaDesde != null) 'fechaDesde': fechaDesde,
        if (fechaHasta != null) 'fechaHasta': fechaHasta,
        'page': page,
        'limit': limit,
      },
    );
    final json = response.data as Map<String, dynamic>;
    final list = (json['data'] as List)
        .map((e) => ResumenDiarioModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return AnulacionesPaginadas<ResumenDiarioModel>(
      data: list,
      total: (json['total'] as num?)?.toInt() ?? list.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      page: (json['page'] as num?)?.toInt() ?? page,
    );
  }
}
