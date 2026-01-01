import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../data/datasources/producto_remote_datasource.dart';
import 'producto_atributo_state.dart';

@injectable
class ProductoAtributoCubit extends Cubit<ProductoAtributoState> {
  final ProductoRemoteDataSource _remoteDataSource;

  ProductoAtributoCubit(this._remoteDataSource)
      : super(const ProductoAtributoInitial());

  /// Cargar todos los atributos de la empresa
  Future<void> loadAtributos(String empresaId) async {
    try {
      emit(const ProductoAtributoLoading());

      final atributos = await _remoteDataSource.getAtributos(
        empresaId: empresaId,
      );

      emit(ProductoAtributoLoaded(atributos));
    } catch (e) {
      emit(ProductoAtributoError(_getErrorMessage(e)));
    }
  }

  /// Crear un nuevo atributo
  Future<void> crearAtributo({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    try {
      emit(const ProductoAtributoLoading());

      await _remoteDataSource.crearAtributo(
        empresaId: empresaId,
        data: data,
      );

      // Recargar la lista
      await loadAtributos(empresaId);

      final currentState = state;
      if (currentState is ProductoAtributoLoaded) {
        emit(ProductoAtributoOperationSuccess(
          'Atributo creado exitosamente',
          currentState.atributos,
        ));
      }
    } catch (e) {
      emit(ProductoAtributoError(_getErrorMessage(e)));
    }
  }

  /// Crear múltiples atributos en lote
  /// Útil para aplicar plantillas o crear varios atributos a la vez
  Future<void> crearAtributosEnLote({
    required String empresaId,
    required List<Map<String, dynamic>> atributos,
  }) async {
    try {
      emit(const ProductoAtributoLoading());

      var creados = 0;
      final errores = <String>[];

      for (var data in atributos) {
        try {
          await _remoteDataSource.crearAtributo(
            empresaId: empresaId,
            data: data,
          );
          creados++;
        } catch (e) {
          errores.add('${data['nombre']}: ${_getErrorMessage(e)}');
        }
      }

      // Recargar la lista
      await loadAtributos(empresaId);

      final currentState = state;
      if (currentState is ProductoAtributoLoaded) {
        final message = errores.isEmpty
            ? '$creados atributos creados exitosamente'
            : '$creados atributos creados, ${errores.length} fallaron';

        emit(ProductoAtributoOperationSuccess(
          message,
          currentState.atributos,
        ));
      }
    } catch (e) {
      emit(ProductoAtributoError(_getErrorMessage(e)));
    }
  }

  /// Verificar si existe un atributo con la misma clave
  bool existeAtributoConClave(String clave) {
    final currentState = state;
    if (currentState is ProductoAtributoLoaded) {
      return currentState.atributos.any((a) => a.clave == clave);
    }
    return false;
  }

  /// Filtrar atributos por categoría
  List<dynamic> getAtributosPorCategoria(String? categoriaId) {
    final currentState = state;
    if (currentState is ProductoAtributoLoaded) {
      if (categoriaId == null) {
        return currentState.atributos.where((a) => a.categoriaId == null).toList();
      }
      return currentState.atributos.where((a) => a.categoriaId == categoriaId).toList();
    }
    return [];
  }

  /// Actualizar un atributo existente
  Future<void> actualizarAtributo({
    required String atributoId,
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    try {
      emit(const ProductoAtributoLoading());

      await _remoteDataSource.actualizarAtributo(
        atributoId: atributoId,
        empresaId: empresaId,
        data: data,
      );

      // Recargar la lista
      await loadAtributos(empresaId);

      final currentState = state;
      if (currentState is ProductoAtributoLoaded) {
        emit(ProductoAtributoOperationSuccess(
          'Atributo actualizado exitosamente',
          currentState.atributos,
        ));
      }
    } catch (e) {
      emit(ProductoAtributoError(_getErrorMessage(e)));
    }
  }

  /// Eliminar un atributo
  Future<void> eliminarAtributo({
    required String atributoId,
    required String empresaId,
  }) async {
    try {
      emit(const ProductoAtributoLoading());

      await _remoteDataSource.eliminarAtributo(
        atributoId: atributoId,
        empresaId: empresaId,
      );

      // Recargar la lista
      await loadAtributos(empresaId);

      final currentState = state;
      if (currentState is ProductoAtributoLoaded) {
        emit(ProductoAtributoOperationSuccess(
          'Atributo eliminado exitosamente',
          currentState.atributos,
        ));
      }
    } catch (e) {
      emit(ProductoAtributoError(_getErrorMessage(e)));
    }
  }

  /// Obtener mensaje de error legible
  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString();
    if (errorStr.contains('Exception:')) {
      return errorStr.replaceFirst('Exception:', '').trim();
    }
    return 'Error inesperado: $errorStr';
  }
}
