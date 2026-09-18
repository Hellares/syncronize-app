import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:syncronize/core/network/network_info.dart';
import 'package:syncronize/core/services/error_handler_service.dart';
import 'package:syncronize/core/utils/resource.dart';
import 'package:syncronize/features/venta/domain/entities/venta.dart';
import 'package:syncronize/features/venta_rapida/data/datasources/venta_rapida_remote_datasource.dart';
import 'package:syncronize/features/venta_rapida/data/repositories/venta_rapida_repository_impl.dart';

/// Aviso de VENTA REPETIDA (caso 814/815): el backend rechaza con 409
/// `VENTA_REPETIDA` y la venta anterior. Si el repositorio no reconoce el
/// código, el cubit nunca ve la venta, la página no pregunta y la cajera
/// solo recibe un error genérico. Se prueba el camino del cobro normal y el
/// del Yape diferido (los dos pasan por `crearYCobrar` en el backend).
/// Dobles con `noSuchMethod`: el repo no tiene librería de mocking.
const _body409 = {
  'statusCode': 409,
  'code': 'VENTA_REPETIDA',
  'message':
      'Hace 18 s cobraste una venta con los mismos productos (VTA-SED-00000814). ¿Es otra venta?',
  'venta': {
    'id': 'venta-814',
    'codigo': 'VTA-SED-00000814',
    'nombreCliente': 'CLIENTES VARIOS',
    'total': 83,
    'estado': 'PAGADA_COMPLETA',
    'segundos': 18,
  },
};

DioException _conflicto(String path) {
  final opts = RequestOptions(path: path);
  return DioException(
    requestOptions: opts,
    response: Response(requestOptions: opts, statusCode: 409, data: _body409),
    type: DioExceptionType.badResponse,
  );
}

class _RemoteFalso implements VentaRapidaRemoteDataSource {
  @override
  Future<Never> cobrar(Map<String, dynamic> data) async =>
      throw _conflicto('/ventas/cobrar');

  @override
  Future<Never> cobrarYapeDiferido(Map<String, dynamic> data) async =>
      throw _conflicto('/ventas/cobrar-yape');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RedConectada implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ErrorHandlerFalso implements ErrorHandlerService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final repo = VentaRapidaRepositoryImpl(
    _RemoteFalso(),
    _RedConectada(),
    _ErrorHandlerFalso(),
  );

  void esVentaRepetida(Resource<Venta> r) {
    expect(r, isA<Error<Venta>>());
    final e = r as Error<Venta>;
    expect(e.errorCode, 'VENTA_REPETIDA');
    expect(e.message, contains('VTA-SED-00000814'));
    final venta = e.details?['venta'] as Map<String, dynamic>?;
    expect(venta, isNotNull);
    expect(venta!['id'], 'venta-814');
    expect(venta['codigo'], 'VTA-SED-00000814');
    expect(venta['total'], 83);
    expect(venta['segundos'], 18);
  }

  test('cobro normal: el 409 VENTA_REPETIDA llega con la venta anterior', () async {
    esVentaRepetida(await repo.cobrar(data: const {}));
  });

  test('Yape diferido: mismo 409, mismos datos', () async {
    esVentaRepetida(await repo.cobrarYapeDiferido(data: const {}));
  });
}
