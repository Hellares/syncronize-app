import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:syncronize/core/services/session_expired_notifier.dart';
import 'package:syncronize/core/storage/local_storage_service.dart';
import 'package:syncronize/features/auth/domain/entities/user.dart';
import 'package:syncronize/features/auth/domain/usecases/check_auth_status_usecase.dart';
import 'package:syncronize/features/auth/domain/usecases/get_local_user_usecase.dart';
import 'package:syncronize/features/auth/domain/usecases/logout_usecase.dart';
import 'package:syncronize/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:syncronize/features/empresa/domain/usecases/get_empresa_context_usecase.dart';
import 'package:syncronize/features/empresa/data/models/empresa_permissions_model.dart';
import 'package:syncronize/features/empresa/domain/entities/empresa_context.dart';
import 'package:syncronize/features/empresa/domain/entities/empresa_info.dart';
import 'package:syncronize/features/empresa/domain/entities/empresa_statistics.dart';
import 'package:syncronize/features/empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import 'package:syncronize/features/empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import 'package:syncronize/features/empresa/presentation/widgets/accesos_rapidos_section.dart';

/// Accesos rápidos reordenables del dashboard de empresa.
///
/// 🔴 Este es un test de MONTAJE, no de comportamiento: `flutter analyze`
/// verifica tipos y no ve el layout, y esta sección vive en la pantalla
/// principal — un `BoxConstraints forces an infinite ...` acá tumba el
/// dashboard entero apenas se abre. Se monta en el MISMO árbol que la pantalla
/// real: `SingleChildScrollView > Column`.
///
/// Los fakes usan `noSuchMethod` en vez de una librería de mocking: el repo no
/// tiene ninguna y no vale agregar una dependencia por un test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // El orden se guarda en SharedPreferences; sin esto el plugin no existe
    // en el entorno de test.
    SharedPreferences.setMockInitialValues({});
  });

  Widget montar({Map<String, dynamic> permisos = const {}}) {
    final contexto = EmpresaContext(
      empresa: const EmpresaInfo(
        id: 'emp_1',
        nombre: 'Empresa Test',
        estadoSuscripcion: 'ACTIVA',
        usuariosActuales: 1,
      ),
      userRoles: const [],
      sedes: const [],
      permissions: EmpresaPermissionsModel.fromJson(permisos),
      statistics: const EmpresaStatistics(
        totalProductos: 0,
        totalServicios: 0,
        totalUsuarios: 0,
        totalSedes: 0,
        ordenesPendientes: 0,
      ),
    );

    return MaterialApp(
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<EmpresaContextCubit>.value(
              value: _FakeEmpresaContextCubit(EmpresaContextLoaded(contexto)),
            ),
            BlocProvider<AuthBloc>.value(value: _FakeAuthBloc()),
          ],
          // El mismo árbol que el dashboard real.
          child: SingleChildScrollView(
            child: Column(
              children: const [AccesosRapidosSection()],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('monta sin reventar con varios accesos visibles', (tester) async {
    await tester.pumpWidget(montar(permisos: const {
      'canViewVentas': true,
      'canManageVentas': true,
      'canViewProducts': true,
      'canManageProducts': true,
      'canViewServices': true,
      'canViewCotizaciones': true,
      'canManageOrders': true,
      'canViewCajas': true,
    }));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Con esos permisos tiene que haber dibujado más de una fila.
    expect(find.byType(LongPressDraggable<int>), findsWidgets);
  });

  testWidgets(
      '🔴 cada id del catalogo tiene su boton en el dashboard',
      (tester) async {
    // La ficha de usuario ofrece un checkbox por cada id de
    // `AccesosRapidosCatalogo.items`, pero el botón lo dibuja
    // `_itemsCatalogo`. Estuvieron desincronizados: 21 checkboxes contra 16
    // botones, así que el admin marcaba y desmarcaba seis accesos que no
    // existían en ninguna pantalla.
    //
    // Con TODOS los permisos en true no hay filtro que valga, así que la
    // cantidad dibujada tiene que ser exactamente la del catálogo.
    await tester.pumpWidget(montar(permisos: const {
      'canManageVentas': true,
      'canViewVentas': true,
      'canViewCotizaciones': true,
      'canViewCaja': true,
      'canViewReports': true,
      'canViewStatistics': true,
      'canManageInvoices': true,
      'canViewProducts': true,
      'canViewServices': true,
      'canManageOrders': true,
      'canManageSettings': true,
    }));
    await tester.pumpAndSettle();

    expect(
      find.byType(LongPressDraggable<int>).evaluate().length,
      AccesosRapidosCatalogo.items.length,
      reason: 'Hay ids en el catalogo sin boton, o botones sin id',
    );
  });

  testWidgets('sin permisos no dibuja nada y tampoco revienta', (tester) async {
    await tester.pumpWidget(montar());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(LongPressDraggable<int>), findsNothing);
  });

  testWidgets('un solo acceso: la fila incompleta no rompe el reparto',
      (tester) async {
    await tester.pumpWidget(montar(permisos: const {'canViewCotizaciones': true}));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(LongPressDraggable<int>), findsOneWidget);
  });

  testWidgets('arrastrar una card sobre otra no revienta y persiste el orden',
      (tester) async {
    await tester.pumpWidget(montar(permisos: const {
      'canViewVentas': true,
      'canManageVentas': true,
      'canViewProducts': true,
      'canViewCotizaciones': true,
    }));
    await tester.pumpAndSettle();

    final cards = find.byType(LongPressDraggable<int>);
    expect(cards, findsWidgets);

    // Mantener presionada la primera y soltarla sobre la segunda.
    final origen = tester.getCenter(cards.first);
    final destino = tester.getCenter(cards.at(1));
    final gesto = await tester.startGesture(origen);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesto.moveTo(destino);
    await tester.pump();
    await gesto.up();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // El orden quedó grabado con la clave por empresa y usuario.
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getStringList('accesos_rapidos_orden:emp_1:user_1'),
      isNotNull,
      reason: 'El reordenamiento tiene que persistir',
    );
  });

  // ── Ocultar accesos (preferencia del propio usuario) ──────────────────
  //
  // Un admin ve 21 botones y eso abruma. Puede esconder los que no usa, PERO
  // esconder no es sacar acceso: el drawer los sigue mostrando según su rol, y
  // por eso esto vive en SharedPreferences y no toca `accesosRapidosOcultos`,
  // que es lo que el admin configura para OTROS usuarios.

  const cuatroAccesos = {
    'canViewVentas': true,
    'canManageVentas': true,
    'canViewProducts': true,
    'canViewCotizaciones': true,
  };

  testWidgets('el mantenido destapa los ✕ sin tener que arrastrar',
      (tester) async {
    await tester.pumpWidget(montar(permisos: cuatroAccesos));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.close), findsNothing,
        reason: 'en reposo la grilla no muestra controles de edición');

    await tester.longPress(find.byType(LongPressDraggable<int>).first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.close),
        findsNWidgets(find.byType(LongPressDraggable<int>).evaluate().length));
  });

  testWidgets('🔴 el ✕ se dibuja ENCIMA: las cards no cambian de tamaño',
      (tester) async {
    // El ✕ vivía en un Stack con el `fit` de fábrica (loose), que afloja las
    // restricciones tight que baja el Expanded de la fila. La card no declara
    // ancho, así que se encogía a su contenido y la grilla entera se deformaba
    // al entrar en modo edición.
    // 🔴 Se mide la CARD, no el `LongPressDraggable`: el Stack recibe
    // restricciones tight y conserva el ancho, así que medirlo a él no ve
    // nada. La que se achica es la card de adentro.
    await tester.pumpWidget(montar(permisos: cuatroAccesos));
    await tester.pumpAndSettle();

    final lasCards = find.byWidgetPredicate((w) {
      final k = w.key;
      return k is ValueKey<String> && k.value.startsWith('acceso-card-');
    });

    List<Size> medirTodas() => [
          for (var i = 0; i < lasCards.evaluate().length; i++)
            tester.getSize(lasCards.at(i)),
        ];

    final antes = medirTodas();
    expect(antes, isNotEmpty);

    await tester.longPress(find.byType(LongPressDraggable<int>).first);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.close), findsWidgets);
    final despues = medirTodas();

    expect(despues, antes,
        reason: 'el control de edición no puede ocupar espacio propio');
  });

  testWidgets('tocar el ✕ esconde la card y lo persiste', (tester) async {
    await tester.pumpWidget(montar(permisos: cuatroAccesos));
    await tester.pumpAndSettle();

    final antes = find.byType(LongPressDraggable<int>).evaluate().length;

    await tester.longPress(find.byType(LongPressDraggable<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(LongPressDraggable<int>).evaluate().length, antes - 1);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getStringList('accesos_rapidos_ocultos:emp_1:user_1'),
      hasLength(1),
      reason: 'sin persistir, el acceso vuelve al reabrir el dashboard',
    );
  });

  testWidgets('🔴 esconder el ÚLTIMO acceso no deja la sección sin salida',
      (tester) async {
    // El caso que se lleva puesta la función entera: la sección se dibujaba
    // solo si había algo visible, así que esconder todo la hacía desaparecer
    // — y con ella el único lugar desde donde volver a mostrarlos. Quedaba
    // recuperable únicamente borrando los datos de la app.
    await tester.pumpWidget(
        montar(permisos: const {'canViewCotizaciones': true}));
    await tester.pumpAndSettle();

    await tester.longPress(find.byType(LongPressDraggable<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(LongPressDraggable<int>), findsNothing);
    expect(find.text('1 acceso oculto'), findsOneWidget,
        reason: 'tiene que quedar la puerta para devolverlos');
  });

  testWidgets('lo escondido se puede devolver desde el diálogo',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'accesos_rapidos_ocultos:emp_1:user_1': <String>[
        AccesosRapidosCatalogo.cotizaciones,
      ],
    });
    await tester.pumpWidget(montar(permisos: cuatroAccesos));
    await tester.pumpAndSettle();

    final conOculto = find.byType(LongPressDraggable<int>).evaluate().length;
    expect(find.text('1 acceso oculto'), findsOneWidget);

    await tester.tap(find.text('1 acceso oculto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cotizaciones'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byType(LongPressDraggable<int>).evaluate().length,
      conOculto + 1,
      reason: 'volvió a la grilla',
    );
    expect(find.text('1 acceso oculto'), findsNothing);
  });

  testWidgets('un id escondido que ya no existe se ignora', (tester) async {
    // Mismo criterio que el orden guardado: lo persistido no es una lista
    // blanca. Un id de una pantalla que sacamos del catálogo no puede dejar
    // el pie contando accesos fantasma.
    SharedPreferences.setMockInitialValues({
      'accesos_rapidos_ocultos:emp_1:user_1': <String>['pantalla-que-ya-no-esta'],
    });
    await tester.pumpWidget(montar(permisos: cuatroAccesos));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('oculto'), findsNothing);
  });
}

class _FakeEmpresaContextCubit extends EmpresaContextCubit {
  _FakeEmpresaContextCubit(EmpresaContextState estado)
      : super(_FakeGetEmpresaContext(), _FakeLocalStorage()) {
    emit(estado);
  }
}

class _FakeGetEmpresaContext implements GetEmpresaContextUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeLocalStorage implements LocalStorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeAuthBloc extends AuthBloc {
  _FakeAuthBloc()
      : super(
          checkAuthStatus: _FakeCheckAuth(),
          getLocalUser: _FakeGetLocalUser(),
          logout: _FakeLogout(),
          sessionExpiredNotifier: _FakeNotifier(),
        ) {
    emit(Authenticated(user: _usuario));
  }

  static final _usuario = User(
    id: 'user_1',
    nombres: 'Ana',
    apellidos: 'Pérez',
    emailVerificado: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}

class _FakeCheckAuth implements CheckAuthStatusUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeGetLocalUser implements GetLocalUserUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeLogout implements LogoutUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeNotifier implements SessionExpiredNotifier {
  // AuthBloc se suscribe a esto en su constructor: tiene que ser un Stream de
  // verdad, no el null que devuelve noSuchMethod.
  @override
  Stream<String> get stream => const Stream<String>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
