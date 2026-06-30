import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/datasources/sede_onboarding_api.dart';

class SedeActivacionState extends Equatable {
  final bool cargando;
  final String? error;
  final SedeReadiness? readiness;
  final List<SedeUsuario> usuarios;

  const SedeActivacionState({
    this.cargando = false,
    this.error,
    this.readiness,
    this.usuarios = const [],
  });

  SedeActivacionState copyWith({
    bool? cargando,
    String? error,
    bool limpiarError = false,
    SedeReadiness? readiness,
    List<SedeUsuario>? usuarios,
  }) {
    return SedeActivacionState(
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
      readiness: readiness ?? this.readiness,
      usuarios: usuarios ?? this.usuarios,
    );
  }

  @override
  List<Object?> get props => [cargando, error, readiness, usuarios];
}

class SedeActivacionCubit extends Cubit<SedeActivacionState> {
  final SedeOnboardingApi _api;
  final String empresaId;
  final String sedeId;

  SedeActivacionCubit(this._api, {required this.empresaId, required this.sedeId})
      : super(const SedeActivacionState());

  Future<void> cargar() async {
    emit(state.copyWith(cargando: true, limpiarError: true));
    try {
      final results = await Future.wait([
        _api.getReadiness(empresaId, sedeId),
        _api.getUsuarios(empresaId, sedeId),
      ]);
      emit(state.copyWith(
        cargando: false,
        readiness: results[0] as SedeReadiness,
        usuarios: results[1] as List<SedeUsuario>,
      ));
    } catch (e) {
      emit(state.copyWith(cargando: false, error: _msg(e)));
    }
  }

  /// Asigna un usuario y recarga. Devuelve null si OK, o el mensaje de error.
  Future<String?> asignar({
    required String usuarioId,
    required String rol,
    bool puedeAbrirCaja = false,
  }) async {
    try {
      await _api.asignarUsuario(
        empresaId,
        sedeId,
        usuarioId: usuarioId,
        rol: rol,
        puedeAbrirCaja: puedeAbrirCaja,
      );
      await cargar();
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  /// Quita un usuario de la sede y recarga.
  Future<String?> remover(String usuarioSedeRolId) async {
    try {
      await _api.removerUsuario(empresaId, sedeId, usuarioSedeRolId);
      await cargar();
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  String _msg(Object e) {
    final s = e.toString();
    return s.length > 160 ? s.substring(0, 160) : s;
  }
}
