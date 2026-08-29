import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/core/network/dio_client.dart';
import 'package:syncronize/features/sede/data/datasources/sede_remote_datasource.dart';

/// Un `empresaId` vacío NO puede llegar a la red.
///
/// La URL queda `/empresas//sedes`, el cliente HTTP la normaliza a
/// `/empresas/sedes`, y el backend lee "sedes" como si fuera el id de la
/// empresa: responde **404 "Empresa no encontrada o no tienes acceso a ella"**.
///
/// Ese mensaje es el problema. Manda a revisar permisos, tenant y accesos —
/// pasó exactamente eso el 29-08 entrando a Tesorería desde el acceso rápido —
/// cuando lo único que hubo fue un id que nunca se pasó. Un 404 que miente
/// cuesta más que un error crudo, así que el pedido se corta antes de salir.
void main() {
  late _DioClientQueGrita cliente;
  late SedeRemoteDataSource datasource;

  setUp(() {
    cliente = _DioClientQueGrita();
    datasource = SedeRemoteDataSource(cliente);
  });

  test('🔴 empresaId vacío: falla acá y no sale ningún request', () async {
    await expectLater(datasource.getSedes(''), throwsArgumentError);
    expect(cliente.hubollamada, isFalse,
        reason: 'si salió el request, el 404 engañoso vuelve');
  });

  test('el mensaje nombra el dato que falta, no el 404', () async {
    await expectLater(
      datasource.getSedes(''),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.message.toString(),
          'message',
          contains('ID de la empresa'),
        ),
      ),
    );
  });

  test('con un id real sí intenta el request', () async {
    await expectLater(datasource.getSedes('emp-1'), throwsA(isA<StateError>()));
    expect(cliente.hubollamada, isTrue);
    expect(cliente.rutaPedida, '/empresas/emp-1/sedes');
  });
}

/// Cliente que registra la llamada y corta: acá no se prueba el HTTP, se
/// prueba si el pedido llegó a salir.
class _DioClientQueGrita implements DioClient {
  bool hubollamada = false;
  String? rutaPedida;

  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    void Function(int, int)? onReceiveProgress,
  }) async {
    hubollamada = true;
    rutaPedida = path;
    throw StateError('salió el request a $path');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
