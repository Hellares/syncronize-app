import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/config/environment/env_config.dart';
import 'package:syncronize/features/balanza/domain/entities/balanza_config.dart';
import 'package:syncronize/features/balanza/domain/entities/perfil_trama.dart';
import 'package:syncronize/features/balanza/domain/services/balanza_device.dart';

/// 🔴 La barrera que impide emitir un comprobante fiscal con un peso inventado.
///
/// 🔑 Estas pruebas corren en la configuración PELIGROSA sin hacer nada
/// especial: `FLAVOR` se lee con `String.fromEnvironment(..., defaultValue:
/// 'prod')`, y `flutter test` no define ninguno. O sea que el entorno de tests
/// ES un build de producción, que es exactamente donde el simulador no puede
/// existir.
void main() {
  final config = BalanzaConfig(
    id: 'b1',
    nombre: 'SIMULADOR',
    transporte: TipoTransporte.simulador,
    direccion: '',
    perfil: PerfilesTrama.casToledo,
  );

  test('el entorno de tests es un build de produccion', () {
    // Si esto falla, el resto del archivo no prueba lo que dice probar.
    expect(EnvConfig.isProd, isTrue);
  });

  test('en produccion el simulador NO se puede elegir', () {
    expect(TipoTransporte.elegibles, isNot(contains(TipoTransporte.simulador)));
    expect(TipoTransporte.elegibles, contains(TipoTransporte.clasico));
    expect(TipoTransporte.elegibles, contains(TipoTransporte.ble));
  });

  test('una config simulada YA guardada tampoco entrega pesos', () {
    // El caso que la primera llave no cubre: la config vino de un build viejo,
    // de un respaldo, o escrita a mano en las preferencias.
    expect(crearDevice(config), isNull);
  });

  test('el simulador no se declara conectable en produccion', () {
    expect(TipoTransporte.simulador.puedeConectar, isFalse);
    expect(TipoTransporte.simulador.disponibleEnEsteBuild, isFalse);
  });

  test('los transportes reales siguen sin implementarse, sin fake de reemplazo',
      () {
    for (final t in [TipoTransporte.clasico, TipoTransporte.ble]) {
      final real = BalanzaConfig(
        id: 'b2',
        nombre: 'Balanza',
        transporte: t,
        direccion: '00:11:22:33:44:55',
        perfil: PerfilesTrama.casToledo,
      );
      // 🔴 null, NUNCA un BalanzaFake de reemplazo: un peso inventado que entra
      // como real es el peor error posible de este módulo.
      expect(crearDevice(real), isNull, reason: t.name);
    }
  });
}
