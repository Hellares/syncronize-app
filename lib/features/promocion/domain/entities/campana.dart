import 'package:equatable/equatable.dart';

class Campana extends Equatable {
  final String id;
  final String empresaId;
  final String titulo;
  final String mensaje;
  final String tipo;
  final String estado;
  final int totalDestinatarios;
  final int totalEnviados;
  final List<String> productosIds;
  final String creadoPor;
  final DateTime creadoEn;
  final String? usuarioNombre;
  final String? usuarioEmail;

  const Campana({
    required this.id,
    required this.empresaId,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.estado,
    required this.totalDestinatarios,
    required this.totalEnviados,
    required this.productosIds,
    required this.creadoPor,
    required this.creadoEn,
    this.usuarioNombre,
    this.usuarioEmail,
  });

  bool get esAutomatica => tipo == 'AUTOMATICA';
  bool get esEnviada => estado == 'ENVIADA';

  @override
  List<Object?> get props => [id, estado, creadoEn];
}

class CampanasPaginadas extends Equatable {
  final List<Campana> data;
  final int total;
  final int page;
  final int totalPages;

  const CampanasPaginadas({
    required this.data,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  @override
  List<Object?> get props => [data, total, page, totalPages];
}

class ProductoEnOferta extends Equatable {
  final String productoStockId;
  final String productoId;
  final String nombre;
  final double? precio;
  final double? precioOferta;
  final DateTime? fechaInicioOferta;
  final DateTime? fechaFinOferta;
  final String sede;

  const ProductoEnOferta({
    required this.productoStockId,
    required this.productoId,
    required this.nombre,
    this.precio,
    this.precioOferta,
    this.fechaInicioOferta,
    this.fechaFinOferta,
    required this.sede,
  });

  @override
  List<Object?> get props => [productoStockId, productoId];
}
