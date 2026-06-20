import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/recaudacion_metodo.dart';

@lazySingleton
class CuentasRecaudacionRemoteDataSource {
  final DioClient _dio;
  static const _base = '/cuentas-recaudacion';

  CuentasRecaudacionRemoteDataSource(this._dio);

  Future<List<RecaudacionMetodo>> listar() async {
    final res = await _dio.get(_base);
    final list = res.data as List<dynamic>? ?? [];
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      final b = m['banco'] as Map<String, dynamic>?;
      return RecaudacionMetodo(
        metodoPago: m['metodoPago'] as String? ?? '',
        bancoId: m['bancoId'] as String?,
        banco: b != null
            ? BancoRecaudacion(
                id: b['id'] as String? ?? '',
                nombreBanco: b['nombreBanco'] as String? ?? '',
                numeroCuenta: b['numeroCuenta'] as String? ?? '',
                moneda: b['moneda'] as String? ?? 'PEN',
              )
            : null,
      );
    }).toList();
  }

  Future<void> setCuenta(String metodoPago, String bancoId) async {
    await _dio.put('$_base/$metodoPago', data: {'bancoId': bancoId});
  }

  Future<void> removeCuenta(String metodoPago) async {
    await _dio.delete('$_base/$metodoPago');
  }
}
