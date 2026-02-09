import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../data/datasources/producto_remote_datasource.dart';
import 'producto_variante_state.dart';

@injectable
class ProductoVarianteCubit extends Cubit<ProductoVarianteState> {
  final ProductoRemoteDataSource _remoteDataSource;

  ProductoVarianteCubit(this._remoteDataSource)
      : super(const ProductoVarianteInitial());

  /// Cargar todas las variantes de un producto
  Future<void> loadVariantes({
    required String productoId,
    required String empresaId,
  }) async {
    try {
      if (isClosed) return;
      emit(const ProductoVarianteLoading());

      final variantes = await _remoteDataSource.getVariantes(
        productoId: productoId,
        empresaId: empresaId,
      );

      if (isClosed) return;
      emit(ProductoVarianteLoaded(variantes));
    } catch (e) {
      if (isClosed) return;
      emit(ProductoVarianteError(_getErrorMessage(e)));
    }
  }

  /// Crear una nueva variante
  Future<void> crearVariante({
    required String productoId,
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    try {
      if (isClosed) return;
      emit(const ProductoVarianteLoading());

      await _remoteDataSource.crearVariante(
        productoId: productoId,
        empresaId: empresaId,
        data: data,
      );

      // Recargar la lista
      if (isClosed) return;
      await loadVariantes(productoId: productoId, empresaId: empresaId);

      if (isClosed) return;
      final currentState = state;
      if (currentState is ProductoVarianteLoaded) {
        emit(ProductoVarianteOperationSuccess(
          'Variante creada exitosamente',
          currentState.variantes,
        ));
      }
    } catch (e) {
      if (isClosed) return;
      emit(ProductoVarianteError(_getErrorMessage(e)));
    }
  }

  /// Actualizar una variante existente
  Future<void> actualizarVariante({
    required String varianteId,
    required String productoId,
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    try {
      if (isClosed) return;
      emit(const ProductoVarianteLoading());

      await _remoteDataSource.actualizarVariante(
        varianteId: varianteId,
        empresaId: empresaId,
        data: data,
      );

      // Recargar la lista
      if (isClosed) return;
      await loadVariantes(productoId: productoId, empresaId: empresaId);

      if (isClosed) return;
      final currentState = state;
      if (currentState is ProductoVarianteLoaded) {
        emit(ProductoVarianteOperationSuccess(
          'Variante actualizada exitosamente',
          currentState.variantes,
        ));
      }
    } catch (e) {
      if (isClosed) return;
      emit(ProductoVarianteError(_getErrorMessage(e)));
    }
  }

  /// Eliminar una variante
  Future<void> eliminarVariante({
    required String varianteId,
    required String productoId,
    required String empresaId,
  }) async {
    try {
      if (isClosed) return;
      emit(const ProductoVarianteLoading());

      await _remoteDataSource.eliminarVariante(
        varianteId: varianteId,
        empresaId: empresaId,
      );

      // Recargar la lista
      if (isClosed) return;
      await loadVariantes(productoId: productoId, empresaId: empresaId);

      if (isClosed) return;
      final currentState = state;
      if (currentState is ProductoVarianteLoaded) {
        emit(ProductoVarianteOperationSuccess(
          'Variante eliminada exitosamente',
          currentState.variantes,
        ));
      }
    } catch (e) {
      if (isClosed) return;
      emit(ProductoVarianteError(_getErrorMessage(e)));
    }
  }

  /// Generar combinaciones de variantes automáticamente
  Future<void> generarCombinaciones({
    required String productoId,
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    try {
      if (isClosed) return;
      emit(const ProductoVarianteLoading());

      final variantes = await _remoteDataSource.generarCombinaciones(
        productoId: productoId,
        empresaId: empresaId,
        data: data,
      );

      // Recargar la lista
      if (isClosed) return;
      await loadVariantes(productoId: productoId, empresaId: empresaId);

      if (isClosed) return;
      final currentState = state;
      if (currentState is ProductoVarianteLoaded) {
        emit(ProductoVarianteOperationSuccess(
          '${variantes.length} variantes generadas exitosamente',
          currentState.variantes,
        ));
      }
    } catch (e) {
      if (isClosed) return;
      emit(ProductoVarianteError(_getErrorMessage(e)));
    }
  }

  /// Actualizar stock de una variante
  Future<void> actualizarStock({
    required String varianteId,
    required String productoId,
    required String empresaId,
    required int cantidad,
  }) async {
    try {
      if (isClosed) return;
      final variante = await _remoteDataSource.actualizarStockVariante(
        varianteId: varianteId,
        empresaId: empresaId,
        cantidad: cantidad,
      );

      if (isClosed) return;
      emit(ProductoVarianteStockUpdated(
        variante,
        'Stock actualizado exitosamente',
      ));

      // Recargar la lista para mantener consistencia
      if (isClosed) return;
      await loadVariantes(productoId: productoId, empresaId: empresaId);
    } catch (e) {
      if (isClosed) return;
      emit(ProductoVarianteError(_getErrorMessage(e)));
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
