import '../../../../core/utils/unidad_presentacion.dart';
import '../../../producto/domain/entities/precio_nivel.dart';
import '../../../descuento/domain/entities/vip_precio.dart';
import '../../../descuento/domain/entities/politica_descuento.dart'
    show EstrategiaMayor;

/// Modelo tipado para items del formulario de venta.
/// A diferencia de [VentaDetalle], no incluye campos calculados
/// del servidor (id, ventaId, igv, subtotal, total).
class VentaDetalleInput {
  final String? productoId;
  final String? varianteId;
  final String? servicioId;
  final String? comboId;

  /// Cobro de una orden de servicio (REPARADO/LISTO_ENTREGA) vía POS:
  /// la línea representa el saldo pendiente de la orden. Cantidad fija 1,
  /// sin descuentos de línea (el descuento comercial vive en la orden).
  /// El backend valida saldo vigente (409 SALDO_ORDEN_DESACTUALIZADO) y
  /// doble cobro (409 ORDEN_YA_COBRADA), y al cobrar marca la orden
  /// ENTREGADO.
  final String? ordenServicioId;

  /// Código de la orden para display en carrito/cobro (ej. "ORD-00012").
  /// Solo client-side, no se envía al backend.
  final String? ordenCodigo;

  /// Adelanto ya pagado de la orden (S/). El precio de la línea es el
  /// COSTO NETO del servicio (el comprobante sale por el total); este
  /// adelanto se descuenta de lo que el cliente paga HOY. Solo
  /// client-side — el backend lo lee de la orden.
  final double ordenAdelanto;

  final String descripcion;
  final double cantidad;
  final double precioUnitario;
  final double descuento;
  final double porcentajeIGV;
  final bool precioIncluyeIgv;
  final String tipoAfectacion;
  final double icbper;
  final int? stockDisponible;

  /// Niveles de precio configurados para este producto/variante.
  /// Se cargan al agregar el item y se usan para recalcular precio
  /// cuando cambia la cantidad. Vacío = no hay niveles configurados.
  final List<PrecioNivel> niveles;

  /// Precio base original sin aplicar nivel (para mostrar tachado en UI).
  /// null cuando aún no se cargaron niveles o no hay nivel aplicable.
  final double? precioBase;

  /// Nombre del nivel aplicado actualmente (ej. "Por Mayor").
  /// null cuando se vende a precio base.
  final String? nivelAplicado;

  /// Porcentaje de descuento aplicado por el nivel (0-100).
  final double? descuentoNivelPct;

  /// Cuando un item proviene de la expansión de un combo, este campo
  /// guarda el id del combo origen (solo client-side — no se envía al
  /// backend). Items con el mismo `origenComboId` se agrupan visualmente
  /// y se editan/eliminan juntos.
  final String? origenComboId;

  /// Nombre del combo origen para display (ej. "Combo: Pack Familiar").
  final String? origenComboNombre;

  /// Parte MANUAL del descuento de la línea (por ítem / global aplicado por
  /// el cajero). En líneas de combo, `descuento` = prorrateo del combo +
  /// `descuentoManual`; guardarlo aparte permite re-prorratear el combo al
  /// editar componentes sin perder el descuento manual apilado. En líneas
  /// sueltas suele coincidir con `descuento` (y este queda en 0).
  final double descuentoManual;

  /// Contexto de pricing del combo origen (solo en líneas con
  /// `origenComboId`), necesario para re-precio al editar componentes:
  /// - [comboTipoPrecio]: 'FIJO' | 'CALCULADO' | 'CALCULADO_CON_DESCUENTO'.
  /// - [comboDescuentoPct]: % del combo (para CALCULADO_CON_DESCUENTO).
  /// - [comboPrecioObjetivo]: precio total objetivo del combo (para FIJO se
  ///   ajusta por la diferencia del componente cambiado; en los demás se
  ///   recalcula desde los componentes).
  /// - [comboModificado]: la receta cambió respecto del combo original.
  final String? comboTipoPrecio;
  final double? comboDescuentoPct;
  final double? comboPrecioObjetivo;
  final bool comboModificado;

  /// Snapshot del precio de costo en sede al momento de agregar al carrito.
  /// Permite calcular margen local (preview "vendiendo bajo costo") y
  /// dispara el dialog de autorización gerencial al cobrar si es negativo.
  /// El backend ignora este valor — vuelve a calcular el costo desde
  /// ProductoStock y persiste su propio snapshot en VentaDetalle.
  final double? precioCostoSnapshot;

  /// True si el producto está en estado liquidación al momento de cargarlo.
  /// Permite mostrar badge naranja y omitir el guard de autorización.
  final bool enLiquidacion;

  /// True si el precio de la línea proviene de una OFERTA pública vigente
  /// en la sede. Solo informativo (badge "OFERTA" en el carrito de
  /// cotización + aviso al aplicar descuento encima): el precio de oferta
  /// ya viene aplicado en `precioUnitario`/`precioBase`.
  final bool enOferta;

  /// Precio NORMAL de la sede antes de la oferta (solo cuando [enOferta]).
  /// Informativo: tachado en el carrito/finalizar para ver cuánto ahorra
  /// el cliente por la oferta pública.
  final double? precioAntesOferta;

  /// El producto pide un identificador por unidad (IMEI, N° de serie, placa).
  /// Viene del producto y es solo capa de vista: sirve para saber que hay que
  /// pedirlo y con qué rótulo.
  final bool requiereIdentificador;
  final String? etiquetaIdentificador;

  /// Un identificador por unidad vendida en esta línea. Cantidad 3 ⇒ tres
  /// valores. Esto SÍ viaja al backend, que valida que estén completos y los
  /// sella en la descripción que se imprime y se declara.
  final List<String> identificadores;

  /// Nota opcional por unidad, en el MISMO orden que [identificadores]
  /// ("NEGRO 128GB"). Va aparte y no pegada al identificador porque este se
  /// guarda limpio para poder buscarlo exacto ante un reclamo de garantía; el
  /// backend la agrega entre paréntesis solo en el texto del comprobante.
  final List<String> notasIdentificador;

  /// Faltan identificadores para la cantidad que se está vendiendo.
  /// Bloquea el cobro: el IMEI no se puede completar después, la boleta ya
  /// salió impresa.
  bool get identificadoresIncompletos {
    if (!requiereIdentificador) return false;
    final cargados =
        identificadores.where((e) => e.trim().isNotEmpty).length;
    return cargados != cantidad.round();
  }

  /// Unidad en la que se le habla al cliente cuando la de venta es demasiado
  /// chica: `cantidad` y `precioUnitario` viajan SIEMPRE en unidad de venta
  /// (1500 g a S/0.008) pero se muestran y se capturan en presentación
  /// (1.5 kg a S/8.00). Null = el producto se vende en su unidad de venta,
  /// que es el caso de siempre.
  ///
  /// Es solo capa de vista y captura: el backend no recibe estos campos.
  final double? factorPresentacion;
  final String? unidadPresentacionSimbolo;

  /// Traductor entre lo que viaja y lo que se muestra. Se puede usar siempre:
  /// sin presentación el factor es 1 y no cambia ningún número.
  UnidadPresentacion get presentacion => UnidadPresentacion(
        factor: (factorPresentacion != null && factorPresentacion! > 1)
            ? factorPresentacion!
            : 1,
        simbolo: unidadPresentacionSimbolo,
      );

  /// Intenciones de precio especial VIP aplicables a esta línea (el cliente
  /// puede estar en varias políticas). Vacío = sin VIP. recalcularPrecioPorNiveles
  /// elige el menor entre ellas.
  final List<VipPrecioIntent> vipIntents;

  const VentaDetalleInput({
    this.productoId,
    this.varianteId,
    this.servicioId,
    this.comboId,
    this.ordenServicioId,
    this.ordenCodigo,
    this.ordenAdelanto = 0,
    required this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
    this.descuento = 0,
    this.porcentajeIGV = 18.0,
    this.precioIncluyeIgv = false,
    this.tipoAfectacion = '10',
    this.icbper = 0,
    this.stockDisponible,
    this.niveles = const [],
    this.precioBase,
    this.nivelAplicado,
    this.descuentoNivelPct,
    this.origenComboId,
    this.origenComboNombre,
    this.descuentoManual = 0,
    this.comboTipoPrecio,
    this.comboDescuentoPct,
    this.comboPrecioObjetivo,
    this.comboModificado = false,
    this.precioCostoSnapshot,
    this.enLiquidacion = false,
    this.enOferta = false,
    this.precioAntesOferta,
    this.requiereIdentificador = false,
    this.etiquetaIdentificador,
    this.identificadores = const [],
    this.notasIdentificador = const [],
    this.factorPresentacion,
    this.unidadPresentacionSimbolo,
    this.vipIntents = const [],
  });

  /// True si el precio actual de la línea proviene de una política VIP.
  bool get esPrecioVip =>
      nivelAplicado != null && nivelAplicado!.startsWith('VIP:');

  /// True si esta línea cobra una orden de servicio (cantidad fija 1,
  /// sin descuentos de línea, sin stock).
  bool get esOrdenServicio => ordenServicioId != null;

  /// Margen unitario neto (precio efectivo por unidad - costo). Negativo
  /// significa que se está vendiendo bajo costo.
  double? get margenUnitario {
    if (precioCostoSnapshot == null) return null;
    final descuentoUnitario = cantidad > 0 ? descuento / cantidad : 0;
    return (precioUnitario - descuentoUnitario) - precioCostoSnapshot!;
  }

  /// Pérdida total de esta línea (si margen<0), en valor absoluto.
  double get perdidaLinea {
    final m = margenUnitario;
    if (m == null || m >= 0) return 0;
    return -m * cantidad;
  }

  /// True si esta línea se está vendiendo con margen negativo y NO está
  /// en estado liquidación (es decir, requiere autorización gerencial).
  bool get requiereAutorizacionBajoCosto {
    if (enLiquidacion) return false;
    final m = margenUnitario;
    return m != null && m < 0 && (precioCostoSnapshot ?? 0) > 0;
  }

  bool get exceedsStock => stockDisponible != null && cantidad > stockDisponible!;

  double get subtotalBruto => cantidad * precioUnitario - descuento;

  /// Redondeo a centavos.
  ///
  /// 🔴 Tiene que dar EXACTAMENTE lo mismo que el `round2` del backend
  /// (`Math.round(n * 100) / 100`), porque el carrito muestra y cobra un monto
  /// que el servidor vuelve a calcular: si difieren en un centavo, el pago
  /// entra corto y la venta queda impaga para siempre. `(v * 100).round()` de
  /// Dart y `Math.round(v * 100)` de JS coinciden en montos positivos —los dos
  /// suben el medio centavo—, que es lo único que hay en una línea de venta.
  double _round2(double v) => (v * 100).round() / 100;

  double get _subtotalExacto => precioIncluyeIgv
      ? subtotalBruto / (1 + porcentajeIGV / 100)
      : subtotalBruto;

  double get _totalExacto =>
      (precioIncluyeIgv
          ? subtotalBruto
          : _subtotalExacto * (1 + porcentajeIGV / 100)) +
      icbper;

  /// 🔑 Los tres van redondeados y CUADRADOS: `subtotal + igv + icbper` da
  /// `total`, siempre. Antes ninguno se redondeaba, así que una línea a granel
  /// arrastraba fracciones de centavo (1237 g × 0.015 = 18.555) y el carrito
  /// terminaba cobrando 192.16 sobre una venta que el backend guardaba en
  /// 192.17. Ver `montos-linea.util.ts`, que hace esta misma cuenta del otro
  /// lado.
  double get total => _round2(_totalExacto);

  double get subtotal => _round2(_subtotalExacto);

  /// Por diferencia, no por porcentaje: es lo que hace que las partes sumen el
  /// total. El centavo que no entra en ningún lado lo absorbe el IGV.
  double get igv => _round2(total - icbper - subtotal);

  Map<String, dynamic> toMap() => {
        if (productoId != null) 'productoId': productoId,
        if (varianteId != null) 'varianteId': varianteId,
        if (servicioId != null) 'servicioId': servicioId,
        if (comboId != null) 'comboId': comboId,
        if (ordenServicioId != null) 'ordenServicioId': ordenServicioId,
        'descripcion': descripcion,
        'cantidad': cantidad,
        'precioUnitario': precioUnitario,
        if (descuento > 0) 'descuento': descuento,
        'porcentajeIGV': porcentajeIGV,
        'precioIncluyeIgv': precioIncluyeIgv,
        'tipoAfectacion': tipoAfectacion,
        if (icbper > 0) 'icbper': icbper,
        // El backend valida que estén completos y los sella en la
        // descripción que se imprime y se declara a SUNAT.
        if (identificadores.any((e) => e.trim().isNotEmpty)) ...{
          'identificadores':
              identificadores.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          // Van solo si hay alguna: el orden importa, así que se mandan
          // completas (con vacíos) para que el índice coincida con el
          // identificador al que anotan.
          if (notasIdentificador.any((e) => e.trim().isNotEmpty))
            'notasIdentificador':
                notasIdentificador.map((e) => e.trim()).toList(),
        },
        if (origenComboId != null) 'origenComboId': origenComboId,
        if (origenComboNombre != null) 'origenComboNombre': origenComboNombre,
      };

  VentaDetalleInput copyWith({
    String? productoId,
    String? varianteId,
    String? servicioId,
    String? comboId,
    String? ordenServicioId,
    String? ordenCodigo,
    double? ordenAdelanto,
    String? descripcion,
    double? cantidad,
    double? precioUnitario,
    double? descuento,
    double? porcentajeIGV,
    bool? precioIncluyeIgv,
    String? tipoAfectacion,
    double? icbper,
    bool? requiereIdentificador,
    String? etiquetaIdentificador,
    List<String>? identificadores,
    List<String>? notasIdentificador,
    int? stockDisponible,
    List<PrecioNivel>? niveles,
    double? precioBase,
    String? nivelAplicado,
    double? descuentoNivelPct,
    String? origenComboId,
    String? origenComboNombre,
    double? descuentoManual,
    String? comboTipoPrecio,
    double? comboDescuentoPct,
    double? comboPrecioObjetivo,
    bool? comboModificado,
    double? precioCostoSnapshot,
    bool? enLiquidacion,
    bool? enOferta,
    double? precioAntesOferta,
    double? factorPresentacion,
    String? unidadPresentacionSimbolo,
    List<VipPrecioIntent>? vipIntents,
    bool clearNivelAplicado = false,
    bool clearPrecioBase = false,
  }) {
    return VentaDetalleInput(
      productoId: productoId ?? this.productoId,
      varianteId: varianteId ?? this.varianteId,
      servicioId: servicioId ?? this.servicioId,
      comboId: comboId ?? this.comboId,
      ordenServicioId: ordenServicioId ?? this.ordenServicioId,
      ordenCodigo: ordenCodigo ?? this.ordenCodigo,
      ordenAdelanto: ordenAdelanto ?? this.ordenAdelanto,
      descripcion: descripcion ?? this.descripcion,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      descuento: descuento ?? this.descuento,
      porcentajeIGV: porcentajeIGV ?? this.porcentajeIGV,
      precioIncluyeIgv: precioIncluyeIgv ?? this.precioIncluyeIgv,
      tipoAfectacion: tipoAfectacion ?? this.tipoAfectacion,
      icbper: icbper ?? this.icbper,
      stockDisponible: stockDisponible ?? this.stockDisponible,
      niveles: niveles ?? this.niveles,
      precioBase: clearPrecioBase ? null : (precioBase ?? this.precioBase),
      nivelAplicado:
          clearNivelAplicado ? null : (nivelAplicado ?? this.nivelAplicado),
      descuentoNivelPct: clearNivelAplicado
          ? null
          : (descuentoNivelPct ?? this.descuentoNivelPct),
      origenComboId: origenComboId ?? this.origenComboId,
      origenComboNombre: origenComboNombre ?? this.origenComboNombre,
      descuentoManual: descuentoManual ?? this.descuentoManual,
      comboTipoPrecio: comboTipoPrecio ?? this.comboTipoPrecio,
      comboDescuentoPct: comboDescuentoPct ?? this.comboDescuentoPct,
      comboPrecioObjetivo: comboPrecioObjetivo ?? this.comboPrecioObjetivo,
      comboModificado: comboModificado ?? this.comboModificado,
      precioCostoSnapshot: precioCostoSnapshot ?? this.precioCostoSnapshot,
      enLiquidacion: enLiquidacion ?? this.enLiquidacion,
      enOferta: enOferta ?? this.enOferta,
      precioAntesOferta: precioAntesOferta ?? this.precioAntesOferta,
      requiereIdentificador:
          requiereIdentificador ?? this.requiereIdentificador,
      etiquetaIdentificador:
          etiquetaIdentificador ?? this.etiquetaIdentificador,
      identificadores: identificadores ?? this.identificadores,
      notasIdentificador: notasIdentificador ?? this.notasIdentificador,
      factorPresentacion: factorPresentacion ?? this.factorPresentacion,
      unidadPresentacionSimbolo:
          unidadPresentacionSimbolo ?? this.unidadPresentacionSimbolo,
      vipIntents: vipIntents ?? this.vipIntents,
    );
  }

  /// Selecciona el nivel aplicable más específico para una cantidad dada.
  /// Devuelve `null` si ningún nivel aplica.
  static PrecioNivel? nivelAplicableParaCantidad(
    List<PrecioNivel> niveles,
    double cantidad,
  ) {
    if (niveles.isEmpty) return null;
    final cantidadInt = cantidad.floor();
    final aplicables = niveles
        .where((n) => n.isActive && n.aplicaParaCantidad(cantidadInt))
        .toList();
    if (aplicables.isEmpty) return null;
    // El más específico = mayor cantidadMinima
    aplicables.sort((a, b) => b.cantidadMinima.compareTo(a.cantidadMinima));
    return aplicables.first;
  }

  /// Recalcula `precioUnitario`, `nivelAplicado` y `descuentoNivelPct`
  /// usando los niveles cacheados sobre el `precioBase` (o el actual
  /// `precioUnitario` si no hay precioBase aún registrado).
  ///
  /// Si no hay nivel aplicable, vuelve al precio base.
  ///
  /// EXCEPCION: si el item está en liquidación, los niveles se ignoran.
  /// El precio de liquidación gana siempre — aplicar un nivel "Por Mayor
  /// PRECIO_FIJO S/9" sobre un producto liquidado a S/5 lo subiría al
  /// vender 12 unidades, lo cual contradice el remate.
  VentaDetalleInput recalcularPrecioPorNiveles(double cantidad) {
    final base = precioBase ?? precioUnitario;

    // 1) Precio "normal" (base / nivel por mayor), igual que antes.
    double precio = base;
    String? etiqueta;
    double? descPct;

    if (!enLiquidacion) {
      final nivel = nivelAplicableParaCantidad(niveles, cantidad);
      if (nivel != null) {
        final precioConNivel = nivel.calcularPrecioFinal(base);
        // Un nivel por volumen NUNCA sube el precio.
        if (precioConNivel < base) {
          precio = precioConNivel;
          etiqueta = nivel.nombre;
          descPct = nivel.calcularDescuentoPorcentaje(base);
        }
      }
    }
    // enLiquidacion → precio = base (precio de liquidación ya viene en base),
    // niveles ignorados (paridad con backend).

    // 2) Candidatos VIP (gana el menor): espejo del reduce del backend. Cada
    //    política aplicable del cliente es un candidato; se toma el menor. El
    //    cliente nunca paga más que una oferta/liquidación pública más barata.
    for (final vip in vipIntents) {
      final vipPrecio = _calcularCandidatoVip(vip, base);
      if (vipPrecio != null && vipPrecio < precio) {
        precio = vipPrecio;
        etiqueta = vip.etiqueta;
        descPct = base > 0 ? ((base - vipPrecio) / base) * 100 : 0;
      }
    }

    if (etiqueta == null) {
      return copyWith(
        cantidad: cantidad,
        precioUnitario: precio,
        precioBase: base,
        clearNivelAplicado: true,
      );
    }
    return copyWith(
      cantidad: cantidad,
      precioUnitario: precio,
      precioBase: base,
      nivelAplicado: etiqueta,
      descuentoNivelPct: descPct,
    );
  }

  /// Calcula el precio candidato de la política VIP para esta línea. Espejo
  /// EXACTO de `_calcularCandidatoVip` del backend (PrecioNivelService). null
  /// si no se puede resolver (costo nulo / sin niveles).
  double? _calcularCandidatoVip(VipPrecioIntent vip, double base) {
    double r4(double v) => (v * 10000).round() / 10000;
    switch (vip.modo) {
      case ModoPrecioVip.precioCosto:
        final costo = precioCostoSnapshot;
        if (costo == null || costo <= 0) return null;
        return r4(costo * (1 + vip.markupSobreCosto / 100));
      case ModoPrecioVip.precioMayorDesdeUnidad:
        final activos = niveles.where((n) => n.isActive).toList();
        if (activos.isEmpty) return null;
        final mayoristas =
            activos.where((n) => n.cantidadMinima > 1).toList();
        final pool = mayoristas.isNotEmpty ? mayoristas : activos;
        // Loop manual (no reduce/sort): `niveles` tiene tipo estático
        // List<PrecioNivel> pero runtime List<PrecioNivelModel>; reduce falla por
        // covarianza (el combine devuelve el tipo del elemento) y sort mutaría.
        PrecioNivel elegido = pool.first;
        final mejorNivel = vip.estrategiaMayor == EstrategiaMayor.mejorNivel;
        for (final n in pool) {
          final mejorQue = mejorNivel
              ? n.calcularPrecioFinal(base) < elegido.calcularPrecioFinal(base)
              : n.cantidadMinima < elegido.cantidadMinima;
          if (mejorQue) elegido = n;
        }
        return r4(elegido.calcularPrecioFinal(base));
      case ModoPrecioVip.porcentaje:
        var desc = base * (vip.valor / 100);
        if (vip.descuentoMaximo != null && desc > vip.descuentoMaximo!) {
          desc = vip.descuentoMaximo!;
        }
        final p = base - desc;
        return r4(p < 0 ? 0 : p);
      case ModoPrecioVip.montoFijo:
        var desc = vip.valor;
        if (vip.descuentoMaximo != null && desc > vip.descuentoMaximo!) {
          desc = vip.descuentoMaximo!;
        }
        final p = base - desc;
        return r4(p < 0 ? 0 : p);
    }
  }
}
