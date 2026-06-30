import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/sede.dart';
import 'sede_activa_state.dart';

/// Contexto GLOBAL de "sede activa": la sede sobre la que el usuario opera el
/// POS (Venta Rápida, Caja, Productos…). Persiste la elección en prefs para que
/// se mantenga entre pantallas y sesiones.
///
/// No es `@injectable` a propósito: se construye en `bloc_provider.dart` con el
/// `SharedPreferences` del locator, sin depender de codegen.
class SedeActivaCubit extends Cubit<SedeActivaState> {
  final SharedPreferences _prefs;
  static const String _key = 'sede_activa_id';

  SedeActivaCubit(this._prefs) : super(const SedeActivaState());

  /// Sincroniza con las sedes operables del contexto de empresa. Reglas de
  /// elección (en orden): la activa actual si sigue operable → la persistida →
  /// la principal (si es operable) → la primera. Auto-selecciona cuando hay una
  /// sola. Es idempotente: se puede llamar en cada entrada a una pantalla.
  void sincronizar(List<Sede> operables, {Sede? principal}) {
    Sede? porId(String? id) {
      if (id == null || id.isEmpty) return null;
      for (final s in operables) {
        if (s.id == id) return s;
      }
      return null;
    }

    Sede? elegida;
    if (operables.isNotEmpty) {
      elegida = porId(state.activa?.id) ??
          porId(_prefs.getString(_key)) ??
          (principal != null ? porId(principal.id) : null) ??
          operables.first;
    }

    if (elegida != null) {
      _prefs.setString(_key, elegida.id);
    }
    emit(SedeActivaState(activa: elegida, operables: operables));
  }

  /// Cambia la sede activa (desde el selector) y la persiste.
  void setSede(Sede sede) {
    _prefs.setString(_key, sede.id);
    emit(state.copyWith(activa: sede));
  }
}
