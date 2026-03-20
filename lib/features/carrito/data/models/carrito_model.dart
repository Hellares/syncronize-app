import '../../domain/entities/carrito.dart';

class CarritoModel {
  final List<CarritoGrupoModel> empresas;
  final int totalItems;
  final int totalCantidad;
  final double total;

  const CarritoModel({
    required this.empresas,
    required this.totalItems,
    required this.totalCantidad,
    required this.total,
  });

  factory CarritoModel.fromJson(Map<String, dynamic> json) {
    return CarritoModel(
      empresas: (json['empresas'] as List<dynamic>?)
              ?.map((e) =>
                  CarritoGrupoModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalItems: json['totalItems'] as int? ?? 0,
      totalCantidad: json['totalCantidad'] as int? ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Carrito toEntity() {
    return Carrito(
      empresas: empresas.map((e) => e.toEntity()).toList(),
      totalItems: totalItems,
      totalCantidad: totalCantidad,
      total: total,
    );
  }
}

class CarritoGrupoModel {
  final CarritoEmpresaModel empresa;
  final List<CarritoItemModel> items;
  final double subtotal;

  const CarritoGrupoModel({
    required this.empresa,
    required this.items,
    required this.subtotal,
  });

  factory CarritoGrupoModel.fromJson(Map<String, dynamic> json) {
    return CarritoGrupoModel(
      empresa: CarritoEmpresaModel.fromJson(
          json['empresa'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) =>
                  CarritoItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  CarritoGrupo toEntity() {
    return CarritoGrupo(
      empresa: empresa.toEntity(),
      items: items.map((e) => e.toEntity()).toList(),
      subtotal: subtotal,
    );
  }
}

class CarritoEmpresaModel {
  final String id;
  final String nombre;
  final String? logo;
  final String? subdominio;

  const CarritoEmpresaModel({
    required this.id,
    required this.nombre,
    this.logo,
    this.subdominio,
  });

  factory CarritoEmpresaModel.fromJson(Map<String, dynamic> json) {
    return CarritoEmpresaModel(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      logo: json['logo'] as String?,
      subdominio: json['subdominio'] as String?,
    );
  }

  CarritoEmpresa toEntity() {
    return CarritoEmpresa(
      id: id,
      nombre: nombre,
      logo: logo,
      subdominio: subdominio,
    );
  }
}

class CarritoItemModel {
  final String id;
  final String productoId;
  final String? varianteId;
  final String empresaId;
  final int cantidad;
  final String productoNombre;
  final String? varianteNombre;
  final double precioUnitario;
  final double? precioOferta;
  final double precioNormal;
  final double subtotal;
  final String? imagenUrl;
  final String? thumbnailUrl;
  final int stockDisponible;
  final bool disponible;

  const CarritoItemModel({
    required this.id,
    required this.productoId,
    this.varianteId,
    required this.empresaId,
    required this.cantidad,
    required this.productoNombre,
    this.varianteNombre,
    required this.precioUnitario,
    this.precioOferta,
    required this.precioNormal,
    required this.subtotal,
    this.imagenUrl,
    this.thumbnailUrl,
    required this.stockDisponible,
    required this.disponible,
  });

  factory CarritoItemModel.fromJson(Map<String, dynamic> json) {
    return CarritoItemModel(
      id: json['id'] as String? ?? '',
      productoId: json['productoId'] as String? ?? '',
      varianteId: json['varianteId'] as String?,
      empresaId: json['empresaId'] as String? ?? '',
      cantidad: json['cantidad'] as int? ?? 1,
      productoNombre: json['productoNombre'] as String? ?? '',
      varianteNombre: json['varianteNombre'] as String?,
      precioUnitario: (json['precioUnitario'] as num?)?.toDouble() ?? 0.0,
      precioOferta: (json['precioOferta'] as num?)?.toDouble(),
      precioNormal: (json['precioNormal'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      imagenUrl: json['imagenUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      stockDisponible: json['stockDisponible'] as int? ?? 0,
      disponible: json['disponible'] as bool? ?? true,
    );
  }

  CarritoItem toEntity() {
    return CarritoItem(
      id: id,
      productoId: productoId,
      varianteId: varianteId,
      empresaId: empresaId,
      cantidad: cantidad,
      productoNombre: productoNombre,
      varianteNombre: varianteNombre,
      precioUnitario: precioUnitario,
      precioOferta: precioOferta,
      precioNormal: precioNormal,
      subtotal: subtotal,
      imagenUrl: imagenUrl,
      thumbnailUrl: thumbnailUrl,
      stockDisponible: stockDisponible,
      disponible: disponible,
    );
  }
}

class CarritoContadorModel {
  final int totalItems;
  final int totalCantidad;

  const CarritoContadorModel({
    required this.totalItems,
    required this.totalCantidad,
  });

  factory CarritoContadorModel.fromJson(Map<String, dynamic> json) {
    return CarritoContadorModel(
      totalItems: json['totalItems'] as int? ?? 0,
      totalCantidad: json['totalCantidad'] as int? ?? 0,
    );
  }
}
