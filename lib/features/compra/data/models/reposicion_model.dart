/// Ítem de reposición sugerida (compras proactivas): producto con stock ≤ mínimo
/// + cantidad sugerida + mejor proveedor histórico.
class ReposicionItem {
  final String? productoId;
  final String? varianteId;
  final String nombre;
  final String? varianteNombre;
  final String? codigoEmpresa;
  final String sedeId;
  final String? sedeNombre;
  final int stockActual;
  final int stockMinimo;
  final int faltante;
  final int sugeridoComprar;
  final double? costoActual;
  final double? ultimoCosto;
  final ReposicionProveedor? mejorProveedor;

  const ReposicionItem({
    this.productoId,
    this.varianteId,
    required this.nombre,
    this.varianteNombre,
    this.codigoEmpresa,
    required this.sedeId,
    this.sedeNombre,
    required this.stockActual,
    required this.stockMinimo,
    required this.faltante,
    required this.sugeridoComprar,
    this.costoActual,
    this.ultimoCosto,
    this.mejorProveedor,
  });

  static double? _toDoubleN(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  factory ReposicionItem.fromJson(Map<String, dynamic> json) {
    return ReposicionItem(
      productoId: json['productoId'] as String?,
      varianteId: json['varianteId'] as String?,
      nombre: json['nombre'] as String? ?? 'Producto',
      varianteNombre: json['varianteNombre'] as String?,
      codigoEmpresa: json['codigoEmpresa'] as String?,
      sedeId: json['sedeId'] as String? ?? '',
      sedeNombre: json['sedeNombre'] as String?,
      stockActual: (json['stockActual'] as num?)?.toInt() ?? 0,
      stockMinimo: (json['stockMinimo'] as num?)?.toInt() ?? 0,
      faltante: (json['faltante'] as num?)?.toInt() ?? 0,
      sugeridoComprar: (json['sugeridoComprar'] as num?)?.toInt() ?? 0,
      costoActual: _toDoubleN(json['costoActual']),
      ultimoCosto: _toDoubleN(json['ultimoCosto']),
      mejorProveedor: json['mejorProveedor'] != null
          ? ReposicionProveedor.fromJson(json['mejorProveedor'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ReposicionProveedor {
  final String? proveedorId;
  final String proveedor;
  final double costoPromedio;

  const ReposicionProveedor({
    this.proveedorId,
    required this.proveedor,
    required this.costoPromedio,
  });

  factory ReposicionProveedor.fromJson(Map<String, dynamic> json) {
    return ReposicionProveedor(
      proveedorId: json['proveedorId'] as String?,
      proveedor: json['proveedor'] as String? ?? '—',
      costoPromedio: ReposicionItem._toDoubleN(json['costoPromedio']) ?? 0,
    );
  }
}
