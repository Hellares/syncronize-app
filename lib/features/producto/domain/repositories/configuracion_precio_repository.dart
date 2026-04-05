import '../../../../core/utils/resource.dart';
import '../entities/configuracion_precio.dart';
import '../../data/models/configuracion_precio_model.dart';

/// Repository interface para operaciones de configuraciones de precios
abstract class ConfiguracionPrecioRepository {
  /// Crea una nueva configuración de precios
  Future<Resource<ConfiguracionPrecio>> crear(
    ConfiguracionPrecioDto dto,
  );

  /// Obtiene todas las configuraciones de la empresa
  Future<Resource<List<ConfiguracionPrecio>>> obtenerTodas();

  /// Obtiene una configuración por ID
  Future<Resource<ConfiguracionPrecio>> obtenerPorId(
    String configuracionId,
  );

  /// Actualiza una configuración
  Future<Resource<ConfiguracionPrecio>> actualizar(
    String configuracionId,
    ConfiguracionPrecioDto dto,
  );

  /// Elimina una configuración
  Future<Resource<void>> eliminar(
    String configuracionId,
  );
}
