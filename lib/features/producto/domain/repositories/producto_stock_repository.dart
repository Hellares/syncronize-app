import '../../../../core/utils/resource.dart';
import '../entities/producto_stock.dart';
import '../entities/movimiento_stock.dart';

/// Repository interface para operaciones de stock por sede
abstract class ProductoStockRepository {
  /// Crea stock inicial en una sede
  Future<Resource<ProductoStock>> crearStock({
    required String empresaId,
    required String sedeId,
    String? productoId,
    String? varianteId,
    required int stockActual,
    int? stockMinimo,
    int? stockMaximo,
    String? ubicacion,
    double? precio,
    double? precioCosto,
    double? precioOferta,
    bool? enOferta,
    DateTime? fechaInicioOferta,
    DateTime? fechaFinOferta,
  });

  /// Lista el stock de una sede específica
  Future<Resource<Map<String, dynamic>>> getStockPorSede({
    required String sedeId,
    required String empresaId,
    int page = 1,
    int limit = 50,
  });

  /// Obtiene el stock de un producto en una sede específica
  Future<Resource<ProductoStock>> getStockProductoEnSede({
    required String productoId,
    required String sedeId,
  });

  /// Obtiene el stock de un producto en TODAS las sedes
  Future<Resource<Map<String, dynamic>>> getStockTodasSedes({
    required String productoId,
    required String empresaId,
    String? varianteId,
  });

  /// Ajusta el stock (entrada o salida)
  Future<Resource<ProductoStock>> ajustarStock({
    required String stockId,
    required String empresaId,
    required TipoMovimientoStock tipo,
    required int cantidad,
    String? motivo,
    String? observaciones,
    String? tipoDocumento,
    String? numeroDocumento,
  });

  /// Actualiza los precios de un ProductoStock
  Future<Resource<ProductoStock>> actualizarPrecios({
    required String productoStockId,
    required String empresaId,
    double? precio,
    double? precioCosto,
    double? precioOferta,
    required bool enOferta,
    DateTime? fechaInicioOferta,
    DateTime? fechaFinOferta,
  });

  /// Obtiene el historial de movimientos de un stock
  Future<Resource<List<MovimientoStock>>> getHistorialMovimientos({
    required String stockId,
    int limit = 50,
  });

  /// Obtiene alertas de productos con stock bajo el mínimo
  Future<Resource<Map<String, dynamic>>> getAlertasStockBajo({
    required String empresaId,
    String? sedeId,
  });

  /// Valida si hay stock suficiente de un combo
  Future<Resource<Map<String, dynamic>>> validarStockCombo({
    required String empresaId,
    required String comboId,
    required String sedeId,
    required int cantidad,
  });

  /// Descuenta el stock de un combo al vender
  Future<Resource<List<MovimientoStock>>> descontarStockCombo({
    required String empresaId,
    required String comboId,
    required String sedeId,
    required int cantidad,
    String? tipoDocumento,
    String? numeroDocumento,
  });

  /// Ajuste masivo de precios por sede
  Future<Resource<Map<String, dynamic>>> ajusteMasivoPreciosPorSede({
    required String sedeId,
    required String empresaId,
    required Map<String, dynamic> dto,
  });
}
