import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncronize/core/storage/local_storage_service.dart';
import 'package:syncronize/features/caja/domain/services/conteo_borrador_store.dart';

/// Tests del borrador del conteo de efectivo.
///
/// Lo que se protege acá es plata contada a mano: que el desglose vuelva EXACTO
/// (una denominación mal serializada cambia el total y el cajero lo aplica sin
/// notarlo) y que un conteo viejo NO reviva — el arqueo se repite sobre la
/// misma caja y unos números plausibles de ayer no se distinguen a simple
/// vista de los de hoy.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ConteoBorradorStore store;
  late LocalStorageService storage;

  const scope = 'cierre_caja-1';

  Future<void> montar([Map<String, Object> inicial = const {}]) async {
    SharedPreferences.setMockInitialValues(inicial);
    storage = LocalStorageService(await SharedPreferences.getInstance());
    store = ConteoBorradorStore(storage);
  }

  setUp(() async => montar());

  group('ida y vuelta del desglose', () {
    test('devuelve las mismas denominaciones y cantidades', () async {
      await store.guardarDesglose(scope, {200: 3, 50: 1, 0.50: 12}, 656.0);

      final b = store.leer(scope);

      expect(b, isNotNull);
      expect(b!.cantidades, {200.0: 3, 50.0: 1, 0.50: 12});
      expect(b.conteoEfectivo, 656.0);
    });

    test('0.50 y 0.20 no se pisan entre sí al releer', () async {
      // Las claves del JSON son texto: sin un formato fijo, 0.5 y 0.50 se
      // guardan como dos entradas distintas y el total sale duplicado.
      await store.guardarDesglose(scope, {0.50: 4, 0.20: 5, 0.10: 6}, 4.6);

      final b = store.leer(scope)!;

      expect(b.cantidades.length, 3);
      expect(b.cantidades[0.50], 4);
      expect(b.cantidades[0.20], 5);
      expect(b.cantidades[0.10], 6);
    });

    test('el conteo tecleado a mano conserva el desglose ya contado', () async {
      await store.guardarDesglose(scope, {100: 2}, 200.0);

      // El cajero cuenta los billetes y después corrige el total a mano.
      await store.guardarConteoEfectivo(scope, 195.50);

      final b = store.leer(scope)!;
      expect(b.cantidades, {100.0: 2}, reason: 'el desglose no se pierde');
      expect(b.conteoEfectivo, 195.50);
    });
  });

  group('nada que recuperar', () {
    test('sin borrador devuelve null', () {
      expect(store.leer(scope), isNull);
    });

    test('un desglose vacío no deja borrador', () async {
      await store.guardarDesglose(scope, {}, 0);
      expect(store.leer(scope), isNull,
          reason: 'si no, el aviso de "recuperamos tu conteo" sale sin conteo');
    });

    test('limpiar el conteo borra el borrador', () async {
      await store.guardarDesglose(scope, {200: 1}, 200.0);
      await store.guardarDesglose(scope, {}, 0);

      expect(store.leer(scope), isNull);
    });
  });

  group('un conteo viejo no revive', () {
    test('a las 12 h caduca y se borra solo', () async {
      final viejo = DateTime.now().subtract(const Duration(hours: 13));
      await montar({
        'flutter.conteo_borrador_v1_$scope': jsonEncode({
          'cantidades': {'200.00': 5},
          'conteoEfectivo': 1000.0,
          'guardadoEn': viejo.toIso8601String(),
        }),
      });

      expect(store.leer(scope), isNull);
      // Y no queda dando vueltas para el intento siguiente.
      expect(storage.getString('conteo_borrador_v1_$scope'), isNull);
    });

    test('dentro de las 12 h sigue disponible', () async {
      final reciente = DateTime.now().subtract(const Duration(hours: 11));
      await montar({
        'flutter.conteo_borrador_v1_$scope': jsonEncode({
          'cantidades': {'100.00': 2},
          'conteoEfectivo': 200.0,
          'guardadoEn': reciente.toIso8601String(),
        }),
      });

      expect(store.leer(scope)?.cantidades, {100.0: 2});
    });

    test('borrar lo deja sin nada que ofrecer', () async {
      await store.guardarDesglose(scope, {200: 1}, 200.0);
      await store.borrar(scope);

      expect(store.leer(scope), isNull);
    });

    test('cierre y arqueo de la misma caja no comparten borrador', () async {
      final cierre = ConteoBorradorStore.scopeCierre('caja-1');
      final arqueo = ConteoBorradorStore.scopeArqueo('caja-1');

      await store.guardarDesglose(cierre, {200: 1}, 200.0);

      expect(store.leer(arqueo), isNull);
    });
  });

  test('un borrador corrupto no traba el cierre: se descarta', () async {
    await montar({'flutter.conteo_borrador_v1_$scope': 'no es json {{{'});

    expect(store.leer(scope), isNull);
    expect(storage.getString('conteo_borrador_v1_$scope'), isNull);
  });

  group('mismoDesglose distingue descartar de salir', () {
    // Las dos salidas vuelven con `null`. Lo único que las separa es que al
    // descartar el sheet deja el borrador igual al desglose ya aplicado.
    test('iguales: el cajero descartó, no hay nada nuevo que traer', () {
      expect(mismoDesglose({200: 3, 10: 1}, {10: 1, 200: 3}), isTrue,
          reason: 'el orden de las denominaciones no importa');
    });

    test('distintos: salió con el conteo fresco, hay que traerlo', () {
      expect(mismoDesglose({200: 3}, {200: 4}), isFalse);
      expect(mismoDesglose({200: 3}, {200: 3, 10: 1}), isFalse);
      expect(mismoDesglose({200: 3}, null), isFalse);
    });

    test('vacío y null son lo mismo: nada contado', () {
      expect(mismoDesglose(null, const {}), isTrue);
      expect(mismoDesglose(const {}, null), isTrue);
    });
  });

  group('antigüedad legible', () {
    ConteoBorrador deHace(Duration d) => ConteoBorrador(
          // Sin `const`: un double no puede ser clave de un mapa constante.
          cantidades: {200.0: 1},
          conteoEfectivo: 200.0,
          guardadoEn: DateTime.now().subtract(d),
        );

    test('muestra de cuándo es el conteo', () {
      expect(deHace(const Duration(seconds: 20)).antiguedadLegible, 'recién');
      expect(deHace(const Duration(minutes: 4)).antiguedadLegible, 'hace 4 min');
      expect(deHace(const Duration(hours: 3)).antiguedadLegible, 'hace 3 h');
    });
  });
}
