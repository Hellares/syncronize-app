import 'package:equatable/equatable.dart';

import '../../../../core/utils/unidad_presentacion.dart';
import '../../../producto/domain/entities/producto_list_item.dart';
import '../../../producto/domain/entities/producto_variante.dart';

/// Una línea de compra mientras se está armando en la grilla de selección.
///
/// Es lo mismo que el formulario de Nueva Compra guarda hoy en su lista
/// `_detalles`, pero tipado: ahí son `Map<String, dynamic>` sueltos y cada
/// lectura tiene que castear a mano. El carrito trabaja con esta clase y recién
/// al entregar las líneas a la página las convierte al Map de siempre
/// ([toItemMap]), así el submit de la compra no se entera de nada.
class LineaCompraDraft extends Equatable {
  final String productoId;
  final String? varianteId;
  final String descripcion;

  /// 🔴 Entera a propósito: `create-compra-detalle.dto.ts` la valida con
  /// `@IsInt() @Min(1)`, así que un decimal lo rechaza el backend, no el app.
  /// Cuando se habiliten cantidades fraccionadas hay que tocar el DTO primero.
  final int cantidad;

  /// Costo de compra por unidad. **null = todavía no se sabe**, que es el caso
  /// real de un producto que nunca se compró en esta sede. No es lo mismo que
  /// cero y por eso no se rellena con cero acá: la línea se marca y el usuario
  /// la completa.
  final double? precioUnitario;

  final double descuento;

  /// La línea se carga en la unidad de COMPRA del producto (saco, paquete) y
  /// el backend convierte ×factor antes de persistir.
  final bool usaUnidadCompra;

  /// Empaque para ESTA compra. Arranca en el del producto y el editor de línea
  /// lo puede pisar si el lote vino con otra cantidad (override puntual).
  final double? factorCompra;

  /// Precio de venta a aplicar al confirmar la compra (opcional).
  ///
  /// 🔴 **Por unidad de VENTA**, que es como lo guarda el backend — aunque el
  /// usuario lo escriba en unidad de presentación (S/9 el kilo). Sin dividir
  /// por el factor, S/9 el kilo se guardaría como S/9 el GRAMO: S/9000 el kilo.
  /// La conversión se hace en el editor, al entrar y al salir del campo.
  final double? nuevoPrecioVenta;

  // ─── Solo para mostrar ────────────────────────────────────────────────
  final String? unidadCompraSimbolo;

  /// Unidad en la que se GUARDA el stock de esta línea (la atómica). Rotula el
  /// campo de cantidad, y por eso NO es la de presentación: un granel se carga
  /// en gramos aunque se lea en kilos, y decir "cantidad en kg" invita a
  /// escribir 15 donde van 15000.
  final String? unidadVentaSimbolo;

  /// Unidad en la que se le habla al usuario. Se resuelve POR VARIANTE: un
  /// saco cerrado se compra por unidad aunque su producto se guarde en gramos.
  final double? factorPresentacion;
  final String? unidadPresentacionSimbolo;

  // ─── Foto de la sede al momento de agregar ────────────────────────────
  // Alimentan el editor de línea (costo proyectado, margen, sugerencias de
  // precio de venta y el aviso de "el costo supera la venta"). Vienen en la
  // respuesta del listado, no cuestan un request.
  final double? costoActualSede;
  final double? precioVentaActualSede;
  final int? stockActualSede;

  const LineaCompraDraft({
    required this.productoId,
    this.varianteId,
    required this.descripcion,
    this.cantidad = 1,
    this.precioUnitario,
    this.descuento = 0,
    this.usaUnidadCompra = false,
    this.factorCompra,
    this.nuevoPrecioVenta,
    this.unidadCompraSimbolo,
    this.unidadVentaSimbolo,
    this.factorPresentacion,
    this.unidadPresentacionSimbolo,
    this.costoActualSede,
    this.precioVentaActualSede,
    this.stockActualSede,
  });

  /// Identidad de la línea. Producto y variante son líneas distintas, y dos
  /// variantes del mismo producto también: se comparan por id y nunca por
  /// nombre, que se repite entre variantes.
  String get clave => '$productoId|${varianteId ?? ''}';

  /// La línea no se puede comprar todavía: sin costo no hay qué pagarle al
  /// proveedor ni con qué actualizar el costo del producto.
  bool get sinCosto => precioUnitario == null || precioUnitario! <= 0;

  double get subtotal => cantidad * (precioUnitario ?? 0) - descuento;

  // ─── Unidades ─────────────────────────────────────────────────────────
  // `cantidad` y `precioUnitario` viven en la unidad en que se CARGA la línea:
  // la de compra (el saco) si el toggle está prendido, y si no la atómica (la
  // de stock/venta). Todo lo que se compara contra el costo del producto tiene
  // que llevarse antes a la atómica.

  /// Empaque efectivo de la línea: el override puntual o 1.
  double get factorEfectivo {
    final f = factorCompra;
    return (f != null && f > 0) ? f : 1;
  }

  /// El producto se puede comprar por saco/paquete.
  bool get soportaUnidadCompra =>
      factorCompra != null &&
      factorCompra! > 0 &&
      (unidadCompraSimbolo?.isNotEmpty ?? false);

  /// 1 cuando no hay presentación configurada, así multiplicar o dividir por
  /// él no cambia ningún número.
  double get factorPresentacionEfectivo =>
      (factorPresentacion != null && factorPresentacion! > 1)
          ? factorPresentacion!
          : 1;

  /// Traductor entre lo que se guarda y lo que se le muestra al usuario.
  UnidadPresentacion get presentacion => UnidadPresentacion(
        factor: factorPresentacionEfectivo,
        simbolo: unidadPresentacionSimbolo,
        simboloVenta: unidadVentaSimbolo,
      );

  // ─── En qué unidad se ESCRIBE la línea ────────────────────────────────
  // Nunca en la atómica cuando hay algo mejor: un granel que se guarda en
  // gramos se compra en KILOS. Escribir 15000 y S/0.008 no es solo incómodo,
  // es la forma más fácil de equivocarse en un cero.

  /// Unidades atómicas que trae 1 de la unidad en la que se escribe: el saco
  /// (×50) si se compra por saco, si no la presentación (×1000 el kilo).
  double get factorCarga => usaUnidadCompra && soportaUnidadCompra
      ? factorEfectivo
      : factorPresentacionEfectivo;

  /// Cómo se llama esa unidad: "SACO", "kg", o la de venta si no hay ninguna.
  String? get simboloCarga => usaUnidadCompra && soportaUnidadCompra
      ? unidadCompraSimbolo
      : presentacion.simboloVisible;

  /// La cantidad como va en el campo: 15 (kg), no 15000 (g).
  double get cantidadCarga =>
      factorCarga > 0 ? cantidadAtomica / factorCarga : cantidad.toDouble();

  /// El precio como va en el campo: S/8.00 el kilo, no S/0.008 el gramo.
  double get precioCarga => precioAtomico * factorCarga;

  /// Costo por unidad atómica (S/50 el saco de 50 → S/1 la unidad).
  double get precioAtomico {
    final raw = precioUnitario ?? 0;
    if (raw <= 0) return 0;
    if (usaUnidadCompra && soportaUnidadCompra && factorEfectivo > 0) {
      return raw / factorEfectivo;
    }
    return raw;
  }

  /// Unidades atómicas que entran con esta línea (3 sacos de 50 → 150).
  int get cantidadAtomica {
    if (cantidad <= 0) return 0;
    if (usaUnidadCompra && soportaUnidadCompra) {
      return (cantidad * factorEfectivo).round();
    }
    return cantidad;
  }

  // ─── Qué le pasa al producto con esta compra ──────────────────────────

  /// Costo del producto DESPUÉS de recibir esta línea: promedio ponderado
  /// entre lo que ya hay en la sede y lo que entra. El backend hace la misma
  /// cuenta al confirmar; esto es el preview.
  double? get costoProyectado {
    final precioNuevo = precioAtomico;
    final cantNueva = cantidadAtomica;
    if (precioNuevo <= 0 || cantNueva <= 0) return costoActualSede;
    final stockPrev = stockActualSede ?? 0;
    final costoPrev = costoActualSede ?? 0;
    if (stockPrev == 0) return precioNuevo;
    final ponderado = (stockPrev * costoPrev + cantNueva * precioNuevo) /
        (stockPrev + cantNueva);
    return double.parse(ponderado.toStringAsFixed(4));
  }

  /// Margen con el que se vende HOY, para poder sostenerlo sobre el costo
  /// nuevo. null si falta el costo o el precio de venta.
  double? get margenActualPct {
    final precio = precioVentaActualSede;
    final costo = costoActualSede;
    if (precio == null || costo == null || costo <= 0) return null;
    return ((precio - costo) / costo) * 100;
  }

  /// Sugerencia: el precio que mantiene el margen actual sobre el costo nuevo.
  double? get precioVentaMantenerMargen {
    final margen = margenActualPct;
    final costoNuevo = costoProyectado;
    if (margen == null || costoNuevo == null) return null;
    return double.parse((costoNuevo * (1 + margen / 100)).toStringAsFixed(2));
  }

  /// Sugerencia: costo nuevo + 10%. Siempre cubre el costo, a diferencia de
  /// basarse en la venta vieja (que ante un salto de costo queda por debajo).
  double? get precioVentaMas10 {
    final costoNuevo = costoProyectado;
    if (costoNuevo == null || costoNuevo <= 0) return null;
    return double.parse((costoNuevo * 1.1).toStringAsFixed(2));
  }

  /// A cuánto quedaría vendiéndose tras esta compra, por unidad de venta.
  double? get precioVentaEfectivo {
    final nuevo = nuevoPrecioVenta;
    if (nuevo != null && nuevo > 0) return nuevo;
    return precioVentaActualSede;
  }

  /// 🔴 Se vendería con PÉRDIDA: el costo que deja esta compra supera el precio
  /// de venta. Es el aviso que evita seguir vendiendo bajo costo sin enterarse
  /// cuando el proveedor sube los precios.
  bool get costoSuperaVenta {
    final precioCompra = precioAtomico;
    if (precioCompra <= 0) return false; // todavía no hay precio de compra
    final costo = costoProyectado ?? precioCompra;
    final venta = precioVentaEfectivo;
    if (venta == null || venta <= 0) return false;
    return costo > venta;
  }

  /// Guarda lo escrito en el editor, que viene en la unidad de CARGA, dejando
  /// la línea como la acepta el backend — que exige `cantidad` ENTERA
  /// (`@IsInt`) y no sabe nada de presentaciones:
  ///
  /// - Por unidad de compra y entera (3 sacos) → viaja así, y el backend
  ///   convierte con el factor. Conserva el snapshot del empaque.
  /// - Por unidad de compra y fraccionaria (1.5 m) → se APLANA a unidad
  ///   atómica (150 cm a su costo equivalente). Da lo mismo y pasa el @IsInt.
  /// - En presentación (15 kg a S/8) → se guarda en atómica (15000 g a
  ///   S/0.008). La cantidad se MULTIPLICA y el precio se DIVIDE.
  LineaCompraDraft conCarga({
    required double cantidad,
    required double precio,
    required bool usaUnidadCompra,
    double? factor,
  }) {
    final factorUsado = (factor != null && factor > 0) ? factor : factorEfectivo;
    final porUnidadDeCompra = usaUnidadCompra && soportaUnidadCompra;

    if (porUnidadDeCompra) {
      final esEntera = (cantidad - cantidad.roundToDouble()).abs() < 1e-9;
      if (esEntera) {
        return copyWith(
          cantidad: cantidad.round(),
          precioUnitario: precio,
          usaUnidadCompra: true,
          factorCompra: factorUsado,
        );
      }
      return copyWith(
        cantidad: (cantidad * factorUsado).round(),
        precioUnitario:
            double.parse((precio / factorUsado).toStringAsFixed(4)),
        usaUnidadCompra: false,
        factorCompra: factorUsado,
      );
    }

    final pres = presentacion;
    return copyWith(
      cantidad: pres.cantidadAUnidadDeVenta(cantidad).round(),
      // 🔴 Seis decimales: un precio POR UNIDAD no es un monto. S/6.73 el kilo
      // son S/0.006727 el gramo, y a dos decimales queda 0.01 — un 48% de más
      // multiplicado por cada gramo del saco.
      precioUnitario: pres.activa
          ? double.parse(
              pres.precioAUnidadDeVenta(precio).toStringAsFixed(6))
          : precio,
      usaUnidadCompra: false,
      factorCompra: factorUsado,
    );
  }

  /// Línea nueva a partir de un producto SIN variantes.
  factory LineaCompraDraft.desdeProducto(
    ProductoListItem producto, {
    required String sedeId,
    int cantidad = 1,
  }) {
    // 🔴 Un producto CON variantes no tiene costo propio: el backend arma su
    // `stocksPorSede` mezclando el stock residual del padre con el de las
    // variantes, y la última con precio configurado PISA el costo
    // (`producto-catalog.service.ts:299`). Ese número es el de alguna variante
    // suelta, así que acá queda en null y el costo se toma al elegir variante.
    final tieneCostoPropio = !producto.tieneVariantes;
    final costo =
        tieneCostoPropio ? producto.precioCostoEnSede(sedeId) : null;
    final presentacion = producto.presentacion;

    return LineaCompraDraft(
      productoId: producto.id,
      descripcion: producto.nombre,
      cantidad: cantidad,
      // En una COMPRA el precio por defecto es el COSTO, nunca el de venta:
      // aceptar el prellenado con el precio de lista registraba la compra a ese
      // número y el costo del producto saltaba con él.
      precioUnitario: costo,
      factorCompra: producto.factorCompra,
      unidadCompraSimbolo: producto.unidadCompraSimbolo,
      unidadVentaSimbolo: producto.unidadMedidaSimbolo,
      factorPresentacion: presentacion.factor,
      unidadPresentacionSimbolo: presentacion.simboloVisible,
      costoActualSede: costo,
      precioVentaActualSede:
          tieneCostoPropio ? producto.precioEnSede(sedeId) : null,
      stockActualSede: producto.stockEnSede(sedeId),
    );
  }

  /// Línea nueva a partir de una variante concreta. Acá el costo SÍ es exacto:
  /// la fila de `ProductoStock` cuelga de la variante y viene en el listado.
  factory LineaCompraDraft.desdeVariante(
    ProductoListItem producto,
    ProductoVariante variante, {
    required String sedeId,
    int cantidad = 1,
  }) {
    final info = variante.stockSedeInfo(sedeId);
    final presentacion = producto.presentacionDeVariante(variante);

    return LineaCompraDraft(
      productoId: producto.id,
      varianteId: variante.id,
      descripcion: '${producto.nombre} - ${variante.nombre}',
      cantidad: cantidad,
      precioUnitario: info?.precioCosto,
      factorCompra: producto.factorCompra,
      unidadCompraSimbolo: producto.unidadCompraSimbolo,
      // La unidad de la VARIANTE cuando tiene la suya: un bulto cerrado se
      // guarda por unidad aunque el producto se guarde en gramos.
      unidadVentaSimbolo:
          (variante.unidadMedidaId != null && variante.unidadMedida != null)
              ? variante.unidadDisplay
              : producto.unidadMedidaSimbolo,
      factorPresentacion: presentacion.factor,
      unidadPresentacionSimbolo: presentacion.simboloVisible,
      costoActualSede: info?.precioCosto,
      precioVentaActualSede: info?.precio,
      stockActualSede: info?.cantidad,
    );
  }

  LineaCompraDraft copyWith({
    int? cantidad,
    double? precioUnitario,
    double? descuento,
    bool? usaUnidadCompra,
    double? factorCompra,
    double? nuevoPrecioVenta,
    bool limpiarPrecioUnitario = false,
    bool limpiarNuevoPrecioVenta = false,
  }) {
    return LineaCompraDraft(
      productoId: productoId,
      varianteId: varianteId,
      descripcion: descripcion,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario: limpiarPrecioUnitario
          ? null
          : (precioUnitario ?? this.precioUnitario),
      descuento: descuento ?? this.descuento,
      usaUnidadCompra: usaUnidadCompra ?? this.usaUnidadCompra,
      factorCompra: factorCompra ?? this.factorCompra,
      nuevoPrecioVenta: limpiarNuevoPrecioVenta
          ? null
          : (nuevoPrecioVenta ?? this.nuevoPrecioVenta),
      unidadCompraSimbolo: unidadCompraSimbolo,
      unidadVentaSimbolo: unidadVentaSimbolo,
      factorPresentacion: factorPresentacion,
      unidadPresentacionSimbolo: unidadPresentacionSimbolo,
      costoActualSede: costoActualSede,
      precioVentaActualSede: precioVentaActualSede,
      stockActualSede: stockActualSede,
    );
  }

  /// Convierte al `Map` que ya espera la página de Nueva Compra, con las
  /// mismas claves que arma hoy el formulario de a una línea.
  Map<String, dynamic> toItemMap() => {
        'productoId': productoId,
        if (varianteId != null) 'varianteId': varianteId,
        'descripcion': descripcion,
        'cantidad': cantidad,
        // 🔴 Nunca null: la tabla del formulario lo lee con `(precio as num)` y
        // un null la tira abajo con un TypeError. Una línea sin costo viaja en
        // 0 y se frena por `precioUnitario <= 0` antes de crear la compra.
        'precioUnitario': precioUnitario ?? 0,
        'descuento': descuento,
        if (usaUnidadCompra) 'usaUnidadCompra': true,
        // El empaque viaja SIEMPRE que exista, no solo con el toggle prendido:
        // sin él, reabrir la línea en el editor ya no ofrecería comprar por
        // saco. Al backend igual no llega — la página solo lo manda cuando
        // `usaUnidadCompra` es true.
        if (factorCompra != null) 'factorCompra': factorCompra,
        if (nuevoPrecioVenta != null) 'nuevoPrecioVenta': nuevoPrecioVenta,
        if (unidadCompraSimbolo != null)
          'unidadCompraSimbolo': unidadCompraSimbolo,
        if (factorPresentacion != null)
          'factorPresentacion': factorPresentacion,
        if (unidadPresentacionSimbolo != null)
          'unidadPresentacionSimbolo': unidadPresentacionSimbolo,
        // Contexto de la sede para poder REABRIR la línea en el editor y
        // seguir viendo costo proyectado, margen y el aviso de vender bajo
        // costo. El backend ignora estas claves: arma el payload con una lista
        // explícita de campos, igual que ya pasa con la presentación.
        if (unidadVentaSimbolo != null) 'unidadVentaSimbolo': unidadVentaSimbolo,
        if (costoActualSede != null) 'costoActualSede': costoActualSede,
        if (precioVentaActualSede != null)
          'precioVentaActualSede': precioVentaActualSede,
        if (stockActualSede != null) 'stockActualSede': stockActualSede,
      };

  /// Reconstruye la línea desde el `Map` que vive en la página de compra, para
  /// poder editarla. Solo tiene sentido con `productoId`: un ítem
  /// personalizado es texto libre y no tiene costo ni stock que proyectar.
  static LineaCompraDraft? desdeItemMap(Map<String, dynamic> item) {
    final productoId = item['productoId'] as String?;
    if (productoId == null) return null;

    double? aDouble(Object? v) => v is num ? v.toDouble() : null;

    return LineaCompraDraft(
      productoId: productoId,
      varianteId: item['varianteId'] as String?,
      descripcion: item['descripcion'] as String? ?? '',
      cantidad: (item['cantidad'] as num?)?.round() ?? 1,
      // En el Map una línea sin costo viaja en 0; adentro vuelve a ser "no se
      // sabe", que es lo que hace que el editor la marque en vez de dar por
      // bueno un precio de cero.
      precioUnitario: (aDouble(item['precioUnitario']) ?? 0) > 0
          ? aDouble(item['precioUnitario'])
          : null,
      descuento: aDouble(item['descuento']) ?? 0,
      usaUnidadCompra: item['usaUnidadCompra'] == true,
      factorCompra: aDouble(item['factorCompra']),
      nuevoPrecioVenta: aDouble(item['nuevoPrecioVenta']),
      unidadCompraSimbolo: item['unidadCompraSimbolo'] as String?,
      unidadVentaSimbolo: item['unidadVentaSimbolo'] as String?,
      factorPresentacion: aDouble(item['factorPresentacion']),
      unidadPresentacionSimbolo: item['unidadPresentacionSimbolo'] as String?,
      costoActualSede: aDouble(item['costoActualSede']),
      precioVentaActualSede: aDouble(item['precioVentaActualSede']),
      stockActualSede: (item['stockActualSede'] as num?)?.toInt(),
    );
  }

  @override
  List<Object?> get props => [
        productoId,
        varianteId,
        descripcion,
        cantidad,
        precioUnitario,
        descuento,
        usaUnidadCompra,
        factorCompra,
        nuevoPrecioVenta,
        unidadCompraSimbolo,
        unidadVentaSimbolo,
        factorPresentacion,
        unidadPresentacionSimbolo,
        costoActualSede,
        precioVentaActualSede,
        stockActualSede,
      ];
}
