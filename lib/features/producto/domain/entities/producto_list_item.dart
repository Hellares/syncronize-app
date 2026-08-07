import 'package:equatable/equatable.dart';
import '../../../../core/utils/unidad_presentacion.dart';
import 'producto_variante.dart';
import 'stock_por_sede_info.dart';
import 'stock_por_sede_mixin.dart';

/// Entity simplificada para listados de productos
class ProductoListItem extends Equatable with StockPorSedeMixin {
  final String id;
  final String nombre;
  final String codigoEmpresa;
  final bool destacado;
  final String? imagenPrincipal;
  final String? categoriaNombre;
  final String? marcaNombre;
  final bool isActive;
  final bool esCombo;
  final bool esInsumo;
  final bool tieneVariantes;
  final List<ProductoVariante>? variantes;
  @override
  final List<StockPorSedeInfo>? stocksPorSede; // Desglose de stock por sede
  final int comboReservado; // Cantidad de combos reservados (solo aplica cuando esCombo)
  final double? impuestoPorcentaje; // IGV específico del producto (null = usar global)
  final double? descuentoMaximo; // Máximo descuento permitido en porcentaje
  final String tipoAfectacionIgv; // GRAVADO, EXONERADO, INAFECTO
  final bool aplicaIcbper;

  // Unidad de compra (opcional). Cuando está seteada, el módulo de
  // compras puede ofrecer al usuario cargar la línea en esta unidad y
  // el backend convierte a unidad atómica antes de afectar stock.
  final double? factorCompra;
  final String? unidadCompraSimbolo;

  /// Símbolo de la unidad base (venta/stock), ej. "cm". Se usa para mostrar
  /// la unidad real en el toggle "Comprar por" y el costo equivalente.
  final String? unidadMedidaSimbolo;

  // Unidad de PRESENTACIÓN: cómo se le habla al usuario y al cliente cuando la
  // unidad de venta es demasiado chica. Un alimento a granel se guarda en
  // gramos —para que el stock entero y la balanza funcionen— pero se cotiza y
  // se cobra en KILOS. No cambia nada de lo almacenado: precio, costo y stock
  // siguen en unidad de venta. Null = se muestra en la unidad de venta, que es
  // el comportamiento de siempre.
  final String? unidadPresentacionSimbolo;

  /// Unidades de venta que trae 1 de presentación (kg = 1000 g).
  final double? factorPresentacion;

  ProductoListItem({
    required this.id,
    required this.nombre,
    required this.codigoEmpresa,
    required this.destacado,
    this.imagenPrincipal,
    this.categoriaNombre,
    this.marcaNombre,
    required this.isActive,
    this.esCombo = false,
    this.esInsumo = false,
    this.tieneVariantes = false,
    this.variantes,
    this.stocksPorSede,
    this.comboReservado = 0,
    this.impuestoPorcentaje,
    this.descuentoMaximo,
    this.tipoAfectacionIgv = 'GRAVADO',
    this.aplicaIcbper = false,
    this.factorCompra,
    this.unidadCompraSimbolo,
    this.unidadMedidaSimbolo,
    this.unidadPresentacionSimbolo,
    this.factorPresentacion,
  });

  /// Factor efectivo de presentación: 1 cuando el producto no tiene una
  /// configurada (o es inválida), así multiplicar/dividir por él es inocuo.
  double get factorPresentacionEfectivo =>
      (factorPresentacion != null && factorPresentacion! > 1)
          ? factorPresentacion!
          : 1;

  /// Símbolo en el que se le habla al usuario: el de presentación si existe,
  /// si no el de la unidad de venta.
  String? get simboloVisible =>
      unidadPresentacionSimbolo ?? unidadMedidaSimbolo;

  /// Traductor entre lo que se guarda y lo que se muestra. Se puede usar
  /// siempre: sin presentación configurada no cambia nada.
  UnidadPresentacion get presentacion => UnidadPresentacion(
        factor: factorPresentacionEfectivo,
        simbolo: unidadPresentacionSimbolo,
        simboloVenta: unidadMedidaSimbolo,
      );

  /// Stock consolidado: para productos con variantes suma el stock de todas las variantes,
  /// para productos normales usa el stock directo
  int get stockConsolidado {
    if (tieneVariantes && variantes != null && variantes!.isNotEmpty) {
      return variantes!.fold(0, (sum, variante) => sum + variante.stockTotal);
    }
    return stockTotal;
  }

  /// Stock en sede consolidando variantes: si tiene variantes, suma el
  /// stock de todas las variantes activas en esa sede. Si no, usa el
  /// stock directo del producto base.
  int stockConsolidadoEnSede(String sedeId) {
    if (tieneVariantes && variantes != null && variantes!.isNotEmpty) {
      return variantes!.fold(
        0,
        (sum, v) => sum + (v.stockEnSede(sedeId) ?? 0),
      );
    }
    return stockEnSede(sedeId) ?? 0;
  }

  /// Las variantes NO se venden todas en la misma unidad.
  ///
  /// Pasa con el saco cerrado vs granel: una variante va por unidad y la otra
  /// por gramo presentada en kilos. Sumarlas da un número sin significado —
  /// "3 sacos + 15000 g = 15003"— y expresarlo en kilos sería peor, porque
  /// escondería los 3 sacos.
  bool get variantesEnUnidadesDistintas {
    final vs = variantes;
    if (!tieneVariantes || vs == null || vs.length < 2) return false;
    final primera = vs.first;
    return vs.any((v) =>
        v.unidadMedidaId != primera.unidadMedidaId ||
        v.factorPresentacion != primera.factorPresentacion);
  }

  /// En qué unidad se MUESTRA una variante.
  ///
  /// Si trae presentación propia, esa. Si no, hereda la del producto — que es
  /// lo que pasa cuando se configura "kg ×1000" una sola vez en el producto en
  /// vez de repetirlo en cada granel. Los bultos cerrados no heredan: tienen
  /// unidad propia distinta, y ahí la presentación del producto no aplica.
  UnidadPresentacion presentacionDeVariante(ProductoVariante v) {
    if (v.tienePresentacionPropia) {
      return UnidadPresentacion(
        factor: v.factorPresentacion!,
        simbolo: v.unidadPresentacionSimbolo,
      );
    }
    // Se compara por SÍMBOLO porque el list item no baja el id de la unidad
    // del producto. Para decidir cómo mostrar un número alcanza; dos unidades
    // distintas con el mismo símbolo serían indistinguibles en pantalla igual.
    final tieneUnidadPropia = v.unidadMedidaId != null &&
        v.unidadMedida != null &&
        v.unidadDisplay != unidadMedidaSimbolo;
    if (tieneUnidadPropia) {
      return UnidadPresentacion(factor: 1, simbolo: v.unidadDisplay);
    }
    return presentacion;
  }

  /// Stock de la sede listo para mostrar, AGRUPADO por unidad: "8 und · 45 kg".
  ///
  /// Se agrupa y no se lista variante por variante porque un producto con
  /// varios sabores tiene doce variantes, y enumerarlas daría una tira
  /// ilegible en una card de POS. Sumar todo junto tampoco sirve: sacos y
  /// gramos no se suman.
  ///
  /// Devuelve null cuando todas las variantes comparten unidad (colores,
  /// tallas) y el consolidado de siempre alcanza.
  String? stockPorVarianteEnSede(String sedeId) {
    if (!variantesEnUnidadesDistintas) return null;
    // LinkedHashMap: conserva el orden de aparición de las variantes, así el
    // texto no baila entre repintados.
    final porUnidad = <String, double>{};
    for (final v in variantes!) {
      final stock = v.stockEnSede(sedeId) ?? 0;
      if (stock <= 0) continue;
      final pres = presentacionDeVariante(v);
      final simbolo = pres.simboloVisible ?? v.unidadDisplay;
      porUnidad[simbolo] = (porUnidad[simbolo] ?? 0) + pres.cantidad(stock);
    }
    if (porUnidad.isEmpty) return null;
    return porUnidad.entries
        .map((e) => '${_sinCerosSobrantes(e.value)} ${e.key}')
        .join(' · ');
  }

  static String _sinCerosSobrantes(double v) {
    if (v == v.truncateToDouble()) return v.toStringAsFixed(0);
    return v
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  /// True si el producto base O alguna de sus variantes está en liquidación
  /// activa en la sede. Usado para mostrar badge "LIQ." en el card padre
  /// aunque la liquidación esté configurada a nivel variante.
  bool tieneLiquidacionActivaEnSede(String sedeId) {
    if (enLiquidacionEnSede(sedeId)) return true;
    if (variantes == null) return false;
    return variantes!.any((v) => v.enLiquidacionEnSede(sedeId));
  }

  /// True si el producto base O alguna variante tiene oferta activa en
  /// la sede, Y NO está en liquidación (liquidación tiene prioridad).
  bool tieneOfertaActivaEnSede(String sedeId) {
    if (tieneLiquidacionActivaEnSede(sedeId)) return false;
    if (enOfertaEnSede(sedeId)) return true;
    if (variantes == null) return false;
    return variantes!.any((v) => v.enOfertaEnSede(sedeId));
  }

  @override
  List<Object?> get props => [
        id,
        nombre,
        codigoEmpresa,
        destacado,
        imagenPrincipal,
        categoriaNombre,
        marcaNombre,
        isActive,
        esCombo,
        esInsumo,
        tieneVariantes,
        variantes,
        stocksPorSede,
        comboReservado,
        impuestoPorcentaje,
        descuentoMaximo,
        tipoAfectacionIgv,
        aplicaIcbper,
        factorCompra,
        unidadCompraSimbolo,
        unidadMedidaSimbolo,
        unidadPresentacionSimbolo,
        factorPresentacion,
      ];
}
