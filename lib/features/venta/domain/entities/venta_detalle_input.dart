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

  /// Los identificadores de la línea, AGRUPADOS por unidad vendida: el índice
  /// es la unidad y cada una puede llevar más de un código, porque un celular
  /// dual SIM tiene dos IMEI. Cantidad 3 ⇒ tres grupos.
  ///
  /// Esto SÍ viaja al backend, que valida que estén completos y los sella en
  /// la descripción que se imprime y se declara.
  final List<List<String>> identificadores;

  /// Nota opcional por CÓDIGO ("SIM1", "NEGRO 128GB"), agrupada igual que
  /// [identificadores] y en el mismo orden. Va aparte y no pegada al
  /// identificador porque este se guarda limpio para poder buscarlo exacto
  /// ante un reclamo de garantía; el backend la agrega entre paréntesis solo
  /// en el texto del comprobante.
  final List<List<String>> notasIdentificador;

  /// El par (código, nota) de cada casilla, recortado a la cantidad ACTUAL y
  /// ya limpio.
  ///
  /// Dos cosas que tienen que pasar acá y no en el consumidor:
  ///
  /// - El state puede tener más o menos grupos que unidades —se bajó la
  ///   cantidad después de tipear, o se subió y todavía no se tocó el campo
  ///   nuevo—, y tanto el bloqueo del cobro como lo que se manda al backend
  ///   tienen que mirar SIEMPRE la cantidad actual.
  /// - 🔴 El par se filtra JUNTO: descartar un código vacío por un lado y su
  ///   nota por otro corre los índices, y la nota termina pegada al código de
  ///   al lado en un documento que se imprime y se declara.
  List<List<(String, String)>> get _casillasLimpias {
    final unidades = cantidad.round();
    return List.generate(unidades < 0 ? 0 : unidades, (u) {
      final codigos =
          u < identificadores.length ? identificadores[u] : const <String>[];
      final notas =
          u < notasIdentificador.length ? notasIdentificador[u] : const <String>[];
      final pares = <(String, String)>[];
      for (var k = 0; k < codigos.length; k++) {
        final codigo = codigos[k].trim();
        if (codigo.isEmpty) continue;
        pares.add((codigo, k < notas.length ? notas[k].trim() : ''));
      }
      return pares;
    });
  }

  /// Los códigos que corresponden a la cantidad que se está vendiendo, uno por
  /// grupo y sin los vacíos.
  List<List<String>> get identificadoresPorUnidad =>
      [for (final grupo in _casillasLimpias) [for (final par in grupo) par.$1]];

  /// Las notas, alineadas una a una con [identificadoresPorUnidad].
  List<List<String>> get notasIdentificadorPorUnidad =>
      [for (final grupo in _casillasLimpias) [for (final par in grupo) par.$2]];

  /// Falta el identificador de alguna unidad que se está vendiendo.
  /// Bloquea el cobro: el IMEI no se puede completar después, la boleta ya
  /// salió impresa.
  ///
  /// Basta UN código por unidad: los extras (el segundo IMEI de un dual SIM)
  /// son opcionales y no frenan la venta.
  bool get identificadoresIncompletos {
    if (!requiereIdentificador) return false;
    return identificadoresPorUnidad.any((codigos) => codigos.isEmpty);
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

  /// Estado del MAYOREO COMBINADO de la línea: a qué grupo pertenece, cuántas
  /// unidades lleva juntadas el carrito y cuántas faltan. Null cuando la línea
  /// no participa de ningún grupo (sin niveles, sin variante, o es componente
  /// de combo). Solo capa de vista — no viaja al backend.
  final MayoreoCombinado? mayoreo;

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
    this.mayoreo,
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
        if (identificadoresPorUnidad.any((g) => g.isNotEmpty)) ...{
          // Agrupado por unidad: es la forma que el backend necesita para
          // saber qué par de IMEI es de qué aparato.
          'identificadoresPorUnidad': identificadoresPorUnidad,
          // Plano, además del agrupado, a propósito: con un código por unidad
          // las dos formas dicen lo mismo, así que este app sigue cobrando
          // contra un backend que todavía no conozca el campo agrupado. Solo
          // una venta con códigos extra necesita el backend nuevo.
          'identificadores':
              identificadoresPorUnidad.expand((g) => g).toList(),
          // Van solo si hay alguna. Las dos formas, por lo mismo que los
          // códigos: aplanadas quedan alineadas por índice con
          // `identificadores`, que es como las lee el backend viejo.
          if (notasIdentificadorPorUnidad
              .any((g) => g.any((n) => n.isNotEmpty))) ...{
            'notasIdentificadorPorUnidad': notasIdentificadorPorUnidad,
            'notasIdentificador':
                notasIdentificadorPorUnidad.expand((g) => g).toList(),
          },
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
    List<List<String>>? identificadores,
    List<List<String>>? notasIdentificador,
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
    MayoreoCombinado? mayoreo,
    bool clearNivelAplicado = false,
    bool clearPrecioBase = false,
    bool clearMayoreo = false,
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
      mayoreo: clearMayoreo ? null : (mayoreo ?? this.mayoreo),
    );
  }

  /// Llave del GRUPO DE MAYOREO al que pertenece un nivel.
  ///
  /// 🔴 ESPEJO EXACTO de `PrecioNivelService.claveGrupoMayoreo` del backend
  /// (`precio-nivel.service.ts`). No hace falta que los strings coincidan entre
  /// los dos lados —cada uno agrupa en su casa—, pero sí que agrupen IGUAL: si
  /// el app junta variantes que el backend separa, el precio que se manda no es
  /// el que el servidor calcula y la venta rebota con 409 PRECIO_DESACTUALIZADO.
  ///
  /// El `nombre` del nivel NO entra: "Por Mayor" y "Mayorista" al mismo precio
  /// son el mismo trato. El `productoId` sí, porque el mayoreo combinado se
  /// acumula DENTRO de un producto.
  static String claveGrupoMayoreo(String productoId, PrecioNivel nivel) {
    final valor = nivel.tipoPrecio == TipoPrecioNivel.precioFijo
        ? (nivel.precio?.toStringAsFixed(6) ?? 'sin-precio')
        : (nivel.porcentajeDesc?.toStringAsFixed(2) ?? 'sin-pct');
    return [
      productoId,
      nivel.cantidadMinima,
      nivel.cantidadMaxima ?? 'inf',
      nivel.tipoPrecio.value,
      valor,
    ].join('|');
  }

  /// Cantidad contra la que se mide un nivel: la de su grupo si el carrito
  /// juntó más que esta línea, y si no la de la línea.
  ///
  /// El `max` es lo que garantiza que el mayoreo combinado nunca EMPEORE un
  /// precio: una línea de 10 unidades se sigue midiendo por sus 10.
  static double _cantidadParaNivel(
    PrecioNivel nivel,
    double cantidad,
    Map<String, double> cantidadesGrupo,
    String productoId,
  ) {
    final delGrupo = cantidadesGrupo[claveGrupoMayoreo(productoId, nivel)];
    return (delGrupo != null && delGrupo > cantidad) ? delGrupo : cantidad;
  }

  /// MAYOREO COMBINADO: unidades que junta cada grupo en TODO el carrito.
  ///
  /// Quien se lleva 3 edredones de tres diseños distintos que comparten el
  /// mismo "Por Mayor ≥ 3" tiene que pagar por mayor los tres: el cliente ve
  /// tres edredones, no tres líneas de uno.
  ///
  /// Cuenta LÍNEAS, no variantes distintas (la misma variante en dos líneas de
  /// 1 también suma 2), y deja afuera los componentes de combo, que tienen su
  /// propio deal de precio.
  static Map<String, double> cantidadesGrupoMayoreo(
    List<VentaDetalleInput> items,
  ) {
    final totales = <String, double>{};
    final acumulan = items
        .where((i) =>
            i.varianteId != null &&
            i.productoId != null &&
            i.origenComboId == null)
        .toList();
    // Una sola línea no combina con nadie.
    if (acumulan.length < 2) return totales;

    for (final item in acumulan) {
      for (final nivel in item.niveles) {
        if (!nivel.isActive) continue;
        final clave = claveGrupoMayoreo(item.productoId!, nivel);
        totales[clave] = (totales[clave] ?? 0) + item.cantidad;
      }
    }
    return totales;
  }

  /// Reprecia el carrito ENTERO de una, aplicando mayoreo combinado.
  ///
  /// 🔴 Este es el punto de entrada: `recalcularPrecioPorNiveles` sola ya no
  /// alcanza, porque el precio de una línea ahora depende de las OTRAS. Cada
  /// vez que se agrega, quita o cambia la cantidad de un ítem hay que pasar la
  /// lista completa por acá, no repreciar la línea tocada.
  static List<VentaDetalleInput> recalcularNivelesEnLote(
    List<VentaDetalleInput> items,
  ) {
    final grupos = cantidadesGrupoMayoreo(items);
    return [
      for (final item in items)
        // Componentes de combo: el precio lo fija el prorrateo del combo, no
        // los niveles. Repreciarlos acá les pisaría el precio del deal.
        // Espejo de `ignorarNiveles` del backend.
        if (item.origenComboId != null)
          item
        else
          item.recalcularPrecioPorNiveles(
            item.cantidad,
            cantidadesGrupo: grupos,
          ),
    ];
  }

  /// Selecciona el nivel aplicable más específico para una cantidad dada.
  /// Devuelve `null` si ningún nivel aplica.
  ///
  /// Con [cantidadesGrupo] (mayoreo combinado) cada nivel se mide contra las
  /// unidades de SU grupo cuando el carrito acumuló más que esta línea. Sin el
  /// mapa manda la cantidad de la línea, que es el comportamiento de siempre.
  static PrecioNivel? nivelAplicableParaCantidad(
    List<PrecioNivel> niveles,
    double cantidad, {
    Map<String, double>? cantidadesGrupo,
    String? productoId,
  }) {
    if (niveles.isEmpty) return null;
    final cantidadInt = cantidad.floor();
    final aplicables = niveles
        .where((n) =>
            n.isActive &&
            n.aplicaParaCantidad(
              cantidadesGrupo == null || productoId == null
                  ? cantidadInt
                  : _cantidadParaNivel(
                      n,
                      cantidad,
                      cantidadesGrupo,
                      productoId,
                    ).floor(),
            ))
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
  ///
  /// [cantidadesGrupo] activa el MAYOREO COMBINADO: el mínimo de cada nivel se
  /// mide contra las unidades del grupo en todo el carrito. Normalmente no se
  /// pasa a mano — se llama [recalcularNivelesEnLote], que lo arma y reprecia
  /// todas las líneas juntas.
  VentaDetalleInput recalcularPrecioPorNiveles(
    double cantidad, {
    Map<String, double>? cantidadesGrupo,
  }) {
    final base = precioBase ?? precioUnitario;

    // 1) Precio "normal" (base / nivel por mayor), igual que antes.
    double precio = base;
    String? etiqueta;
    double? descPct;

    if (!enLiquidacion) {
      final nivel = nivelAplicableParaCantidad(
        niveles,
        cantidad,
        cantidadesGrupo: cantidadesGrupo,
        // Solo las líneas de VARIANTE combinan, igual que en el backend
        // (que scopea el grupo por `variante.productoId`). Un producto sin
        // variantes no tiene con quién agruparse, y pasarle el productoId acá
        // lo haría enganchar con el grupo de las variantes de ese mismo
        // producto — un grupo que el servidor no arma. Eso es un 409.
        productoId: varianteId != null ? productoId : null,
      );
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

    // 3) Estado del mayoreo para el badge del carrito. Se calcula SIEMPRE que
    //    haya mapa de grupos, aplique o no el nivel: el caso más útil para el
    //    vendedor es justo el que NO aplicó todavía ("falta 1 para S/72").
    final estadoMayoreo = cantidadesGrupo == null
        ? null
        : _estadoMayoreo(cantidad, cantidadesGrupo, base);

    if (etiqueta == null) {
      return copyWith(
        cantidad: cantidad,
        precioUnitario: precio,
        precioBase: base,
        clearNivelAplicado: true,
        mayoreo: estadoMayoreo,
        clearMayoreo: estadoMayoreo == null,
      );
    }
    return copyWith(
      cantidad: cantidad,
      precioUnitario: precio,
      precioBase: base,
      nivelAplicado: etiqueta,
      descuentoNivelPct: descPct,
      mayoreo: estadoMayoreo,
      clearMayoreo: estadoMayoreo == null,
    );
  }

  /// Arma el estado del mayoreo combinado para el badge: el nivel MÁS BARATO
  /// que el grupo ya alcanzó y, si no alcanzó ninguno, el más cercano — el que
  /// le falta menos. Null si la línea no participa de ningún grupo o si el
  /// grupo no aporta nada por encima de la propia línea (ahí el badge sería
  /// ruido: no hay nada "combinado" que explicar).
  MayoreoCombinado? _estadoMayoreo(
    double cantidad,
    Map<String, double> cantidadesGrupo,
    double base,
  ) {
    if (productoId == null || varianteId == null) return null;
    if (origenComboId != null || enLiquidacion) return null;

    MayoreoCombinado? mejorAlcanzado;
    MayoreoCombinado? masCercano;

    for (final nivel in niveles) {
      if (!nivel.isActive) continue;
      final unidades =
          cantidadesGrupo[claveGrupoMayoreo(productoId!, nivel)] ?? cantidad;
      // Sin aporte del resto del carrito no hay nada que contar.
      if (unidades <= cantidad) continue;
      final precioNivel = nivel.calcularPrecioFinal(base);
      if (precioNivel >= base) continue;

      final estado = MayoreoCombinado(
        nombreNivel: nivel.nombre,
        precioNivel: precioNivel,
        minimo: nivel.cantidadMinima,
        unidadesGrupo: unidades,
      );
      if (estado.alcanzado) {
        if (mejorAlcanzado == null ||
            estado.precioNivel < mejorAlcanzado.precioNivel) {
          mejorAlcanzado = estado;
        }
      } else if (masCercano == null || estado.faltan < masCercano.faltan) {
        masCercano = estado;
      }
    }
    return mejorAlcanzado ?? masCercano;
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

/// Estado del MAYOREO COMBINADO de una línea, para explicarlo en el carrito.
///
/// Existe porque el precio de una línea pasó a depender de las OTRAS, y sin
/// contarlo el vendedor ve un precio que baja (o que no baja) sin motivo
/// visible. Los dos mensajes que importan:
/// - alcanzado: "Por Mayor S/72 · 3 de 3" — por qué bajó.
/// - por alcanzar: "Falta 1 para Por Mayor S/72" — la venta que se puede
///   cerrar diciéndolo en voz alta.
///
/// Además es la red contra el riesgo de agrupar por precio: si a una variante
/// le cambian el mayor en S/1 sale del grupo en silencio, y el "2 de 3" que no
/// llega a 3 es lo que lo hace visible en el mostrador.
class MayoreoCombinado {
  /// Nombre del nivel, tal cual lo cargó la empresa ("Por Mayor").
  final String nombreNivel;

  /// Precio unitario que deja el nivel.
  final double precioNivel;

  /// Unidades que pide el nivel.
  final int minimo;

  /// Unidades que juntó el GRUPO en todo el carrito (incluye esta línea).
  final double unidadesGrupo;

  const MayoreoCombinado({
    required this.nombreNivel,
    required this.precioNivel,
    required this.minimo,
    required this.unidadesGrupo,
  });

  bool get alcanzado => unidadesGrupo.floor() >= minimo;

  /// Cuántas unidades faltan para el mínimo. 0 si ya se alcanzó.
  int get faltan {
    final resto = minimo - unidadesGrupo.floor();
    return resto > 0 ? resto : 0;
  }

  /// Texto listo para el chip del carrito. Corto a propósito: la columna del
  /// carrito es angosta y el chip convive con el del nivel aplicado.
  ///
  /// Alcanzado explica por qué una línea de 1 unidad bajó de precio; el otro
  /// es el que cierra ventas ("llevate uno más y te los dejo a 72").
  String get etiqueta => alcanzado
      ? 'Mayoreo: ${unidadesGrupo.floor()} de $minimo'
      : 'Falta${faltan == 1 ? '' : 'n'} $faltan para '
          'S/ ${precioNivel.toStringAsFixed(2)}';
}
