import 'package:equatable/equatable.dart';

/// Información resumida de la empresa vendedora dentro de una card del marketplace.
class EmpresaMarketplace extends Equatable {
  final String id;
  final String nombre;
  final String? logo;
  final String? subdominio;
  final String? telefono;
  final String ubicacion;

  const EmpresaMarketplace({
    required this.id,
    required this.nombre,
    this.logo,
    this.subdominio,
    this.telefono,
    this.ubicacion = '',
  });

  @override
  List<Object?> get props => [id, nombre, logo, subdominio, telefono, ubicacion];
}

/// Producto tal como se muestra en las cards y carruseles del marketplace.
///
/// Corresponde al shape que arma el backend en `_mapearProductos`
/// (listado, home, vistos y recomendados comparten esta forma).
class ProductoMarketplace extends Equatable {
  final String id;
  final String nombre;
  final String? descripcion;
  final String? categoria;
  final String? marca;
  final double? precio;
  final double? precioOferta;
  final bool enOferta;
  final bool hayStock;
  final String? imagen;
  final double? calificacion;
  final int totalOpiniones;
  final double? distancia;
  final bool destacado;
  final DateTime? creadoEn;
  final EmpresaMarketplace empresa;

  const ProductoMarketplace({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.categoria,
    this.marca,
    this.precio,
    this.precioOferta,
    this.enOferta = false,
    this.hayStock = false,
    this.imagen,
    this.calificacion,
    this.totalOpiniones = 0,
    this.distancia,
    this.destacado = false,
    this.creadoEn,
    required this.empresa,
  });

  /// Precio efectivo a mostrar (oferta vigente si aplica).
  double? get precioFinal =>
      enOferta && precioOferta != null ? precioOferta : precio;

  /// Si hay un descuento real calculable (oferta vigente + precio base).
  bool get tieneDescuento =>
      enOferta && precioOferta != null && precio != null;

  /// Porcentaje de descuento redondeado (0 si no aplica).
  int get descuentoPct => tieneDescuento && precio! > 0
      ? ((1 - precioOferta! / precio!) * 100).round()
      : 0;

  /// Producto publicado hace 2 días o menos.
  bool get esNuevo =>
      creadoEn != null && DateTime.now().difference(creadoEn!).inDays <= 2;

  /// Tiene opiniones suficientes para mostrar calificación.
  bool get tieneCalificacion => calificacion != null && totalOpiniones > 0;

  @override
  List<Object?> get props => [
        id,
        nombre,
        descripcion,
        categoria,
        marca,
        precio,
        precioOferta,
        enOferta,
        hayStock,
        imagen,
        calificacion,
        totalOpiniones,
        distancia,
        destacado,
        creadoEn,
        empresa,
      ];
}
