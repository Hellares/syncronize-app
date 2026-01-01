import '../../../../core/utils/resource.dart';
import '../entities/precio_nivel.dart';
import '../../data/models/precio_nivel_model.dart';

/// Repository interface para operaciones de precios por nivel
abstract class PrecioNivelRepository {
  /// Crea un nivel de precio para un producto
  Future<Resource<PrecioNivel>> crearPrecioNivelProducto({
    required String productoId,
    required PrecioNivelDto dto,
  });

  /// Crea un nivel de precio para una variante
  Future<Resource<PrecioNivel>> crearPrecioNivelVariante({
    required String varianteId,
    required PrecioNivelDto dto,
  });

  /// Obtiene todos los niveles de precio de un producto
  Future<Resource<List<PrecioNivel>>> getPreciosNivelProducto({
    required String productoId,
  });

  /// Obtiene todos los niveles de precio de una variante
  Future<Resource<List<PrecioNivel>>> getPreciosNivelVariante({
    required String varianteId,
  });

  /// Obtiene un nivel de precio por ID
  Future<Resource<PrecioNivel>> getPrecioNivel({
    required String nivelId,
  });

  /// Actualiza un nivel de precio
  Future<Resource<PrecioNivel>> actualizarPrecioNivel({
    required String nivelId,
    required Map<String, dynamic> data,
  });

  /// Elimina un nivel de precio
  Future<Resource<void>> eliminarPrecioNivel({
    required String nivelId,
  });

  /// Calcula el precio según la cantidad para un producto
  Future<Resource<CalculoPrecioResult>> calcularPrecioProducto({
    required String productoId,
    required int cantidad,
  });

  /// Calcula el precio según la cantidad para una variante
  Future<Resource<CalculoPrecioResult>> calcularPrecioVariante({
    required String varianteId,
    required int cantidad,
  });
}
