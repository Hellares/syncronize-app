import 'package:equatable/equatable.dart';

/// MONITOR DE MAYOREO COMBINADO — cómo quedan agrupadas las variantes de un
/// producto según sus niveles de precio.
///
/// El grupo es IMPLÍCITO: dos variantes combinan cuando tienen un nivel
/// equivalente (mismo mínimo, máximo, tipo y valor), no porque alguien las haya
/// puesto en una lista. Eso es lo que hace que no haga falta configurar nada
/// — y también lo que lo vuelve invisible. Estas entidades existen para poder
/// MIRARLO antes de vender.
///
/// 🔴 Los grupos los arma el BACKEND con la misma llave que usa para cobrar. El
/// app no los recalcula a propósito: un monitor que agrupara por su cuenta
/// podría mostrar algo distinto de lo que el POS termina cobrando, que es
/// justo el problema que viene a resolver.

/// Una variante dentro de un grupo (o fuera de todos).
class VarianteMayoreo extends Equatable {
  final String varianteId;
  final String nombre;
  final String sku;
  final bool isActive;

  /// Precio de lista en la sede consultada. Null si no está configurado.
  final double? precioVenta;
  final int? stockActual;

  /// Precio unitario que deja el nivel. En un nivel por PORCENTAJE cambia de
  /// variante en variante, porque se aplica sobre el precio de lista de cada
  /// una. Null en las que no están en ningún grupo.
  final double? precioConNivel;

  /// Cuánto baja por unidad. Null si falta alguno de los dos precios.
  final double? ahorroUnitario;

  const VarianteMayoreo({
    required this.varianteId,
    required this.nombre,
    required this.sku,
    required this.isActive,
    this.precioVenta,
    this.stockActual,
    this.precioConNivel,
    this.ahorroUnitario,
  });

  factory VarianteMayoreo.fromJson(Map<String, dynamic> json) =>
      VarianteMayoreo(
        varianteId: json['varianteId'] as String,
        nombre: json['nombre'] as String? ?? '',
        sku: json['sku'] as String? ?? '',
        isActive: json['isActive'] as bool? ?? true,
        precioVenta: _double(json['precioVenta']),
        stockActual: (json['stockActual'] as num?)?.toInt(),
        precioConNivel: _double(json['precioConNivel']),
        ahorroUnitario: _double(json['ahorroUnitario']),
      );

  @override
  List<Object?> get props => [varianteId, nombre, sku, precioConNivel];
}

/// Un grupo: las variantes que suman entre sí para llegar a un mismo mínimo.
class GrupoMayoreo extends Equatable {
  /// Llave con la que el backend agrupa. Solo para identificar el grupo en la
  /// UI (keys de widgets, expandir/colapsar); no se muestra.
  final String clave;

  final String nombreNivel;
  final int cantidadMinima;
  final int? cantidadMaxima;

  /// 'PRECIO_FIJO' o 'PORCENTAJE_DESCUENTO'.
  final String tipoPrecio;
  final double? precio;
  final double? porcentajeDesc;

  final List<VarianteMayoreo> variantes;

  /// Las variantes del grupo NO comparten precio de lista. La misma rebaja les
  /// deja descuentos distintos: casi siempre es un precio mal cargado.
  final bool preciosVentaDispares;

  /// El nivel no baja el precio de al menos una variante, así que en esa nunca
  /// va a aplicar (el motor descarta el nivel que no mejora la base).
  final bool nivelSinEfecto;

  const GrupoMayoreo({
    required this.clave,
    required this.nombreNivel,
    required this.cantidadMinima,
    this.cantidadMaxima,
    required this.tipoPrecio,
    this.precio,
    this.porcentajeDesc,
    required this.variantes,
    this.preciosVentaDispares = false,
    this.nivelSinEfecto = false,
  });

  bool get esPorcentaje => tipoPrecio == 'PORCENTAJE_DESCUENTO';

  /// Un grupo de una sola variante NO combina con nadie: esa variante necesita
  /// llegar al mínimo ella sola, como antes. Es la señal de que algo quedó
  /// suelto — casi siempre un precio distinto por un sol.
  bool get combinaConAlguien => variantes.length > 1;

  /// Unidades en stock de todo el grupo: cuánto se podría llegar a combinar.
  int get stockDelGrupo => variantes.fold(
        0,
        (acc, v) => acc + (v.stockActual ?? 0),
      );

  factory GrupoMayoreo.fromJson(Map<String, dynamic> json) => GrupoMayoreo(
        clave: json['clave'] as String? ?? '',
        nombreNivel: json['nombreNivel'] as String? ?? 'Por Mayor',
        cantidadMinima: (json['cantidadMinima'] as num?)?.toInt() ?? 0,
        cantidadMaxima: (json['cantidadMaxima'] as num?)?.toInt(),
        tipoPrecio: json['tipoPrecio'] as String? ?? 'PRECIO_FIJO',
        precio: _double(json['precio']),
        porcentajeDesc: _double(json['porcentajeDesc']),
        variantes: ((json['variantes'] as List?) ?? const [])
            .map((e) => VarianteMayoreo.fromJson(e as Map<String, dynamic>))
            .toList(),
        preciosVentaDispares: json['preciosVentaDispares'] as bool? ?? false,
        nivelSinEfecto: json['nivelSinEfecto'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [clave, variantes];
}

/// La foto completa del producto.
class GruposMayoreoResumen extends Equatable {
  final String productoId;
  final String productoNombre;
  final int totalVariantes;

  /// Cuántas están en al menos un grupo (o sea, pueden hacer mayoreo).
  final int variantesEnGrupo;

  final List<GrupoMayoreo> grupos;

  /// Estas NUNCA van a hacer mayoreo: no tienen ningún nivel cargado.
  final List<VarianteMayoreo> sinNivel;

  const GruposMayoreoResumen({
    required this.productoId,
    required this.productoNombre,
    required this.totalVariantes,
    required this.variantesEnGrupo,
    required this.grupos,
    required this.sinNivel,
  });

  bool get vacio => grupos.isEmpty;

  /// Grupos de una sola variante: no combinan con nadie.
  int get gruposSolitarios =>
      grupos.where((g) => !g.combinaConAlguien).length;

  /// Grupos con algo que revisar (precios dispares o nivel sin efecto).
  int get gruposConAviso => grupos
      .where((g) => g.preciosVentaDispares || g.nivelSinEfecto)
      .length;

  factory GruposMayoreoResumen.fromJson(Map<String, dynamic> json) =>
      GruposMayoreoResumen(
        productoId: json['productoId'] as String? ?? '',
        productoNombre: json['productoNombre'] as String? ?? '',
        totalVariantes: (json['totalVariantes'] as num?)?.toInt() ?? 0,
        variantesEnGrupo: (json['variantesEnGrupo'] as num?)?.toInt() ?? 0,
        grupos: ((json['grupos'] as List?) ?? const [])
            .map((e) => GrupoMayoreo.fromJson(e as Map<String, dynamic>))
            .toList(),
        sinNivel: ((json['sinNivel'] as List?) ?? const [])
            .map((e) => VarianteMayoreo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [productoId, grupos, sinNivel];
}

/// Los Decimal de Prisma viajan como String, no como número
/// (ver feedback_prisma_decimal_serializa_como_string).
double? _double(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
