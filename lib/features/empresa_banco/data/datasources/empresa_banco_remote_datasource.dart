import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/empresa_banco_model.dart';

@lazySingleton
class EmpresaBancoRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/empresa-banco';

  EmpresaBancoRemoteDataSource(this._dioClient);

  Future<List<EmpresaBancoModel>> listar() async {
    final response = await _dioClient.get(_basePath);
    final data = response.data as List<dynamic>? ?? [];
    return data
        .map((e) => EmpresaBancoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EmpresaBancoModel> crear({
    required String nombreBanco,
    required String tipoCuenta,
    required String numeroCuenta,
    String? cci,
    String? moneda,
    String? titular,
    bool? esPrincipal,
    double? saldoActual,
  }) async {
    final data = <String, dynamic>{
      'nombreBanco': nombreBanco,
      'tipoCuenta': tipoCuenta,
      'numeroCuenta': numeroCuenta,
    };
    if (cci != null && cci.isNotEmpty) data['cci'] = cci;
    if (moneda != null && moneda.isNotEmpty) data['moneda'] = moneda;
    if (titular != null && titular.isNotEmpty) data['titular'] = titular;
    if (esPrincipal != null) data['esPrincipal'] = esPrincipal;
    if (saldoActual != null) data['saldoActual'] = saldoActual;

    final response = await _dioClient.post(_basePath, data: data);
    return EmpresaBancoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<EmpresaBancoModel> actualizar({
    required String id,
    String? nombreBanco,
    String? tipoCuenta,
    String? numeroCuenta,
    String? cci,
    String? moneda,
    String? titular,
    bool? esPrincipal,
  }) async {
    final data = <String, dynamic>{};
    if (nombreBanco != null) data['nombreBanco'] = nombreBanco;
    if (tipoCuenta != null) data['tipoCuenta'] = tipoCuenta;
    if (numeroCuenta != null) data['numeroCuenta'] = numeroCuenta;
    if (cci != null) data['cci'] = cci;
    if (moneda != null) data['moneda'] = moneda;
    if (titular != null) data['titular'] = titular;
    if (esPrincipal != null) data['esPrincipal'] = esPrincipal;

    final response = await _dioClient.patch('$_basePath/$id', data: data);
    return EmpresaBancoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> eliminar({required String id}) async {
    await _dioClient.delete('$_basePath/$id');
  }

  Future<EmpresaBancoModel> marcarPrincipal({required String id}) async {
    final response = await _dioClient.post('$_basePath/$id/principal');
    return EmpresaBancoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<EmpresaBancoModel> actualizarSaldo({
    required String id,
    required double saldo,
  }) async {
    final response = await _dioClient.patch(
      '$_basePath/$id/saldo',
      data: {'saldo': saldo},
    );
    return EmpresaBancoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ConciliacionBancariaModel> getConciliacion({
    required String cuentaId,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    final queryParams = <String, dynamic>{};
    if (fechaDesde != null) queryParams['fechaDesde'] = fechaDesde;
    if (fechaHasta != null) queryParams['fechaHasta'] = fechaHasta;

    final response = await _dioClient.get(
      '$_basePath/$cuentaId/conciliacion',
      queryParameters: queryParams,
    );
    return ConciliacionBancariaModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
