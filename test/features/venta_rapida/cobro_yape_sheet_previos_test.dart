import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:syncronize/core/services/realtime_sync_service.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import 'package:syncronize/features/venta_rapida/presentation/bloc/venta_rapida_cubit.dart';
import 'package:syncronize/features/venta_rapida/presentation/widgets/cobro_yape_sheet.dart';

/// Hoja de cobro Yape: "el cliente yapeó ANTES de la venta" (09-18). La hoja
/// ofrece los Yapes que ya entraron por el monto y la cajera elige uno.
///
/// 🔴 Test de MONTAJE: `flutter analyze` no ve el layout, y la hoja NO
/// scrolleaba — ahora suma una lista. Se abre con el mismo
/// `CobroYapeSheet.mostrar` del app en una pantalla BAJA (500×640): ancho
/// holgado porque las fuentes de test son más anchas que las del celular,
/// alto de celular chico para que un desborde vertical aparezca.
/// Dobles con `noSuchMethod`: el repo no tiene librería de mocking.
class _CubitFalso implements VentaRapidaCubit {
  final List<YapePrevio> previos;
  final List<Map<String, Object?>> aprobados = [];

  _CubitFalso(this.previos);

  @override
  Future<Map<String, dynamic>?> cobroYapeTramo(
    String ventaId,
    double monto,
  ) async =>
      // Sin QR ni lector: la hoja queda en modo "aprobar a mano" (sin spinner).
      {'habilitado': false, 'payAmount': monto, 'qrYapeUrl': null, 'qrPlinUrl': null};

  @override
  Future<({String estado, double montoRecibido})> progresoVentaYape(
    String ventaId,
  ) async =>
      (estado: 'CONFIRMADA', montoRecibido: 0.0);

  @override
  Future<List<YapePrevio>> pagosYapePrevios(String ventaId, double monto) async =>
      previos;

  @override
  Future<String?> confirmarPagoManualYape({
    required String ventaId,
    required double monto,
    required String metodo,
    String? referencia,
    String? banco,
    String? yapePagoId,
    bool aceptaRiesgoBancarizacion = false,
  }) async {
    aprobados.add({
      'monto': monto,
      'referencia': referencia,
      'yapePagoId': yapePagoId,
    });
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RealtimeFalso implements RealtimeSyncService {
  final _eventos = StreamController<RealtimeEvent>.broadcast();

  @override
  Stream<RealtimeEvent> get events => _eventos.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

YapePrevio _yape(String id, String remitente, {int haceMin = 5, bool calza = false}) => (
      id: id,
      remitente: remitente,
      monto: 83.0,
      recibido: DateTime.now().subtract(Duration(minutes: haceMin)),
      calzaNombre: calza,
    );

const _titulo = 'Ya entró un Yape por este monto. ¿Es alguno de estos?';

void main() {
  /// Abre la hoja como el app y devuelve el cubit falso + el resultado.
  Future<({_CubitFalso cubit, Completer<bool> resultado})> abrir(
    WidgetTester tester,
    List<YapePrevio> previos,
  ) async {
    tester.view.physicalSize = const Size(500, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final cubit = _CubitFalso(previos);
    final resultado = Completer<bool>();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              resultado.complete(await CobroYapeSheet.mostrar(
                context,
                ventaId: 'v1',
                montoTotal: 83,
                metodoInicial: 'YAPE',
                maxPorTransaccion: 500,
                cubit: cubit,
                realtime: _RealtimeFalso(),
              ));
            },
            child: const Text('cobrar'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('cobrar'));
    await tester.pump(); // abre la hoja
    await tester.pump(const Duration(milliseconds: 600)); // animación + charge + lista
    return (cubit: cubit, resultado: resultado);
  }

  Future<void> aprobar(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Aprobar pago'));
    await tester.pump();
    await tester.tap(find.text('Aprobar pago'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600)); // cierra la hoja
  }

  testWidgets('10 Yapes previos en una pantalla baja: se monta sin desbordar', (tester) async {
    await abrir(tester, [
      _yape('aquino', 'AQUINO ARENAS JHONATAN', haceMin: 21, calza: true),
      for (var i = 0; i < 9; i++) _yape('p$i', 'Oscar Gut*', haceMin: 30 + i),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text(_titulo), findsOneWidget);
    expect(find.text('AQUINO ARENAS JHONATAN'), findsOneWidget);
    expect(find.textContaining('coincide el nombre'), findsOneWidget);
    expect(find.textContaining('hace 21 min'), findsOneWidget);

    await tester.pumpWidget(const SizedBox()); // desmonta: corta el poll
  });

  testWidgets('elegir un Yape oculta el N° de operación y aprueba CON ese Yape', (tester) async {
    final r = await abrir(tester, [
      _yape('aquino', 'AQUINO ARENAS JHONATAN', haceMin: 21),
      _yape('otro', 'Rosa Qui*', haceMin: 2),
    ]);
    expect(find.byType(CustomText), findsOneWidget); // N° de operación

    await tester.tap(find.text('AQUINO ARENAS JHONATAN'));
    await tester.pump();
    expect(find.byType(CustomText), findsNothing); // la referencia sale del Yape

    await aprobar(tester);

    expect(r.cubit.aprobados, [
      {'monto': 83.0, 'referencia': null, 'yapePagoId': 'aquino'},
    ]);
    expect(await r.resultado.future, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tocarlo de nuevo lo suelta: vuelve el N° de operación', (tester) async {
    await abrir(tester, [_yape('aquino', 'AQUINO ARENAS JHONATAN')]);

    await tester.tap(find.text('AQUINO ARENAS JHONATAN'));
    await tester.pump();
    await tester.tap(find.text('AQUINO ARENAS JHONATAN'));
    await tester.pump();

    expect(find.byType(CustomText), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('sin Yapes previos: no hay lista y aprueba como siempre (00000)', (tester) async {
    final r = await abrir(tester, const []);

    expect(find.text(_titulo), findsNothing);
    expect(find.byType(CustomText), findsOneWidget);

    await aprobar(tester);

    expect(r.cubit.aprobados, [
      {'monto': 83.0, 'referencia': '00000', 'yapePagoId': null},
    ]);
    expect(await r.resultado.future, isTrue);
  });
}
