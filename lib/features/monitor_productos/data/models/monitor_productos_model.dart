import '../../domain/entities/monitor_productos.dart';

class MonitorProductosModel {
  final EstadisticasProductosModel estadisticas;
  final AlertasProductosModel alertas;

  const MonitorProductosModel({
    required this.estadisticas,
    required this.alertas,
  });

  factory MonitorProductosModel.fromJson(Map<String, dynamic> json) {
    return MonitorProductosModel(
      estadisticas: EstadisticasProductosModel.fromJson(
        json['estadisticas'] as Map<String, dynamic>? ?? {},
      ),
      alertas: AlertasProductosModel.fromJson(
        json['alertas'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  MonitorProductos toEntity() {
    return MonitorProductos(
      estadisticas: estadisticas.toEntity(),
      alertas: alertas.toEntity(),
    );
  }
}

class EstadisticasProductosModel {
  final int totalProductos;
  final int totalProductoStock;
  final int conStock;
  final int sinStock;
  final int bajoMinimo;
  final int conPrecio;
  final int sinPrecio;
  final int conPrecioCosto;
  final int sinPrecioCosto;
  final int conUbicacion;
  final int sinUbicacion;
  final int visibleMarketplace;
  final int noVisibleMarketplace;
  final int precioIncluyeIgv;
  final int precioNoIncluyeIgv;
  final int enOferta;
  final int conImagen;
  final int sinImagen;
  final int conBarcode;
  final int sinBarcode;
  final double porcentajeCatalogoCompleto;
  final int listosParaVenta;

  const EstadisticasProductosModel({
    this.totalProductos = 0,
    this.totalProductoStock = 0,
    this.conStock = 0,
    this.sinStock = 0,
    this.bajoMinimo = 0,
    this.conPrecio = 0,
    this.sinPrecio = 0,
    this.conPrecioCosto = 0,
    this.sinPrecioCosto = 0,
    this.conUbicacion = 0,
    this.sinUbicacion = 0,
    this.visibleMarketplace = 0,
    this.noVisibleMarketplace = 0,
    this.precioIncluyeIgv = 0,
    this.precioNoIncluyeIgv = 0,
    this.enOferta = 0,
    this.conImagen = 0,
    this.sinImagen = 0,
    this.conBarcode = 0,
    this.sinBarcode = 0,
    this.porcentajeCatalogoCompleto = 0,
    this.listosParaVenta = 0,
  });

  factory EstadisticasProductosModel.fromJson(Map<String, dynamic> json) {
    return EstadisticasProductosModel(
      totalProductos: json['totalProductos'] as int? ?? 0,
      totalProductoStock: json['totalProductoStock'] as int? ?? 0,
      conStock: json['conStock'] as int? ?? 0,
      sinStock: json['sinStock'] as int? ?? 0,
      bajoMinimo: json['bajoMinimo'] as int? ?? 0,
      conPrecio: json['conPrecio'] as int? ?? 0,
      sinPrecio: json['sinPrecio'] as int? ?? 0,
      conPrecioCosto: json['conPrecioCosto'] as int? ?? 0,
      sinPrecioCosto: json['sinPrecioCosto'] as int? ?? 0,
      conUbicacion: json['conUbicacion'] as int? ?? 0,
      sinUbicacion: json['sinUbicacion'] as int? ?? 0,
      visibleMarketplace: json['visibleMarketplace'] as int? ?? 0,
      noVisibleMarketplace: json['noVisibleMarketplace'] as int? ?? 0,
      precioIncluyeIgv: json['precioIncluyeIgv'] as int? ?? 0,
      precioNoIncluyeIgv: json['precioNoIncluyeIgv'] as int? ?? 0,
      enOferta: json['enOferta'] as int? ?? 0,
      conImagen: json['conImagen'] as int? ?? 0,
      sinImagen: json['sinImagen'] as int? ?? 0,
      conBarcode: json['conBarcode'] as int? ?? 0,
      sinBarcode: json['sinBarcode'] as int? ?? 0,
      porcentajeCatalogoCompleto: (json['porcentajeCatalogoCompleto'] as num?)?.toDouble() ?? 0,
      listosParaVenta: json['listosParaVenta'] as int? ?? 0,
    );
  }

  EstadisticasProductos toEntity() {
    return EstadisticasProductos(
      totalProductos: totalProductos,
      totalProductoStock: totalProductoStock,
      conStock: conStock,
      sinStock: sinStock,
      bajoMinimo: bajoMinimo,
      conPrecio: conPrecio,
      sinPrecio: sinPrecio,
      conPrecioCosto: conPrecioCosto,
      sinPrecioCosto: sinPrecioCosto,
      conUbicacion: conUbicacion,
      sinUbicacion: sinUbicacion,
      visibleMarketplace: visibleMarketplace,
      noVisibleMarketplace: noVisibleMarketplace,
      precioIncluyeIgv: precioIncluyeIgv,
      precioNoIncluyeIgv: precioNoIncluyeIgv,
      enOferta: enOferta,
      conImagen: conImagen,
      sinImagen: sinImagen,
      conBarcode: conBarcode,
      sinBarcode: sinBarcode,
      porcentajeCatalogoCompleto: porcentajeCatalogoCompleto,
      listosParaVenta: listosParaVenta,
    );
  }
}

class AlertasProductosModel {
  final List<ProductoAlertaModel> sinPrecio;
  final List<ProductoAlertaModel> sinPrecioCosto;
  final List<ProductoAlertaModel> sinUbicacion;
  final List<ProductoAlertaModel> sinImagen;
  final List<ProductoAlertaModel> stockCero;
  final List<ProductoAlertaModel> bajoMinimo;
  final List<ProductoAlertaModel> marketplaceSinImagen;
  final List<ProductoAlertaModel> precioSinIgv;

  const AlertasProductosModel({
    this.sinPrecio = const [],
    this.sinPrecioCosto = const [],
    this.sinUbicacion = const [],
    this.sinImagen = const [],
    this.stockCero = const [],
    this.bajoMinimo = const [],
    this.marketplaceSinImagen = const [],
    this.precioSinIgv = const [],
    this.sinBarcode = const [],
  });

  final List<ProductoAlertaModel> sinBarcode;

  static List<ProductoAlertaModel> _parseList(dynamic json) {
    if (json == null) return [];
    final list = json as List<dynamic>;
    return list
        .map((e) => ProductoAlertaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  factory AlertasProductosModel.fromJson(Map<String, dynamic> json) {
    return AlertasProductosModel(
      sinPrecio: _parseList(json['sinPrecio']),
      sinPrecioCosto: _parseList(json['sinPrecioCosto']),
      sinUbicacion: _parseList(json['sinUbicacion']),
      sinImagen: _parseList(json['sinImagen']),
      stockCero: _parseList(json['stockCero']),
      bajoMinimo: _parseList(json['bajoMinimo']),
      marketplaceSinImagen: _parseList(json['marketplaceSinImagen']),
      precioSinIgv: _parseList(json['precioSinIgv']),
      sinBarcode: _parseList(json['sinBarcode']),
    );
  }

  AlertasProductos toEntity() {
    return AlertasProductos(
      sinPrecio: sinPrecio.map((e) => e.toEntity()).toList(),
      sinPrecioCosto: sinPrecioCosto.map((e) => e.toEntity()).toList(),
      sinUbicacion: sinUbicacion.map((e) => e.toEntity()).toList(),
      sinImagen: sinImagen.map((e) => e.toEntity()).toList(),
      stockCero: stockCero.map((e) => e.toEntity()).toList(),
      bajoMinimo: bajoMinimo.map((e) => e.toEntity()).toList(),
      marketplaceSinImagen: marketplaceSinImagen.map((e) => e.toEntity()).toList(),
      precioSinIgv: precioSinIgv.map((e) => e.toEntity()).toList(),
      sinBarcode: sinBarcode.map((e) => e.toEntity()).toList(),
    );
  }
}

class ProductoAlertaModel {
  final String id;
  final String productoId;
  final String nombre;
  final String? codigoEmpresa;
  final String? sedeNombre;
  final String? ubicacion;
  final int stockActual;
  final double? precio;

  const ProductoAlertaModel({
    required this.id,
    required this.productoId,
    required this.nombre,
    this.codigoEmpresa,
    this.sedeNombre,
    this.ubicacion,
    this.stockActual = 0,
    this.precio,
  });

  factory ProductoAlertaModel.fromJson(Map<String, dynamic> json) {
    return ProductoAlertaModel(
      id: json['id'] as String? ?? '',
      productoId: json['productoId'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      codigoEmpresa: json['codigoEmpresa'] as String?,
      sedeNombre: json['sedeNombre'] as String?,
      ubicacion: json['ubicacion'] as String?,
      stockActual: json['stockActual'] as int? ?? 0,
      precio: (json['precio'] as num?)?.toDouble(),
    );
  }

  ProductoAlerta toEntity() {
    return ProductoAlerta(
      id: id,
      productoId: productoId,
      nombre: nombre,
      codigoEmpresa: codigoEmpresa,
      sedeNombre: sedeNombre,
      ubicacion: ubicacion,
      stockActual: stockActual,
      precio: precio,
    );
  }
}
