/// Un proveedor de un producto: con qué código lo identifica ÉL, cómo lo
/// llama y a cuánto salió la última vez.
///
/// Sale del diccionario `ProveedorProducto`, que el backend aprende SOLO al
/// confirmar una compra que traiga el código del proveedor.
///
/// 🔑 Este código es la equivalencia VIVA —se corrige sin tocar compras
/// viejas—, a diferencia del que queda congelado en cada línea de compra, que
/// es lo que decía el papel ese día.
library;

class ProveedorDeProducto {
  final String id;
  final String proveedorId;
  final String proveedorNombre;

  /// Cuando el proveedor codifica una VARIANTE y no el producto padre.
  final String? varianteId;
  final String? varianteNombre;

  final String? codigoProveedor;

  /// Cómo lo llama él en su factura ("WEB CAM 2K TEROS TE-9072").
  final String? descripcionProveedor;

  /// El precio PREFERENCIAL acordado, que es otra cosa que [ultimoPrecio]: uno
  /// se negocia, el otro es lo que salió de verdad la última vez.
  final double? precioCompra;
  final double? ultimoPrecio;
  final String? ultimaMoneda;
  final DateTime? ultimaCompraAt;

  final bool esPreferido;

  const ProveedorDeProducto({
    required this.id,
    required this.proveedorId,
    required this.proveedorNombre,
    this.varianteId,
    this.varianteNombre,
    this.codigoProveedor,
    this.descripcionProveedor,
    this.precioCompra,
    this.ultimoPrecio,
    this.ultimaMoneda,
    this.ultimaCompraAt,
    this.esPreferido = false,
  });

  /// 🔴 Los Decimal de Prisma llegan como String: `toDouble()` sobre un String
  /// explota, así que se parsea desde el texto.
  static double? _aDouble(Object? v) =>
      v == null ? null : double.tryParse(v.toString());

  factory ProveedorDeProducto.fromJson(Map<String, dynamic> json) =>
      ProveedorDeProducto(
        id: json['id'] as String,
        proveedorId: json['proveedorId'] as String,
        proveedorNombre: (json['proveedorNombre'] as String?) ?? '',
        varianteId: json['varianteId'] as String?,
        varianteNombre: json['varianteNombre'] as String?,
        codigoProveedor: json['codigoProveedor'] as String?,
        descripcionProveedor: json['descripcionProveedor'] as String?,
        precioCompra: _aDouble(json['precioCompra']),
        ultimoPrecio: _aDouble(json['ultimoPrecio']),
        ultimaMoneda: json['ultimaMoneda'] as String?,
        ultimaCompraAt: json['ultimaCompraAt'] != null
            ? DateTime.tryParse(json['ultimaCompraAt'].toString())
            : null,
        esPreferido: json['esPreferido'] == true,
      );
}
