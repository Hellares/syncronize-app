import 'package:equatable/equatable.dart';

class Carrito extends Equatable {
  final List<CarritoGrupo> empresas;
  final int totalItems;
  final int totalCantidad;
  final double total;

  const Carrito({
    required this.empresas,
    required this.totalItems,
    required this.totalCantidad,
    required this.total,
  });

  bool get isEmpty => empresas.isEmpty;

  @override
  List<Object?> get props => [empresas, totalItems, totalCantidad, total];
}

class CarritoGrupo extends Equatable {
  final CarritoEmpresa empresa;
  final List<CarritoItem> items;
  final double subtotal;

  const CarritoGrupo({
    required this.empresa,
    required this.items,
    required this.subtotal,
  });

  @override
  List<Object?> get props => [empresa, items, subtotal];
}

class CarritoEmpresa extends Equatable {
  final String id;
  final String nombre;
  final String? logo;
  final String? subdominio;

  const CarritoEmpresa({
    required this.id,
    required this.nombre,
    this.logo,
    this.subdominio,
  });

  @override
  List<Object?> get props => [id, nombre, logo, subdominio];
}

class CarritoItem extends Equatable {
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

  const CarritoItem({
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

  bool get tieneOferta => precioOferta != null && precioOferta! < precioNormal;

  @override
  List<Object?> get props => [
        id,
        productoId,
        varianteId,
        cantidad,
        precioUnitario,
        subtotal,
        disponible,
      ];
}
