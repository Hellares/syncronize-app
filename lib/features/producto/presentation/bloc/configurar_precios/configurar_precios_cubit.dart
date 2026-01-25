import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/producto_stock.dart';
import '../../../domain/usecases/actualizar_precios_producto_stock_usecase.dart';
import 'configurar_precios_state.dart';

/// Cubit para manejar la configuración de precios por sede
@injectable
class ConfigurarPreciosCubit extends Cubit<ConfigurarPreciosState> {
  final ActualizarPreciosProductoStockUseCase _actualizarPreciosUseCase;

  ConfigurarPreciosCubit(this._actualizarPreciosUseCase)
      : super(const ConfigurarPreciosInitial());

  /// Configura los precios de un ProductoStock
  Future<void> configurarPrecios({
    required String productoStockId,
    required String empresaId,
    double? precio,
    double? precioCosto,
    double? precioOferta,
    required bool enOferta,
    DateTime? fechaInicioOferta,
    DateTime? fechaFinOferta,
  }) async {
    emit(const ConfigurarPreciosLoading());

    final result = await _actualizarPreciosUseCase(
      productoStockId: productoStockId,
      empresaId: empresaId,
      precio: precio,
      precioCosto: precioCosto,
      precioOferta: precioOferta,
      enOferta: enOferta,
      fechaInicioOferta: fechaInicioOferta,
      fechaFinOferta: fechaFinOferta,
    );

    if (result is Success<ProductoStock>) {
      emit(ConfigurarPreciosSuccess(stock: result.data));
    } else if (result is Error<ProductoStock>) {
      emit(ConfigurarPreciosError(result.message));
    }
  }

  /// Resetea el estado
  void reset() {
    emit(const ConfigurarPreciosInitial());
  }
}
