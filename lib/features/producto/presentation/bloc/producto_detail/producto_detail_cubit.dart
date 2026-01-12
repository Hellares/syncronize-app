import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/producto.dart';
import '../../../domain/usecases/get_producto_usecase.dart';
import 'producto_detail_state.dart';

@injectable
class ProductoDetailCubit extends Cubit<ProductoDetailState> {
  final GetProductoUseCase _getProductoUseCase;

  ProductoDetailCubit(
    this._getProductoUseCase,
  ) : super(const ProductoDetailInitial());

  String? _currentProductoId;
  String? _currentEmpresaId;

  /// Carga el detalle de un producto
  Future<void> loadProducto({
    required String productoId,
    required String empresaId,
  }) async {
    _currentProductoId = productoId;
    _currentEmpresaId = empresaId;

    emit(const ProductoDetailLoading());

    final result = await _getProductoUseCase(
      productoId: productoId,
      empresaId: empresaId,
    );

    // Verificar que el cubit no se haya cerrado antes de emitir
    if (isClosed) return;

    if (result is Success<Producto>) {
      emit(ProductoDetailLoaded(result.data));
    } else if (result is Error<Producto>) {
      emit(ProductoDetailError(result.message, errorCode: result.errorCode));
    }
  }

  /// Recarga el producto actual
  Future<void> reload() async {
    if (_currentProductoId == null || _currentEmpresaId == null) return;

    await loadProducto(
      productoId: _currentProductoId!,
      empresaId: _currentEmpresaId!,
    );
  }

  /// Limpia el estado
  void clear() {
    _currentProductoId = null;
    _currentEmpresaId = null;
    emit(const ProductoDetailInitial());
  }
}
