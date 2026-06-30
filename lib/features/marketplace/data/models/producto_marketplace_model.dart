import '../../domain/entities/producto_marketplace.dart';

/// Parseo defensivo a double (la API puede enviar num o string).
double? _toDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

DateTime? _toDateOrNull(dynamic value) {
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

class EmpresaMarketplaceModel {
  final String id;
  final String nombre;
  final String? logo;
  final String? subdominio;
  final String? telefono;
  final String ubicacion;

  const EmpresaMarketplaceModel({
    required this.id,
    required this.nombre,
    this.logo,
    this.subdominio,
    this.telefono,
    this.ubicacion = '',
  });

  factory EmpresaMarketplaceModel.fromJson(Map<String, dynamic> json) {
    return EmpresaMarketplaceModel(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      logo: json['logo'] as String?,
      subdominio: json['subdominio'] as String?,
      telefono: json['telefono'] as String?,
      ubicacion: json['ubicacion'] as String? ?? '',
    );
  }

  EmpresaMarketplace toEntity() => EmpresaMarketplace(
        id: id,
        nombre: nombre,
        logo: logo,
        subdominio: subdominio,
        telefono: telefono,
        ubicacion: ubicacion,
      );
}

class ProductoMarketplaceModel {
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
  final EmpresaMarketplaceModel empresa;

  const ProductoMarketplaceModel({
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

  factory ProductoMarketplaceModel.fromJson(Map<String, dynamic> json) {
    final empresaJson = json['empresa'] as Map<String, dynamic>? ?? const {};
    return ProductoMarketplaceModel(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      categoria: json['categoria'] as String?,
      marca: json['marca'] as String?,
      precio: _toDoubleOrNull(json['precio']),
      precioOferta: _toDoubleOrNull(json['precioOferta']),
      enOferta: json['enOferta'] as bool? ?? false,
      hayStock: json['hayStock'] as bool? ?? false,
      imagen: json['imagen'] as String?,
      calificacion: _toDoubleOrNull(json['calificacion']),
      totalOpiniones: json['totalOpiniones'] as int? ?? 0,
      distancia: _toDoubleOrNull(json['distancia']),
      destacado: json['destacado'] as bool? ?? false,
      creadoEn: _toDateOrNull(json['creadoEn']),
      empresa: EmpresaMarketplaceModel.fromJson(empresaJson),
    );
  }

  ProductoMarketplace toEntity() => ProductoMarketplace(
        id: id,
        nombre: nombre,
        descripcion: descripcion,
        categoria: categoria,
        marca: marca,
        precio: precio,
        precioOferta: precioOferta,
        enOferta: enOferta,
        hayStock: hayStock,
        imagen: imagen,
        calificacion: calificacion,
        totalOpiniones: totalOpiniones,
        distancia: distancia,
        destacado: destacado,
        creadoEn: creadoEn,
        empresa: empresa.toEntity(),
      );
}
