import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../data/models/producto_stock_simple_model.dart';
import '../../../domain/usecases/get_productos_stock_usecase.dart';

part 'productos_stock_selector_state.dart';

// Modelo temporal para producto stock (simplificado)
class ProductoStockSimple {
  final String id;
  final String nombre;
  final String? sku;
  final int cantidadDisponible;

  const ProductoStockSimple({
    required this.id,
    required this.nombre,
    this.sku,
    required this.cantidadDisponible,
  });

  factory ProductoStockSimple.fromModel(ProductoStockSimpleModel model) {
    return ProductoStockSimple(
      id: model.id,
      nombre: model.nombreCompleto,
      sku: model.sku,
      cantidadDisponible: model.stockDisponible,
    );
  }
}

@injectable
class ProductosStockSelectorCubit extends Cubit<ProductosStockSelectorState> {
  final GetProductosStockUseCase _getProductosStockUseCase;

  ProductosStockSelectorCubit(this._getProductosStockUseCase)
      : super(const ProductosStockSelectorInitial());

  Future<void> cargarProductos({
    required String empresaId,
    required String sedeId,
  }) async {
    emit(const ProductosStockSelectorLoading());

    try {
      final result = await _getProductosStockUseCase.call(
        empresaId: empresaId,
        sedeId: sedeId,
      );

      switch (result) {
        case Success<List<ProductoStockSimpleModel>>():
          final productosSimples = result.data
              .where((producto) => producto.stockDisponible > 0)
              .map((producto) => ProductoStockSimple.fromModel(producto))
              .toList();
          emit(ProductosStockSelectorLoaded(productosSimples));
        case Error<List<ProductoStockSimpleModel>>():
          emit(ProductosStockSelectorError(result.message));
      }
    } catch (e) {
      emit(ProductosStockSelectorError(e.toString()));
    }
  }
}
