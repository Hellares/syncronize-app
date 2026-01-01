import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/usecases/asignar_usuarios.dart';
import '../../../domain/usecases/obtener_usuarios_asignados.dart';
import 'asignar_usuarios_state.dart';

@injectable
class AsignarUsuariosCubit extends Cubit<AsignarUsuariosState> {
  final AsignarUsuarios _asignarUsuarios;
  final ObtenerUsuariosAsignados _obtenerUsuariosAsignados;

  AsignarUsuariosCubit(
    this._asignarUsuarios,
    this._obtenerUsuariosAsignados,
  ) : super(const AsignarUsuariosInitial());

  String? _politicaId;
  List<Map<String, dynamic>> _usuariosAsignados = [];
  List<Map<String, dynamic>> _todosUsuarios = [];

  /// Carga la política y sus usuarios asignados
  Future<void> loadData(String politicaId, List<Map<String, dynamic>> todosUsuarios) async {
    _politicaId = politicaId;
    _todosUsuarios = todosUsuarios;

    emit(const AsignarUsuariosLoading());

    try {
      // Obtener los IDs de usuarios asignados a esta política
      final result = await _obtenerUsuariosAsignados(politicaId);

      if (result is Success<List<String>>) {
        final usuariosIds = result.data;

        // Convertir los IDs a formato Map para el estado
        _usuariosAsignados = usuariosIds
            .map((id) => <String, dynamic>{'usuarioId': id})
            .toList();

        emit(AsignarUsuariosLoaded(
          usuariosAsignados: _usuariosAsignados,
          todosUsuarios: _todosUsuarios,
        ));
      } else if (result is Error<List<String>>) {
        emit(AsignarUsuariosError(result.message, errorCode: result.errorCode));
      }
    } catch (e) {
      emit(AsignarUsuariosError('Error al cargar datos: $e'));
    }
  }

  /// Asigna usuarios seleccionados a la política
  Future<void> asignarSeleccionados(
    List<String> usuariosIds, {
    int? limiteMensualUsos,
  }) async {
    print('🟢 [CUBIT] asignarSeleccionados llamado');
    print('🟢 [CUBIT] _politicaId: $_politicaId');
    print('🟢 [CUBIT] usuariosIds: $usuariosIds');

    if (_politicaId == null) {
      print('❌ [CUBIT] _politicaId es NULL! Retornando...');
      return;
    }

    print('🟢 [CUBIT] Emitiendo AsignarUsuariosLoading...');
    emit(const AsignarUsuariosLoading());

    try {
      print('🟢 [CUBIT] Llamando a _asignarUsuarios...');
      final result = await _asignarUsuarios(
        politicaId: _politicaId!,
        usuariosIds: usuariosIds,
        limiteMensualUsos: limiteMensualUsos,
      );

      print('🟢 [CUBIT] Resultado recibido: ${result.runtimeType}');

      if (result is Success<List<Map<String, dynamic>>>) {
        print('✅ [CUBIT] Success! Usuarios asignados');
        // Actualizar lista de asignados
        final nuevosAsignados = result.data;
        _usuariosAsignados.addAll(nuevosAsignados);

        print('🟢 [CUBIT] Emitiendo AsignarUsuariosSuccess...');
        emit(const AsignarUsuariosSuccess('Usuarios asignados correctamente'));

        // Volver a estado loaded
        emit(AsignarUsuariosLoaded(
          usuariosAsignados: _usuariosAsignados,
          todosUsuarios: _todosUsuarios,
        ));
      } else if (result is Error<List<Map<String, dynamic>>>) {
        print('❌ [CUBIT] Error: ${result.message}');
        emit(AsignarUsuariosError(result.message, errorCode: result.errorCode));

        // Volver a estado loaded
        emit(AsignarUsuariosLoaded(
          usuariosAsignados: _usuariosAsignados,
          todosUsuarios: _todosUsuarios,
        ));
      }
    } catch (e) {
      print('❌ [CUBIT] Exception: $e');
      emit(AsignarUsuariosError('Error al asignar usuarios: $e'));

      // Volver a estado loaded
      emit(AsignarUsuariosLoaded(
        usuariosAsignados: _usuariosAsignados,
        todosUsuarios: _todosUsuarios,
      ));
    }
  }

  /// Resetea el estado
  void reset() {
    _politicaId = null;
    _usuariosAsignados = [];
    _todosUsuarios = [];
    emit(const AsignarUsuariosInitial());
  }
}
