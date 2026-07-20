import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../data/datasources/producto_remote_datasource.dart';
import '../../../domain/entities/bulk_editar_stock_precios.dart';
import '../../../domain/entities/producto_variante.dart';
import '../../../domain/usecases/bulk_editar_stock_precios_usecase.dart';
import 'edicion_masiva_stock_state.dart';

/// Cubit de la grilla de edición masiva de stock y precios.
/// Carga las variantes del producto (con su desglose por sede) y aplica
/// los cambios en bloque vía el endpoint bulk (kardex + historial).
@injectable
class EdicionMasivaStockCubit extends Cubit<EdicionMasivaStockState> {
  final ProductoRemoteDataSource _remoteDataSource;
  final BulkEditarStockPreciosUseCase _bulkEditarUseCase;

  EdicionMasivaStockCubit(this._remoteDataSource, this._bulkEditarUseCase)
      : super(const EdicionMasivaStockInitial());

  List<ProductoVariante> _variantes = [];

  Future<void> loadVariantes({
    required String productoId,
    required String empresaId,
  }) async {
    try {
      if (isClosed) return;
      emit(const EdicionMasivaStockLoading());

      _variantes = await _remoteDataSource.getVariantes(
        productoId: productoId,
        empresaId: empresaId,
      );

      if (isClosed) return;
      emit(EdicionMasivaStockLoaded(_variantes));
    } catch (e) {
      if (isClosed) return;
      emit(EdicionMasivaStockError(_getErrorMessage(e)));
    }
  }

  Future<void> guardarCambios({
    required String sedeId,
    required String empresaId,
    required String productoId,
    required List<BulkEditarItem> items,
    String? motivo,
  }) async {
    if (isClosed) return;
    emit(EdicionMasivaStockSaving(_variantes));

    final result = await _bulkEditarUseCase(
      sedeId: sedeId,
      empresaId: empresaId,
      items: items,
      motivo: motivo,
    );

    if (isClosed) return;

    if (result is Success<BulkEditarResumen>) {
      // Recargar para reflejar stock/precios nuevos en la grilla
      try {
        _variantes = await _remoteDataSource.getVariantes(
          productoId: productoId,
          empresaId: empresaId,
        );
      } catch (_) {
        // El guardado ya fue exitoso; si el reload falla se mantiene la
        // lista anterior y el usuario puede refrescar manualmente.
      }
      if (isClosed) return;
      emit(EdicionMasivaStockSuccess(result.data, _variantes));
    } else if (result is Error<BulkEditarResumen>) {
      emit(EdicionMasivaStockError(result.message, variantes: _variantes));
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString();
    if (errorStr.contains('Exception:')) {
      return errorStr.replaceFirst('Exception:', '').trim();
    }
    return 'Error inesperado: $errorStr';
  }
}
