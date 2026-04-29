import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/crear_comunicacion_baja_request.dart';
import '../../domain/entities/crear_nota_request.dart';
import '../../domain/entities/tipo_nota.dart';
import '../models/comprobante_elegible_baja_model.dart';
import '../models/comunicacion_baja_model.dart';
import '../models/crear_nota_request_model.dart';
import '../models/motivo_nota_model.dart';
import '../models/nota_emitida_model.dart';

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
}
