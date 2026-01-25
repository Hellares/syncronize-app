import '../../domain/entities/producto_stock.dart';

class ProductoStockModel extends ProductoStock {
  const ProductoStockModel({
    required super.id,
    required super.sedeId,
    super.productoId,
    super.varianteId,
    required super.empresaId,
    required super.stockActual,
    super.stockReservado = 0,
    super.stockReservadoVenta = 0,
    super.stockDanado = 0,
    super.stockEnGarantia = 0,
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
    required super.creadoEn,
    required super.actualizadoEn,
    super.sede,
    super.producto,
    super.variante,
  });

  factory ProductoStockModel.fromJson(Map<String, dynamic> json) {
    return ProductoStockModel(
      id: json['id'] as String,
      sedeId: json['sedeId'] as String,
      productoId: json['productoId'] as String?,
      varianteId: json['varianteId'] as String?,
      empresaId: json['empresaId'] as String,
      stockActual: _toInt(json['stockActual']),
      stockReservado: json['stockReservado'] != null
          ? _toInt(json['stockReservado'])
          : 0,
      stockReservadoVenta: json['stockReservadoVenta'] != null
          ? _toInt(json['stockReservadoVenta'])
          : 0,
      stockDanado: json['stockDanado'] != null
          ? _toInt(json['stockDanado'])
          : 0,
      stockEnGarantia: json['stockEnGarantia'] != null
          ? _toInt(json['stockEnGarantia'])
          : 0,
      stockMinimo: json['stockMinimo'] != null
          ? _toInt(json['stockMinimo'])
          : null,
      stockMaximo: json['stockMaximo'] != null
          ? _toInt(json['stockMaximo'])
          : null,
      ubicacion: json['ubicacion'] as String?,
      precio: json['precio'] != null ? _toDouble(json['precio']) : null,
      precioCosto: json['precioCosto'] != null ? _toDouble(json['precioCosto']) : null,
      precioOferta: json['precioOferta'] != null ? _toDouble(json['precioOferta']) : null,
      enOferta: json['enOferta'] as bool? ?? false,
      fechaInicioOferta: json['fechaInicioOferta'] != null
          ? DateTime.parse(json['fechaInicioOferta'] as String)
          : null,
      fechaFinOferta: json['fechaFinOferta'] != null
          ? DateTime.parse(json['fechaFinOferta'] as String)
          : null,
      precioConfigurado: json['precioConfigurado'] as bool? ?? false,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
      sede: json['sede'] != null
          ? SedeStockModel.fromJson(json['sede'] as Map<String, dynamic>)
          : null,
      producto: json['producto'] != null
          ? ProductoStockInfoModel.fromJson(
              json['producto'] as Map<String, dynamic>)
          : null,
      variante: json['variante'] != null
          ? VarianteStockInfoModel.fromJson(
              json['variante'] as Map<String, dynamic>)
          : null,
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.parse(value);
    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sedeId': sedeId,
      if (productoId != null) 'productoId': productoId,
      if (varianteId != null) 'varianteId': varianteId,
      'empresaId': empresaId,
      'stockActual': stockActual,
      'stockReservado': stockReservado,
      'stockReservadoVenta': stockReservadoVenta,
      'stockDanado': stockDanado,
      'stockEnGarantia': stockEnGarantia,
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
      'creadoEn': creadoEn.toIso8601String(),
      'actualizadoEn': actualizadoEn.toIso8601String(),
    };
  }
}

class SedeStockModel extends SedeStock {
  const SedeStockModel({
    required super.id,
    required super.nombre,
    super.codigo,
    super.isActive,
  });

  factory SedeStockModel.fromJson(Map<String, dynamic> json) {
    return SedeStockModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      codigo: json['codigo'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      if (codigo != null) 'codigo': codigo,
      'isActive': isActive,
    };
  }
}

class ProductoStockInfoModel extends ProductoStockInfo {
  const ProductoStockInfoModel({
    required super.id,
    required super.nombre,
    super.codigoEmpresa,
    super.sku,
  });

  factory ProductoStockInfoModel.fromJson(Map<String, dynamic> json) {
    return ProductoStockInfoModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      codigoEmpresa: json['codigoEmpresa'] as String?,
      sku: json['sku'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      if (codigoEmpresa != null) 'codigoEmpresa': codigoEmpresa,
      if (sku != null) 'sku': sku,
    };
  }
}

class VarianteStockInfoModel extends VarianteStockInfo {
  const VarianteStockInfoModel({
    required super.id,
    required super.nombre,
    super.sku,
  });

  factory VarianteStockInfoModel.fromJson(Map<String, dynamic> json) {
    return VarianteStockInfoModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      sku: json['sku'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      if (sku != null) 'sku': sku,
    };
  }
}

/// Modelo para la respuesta de stock en todas las sedes
class StockTodasSedesModel {
  final List<ProductoStockModel> stocks;
  final ResumenStockModel resumen;

  const StockTodasSedesModel({
    required this.stocks,
    required this.resumen,
  });

  factory StockTodasSedesModel.fromJson(Map<String, dynamic> json) {
    return StockTodasSedesModel(
      stocks: (json['stocks'] as List)
          .map((e) => ProductoStockModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      resumen:
          ResumenStockModel.fromJson(json['resumen'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stocks': stocks.map((e) => e.toJson()).toList(),
      'resumen': resumen.toJson(),
    };
  }
}

class ResumenStockModel {
  final int totalSedes;
  final int stockTotal;
  final int sedesConStock;
  final int sedesSinStock;

  const ResumenStockModel({
    required this.totalSedes,
    required this.stockTotal,
    required this.sedesConStock,
    required this.sedesSinStock,
  });

  factory ResumenStockModel.fromJson(Map<String, dynamic> json) {
    return ResumenStockModel(
      totalSedes: json['totalSedes'] as int,
      stockTotal: json['stockTotal'] as int,
      sedesConStock: json['sedesConStock'] as int,
      sedesSinStock: json['sedesSinStock'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSedes': totalSedes,
      'stockTotal': stockTotal,
      'sedesConStock': sedesConStock,
      'sedesSinStock': sedesSinStock,
    };
  }
}
