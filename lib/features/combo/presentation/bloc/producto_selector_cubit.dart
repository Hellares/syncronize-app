import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../../producto/domain/entities/producto.dart';
import '../../../producto/domain/usecases/get_productos_disponibles_para_combo_usecase.dart';
import 'producto_selector_state.dart';

@injectable
class ProductoSelectorCubit extends Cubit<ProductoSelectorState> {
  final GetProductosDisponiblesParaComboUseCase _getProductosDisponibles;

  ProductoSelectorCubit(this._getProductosDisponibles)
      : super(ProductoSelectorInitial());

  /// Carga los productos disponibles para usar como componentes
  Future<void> loadProductosDisponibles({
    required String empresaId,
  }) async {
    emit(ProductoSelectorLoading());

    final result = await _getProductosDisponibles(empresaId: empresaId);

    if (result is Success<List<Producto>>) {
      emit(ProductosDisponiblesLoaded(result.data));
    } else if (result is Error) {
      final error = result as Error;
      emit(ProductoSelectorError(
        error.message,
        errorCode: error.errorCode,
      ));
    }
  }

  /// Selecciona un producto
  void selectProducto(Producto producto) {
    emit(ProductoSelected(producto));
  }

  /// Deselecciona el producto actual
  void clearSelection() {
    emit(ProductoSelectorInitial());
  }
}
