import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Nivel de detalle de logs para BLoC
enum BlocLogLevel {
  /// No mostrar logs (excepto errores críticos)
  none,

  /// Solo errores
  errors,

  /// Errores + eventos/estados importantes (default recomendado)
  important,

  /// Todo: incluye eventos triviales como cambios de formulario
  all,
}

/// BlocObserver inteligente que filtra automáticamente eventos molestos
///
/// Características:
/// - Detecta automáticamente eventos triviales por sufijo (Changed, Updated, etc.)
/// - Filtra transiciones de estado duplicadas (LoginState → LoginState)
/// - Niveles de log configurables
/// - Integración con Talker para logs estructurados
///
/// Uso:
/// ```dart
/// Bloc.observer = SmartBlocObserver(
///   talker,
///   logLevel: BlocLogLevel.important, // Default
/// );
/// ```
class SmartBlocObserver extends BlocObserver {
  final Talker talker;
  final BlocLogLevel logLevel;

  SmartBlocObserver(
    this.talker, {
    this.logLevel = BlocLogLevel.important,
  });

  /// Sufijos que indican eventos triviales de formularios
  /// Cualquier evento que termine con estos sufijos será ignorado automáticamente
  static const _trivialEventSuffixes = [
    'Changed', // EmailChanged, PasswordChanged, NameChanged, etc.
    'Updated', // FieldUpdated, ValueUpdated, etc.
    'Typed', // SearchTyped, InputTyped, etc.
    'Entered', // TextEntered, DataEntered, etc.
    'Selected', // ItemSelected, OptionSelected, etc. (para dropdowns)
    'Toggled', // SwitchToggled, CheckboxToggled, etc.
  ];

  /// Patrones que indican eventos importantes
  /// Eventos que contengan estos patrones SIEMPRE se mostrarán
  static const _importantEventPatterns = [
    'Submitted', // LoginSubmitted, RegisterSubmitted, FormSubmitted
    'Confirmed', // OrderConfirmed, PaymentConfirmed
    'Cancelled', // OrderCancelled, OperationCancelled
    'Logout', // UserLoggedOut, SessionLoggedOut
    'Delete', // ItemDeleted, RecordDeleted
    'Create', // ItemCreated, RecordCreated
    'Failed', // OperationFailed, LoginFailed
    'Success', // OperationSuccess, LoginSuccess
    'Refresh', // DataRefreshed, PageRefreshed
    'Load', // DataLoaded, PageLoaded (evitar LoadingStarted/LoadingEnded)
    'Fetch', // DataFetched, ItemsFetched
    'Save', // DataSaved, FormSaved
    'Upload', // FileUploaded, ImageUploaded
    'Download', // FileDownloaded, DataDownloaded
  ];

  /// Patrones de estados triviales a ignorar
  static const _trivialStatePatterns = [
    'FormValidating',
    'FormFieldUpdated',
    'Validating',
  ];

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    if (logLevel != BlocLogLevel.none && kDebugMode) {
      talker.debug('📦 [BLOC] ${bloc.runtimeType} creado');
    }
  }

  @override
  void onEvent(BlocBase bloc, Object? event) {
    super.onEvent(bloc as Bloc, event);

    // Respetar nivel de log
    if (logLevel == BlocLogLevel.none || logLevel == BlocLogLevel.errors) {
      return;
    }

    // En modo important, filtrar eventos triviales
    if (logLevel == BlocLogLevel.important && _shouldIgnoreEvent(event)) {
      return;
    }

    if (kDebugMode) {
      talker.debug('📨 [BLOC-EVENT] ${bloc.runtimeType} | ${event.runtimeType}');
    }
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);

    // Respetar nivel de log
    if (logLevel == BlocLogLevel.none || logLevel == BlocLogLevel.errors) {
      return;
    }

    // Ignorar si el estado no cambió realmente de tipo
    if (_isSameStateType(change.currentState, change.nextState)) {
      return;
    }

    // En modo important, filtrar estados triviales
    if (logLevel == BlocLogLevel.important &&
        _shouldIgnoreState(change.nextState)) {
      return;
    }

    if (kDebugMode) {
      talker.info(
        '📊 [BLOC-STATE] ${bloc.runtimeType}\n'
        '   ${change.currentState.runtimeType} → ${change.nextState.runtimeType}',
      );
    }
  }

  @override
  void onTransition(BlocBase bloc, Transition transition) {
    super.onTransition(bloc as Bloc, transition);

    // Respetar nivel de log
    if (logLevel == BlocLogLevel.none || logLevel == BlocLogLevel.errors) {
      return;
    }

    // Ignorar si el estado no cambió realmente de tipo
    if (_isSameStateType(transition.currentState, transition.nextState)) {
      return;
    }

    // En modo important, filtrar transiciones triviales
    if (logLevel == BlocLogLevel.important &&
        (_shouldIgnoreEvent(transition.event) ||
            _shouldIgnoreState(transition.nextState))) {
      return;
    }

    if (kDebugMode) {
      talker.info(
        '🔄 [BLOC-TRANSITION] ${bloc.runtimeType}\n'
        '   Event: ${transition.event.runtimeType}\n'
        '   ${transition.currentState.runtimeType} → ${transition.nextState.runtimeType}',
      );
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);

    // Los errores SIEMPRE se muestran (en todos los niveles de log)
    talker.error(
      '❌ [BLOC-ERROR] ${bloc.runtimeType}',
      error,
      stackTrace,
    );
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    if (logLevel != BlocLogLevel.none && kDebugMode) {
      talker.debug('🗑️ [BLOC] ${bloc.runtimeType} cerrado');
    }
  }

  /// Verifica si debemos ignorar este evento
  ///
  /// Algoritmo:
  /// 1. Si es un evento importante → NO ignorar
  /// 2. Si termina con sufijo trivial → Ignorar
  /// 3. Caso por defecto → NO ignorar (por seguridad)
  bool _shouldIgnoreEvent(Object? event) {
    if (event == null) return false;

    final eventTypeName = event.runtimeType.toString();

    // Paso 1: ¿Es un evento importante? → NO ignorar
    if (_importantEventPatterns.any((pattern) =>
        eventTypeName.contains(pattern))) {
      return false;
    }

    // Paso 2: ¿Es trivial por sufijo? → Ignorar
    if (_trivialEventSuffixes.any((suffix) =>
        eventTypeName.endsWith(suffix))) {
      return true;
    }

    // Paso 3: Por defecto NO ignorar (conservador)
    return false;
  }

  /// Verifica si debemos ignorar este estado
  bool _shouldIgnoreState(Object? state) {
    if (state == null) return false;

    final stateTypeName = state.runtimeType.toString();
    return _trivialStatePatterns.any((pattern) =>
        stateTypeName.contains(pattern));
  }

  /// Verifica si dos estados son del mismo tipo
  /// Esto evita mostrar LoginState → LoginState (validaciones)
  bool _isSameStateType(Object? currentState, Object? nextState) {
    if (currentState == null || nextState == null) return false;
    return currentState.runtimeType == nextState.runtimeType;
  }
}
