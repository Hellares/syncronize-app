import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sede_selection_state.dart';

@injectable
class SedeSelectionCubit extends Cubit<SedeSelectionState> {
  final SharedPreferences _prefs;

  static const String _selectedSedeKey = 'producto_selected_sede_id';

  SedeSelectionCubit(this._prefs) : super(const SedeSelectionInitial()) {
    _loadSavedSede();
  }

  /// Carga la sede guardada anteriormente
  Future<void> _loadSavedSede() async {
    final savedSedeId = _prefs.getString(_selectedSedeKey);
    if (savedSedeId != null && savedSedeId.isNotEmpty) {
      emit(SedeSelected(savedSedeId));
    } else {
      emit(const NoSedeSelected());
    }
  }

  /// Selecciona una sede y la persiste
  Future<void> selectSede(String sedeId) async {
    await _prefs.setString(_selectedSedeKey, sedeId);
    emit(SedeSelected(sedeId));
  }

  /// Limpia la selección de sede
  Future<void> clearSede() async {
    await _prefs.remove(_selectedSedeKey);
    emit(const NoSedeSelected());
  }

  /// Obtiene el ID de la sede seleccionada actualmente
  String? get selectedSedeId {
    final currentState = state;
    if (currentState is SedeSelected) {
      return currentState.sedeId;
    }
    return null;
  }
}
