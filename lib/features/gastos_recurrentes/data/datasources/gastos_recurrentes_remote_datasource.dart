import 'dart:io';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/dashboard_gastos.dart';
import '../../domain/entities/gasto_recurrente.dart';
import '../../domain/entities/pago_gasto_recurrente.dart';
import '../models/dashboard_gastos_model.dart';
import '../models/gasto_recurrente_model.dart';
import '../models/pago_gasto_recurrente_model.dart';

@lazySingleton
class GastosRecurrentesRemoteDataSource {
  final DioClient _dioClient;
  static const String _basePath = '/gastos-recurrentes';

  GastosRecurrentesRemoteDataSource(this._dioClient);

  Future<List<GastoRecurrenteModel>> listar({
    String? sedeId,
    String? categoriaGastoId,
    String? proveedorId,
    FrecuenciaGasto? frecuencia,
    bool? activo,
  }) async {
    final qp = <String, dynamic>{};
    if (sedeId != null) qp['sedeId'] = sedeId;
    if (categoriaGastoId != null) qp['categoriaGastoId'] = categoriaGastoId;
    if (proveedorId != null) qp['proveedorId'] = proveedorId;
    if (frecuencia != null) qp['frecuencia'] = frecuencia.apiValue;
    if (activo != null) qp['activo'] = activo.toString();

    final res = await _dioClient.get(_basePath, queryParameters: qp);
    return (res.data as List)
        .map((e) => GastoRecurrenteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GastoRecurrenteModel> obtener(String id) async {
    final res = await _dioClient.get('$_basePath/$id');
    return GastoRecurrenteModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<GastoRecurrenteModel> crear({
    required String nombre,
    required String categoriaGastoId,
    String? sedeId,
    String? proveedorId,
    required double montoEstimado,
    required FrecuenciaGasto frecuencia,
    required int diaVencimiento,
    String? notas,
  }) async {
    final data = <String, dynamic>{
      'nombre': nombre,
      'categoriaGastoId': categoriaGastoId,
      'montoEstimado': montoEstimado,
      'frecuencia': frecuencia.apiValue,
      'diaVencimiento': diaVencimiento,
    };
    if (sedeId != null) data['sedeId'] = sedeId;
    if (proveedorId != null) data['proveedorId'] = proveedorId;
    if (notas != null && notas.isNotEmpty) data['notas'] = notas;

    final res = await _dioClient.post(_basePath, data: data);
    return GastoRecurrenteModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<GastoRecurrenteModel> actualizar({
    required String id,
    String? nombre,
    String? categoriaGastoId,
    String? sedeId,
    String? proveedorId,
    double? montoEstimado,
    FrecuenciaGasto? frecuencia,
    int? diaVencimiento,
    bool? activo,
    String? notas,
  }) async {
    final data = <String, dynamic>{};
    if (nombre != null) data['nombre'] = nombre;
    if (categoriaGastoId != null) data['categoriaGastoId'] = categoriaGastoId;
    if (sedeId != null) data['sedeId'] = sedeId;
    if (proveedorId != null) data['proveedorId'] = proveedorId;
    if (montoEstimado != null) data['montoEstimado'] = montoEstimado;
    if (frecuencia != null) data['frecuencia'] = frecuencia.apiValue;
    if (diaVencimiento != null) data['diaVencimiento'] = diaVencimiento;
    if (activo != null) data['activo'] = activo;
    if (notas != null) data['notas'] = notas;

    final res = await _dioClient.patch('$_basePath/$id', data: data);
    return GastoRecurrenteModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<GastoRecurrenteModel> toggleActivo(String id) async {
    final res = await _dioClient.patch('$_basePath/$id/toggle-activo');
    return GastoRecurrenteModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> eliminar(String id) async {
    await _dioClient.delete('$_basePath/$id');
  }

  Future<DashboardGastosModel> dashboard({String? periodo, String? sedeId}) async {
    final qp = <String, dynamic>{};
    if (periodo != null) qp['periodo'] = periodo;
    if (sedeId != null) qp['sedeId'] = sedeId;

    final res = await _dioClient.get('$_basePath/dashboard', queryParameters: qp);
    return DashboardGastosModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PagoGastoRecurrenteModel> pagar({
    required String gastoId,
    required String periodo,
    required double montoReal,
    required FuentePagoGasto fuente,
    required MetodoPagoGasto metodoPago,
    String? cajaId,
    String? bancoId,
    String? comprobanteUrl,
    String? notas,
  }) async {
    final data = <String, dynamic>{
      'periodo': periodo,
      'montoReal': montoReal,
      'fuente': fuente.apiValue,
      'metodoPago': metodoPago.apiValue,
    };
    if (cajaId != null) data['cajaId'] = cajaId;
    if (bancoId != null) data['bancoId'] = bancoId;
    if (comprobanteUrl != null && comprobanteUrl.isNotEmpty) {
      data['comprobanteUrl'] = comprobanteUrl;
    }
    if (notas != null && notas.isNotEmpty) data['notas'] = notas;

    final res = await _dioClient.post('$_basePath/$gastoId/pagar', data: data);
    return PagoGastoRecurrenteModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<PagoGastoRecurrenteModel>> listarPagos(
    String gastoId, {
    int? take,
    int? skip,
  }) async {
    final qp = <String, dynamic>{};
    if (take != null) qp['take'] = take;
    if (skip != null) qp['skip'] = skip;

    final res = await _dioClient.get(
      '$_basePath/$gastoId/pagos',
      queryParameters: qp,
    );
    final items = (res.data['items'] as List).cast<Map<String, dynamic>>();
    return items.map((e) => PagoGastoRecurrenteModel.fromJson(e)).toList();
  }

  Future<ComprobanteUploadResult> uploadComprobante(String filePath) async {
    final file = File(filePath);
    final fileName = filePath.split(RegExp(r'[\\/]')).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });

    final res = await _dioClient.post(
      '$_basePath/upload-comprobante',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final data = res.data as Map<String, dynamic>;
    return ComprobanteUploadResult(
      archivoId: data['archivoId'] as String,
      url: data['url'] as String,
      tipoArchivo: data['tipoArchivo'] as String,
      tamanoBytes: data['tamanoBytes'] as int? ?? 0,
    );
  }
}
