/// Historial de compras de un producto (endpoint ligero
/// GET /productos/:id/historial-compras). Para mostrar al comprar: a cuánto
/// dejó el producto cada proveedor + último costo + mejor proveedor.
class HistorialComprasResult {
  final List<HistorialCompraItem> compras;
  final List<HistorialProveedor> proveedores;
  final double? ultimoCosto;
  final String? mejorProveedorId;

  const HistorialComprasResult({
    required this.compras,
    required this.proveedores,
    this.ultimoCosto,
    this.mejorProveedorId,
  });

  bool get vacio => compras.isEmpty;

  static double? _toDoubleN(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static double _toDouble(dynamic v) => _toDoubleN(v) ?? 0;

  factory HistorialComprasResult.fromJson(Map<String, dynamic> json) {
    return HistorialComprasResult(
      compras: (json['compras'] as List<dynamic>? ?? [])
          .map((e) => HistorialCompraItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      proveedores: (json['proveedores'] as List<dynamic>? ?? [])
          .map((e) => HistorialProveedor.fromJson(e as Map<String, dynamic>))
          .toList(),
      ultimoCosto: _toDoubleN(json['ultimoCosto']),
      mejorProveedorId: json['mejorProveedorId'] as String?,
    );
  }
}

class HistorialCompraItem {
  final String? compraId;
  final String codigo;
  final DateTime? fecha;
  final String? proveedorId;
  final String proveedor;
  final String moneda;
  final int cantidad;
  final double costoUnitario;
  final double total;

  /// Si la compra se hizo en unidad de compra (saco, paquete, caja...).
  final bool usaUnidadCompra;

  /// Cantidad en unidad de compra (ej. 2 sacos). `cantidad` es la atómica.
  final double? cantidadOriginal;

  /// Símbolo de la unidad de compra (ej. "Saco").
  final String? unidadOriginalSimbolo;

  const HistorialCompraItem({
    this.compraId,
    required this.codigo,
    this.fecha,
    this.proveedorId,
    required this.proveedor,
    required this.moneda,
    required this.cantidad,
    required this.costoUnitario,
    required this.total,
    this.usaUnidadCompra = false,
    this.cantidadOriginal,
    this.unidadOriginalSimbolo,
  });

  /// Costo por paquete/saco (total ÷ cantidad en unidad de compra).
  double? get costoPaquete =>
      (cantidadOriginal != null && cantidadOriginal! > 0)
          ? total / cantidadOriginal!
          : null;

  /// Cuántas unidades atómicas trae cada paquete (factor de compra).
  double? get unidadesPorPaquete =>
      (cantidadOriginal != null && cantidadOriginal! > 0)
          ? cantidad / cantidadOriginal!
          : null;

  factory HistorialCompraItem.fromJson(Map<String, dynamic> json) {
    return HistorialCompraItem(
      compraId: json['compraId'] as String?,
      codigo: json['codigo'] as String? ?? '',
      fecha: json['fecha'] != null ? DateTime.tryParse(json['fecha'].toString()) : null,
      proveedorId: json['proveedorId'] as String?,
      proveedor: json['proveedor'] as String? ?? '—',
      moneda: json['moneda'] as String? ?? 'PEN',
      cantidad: (json['cantidad'] as num?)?.toInt() ?? 0,
      costoUnitario: HistorialComprasResult._toDouble(json['costoUnitario']),
      total: HistorialComprasResult._toDouble(json['total']),
      usaUnidadCompra: json['usaUnidadCompra'] == true,
      cantidadOriginal: HistorialComprasResult._toDoubleN(json['cantidadOriginal']),
      unidadOriginalSimbolo: json['unidadOriginalSimbolo'] as String?,
    );
  }
}

class HistorialProveedor {
  final String? proveedorId;
  final String proveedor;
  final int veces;
  final int cantidadAcum;
  final double costoPromedio;
  final double? ultimoCosto;
  final DateTime? ultimaFecha;

  const HistorialProveedor({
    this.proveedorId,
    required this.proveedor,
    required this.veces,
    required this.cantidadAcum,
    required this.costoPromedio,
    this.ultimoCosto,
    this.ultimaFecha,
  });

  factory HistorialProveedor.fromJson(Map<String, dynamic> json) {
    return HistorialProveedor(
      proveedorId: json['proveedorId'] as String?,
      proveedor: json['proveedor'] as String? ?? '—',
      veces: (json['veces'] as num?)?.toInt() ?? 0,
      cantidadAcum: (json['cantidadAcum'] as num?)?.toInt() ?? 0,
      costoPromedio: HistorialComprasResult._toDouble(json['costoPromedio']),
      ultimoCosto: HistorialComprasResult._toDoubleN(json['ultimoCosto']),
      ultimaFecha: json['ultimaFecha'] != null
          ? DateTime.tryParse(json['ultimaFecha'].toString())
          : null,
    );
  }
}
