import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/services/logger_service.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/usecases/asignar_usuarios.dart';
import '../../../domain/usecases/obtener_usuarios_asignados.dart';
import 'asignar_usuarios_state.dart';

@injectable
class AsignarUsuariosCubit extends Cubit<AsignarUsuariosState> {
  final AsignarUsuarios _asignarUsuarios;
  final ObtenerUsuariosAsignados _obtenerUsuariosAsignados;
  final LoggerService _logger;

  AsignarUsuariosCubit(
    this._asignarUsuarios,
    this._obtenerUsuariosAsignados,
    this._logger,
  ) : super(const AsignarUsuariosInitial()) {
    _logger.debug('AsignarUsuariosCubit inicializado', tag: 'AsignarUsuariosCubit');
  }

  String? _politicaId;
  List<Map<String, dynamic>> _usuariosAsignados = [];
  List<Map<String, dynamic>> _todosUsuarios = [];

  /// Carga la política y sus usuarios asignados
  Future<void> loadData(String politicaId, List<Map<String, dynamic>> todosUsuarios) async {
    _logger.info(
      'Cargando datos para política: $politicaId',
      tag: 'AsignarUsuariosCubit',
    );

    _politicaId = politicaId;
    _todosUsuarios = todosUsuarios;

    _logger.logStateChange(
      'AsignarUsuariosCubit',
      previous: state.runtimeType.toString(),
      current: 'AsignarUsuariosLoading',
    );
    emit(const AsignarUsuariosLoading());

    try {
      // Obtener los IDs de usuarios asignados a esta política
      final result = await _obtenerUsuariosAsignados(politicaId);

      if (result is Success<List<String>>) {
        final usuariosIds = result.data;

        _logger.info(
          'Usuarios asignados cargados: ${usuariosIds.length}',
          tag: 'AsignarUsuariosCubit',
        );

        // Convertir los IDs a formato Map para el estado
        _usuariosAsignados = usuariosIds
            .map((id) => <String, dynamic>{'usuarioId': id})
            .toList();

        _logger.logStateChange(
          'AsignarUsuariosCubit',
          previous: 'AsignarUsuariosLoading',
          current: 'AsignarUsuariosLoaded',
        );
        emit(AsignarUsuariosLoaded(
          usuariosAsignados: _usuariosAsignados,
          todosUsuarios: _todosUsuarios,
        ));
      } else if (result is Error<List<String>>) {
        _logger.error(
          'Error al cargar usuarios asignados: ${result.message}',
          tag: 'AsignarUsuariosCubit',
        );
        _logger.logStateChange(
          'AsignarUsuariosCubit',
          previous: 'AsignarUsuariosLoading',
          current: 'AsignarUsuariosError',
        );
        emit(AsignarUsuariosError(result.message, errorCode: result.errorCode));
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Exception al cargar datos',
        tag: 'AsignarUsuariosCubit',
        exception: e,
        stackTrace: stackTrace,
      );
      _logger.logStateChange(
        'AsignarUsuariosCubit',
        previous: 'AsignarUsuariosLoading',
        current: 'AsignarUsuariosError',
      );
      emit(AsignarUsuariosError('Error al cargar datos: $e'));
    }
  }

  /// Asigna usuarios seleccionados a la política
  Future<void> asignarSeleccionados(
    List<String> usuariosIds, {
    int? limiteMensualUsos,
  }) async {
    _logger.debug(
      'asignarSeleccionados llamado',
      tag: 'AsignarUsuariosCubit',
    );
    _logger.debug(
      'Política: $_politicaId, Usuarios: ${usuariosIds.length}',
      tag: 'AsignarUsuariosCubit',
    );

    if (_politicaId == null) {
      _logger.error(
        'Política ID es NULL, no se puede asignar usuarios',
        tag: 'AsignarUsuariosCubit',
      );
      return;
    }

    _logger.logStateChange(
      'AsignarUsuariosCubit',
      previous: state.runtimeType.toString(),
      current: 'AsignarUsuariosLoading',
    );
    emit(const AsignarUsuariosLoading());

    try {
      _logger.info(
        'Asignando ${usuariosIds.length} usuarios a política $_politicaId',
        tag: 'AsignarUsuariosCubit',
      );

      final result = await _asignarUsuarios(
        politicaId: _politicaId!,
        usuariosIds: usuariosIds,
        limiteMensualUsos: limiteMensualUsos,
      );

      _logger.debug(
        'Resultado recibido: ${result.runtimeType}',
        tag: 'AsignarUsuariosCubit',
      );

      if (result is Success<List<Map<String, dynamic>>>) {
        _logger.info(
          'Usuarios asignados exitosamente: ${result.data.length} usuarios',
          tag: 'AsignarUsuariosCubit',
        );

        // Actualizar lista de asignados
        final nuevosAsignados = result.data;
        _usuariosAsignados.addAll(nuevosAsignados);

        _logger.logStateChange(
          'AsignarUsuariosCubit',
          previous: 'AsignarUsuariosLoading',
          current: 'AsignarUsuariosSuccess',
        );
        emit(const AsignarUsuariosSuccess('Usuarios asignados correctamente'));

        // Volver a estado loaded
        _logger.logStateChange(
          'AsignarUsuariosCubit',
          previous: 'AsignarUsuariosSuccess',
          current: 'AsignarUsuariosLoaded',
        );
        emit(AsignarUsuariosLoaded(
          usuariosAsignados: _usuariosAsignados,
          todosUsuarios: _todosUsuarios,
        ));
      } else if (result is Error<List<Map<String, dynamic>>>) {
        _logger.error(
          'Error al asignar usuarios: ${result.message}',
          tag: 'AsignarUsuariosCubit',
        );
        _logger.logStateChange(
          'AsignarUsuariosCubit',
          previous: 'AsignarUsuariosLoading',
          current: 'AsignarUsuariosError',
        );
        emit(AsignarUsuariosError(result.message, errorCode: result.errorCode));

        // Volver a estado loaded
        emit(AsignarUsuariosLoaded(
          usuariosAsignados: _usuariosAsignados,
          todosUsuarios: _todosUsuarios,
        ));
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Exception al asignar usuarios',
        tag: 'AsignarUsuariosCubit',
        exception: e,
        stackTrace: stackTrace,
      );
      _logger.logStateChange(
        'AsignarUsuariosCubit',
        previous: 'AsignarUsuariosLoading',
        current: 'AsignarUsuariosError',
      );
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
    _logger.info('Reseteando estado del cubit', tag: 'AsignarUsuariosCubit');
    _logger.logStateChange(
      'AsignarUsuariosCubit',
      previous: state.runtimeType.toString(),
      current: 'AsignarUsuariosInitial',
    );

    _politicaId = null;
    _usuariosAsignados = [];
    _todosUsuarios = [];
    emit(const AsignarUsuariosInitial());
  }
}
