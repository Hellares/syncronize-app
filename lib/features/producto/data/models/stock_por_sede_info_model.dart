import 'package:syncronize/core/utils/type_converters.dart';
import '../../domain/entities/stock_por_sede_info.dart';

class StockPorSedeInfoModel extends StockPorSedeInfo {
  const StockPorSedeInfoModel({
    required super.sedeId,
    required super.sedeNombre,
    required super.sedeCodigo,
    required super.cantidad,
    super.stockMinimo,
    super.stockMaximo,
    super.ubicacion,
    super.precio,
    super.precioCosto,
    super.precioOferta,
    super.enOferta = false,
    super.fechaInicioOferta,
    super.fechaFinOferta,
    super.precioConfigurado = false,
  });

  factory StockPorSedeInfoModel.fromJson(Map<String, dynamic> json) {
    // Soporta dos formatos:
    // 1. Formato transformado del ProductoCatalogService (campos planos)
    // 2. Formato directo del marketplace (con objeto 'sede' anidado)

    String sedeId;
    String sedeNombre;
    String sedeCodigo;
    int cantidad;

    if (json.containsKey('sede')) {
      // Formato directo del marketplace (con objeto sede anidado)
      final sede = json['sede'] as Map<String, dynamic>;
      sedeId = sede['id'] as String;
      sedeNombre = sede['nombre'] as String;
      sedeCodigo = sede['codigo'] as String? ?? '';
      cantidad = json['stockActual'] as int;
    } else {
      // Formato transformado del ProductoCatalogService
      sedeId = json['sedeId'] as String;
      sedeNombre = json['sedeNombre'] as String;
      sedeCodigo = json['sedeCodigo'] as String;
      cantidad = json['cantidad'] as int;
    }

    return StockPorSedeInfoModel(
      sedeId: sedeId,
      sedeNombre: sedeNombre,
      sedeCodigo: sedeCodigo,
      cantidad: cantidad,
      stockMinimo: json['stockMinimo'] as int?,
      stockMaximo: json['stockMaximo'] as int?,
      ubicacion: json['ubicacion'] as String?,
      precio: json['precio'] != null ? toSafeDouble(json['precio']) : null,
      precioCosto: json['precioCosto'] != null ? toSafeDouble(json['precioCosto']) : null,
      precioOferta: json['precioOferta'] != null ? toSafeDouble(json['precioOferta']) : null,
      enOferta: json['enOferta'] as bool? ?? false,
      fechaInicioOferta: json['fechaInicioOferta'] != null
          ? DateTime.parse(json['fechaInicioOferta'] as String)
          : null,
      fechaFinOferta: json['fechaFinOferta'] != null
          ? DateTime.parse(json['fechaFinOferta'] as String)
          : null,
      precioConfigurado: json['precioConfigurado'] as bool? ?? false,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'sedeId': sedeId,
      'sedeNombre': sedeNombre,
      'sedeCodigo': sedeCodigo,
      'cantidad': cantidad,
      if (stockMinimo != null) 'stockMinimo': stockMinimo,
      if (stockMaximo != null) 'stockMaximo': stockMaximo,
      if (ubicacion != null) 'ubicacion': ubicacion,
      if (precio != null) 'precio': precio,
      if (precioCosto != null) 'precioCosto': precioCosto,
      if (precioOferta != null) 'precioOferta': precioOferta,
      'enOferta': enOferta,
      if (fechaInicioOferta != null) 'fechaInicioOferta': fechaInicioOferta!.toIso8601String(),
      if (fechaFinOferta != null) 'fechaFinOferta': fechaFinOferta!.toIso8601String(),
      'precioConfigurado': precioConfigurado,
    };
  }

  factory StockPorSedeInfoModel.fromEntity(StockPorSedeInfo entity) {
    return StockPorSedeInfoModel(
      sedeId: entity.sedeId,
      sedeNombre: entity.sedeNombre,
      sedeCodigo: entity.sedeCodigo,
      cantidad: entity.cantidad,
      stockMinimo: entity.stockMinimo,
      stockMaximo: entity.stockMaximo,
      ubicacion: entity.ubicacion,
      precio: entity.precio,
      precioCosto: entity.precioCosto,
      precioOferta: entity.precioOferta,
      enOferta: entity.enOferta,
      fechaInicioOferta: entity.fechaInicioOferta,
      fechaFinOferta: entity.fechaFinOferta,
      precioConfigurado: entity.precioConfigurado,
    );
  }

  StockPorSedeInfo toEntity() => this;
}
