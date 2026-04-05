import '../../domain/entities/devolucion_venta.dart';

class DevolucionVentaModel extends DevolucionVenta {
  const DevolucionVentaModel({
    required super.id, required super.codigo, required super.empresaId,
    required super.sedeId, required super.estado, super.tipoReembolso,
    super.ventaId, super.clienteId, super.motivo, super.observaciones,
    required super.creadoEn, super.aprobadoEn, super.procesadoEn,
    required super.actualizadoEn, super.sedeNombre, super.ventaCodigo,
    super.ventaNombreCliente, super.items, super.cantidadItems,
  });

  factory DevolucionVentaModel.fromJson(Map<String, dynamic> json) {
    final sede = json['sede'] as Map<String, dynamic>?;
    final venta = json['venta'] as Map<String, dynamic>?;
    final count = json['_count'] as Map<String, dynamic>?;

    List<DevolucionVentaItem>? items;
    if (json['items'] != null) {
      items = (json['items'] as List).map((e) {
        final m = e as Map<String, dynamic>;
        final producto = m['producto'] as Map<String, dynamic>?;
        final variante = m['variante'] as Map<String, dynamic>?;
        final productoReemplazo = m['productoReemplazo'] as Map<String, dynamic>?;
        return DevolucionVentaItem(
          id: m['id'] as String,
          devolucionId: m['devolucionId'] as String,
          productoId: m['productoId'] as String?,
          varianteId: m['varianteId'] as String?,
          cantidad: m['cantidad'] as int,
          motivo: MotivoDevolucion.fromString(m['motivo'] as String),
          estadoProducto: EstadoProductoDevolucion.fromString(m['estadoProducto'] as String),
          accion: AccionDevolucion.fromString(m['accion'] as String),
          observaciones: m['observaciones'] as String?,
          productoNombre: producto?['nombre'] as String?,
          varianteNombre: variante?['nombre'] as String?,
          productoReemplazoId: m['productoReemplazoId'] as String?,
          varianteReemplazoId: m['varianteReemplazoId'] as String?,
          productoReemplazoNombre: productoReemplazo?['nombre'] as String?,
          precioOriginal: _toDoubleNullable(m['precioOriginal']),
          precioReemplazo: _toDoubleNullable(m['precioReemplazo']),
          diferenciaPrecio: _toDoubleNullable(m['diferenciaPrecio']),
        );
      }).toList();
    }

    return DevolucionVentaModel(
      id: json['id'] as String,
      codigo: json['codigo'] as String,
      empresaId: json['empresaId'] as String,
      sedeId: json['sedeId'] as String,
      estado: EstadoDevolucion.fromString(json['estado'] as String),
      tipoReembolso: TipoReembolso.fromString(json['tipoReembolso'] as String? ?? 'EFECTIVO'),
      ventaId: json['ventaId'] as String?,
      clienteId: json['clienteId'] as String?,
      motivo: json['motivo'] as String?,
      observaciones: json['observaciones'] as String?,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      aprobadoEn: json['aprobadoEn'] != null ? DateTime.parse(json['aprobadoEn'] as String) : null,
      procesadoEn: json['procesadoEn'] != null ? DateTime.parse(json['procesadoEn'] as String) : null,
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
      sedeNombre: sede?['nombre'] as String?,
      ventaCodigo: venta?['codigo'] as String?,
      ventaNombreCliente: venta?['nombreCliente'] as String?,
      items: items,
      cantidadItems: count?['items'] as int?,
    );
  }

  DevolucionVenta toEntity() => this;

  static double? _toDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
