import 'package:equatable/equatable.dart';
import 'politica_descuento.dart' show EstrategiaMayor;

/// Modo de cálculo del precio especial VIP (espejo de TipoCalculoDescuento
/// del backend, pero acotado a lo que el cliente necesita para el preview).
enum ModoPrecioVip {
  precioCosto,
  precioMayorDesdeUnidad,
  porcentaje,
  montoFijo;

  static ModoPrecioVip fromTipoCalculo(String value) {
    switch (value) {
      case 'PRECIO_COSTO':
        return ModoPrecioVip.precioCosto;
      case 'PRECIO_MAYOR_DESDE_UNIDAD':
        return ModoPrecioVip.precioMayorDesdeUnidad;
      case 'MONTO_FIJO':
        return ModoPrecioVip.montoFijo;
      case 'PORCENTAJE':
      default:
        return ModoPrecioVip.porcentaje;
    }
  }
}

/// Intención de precio VIP YA RESUELTA para una línea concreta. La calcula el
/// [VipResolver] a partir de la política aplicable. La consume
/// `VentaDetalleInput.recalcularPrecioPorNiveles` para fijar el precio.
class VipPrecioIntent extends Equatable {
  final String politicaId;

  /// Etiqueta para el badge/snapshot, ej. "VIP: Mayoristas".
  final String etiqueta;
  final ModoPrecioVip modo;

  /// % o monto fijo (modos PORCENTAJE / MONTO_FIJO).
  final double valor;

  /// % sobre costo (modo PRECIO_COSTO). 0 = costo puro.
  final double markupSobreCosto;

  /// Estrategia de escalón (modo PRECIO_MAYOR_DESDE_UNIDAD).
  final EstrategiaMayor estrategiaMayor;

  /// Tope de descuento en monto (modos PORCENTAJE / MONTO_FIJO).
  final double? descuentoMaximo;

  const VipPrecioIntent({
    required this.politicaId,
    required this.etiqueta,
    required this.modo,
    this.valor = 0,
    this.markupSobreCosto = 0,
    this.estrategiaMayor = EstrategiaMayor.primerNivel,
    this.descuentoMaximo,
  });

  @override
  List<Object?> get props => [
        politicaId,
        etiqueta,
        modo,
        valor,
        markupSobreCosto,
        estrategiaMayor,
        descuentoMaximo,
      ];
}

/// Una política de precio especial vigente del cliente, con su alcance,
/// parseada desde el endpoint `/politicas-descuento/cliente/.../vigentes`.
///
/// NOTA: el alcance por CATEGORÍA no se resuelve en el cliente (la línea del
/// carrito no carga la categoría). Las políticas category-only no se previsualizan
/// pero el backend SÍ las aplica al cobrar; el guard 409 las tolera porque el
/// precio resultante es FAVORABLE al cliente (≤ el enviado).
class VipPoliticaVigente {
  final String politicaId;
  final String nombre;
  final ModoPrecioVip modo;
  final double valor;
  final double markupSobreCosto;
  final EstrategiaMayor estrategiaMayor;
  final double? descuentoMaximo;
  final int prioridad;
  final bool aplicarATodos;
  final Set<String> productoIds;
  final Map<String, double> overridePorProducto;

  const VipPoliticaVigente({
    required this.politicaId,
    required this.nombre,
    required this.modo,
    required this.valor,
    required this.markupSobreCosto,
    required this.estrategiaMayor,
    required this.descuentoMaximo,
    required this.prioridad,
    required this.aplicarATodos,
    required this.productoIds,
    required this.overridePorProducto,
  });

  factory VipPoliticaVigente.fromJson(Map<String, dynamic> json) {
    double parseD(dynamic v) =>
        v == null ? 0.0 : (v as num).toDouble();
    final productos =
        (json['productosAplicables'] as List?)?.cast<Map<String, dynamic>>() ??
            const [];
    final override = <String, double>{};
    final ids = <String>{};
    for (final p in productos) {
      final pid = p['productoId'] as String?;
      if (pid == null) continue;
      ids.add(pid);
      if (p['descuentoOverride'] != null) {
        override[pid] = (p['descuentoOverride'] as num).toDouble();
      }
    }
    return VipPoliticaVigente(
      politicaId: json['politicaId'] as String,
      nombre: json['nombre'] as String? ?? 'VIP',
      modo: ModoPrecioVip.fromTipoCalculo(json['tipoCalculo'] as String? ?? ''),
      valor: parseD(json['valorDescuento']),
      markupSobreCosto: parseD(json['markupSobreCosto']),
      estrategiaMayor: (json['estrategiaMayor'] as String?) == 'MEJOR_NIVEL'
          ? EstrategiaMayor.mejorNivel
          : EstrategiaMayor.primerNivel,
      descuentoMaximo: json['descuentoMaximo'] != null
          ? (json['descuentoMaximo'] as num).toDouble()
          : null,
      prioridad: (json['prioridad'] as num?)?.toInt() ?? 0,
      aplicarATodos: json['aplicarATodos'] as bool? ?? false,
      productoIds: ids,
      overridePorProducto: override,
    );
  }

  bool aplicaAProducto(String? productoId) {
    if (aplicarATodos) return true;
    return productoId != null && productoIds.contains(productoId);
  }
}

/// Resuelve, por línea, qué precio especial VIP corresponde según el alcance
/// de las políticas vigentes del cliente (mayor prioridad gana). Espejo del
/// `_buildResolverVip` del backend.
class VipResolver {
  final List<VipPoliticaVigente> politicas;

  const VipResolver(this.politicas);

  factory VipResolver.fromVigentes(List<Map<String, dynamic>> list) {
    return VipResolver(
      list.map((e) => VipPoliticaVigente.fromJson(e)).toList(),
    );
  }

  bool get isEmpty => politicas.isEmpty;

  /// TODAS las políticas aplicables a la línea (el cliente puede estar en
  /// varias). El cálculo de precio elige el menor entre ellas (gana el menor).
  List<VipPrecioIntent> intentsParaProducto(String? productoId) {
    return politicas.where((p) => p.aplicaAProducto(productoId)).map((g) {
      var valor = g.valor;
      if (productoId != null && g.overridePorProducto.containsKey(productoId)) {
        valor = g.overridePorProducto[productoId]!;
      }
      return VipPrecioIntent(
        politicaId: g.politicaId,
        etiqueta: 'VIP: ${g.nombre}',
        modo: g.modo,
        valor: valor,
        markupSobreCosto: g.markupSobreCosto,
        estrategiaMayor: g.estrategiaMayor,
        descuentoMaximo: g.descuentoMaximo,
      );
    }).toList();
  }
}
