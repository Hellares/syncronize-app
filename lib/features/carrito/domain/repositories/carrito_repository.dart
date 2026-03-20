import '../../../../core/utils/resource.dart';
import '../entities/carrito.dart';

abstract class CarritoRepository {
  Future<Resource<Carrito>> getCarrito();

  Future<Resource<Carrito>> agregarItem({
    required String productoId,
    String? varianteId,
    int cantidad = 1,
  });

  Future<Resource<Carrito>> actualizarCantidad({
    required String itemId,
    required int cantidad,
  });

  Future<Resource<Carrito>> eliminarItem({required String itemId});

  Future<Resource<Carrito>> vaciarCarrito();

  Future<Resource<CarritoContador>> getContador();
}

class CarritoContador {
  final int totalItems;
  final int totalCantidad;

  const CarritoContador({
    required this.totalItems,
    required this.totalCantidad,
  });
}
