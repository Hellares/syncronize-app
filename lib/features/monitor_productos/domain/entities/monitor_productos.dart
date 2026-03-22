import 'package:equatable/equatable.dart';

class MonitorProductos extends Equatable {
  final EstadisticasProductos estadisticas;
  final AlertasProductos alertas;

  const MonitorProductos({
    required this.estadisticas,
    required this.alertas,
  });

  @override
  List<Object?> get props => [estadisticas, alertas];
}

class EstadisticasProductos extends Equatable {
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

  const EstadisticasProductos({
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

  @override
  List<Object?> get props => [
        totalProductos,
        totalProductoStock,
        conStock,
        sinStock,
        bajoMinimo,
        conPrecio,
        sinPrecio,
        conPrecioCosto,
        sinPrecioCosto,
        conUbicacion,
        sinUbicacion,
        visibleMarketplace,
        noVisibleMarketplace,
        precioIncluyeIgv,
        precioNoIncluyeIgv,
        enOferta,
        conImagen,
        sinImagen,
        conBarcode,
        sinBarcode,
        porcentajeCatalogoCompleto,
        listosParaVenta,
      ];
}

class AlertasProductos extends Equatable {
  final List<ProductoAlerta> sinPrecio;
  final List<ProductoAlerta> sinPrecioCosto;
  final List<ProductoAlerta> sinUbicacion;
  final List<ProductoAlerta> sinImagen;
  final List<ProductoAlerta> stockCero;
  final List<ProductoAlerta> bajoMinimo;
  final List<ProductoAlerta> marketplaceSinImagen;
  final List<ProductoAlerta> precioSinIgv;

  const AlertasProductos({
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

  final List<ProductoAlerta> sinBarcode;

  @override
  List<Object?> get props => [
        sinPrecio,
        sinPrecioCosto,
        sinUbicacion,
        sinImagen,
        stockCero,
        bajoMinimo,
        marketplaceSinImagen,
        precioSinIgv,
        sinBarcode,
      ];
}

class ProductoAlerta extends Equatable {
  final String id;
  final String productoId;
  final String nombre;
  final String? codigoEmpresa;
  final String? sedeNombre;
  final String? ubicacion;
  final int stockActual;
  final double? precio;

  const ProductoAlerta({
    required this.id,
    required this.productoId,
    required this.nombre,
    this.codigoEmpresa,
    this.sedeNombre,
    this.ubicacion,
    this.stockActual = 0,
    this.precio,
  });

  @override
  List<Object?> get props => [
        id,
        productoId,
        nombre,
        codigoEmpresa,
        sedeNombre,
        ubicacion,
        stockActual,
        precio,
      ];
}
