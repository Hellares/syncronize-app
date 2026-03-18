import '../../domain/entities/campana.dart';

class CampanaModel extends Campana {
  const CampanaModel({
    required super.id,
    required super.empresaId,
    required super.titulo,
    required super.mensaje,
    required super.tipo,
    required super.estado,
    required super.totalDestinatarios,
    required super.totalEnviados,
    required super.productosIds,
    required super.creadoPor,
    required super.creadoEn,
    super.usuarioNombre,
    super.usuarioEmail,
  });

  factory CampanaModel.fromJson(Map<String, dynamic> json) {
    final usuario = json['usuario'] as Map<String, dynamic>?;
    final persona = usuario?['persona'] as Map<String, dynamic>?;
    final productosRaw = json['productosIds'];

    return CampanaModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      titulo: json['titulo'] as String,
      mensaje: json['mensaje'] as String,
      tipo: json['tipo'] as String? ?? 'MANUAL',
      estado: json['estado'] as String? ?? 'ENVIADA',
      totalDestinatarios: json['totalDestinatarios'] as int? ?? 0,
      totalEnviados: json['totalEnviados'] as int? ?? 0,
      productosIds: productosRaw is List
          ? productosRaw.map((e) => e.toString()).toList()
          : <String>[],
      creadoPor: json['creadoPor'] as String,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      usuarioNombre: persona?['nombres'] as String?,
      usuarioEmail: usuario?['email'] as String?,
    );
  }

  Campana toEntity() => this;
}

class ProductoEnOfertaModel extends ProductoEnOferta {
  const ProductoEnOfertaModel({
    required super.productoStockId,
    required super.productoId,
    required super.nombre,
    super.precio,
    super.precioOferta,
    super.fechaInicioOferta,
    super.fechaFinOferta,
    required super.sede,
  });

  factory ProductoEnOfertaModel.fromJson(Map<String, dynamic> json) {
    return ProductoEnOfertaModel(
      productoStockId: json['productoStockId'] as String,
      productoId: json['productoId'] as String,
      nombre: json['nombre'] as String,
      precio: (json['precio'] as num?)?.toDouble(),
      precioOferta: (json['precioOferta'] as num?)?.toDouble(),
      fechaInicioOferta: json['fechaInicioOferta'] != null
          ? DateTime.parse(json['fechaInicioOferta'] as String)
          : null,
      fechaFinOferta: json['fechaFinOferta'] != null
          ? DateTime.parse(json['fechaFinOferta'] as String)
          : null,
      sede: json['sede'] as String,
    );
  }

  ProductoEnOferta toEntity() => this;
}
