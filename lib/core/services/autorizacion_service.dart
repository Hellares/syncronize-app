import 'package:injectable/injectable.dart';
import '../network/dio_client.dart';

class AutorizacionResult {
  final bool authorized;
  final String autorizadoPorId;
  final String autorizadoPorNombre;

  const AutorizacionResult({
    required this.authorized,
    required this.autorizadoPorId,
    required this.autorizadoPorNombre,
  });

  factory AutorizacionResult.fromJson(Map<String, dynamic> json) {
    return AutorizacionResult(
      authorized: json['authorized'] as bool? ?? false,
      autorizadoPorId: json['autorizadoPorId'] as String? ?? '',
      autorizadoPorNombre: json['autorizadoPorNombre'] as String? ?? '',
    );
  }
}

@lazySingleton
class AutorizacionService {
  final DioClient _dioClient;

  AutorizacionService(this._dioClient);

  Future<AutorizacionResult> autorizar({
    required String dni,
    required String password,
    required String operacion,
    String? motivo,
  }) async {
    final response = await _dioClient.post(
      '/auth/autorizar-operacion',
      data: {
        'dni': dni,
        'password': password,
        'operacion': operacion,
        if (motivo != null) 'motivo': motivo,
      },
    );
    return AutorizacionResult.fromJson(response.data as Map<String, dynamic>);
  }
}
