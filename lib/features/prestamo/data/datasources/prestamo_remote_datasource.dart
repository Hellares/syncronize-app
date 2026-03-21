import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/prestamo_model.dart';

@lazySingleton
class PrestamoRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/prestamos';

  PrestamoRemoteDataSource(this._dioClient);

  Future<List<PrestamoModel>> listar({String? estado}) async {
    final queryParams = <String, dynamic>{};
    if (estado != null && estado.isNotEmpty) {
      queryParams['estado'] = estado;
    }

    final response = await _dioClient.get(
      _basePath,
      queryParameters: queryParams,
    );
    final data = response.data as List<dynamic>? ?? [];
    return data
        .map((e) => PrestamoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ResumenPrestamosModel> getResumen() async {
    final response = await _dioClient.get('$_basePath/resumen');
    return ResumenPrestamosModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<PrestamoModel> crear({
    required String tipo,
    required String entidadPrestamo,
    String? descripcion,
    required double montoOriginal,
    double? tasaInteres,
    String? moneda,
    int? cantidadCuotas,
    double? montoCuota,
    required String fechaDesembolso,
    String? fechaVencimiento,
    String? observaciones,
  }) async {
    final data = <String, dynamic>{
      'tipo': tipo,
      'entidadPrestamo': entidadPrestamo,
      'montoOriginal': montoOriginal,
      'fechaDesembolso': fechaDesembolso,
    };
    if (descripcion != null && descripcion.isNotEmpty) data['descripcion'] = descripcion;
    if (tasaInteres != null) data['tasaInteres'] = tasaInteres;
    if (moneda != null && moneda.isNotEmpty) data['moneda'] = moneda;
    if (cantidadCuotas != null) data['cantidadCuotas'] = cantidadCuotas;
    if (montoCuota != null) data['montoCuota'] = montoCuota;
    if (fechaVencimiento != null && fechaVencimiento.isNotEmpty) {
      data['fechaVencimiento'] = fechaVencimiento;
    }
    if (observaciones != null && observaciones.isNotEmpty) {
      data['observaciones'] = observaciones;
    }

    final response = await _dioClient.post(_basePath, data: data);
    return PrestamoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PrestamoModel> registrarPago({
    required String prestamoId,
    required String metodoPago,
    required double monto,
    String? referencia,
  }) async {
    final data = <String, dynamic>{
      'metodoPago': metodoPago,
      'monto': monto,
    };
    if (referencia != null && referencia.isNotEmpty) {
      data['referencia'] = referencia;
    }

    final response = await _dioClient.post(
      '$_basePath/$prestamoId/pago',
      data: data,
    );
    return PrestamoModel.fromJson(response.data as Map<String, dynamic>);
  }
}
