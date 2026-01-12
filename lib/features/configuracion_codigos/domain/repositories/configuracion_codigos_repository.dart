import '../../../../core/utils/resource.dart';
import '../entities/configuracion_codigos.dart';

/// Repository abstracto para gestión de configuración de códigos
/// Define el contrato que debe implementar la capa de datos
abstract class ConfiguracionCodigosRepository {
  /// Obtener configuración de códigos de una empresa
  Future<Resource<ConfiguracionCodigos>> getConfiguracion(String empresaId);

  /// Actualizar configuración de productos
  Future<Resource<ConfiguracionCodigos>> updateConfigProductos({
    required String empresaId,
    String? productoCodigo,
    String? productoSeparador,
    int? productoLongitud,
    bool? productoIncluirSede,
  });

  /// Actualizar configuración de variantes
  Future<Resource<ConfiguracionCodigos>> updateConfigVariantes({
    required String empresaId,
    String? varianteCodigo,
    String? varianteSeparador,
    int? varianteLongitud,
  });

  /// Actualizar configuración de servicios
  Future<Resource<ConfiguracionCodigos>> updateConfigServicios({
    required String empresaId,
    String? servicioCodigo,
    String? servicioSeparador,
    int? servicioLongitud,
    bool? servicioIncluirSede,
  });

  /// Actualizar configuración de ventas (Notas de Venta)
  Future<Resource<ConfiguracionCodigos>> updateConfigVentas({
    required String empresaId,
    String? ventaCodigo,
    String? ventaSeparador,
    int? ventaLongitud,
    bool? ventaIncluirSede,
  });

  /// Vista previa de código
  Future<Resource<PreviewCodigo>> previewCodigo({
    required String empresaId,
    required TipoCodigo tipo,
    String? sedeId,
    int? numero,
  });

  /// Sincronizar contador con estado real de BD
  Future<Resource<Map<String, dynamic>>> sincronizarContador({
    required String empresaId,
    required String tipo, // PRODUCTO, VARIANTE, SERVICIO
  });
}
