class ProductoStockSimpleModel {
  final String id;
  final String productoId;
  final String? varianteId;
  final String sedeId;
  final String nombreProducto;
  final String? nombreVariante;
  final String? sku;
  final int stockActual;
  final int stockDisponible;

  const ProductoStockSimpleModel({
    required this.id,
    required this.productoId,
    this.varianteId,
    required this.sedeId,
    required this.nombreProducto,
    this.nombreVariante,
    this.sku,
    required this.stockActual,
    required this.stockDisponible,
  });

  factory ProductoStockSimpleModel.fromJson(Map<String, dynamic> json) {
    // Extraer información del producto y variante anidados
    final producto = json['producto'] as Map<String, dynamic>?;
    final variante = json['variante'] as Map<String, dynamic>?;

    String nombreProducto = 'Producto';
    String? nombreVariante;
    String? sku;

    if (producto != null) {
      nombreProducto = producto['nombre'] as String? ?? 'Producto';
      sku = producto['codigoSistema'] as String?;
    }

    if (variante != null) {
      nombreVariante = variante['nombre'] as String?;
      if (variante['sku'] != null) {
        sku = variante['sku'] as String;
      }
    }

    return ProductoStockSimpleModel(
      id: json['id'] as String,
      productoId: json['productoId'] as String,
      varianteId: json['varianteId'] as String?,
      sedeId: json['sedeId'] as String,
      nombreProducto: nombreProducto,
      nombreVariante: nombreVariante,
      sku: sku,
      stockActual: _toInt(json['stockActual']),
      stockDisponible: _toInt(json['stockDisponible']),
    );
  }

  String get nombreCompleto {
    if (nombreVariante != null && nombreVariante!.isNotEmpty) {
      return '$nombreProducto - $nombreVariante';
    }
    return nombreProducto;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
