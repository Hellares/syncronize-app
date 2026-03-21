import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../../../pos/domain/entities/cotizacion_pos.dart';
import '../../../venta/data/models/venta_model.dart';

@lazySingleton
class PosRemoteDataSource {
  final DioClient _dioClient;

  PosRemoteDataSource(this._dioClient);

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  Future<List<CotizacionPOS>> getColaPOS({String? sedeId}) async {
    final params = <String, dynamic>{};
    if (sedeId != null) params['sedeId'] = sedeId;

    final response = await _dioClient.get(
      '/cotizaciones/cola-pos',
      queryParameters: params,
    );

    final list = response.data as List;
    return list.map((e) {
      final map = e as Map<String, dynamic>;
      return CotizacionPOS(
        id: map['id'] as String,
        codigo: map['codigo'] as String,
        estado: map['estado']?.toString() ?? 'APROBADA',
        nombreCliente: map['nombreCliente']?.toString() ?? 'Sin cliente',
        vendedor: map['vendedor']?.toString() ?? 'Sin vendedor',
        sede: map['sede']?.toString(),
        total: _toDouble(map['total']),
        moneda: map['moneda']?.toString() ?? 'PEN',
        totalItems: _toInt(map['totalItems']),
        detalles: ((map['detalles'] as List?) ?? []).map((d) {
          final dm = d as Map<String, dynamic>;
          return DetallePOS(
            id: dm['id'] as String,
            producto: dm['producto']?.toString(),
            cantidad: _toInt(dm['cantidad']),
            precioUnitario: _toDouble(dm['precioUnitario']),
            subtotal: _toDouble(dm['subtotal']),
          );
        }).toList(),
        creadoEn: DateTime.parse(map['creadoEn'] as String),
      );
    }).toList();
  }

  Future<Map<String, dynamic>> getCotizacion(String cotizacionId) async {
    final response = await _dioClient.get('/cotizaciones/$cotizacionId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> validarStock(String cotizacionId) async {
    final response = await _dioClient.get('/cotizaciones/$cotizacionId/validar-stock');
    return response.data as Map<String, dynamic>;
  }

  Future<double?> getTipoCambio() async {
    try {
      final response = await _dioClient.get('/consultas/tipo-cambio');
      if (response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final venta = data['venta'];
        if (venta == null) return null;
        if (venta is double) return venta;
        if (venta is int) return venta.toDouble();
        if (venta is String) return double.tryParse(venta);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<VentaModel> cobrarCotizacion(
    String cotizacionId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.post(
      '/ventas/desde-cotizacion/$cotizacionId',
      data: data,
    );
    return VentaModel.fromJson(response.data as Map<String, dynamic>);
  }
}
