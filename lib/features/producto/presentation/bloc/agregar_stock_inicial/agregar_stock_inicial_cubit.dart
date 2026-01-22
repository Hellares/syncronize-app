import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/producto_stock.dart';
import '../../../domain/usecases/crear_stock_inicial_usecase.dart';
import 'agregar_stock_inicial_state.dart';

@injectable
class AgregarStockInicialCubit extends Cubit<AgregarStockInicialState> {
  final CrearStockInicialUseCase _crearStockInicialUseCase;

  AgregarStockInicialCubit(this._crearStockInicialUseCase)
      : super(const AgregarStockInicialInitial());

  /// Agrega stock inicial a múltiples sedes
  Future<void> agregarStockInicial({
    required String empresaId,
    required String productoId,
    required Map<String, StockInicialData> stocksPorSede,
  }) async {
    emit(const AgregarStockInicialLoading());

    final List<ProductoStock> stocksCreados = [];
    String? errorMessage;

    // Crear stock en cada sede
    for (final entry in stocksPorSede.entries) {
      final sedeId = entry.key;
      final data = entry.value;

      final result = await _crearStockInicialUseCase(
        empresaId: empresaId,
        sedeId: sedeId,
        productoId: productoId,
        stockActual: data.cantidad,
        stockMinimo: data.stockMinimo,
        stockMaximo: data.stockMaximo,
        ubicacion: data.ubicacion,
      );

      if (result is Success<ProductoStock>) {
        stocksCreados.add(result.data);
      } else if (result is Error<ProductoStock>) {
        errorMessage = result.message;
        break; // Detener si hay error
      }
    }

    if (isClosed) return;

    if (errorMessage != null) {
      emit(AgregarStockInicialError(errorMessage));
    } else {
      emit(AgregarStockInicialSuccess(stocksCreados));
    }
  }

  /// Resetea el estado
  void reset() {
    emit(const AgregarStockInicialInitial());
  }
}

/// Datos de stock inicial por sede
class StockInicialData {
  final int cantidad;
  final int? stockMinimo;
  final int? stockMaximo;
  final String? ubicacion;

  StockInicialData({
    required this.cantidad,
    this.stockMinimo,
    this.stockMaximo,
    this.ubicacion,
  });
}
