import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/producto_stock.dart';
import '../../../domain/entities/movimiento_stock.dart';
import '../../../domain/usecases/crear_stock_inicial_usecase.dart';
import '../../../domain/usecases/get_stock_producto_en_sede_usecase.dart';
import '../../../domain/usecases/actualizar_precios_producto_stock_usecase.dart';
import '../../../domain/usecases/ajustar_stock_usecase.dart';
import 'agregar_stock_inicial_state.dart';

@injectable
class AgregarStockInicialCubit extends Cubit<AgregarStockInicialState> {
  final CrearStockInicialUseCase _crearStockInicialUseCase;
  final GetStockProductoEnSedeUseCase _getStockProductoEnSedeUseCase;
  final ActualizarPreciosProductoStockUseCase _actualizarPreciosUseCase;
  final AjustarStockUseCase _ajustarStockUseCase;

  AgregarStockInicialCubit(
    this._crearStockInicialUseCase,
    this._getStockProductoEnSedeUseCase,
    this._actualizarPreciosUseCase,
    this._ajustarStockUseCase,
  ) : super(const AgregarStockInicialInitial());

  /// Agrega stock inicial a múltiples sedes
  Future<void> agregarStockInicial({
    required String empresaId,
    required String productoId,
    required Map<String, StockInicialData> stocksPorSede,
  }) async {
    emit(const AgregarStockInicialLoading());

    final List<ProductoStock> stocksCreados = [];
    String? errorMessage;

    // Crear/Actualizar stock en cada sede
    for (final entry in stocksPorSede.entries) {
      final sedeId = entry.key;
      final data = entry.value;

      // 1. Verificar si ya existe un registro de ProductoStock para este producto en esta sede
      final getStockResult = await _getStockProductoEnSedeUseCase(
        productoId: productoId,
        sedeId: sedeId,
      );

      Resource<ProductoStock> result;

      if (getStockResult is Success<ProductoStock>) {
        // Ya existe un registro, actualizarlo
        final stockExistente = getStockResult.data;

        // 1a. Actualizar precios
        final actualizarPreciosResult = await _actualizarPreciosUseCase(
          productoStockId: stockExistente.id,
          empresaId: empresaId,
          precio: data.precio,
          precioCosto: data.precioCosto,
          precioOferta: data.precioOferta,
          enOferta: data.enOferta ?? false,
          fechaInicioOferta: data.fechaInicioOferta,
          fechaFinOferta: data.fechaFinOferta,
        );

        if (actualizarPreciosResult is Error<ProductoStock>) {
          errorMessage = actualizarPreciosResult.message;
          break;
        }

        // 1b. Ajustar stock (si es mayor a 0)
        if (data.cantidad > stockExistente.stockActual) {
          final diferencia = data.cantidad - stockExistente.stockActual;
          final ajustarStockResult = await _ajustarStockUseCase(
            stockId: stockExistente.id,
            empresaId: empresaId,
            tipo: TipoMovimientoStock.entradaAjuste,
            cantidad: diferencia,
            motivo: 'Stock inicial',
          );

          if (ajustarStockResult is Success<ProductoStock>) {
            result = ajustarStockResult;
          } else {
            errorMessage = (ajustarStockResult as Error).message;
            break;
          }
        } else {
          // Si no hay que ajustar stock, obtener el stock actualizado
          result = await _getStockProductoEnSedeUseCase(
            productoId: productoId,
            sedeId: sedeId,
          );
        }
      } else {
        // No existe, crear uno nuevo
        result = await _crearStockInicialUseCase(
          empresaId: empresaId,
          sedeId: sedeId,
          productoId: productoId,
          stockActual: data.cantidad,
          stockMinimo: data.stockMinimo,
          stockMaximo: data.stockMaximo,
          ubicacion: data.ubicacion,
          precio: data.precio,
          precioCosto: data.precioCosto,
          precioOferta: data.precioOferta,
          enOferta: data.enOferta,
          fechaInicioOferta: data.fechaInicioOferta,
          fechaFinOferta: data.fechaFinOferta,
        );
      }

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
  final double? precio;
  final double? precioCosto;
  final double? precioOferta;
  final bool? enOferta;
  final DateTime? fechaInicioOferta;
  final DateTime? fechaFinOferta;

  StockInicialData({
    required this.cantidad,
    this.stockMinimo,
    this.stockMaximo,
    this.ubicacion,
    this.precio,
    this.precioCosto,
    this.precioOferta,
    this.enOferta,
    this.fechaInicioOferta,
    this.fechaFinOferta,
  });
}
