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
