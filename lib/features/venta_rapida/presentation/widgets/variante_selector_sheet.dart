import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/unidad_presentacion.dart';
import '../../../producto/presentation/widgets/abrir_bulto_dialog.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../producto/domain/entities/precio_nivel.dart';
import '../../../producto/domain/entities/producto_list_item.dart';
import '../../../producto/domain/entities/producto_variante.dart';
import '../../../producto/domain/services/precio_nivel_cache_service.dart';
import '../../../venta/domain/entities/venta_detalle_input.dart';
import '../../../auth/presentation/widgets/custom_text.dart';

/// Sheet de selección de variante POR ATRIBUTO.
///
/// En vez de listar cada combinación como una card suelta, agrupa los
/// atributos del producto (Talla, Forma, Modelo, ...) derivándolos de las
/// propias variantes y muestra un set de chips por atributo. La combinación
/// elegida resuelve a una variante concreta; el usuario fija la cantidad y
/// agrega al carrito.
///
/// [onAgregar] recibe la variante resuelta y la cantidad elegida. El caller
/// decide cómo materializarla en el carrito (típicamente llamando N veces a
/// `cubit.agregarVariante`).
Future<void> showVarianteSelectorSheet({
  required BuildContext context,
  required ProductoListItem producto,
  required String sedeId,
  required void Function(ProductoVariante variante, int cantidad) onAgregar,
  void Function(ProductoVariante variante)? onQuitarUnidad,
  Map<String, int> cantidadesEnCarrito = const {},
  Map<String, List<PrecioNivel>> nivelesVariantes = const {},
  VoidCallback? onBultoAbierto,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(
      // Altura fija (min == max). Al 85% y no al 70% porque con el teclado
      // numérico abierto el sheet descuenta el inset adentro: con 70% el
      // cuerpo quedaba en una franja de ~30% de pantalla y no se veía ni lo
      // que se estaba tipeando.
      minHeight: MediaQuery.of(context).size.height * 0.85,
      maxHeight: MediaQuery.of(context).size.height * 0.85,
    ),
    builder: (_) => _VarianteSelectorSheet(
      producto: producto,
      sedeId: sedeId,
      onAgregar: onAgregar,
      onQuitarUnidad: onQuitarUnidad,
      cantidadesEnCarrito: cantidadesEnCarrito,
      nivelesVariantes: nivelesVariantes,
      onBultoAbierto: onBultoAbierto,
    ),
  );
}

/// Grupo de atributo derivado de las variantes: clave única, nombre visible
/// y valores posibles (en orden de aparición).
class _AtributoGrupo {
  final String clave;
  final String nombre;
  final List<String> valores;
  _AtributoGrupo(this.clave, this.nombre, this.valores);
}

class _VarianteSelectorSheet extends StatefulWidget {
  final ProductoListItem producto;
  final String sedeId;
  final void Function(ProductoVariante variante, int cantidad) onAgregar;
  final void Function(ProductoVariante variante)? onQuitarUnidad;
  final Map<String, int> cantidadesEnCarrito;
  final Map<String, List<PrecioNivel>> nivelesVariantes;

  /// Se abrió un bulto desde la venta: el stock del granel cambió y el caller
  /// tiene que revalidar el catálogo.
  final VoidCallback? onBultoAbierto;

  const _VarianteSelectorSheet({
    required this.producto,
    required this.sedeId,
    required this.onAgregar,
    this.onQuitarUnidad,
    this.cantidadesEnCarrito = const {},
    this.nivelesVariantes = const {},
    this.onBultoAbierto,
  });

  @override
  State<_VarianteSelectorSheet> createState() => _VarianteSelectorSheetState();
}

/// Clave sintética usada cuando las variantes NO tienen atributos
/// estructurados: se selecciona la variante por su nombre directamente.
const String _kVarianteClave = '__variante__';

class _VarianteSelectorSheetState extends State<_VarianteSelectorSheet> {
  late final List<ProductoVariante> _variantes;
  late final List<_AtributoGrupo> _grupos;

  /// Valor elegido por clave de atributo (null = sin elegir).
  final Map<String, String?> _seleccion = {};

  /// Grupo desplegado en el acordeón. Los demás se muestran colapsados en una
  /// sola línea con su valor elegido. `null` = usar el default de
  /// [_claveExpandida].
  ///
  /// Con 5 atributos (tamaño, temporada, piezas, género, diseño) y 37 diseños,
  /// apilar todos los `Wrap` a la vez deja el botón de agregar fuera de
  /// pantalla y llena el sheet de chips deshabilitados. Colapsar lo ya resuelto
  /// deja 4 renglones en vez de 4 filas de chips.
  String? _grupoExpandido;

  /// SIEMPRE en unidad atómica (gramos para un granel). Lo que se teclea en
  /// kilos se convierte antes de tocar esta variable, así el resto del sheet
  /// —stock, niveles, carrito— sigue hablando un solo idioma.
  int _cantidad = 1;

  /// Texto del campo de granel, en unidad de presentación.
  final _cantidadGranelCtrl = TextEditingController();

  /// El campo de kilos arranca con el foco puesto. Antes era `autofocus: true`
  /// del TextField; `CustomText` no lo expone, así que se pide a mano cada vez
  /// que el campo aparece — al abrir el sheet en una variante a granel y al
  /// cambiar de una variante por unidad a una a granel.
  final _granelFocus = FocusNode();

  /// Bulto cerrado con el que se puede reponer el granel que se está
  /// vendiendo. Se consulta UNA sola vez y recién cuando hace falta: es el
  /// camino excepcional (quedarse corto a media venta), no el normal.
  Map<String, dynamic>? _bultoParaReponer;
  bool _bultoConsultado = false;

  /// Copia mutable de lo que ya está en el carrito (varianteId -> cantidad).
  /// Se actualiza localmente al "Limpiar" para refrescar el stock disponible.
  late Map<String, int> _enCarrito;

  /// Niveles de precio (por volumen) por varianteId. Se siembra con el
  /// snapshot recibido y se va completando al resolver cada variante.
  late Map<String, List<PrecioNivel>> _niveles;

  /// varianteIds cuyos niveles ya pedimos en esta sesión del sheet (evita
  /// refetch repetido al re-seleccionar la misma combinación).
  final Set<String> _nivelesPedidos = {};

  final PrecioNivelCacheService _nivelCache = locator<PrecioNivelCacheService>();

  @override
  void initState() {
    super.initState();
    _variantes = (widget.producto.variantes ?? const <ProductoVariante>[])
        .where((v) => v.isActive)
        .toList();
    _enCarrito = Map.of(widget.cantidadesEnCarrito);
    _niveles = Map.of(widget.nivelesVariantes);
    _grupos = _derivarGrupos(_variantes);
    _autoSeleccionInicial();
    // Cargar (fresco) los niveles de la variante inicial.
    _cargarNivelesResuelta();
  }

  /// Carga los niveles de la variante resuelta y reconstruye. Fuerza un
  /// refresco del cache la primera vez que se ve cada variante en esta
  /// sesión, para tomar niveles recién creados/editados (el cache compartido
  /// pudo haber guardado `[]` antes de que existiera el nivel).
  void _cargarNivelesResuelta() {
    final v = _varianteResuelta;
    if (v == null || _nivelesPedidos.contains(v.id)) return;
    _nivelesPedidos.add(v.id);
    _nivelCache.invalidateVariante(v.id);
    _nivelCache.getNivelesVariante(v.id).then((niveles) {
      if (!mounted) return;
      setState(() => _niveles[v.id] = niveles);
    });
  }

  // ---- Derivación de atributos ---------------------------------------------

  List<_AtributoGrupo> _derivarGrupos(List<ProductoVariante> variantes) {
    final orden = <String>[];
    final nombre = <String, String>{};
    final valores = <String, List<String>>{};
    for (final v in variantes) {
      for (final av in v.atributosValores) {
        final clave = av.atributo.clave;
        if (!valores.containsKey(clave)) {
          valores[clave] = [];
          nombre[clave] = av.atributo.nombre;
          orden.add(clave);
        }
        if (!valores[clave]!.contains(av.valor)) {
          valores[clave]!.add(av.valor);
        }
      }
    }
    // Fallback: variantes "simples" sin atributos estructurados (ej. nombradas
    // AZUL/ROJA pero sin el atributo Color asignado). Sintetizamos un único
    // grupo "Variante" cuyos valores son los nombres de cada variante.
    if (orden.isEmpty && variantes.isNotEmpty) {
      final nombres = <String>[];
      for (final v in variantes) {
        if (!nombres.contains(v.nombre)) nombres.add(v.nombre);
      }
      return [_AtributoGrupo(_kVarianteClave, 'Variante', nombres)];
    }
    return orden
        .map((c) => _AtributoGrupo(c, nombre[c] ?? c, valores[c]!))
        .toList();
  }

  /// Pre-selecciona la primera variante con stock (o la primera a secas),
  /// para que el sheet abra con una combinación válida lista, como la imagen.
  void _autoSeleccionInicial() {
    final ordenadas = [..._variantes]..sort((a, b) => a.orden.compareTo(b.orden));
    ProductoVariante? candidata;
    for (final v in ordenadas) {
      if (_stockDisponible(v) > 0) {
        candidata = v;
        break;
      }
    }
    candidata ??= ordenadas.isNotEmpty ? ordenadas.first : null;
    if (candidata != null) {
      final esSintetico =
          _grupos.length == 1 && _grupos.first.clave == _kVarianteClave;
      if (esSintetico) {
        _seleccion[_kVarianteClave] = candidata.nombre;
      } else {
        for (final av in candidata.atributosValores) {
          _seleccion[av.atributo.clave] = av.valor;
        }
      }
    }
    // A granel el campo arranca vacío: no tiene sentido proponer "1 g".
    _cantidad = _stockRestante > 0 && !_esGranel ? 1 : 0;
    _enfocarGranel();
  }

  /// Pone el foco en el campo de kilos si la variante resuelta es a granel.
  /// Post-frame porque se llama desde `initState` y desde un `setState`: el
  /// campo todavía no existe en el árbol cuando esto corre.
  void _enfocarGranel() {
    if (!_esGranel) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _esGranel) _granelFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _cantidadGranelCtrl.dispose();
    _granelFocus.dispose();
    super.dispose();
  }

  // ---- Matching y disponibilidad -------------------------------------------

  int _stockDisponible(ProductoVariante v) {
    final real = v.stockEnSede(widget.sedeId) ?? 0;
    final enCarrito = _enCarrito[v.id] ?? 0;
    return (real - enCarrito).clamp(0, real);
  }

  /// ¿La variante satisface todas las claves no-nulas de [sel]?
  bool _coincide(ProductoVariante v, Map<String, String?> sel) {
    for (final entry in sel.entries) {
      final valor = entry.value;
      if (valor == null) continue;
      if (entry.key == _kVarianteClave) {
        // Modo sintético: se matchea directamente por nombre de variante.
        if (v.nombre != valor) return false;
        continue;
      }
      final match = v.atributosValores
          .where((a) => a.atributo.clave == entry.key)
          .map((a) => a.valor);
      if (match.isEmpty || match.first != valor) return false;
    }
    return true;
  }

  /// Variante resuelta cuando hay un valor elegido por cada atributo.
  ProductoVariante? get _varianteResuelta {
    if (_grupos.any((g) => _seleccion[g.clave] == null)) return null;
    for (final v in _variantes) {
      if (_coincide(v, _seleccion)) return v;
    }
    return null;
  }

  /// Un valor está disponible si, manteniendo las OTRAS selecciones actuales,
  /// existe al menos una variante con stock que lo use.
  bool _valorDisponible(String clave, String valor) {
    final tentativa = <String, String?>{};
    for (final g in _grupos) {
      tentativa[g.clave] = g.clave == clave ? valor : _seleccion[g.clave];
    }
    for (final v in _variantes) {
      if (_coincide(v, tentativa) && _stockDisponible(v) > 0) return true;
    }
    return false;
  }

  int get _stockRestante {
    final v = _varianteResuelta;
    return v == null ? 0 : _stockDisponible(v);
  }

  /// Qué grupo va desplegado. Si el usuario tocó uno, ese; si no, el primero
  /// sin elegir, y si está todo elegido —lo normal, porque
  /// [_autoSeleccionInicial] preselecciona una combinación entera— el último,
  /// que es el más granular (el diseño) y el que más se cambia en mostrador.
  String get _claveExpandida {
    if (_grupos.isEmpty) return '';
    final forzado = _grupoExpandido;
    if (forzado != null) return forzado;
    for (final g in _grupos) {
      if (_seleccion[g.clave] == null) return g.clave;
    }
    return _grupos.last.clave;
  }

  /// Cuántos valores del grupo tienen stock con las otras selecciones puestas.
  int _valoresConStock(_AtributoGrupo g) {
    var n = 0;
    for (final valor in g.valores) {
      if (_valorDisponible(g.clave, valor)) n++;
    }
    return n;
  }

  /// Stock de la variante que quedaría al elegir `valor`, pero **solo si con
  /// eso la combinación queda completa**. Si todavía faltan atributos el número
  /// sería la suma de varias variantes y prometería un stock que esa
  /// combinación puntual no tiene, así que en ese caso no se muestra nada.
  int? _stockSiCompleta(String clave, String valor) {
    final tentativa = <String, String?>{};
    for (final g in _grupos) {
      tentativa[g.clave] = g.clave == clave ? valor : _seleccion[g.clave];
    }
    for (final v in tentativa.values) {
      if (v == null) return null;
    }
    for (final v in _variantes) {
      if (_coincide(v, tentativa)) return _stockDisponible(v);
    }
    return null;
  }

  /// Lo que se está eligiendo, en el mismo orden en que se ven los chips:
  /// "ADULTO · CARNE · GRANEL". La cabecera muestra el nombre del producto
  /// BASE, que en un multi-sabor es igual para 24 variantes; sin esto no hay
  /// forma de saber qué se está por agregar hasta mirar los chips uno por uno.
  ///
  /// Va mostrando la selección parcial: con dos de tres atributos elegidos se
  /// leen esos dos. Vacío mientras no haya nada elegido.
  String get _combinacionTexto {
    final partes = <String>[];
    for (final g in _grupos) {
      final valor = _seleccion[g.clave];
      if (valor != null && valor.isNotEmpty) partes.add(valor);
    }
    return partes.join(' · ');
  }

  void _seleccionar(String clave, String valor) {
    HapticFeedback.selectionClick();
    setState(() {
      _seleccion[clave] = valor;
      // Avanzar el acordeón al grupo siguiente: elegir tamaño abre piezas,
      // piezas abre género, y así hasta el último. En el último no se mueve,
      // para poder cambiar de diseño varias veces sin que el panel salte.
      final i = _grupos.indexWhere((g) => g.clave == clave);
      if (i >= 0 && i < _grupos.length - 1) {
        _grupoExpandido = _grupos[i + 1].clave;
      }
      // Reparar otros atributos cuya selección quedó incompatible con el
      // nuevo valor, eligiendo el primer valor disponible (UX e-commerce:
      // cambiar color a uno sin tu talla reajusta la talla).
      for (final g in _grupos) {
        if (g.clave == clave) continue;
        final actual = _seleccion[g.clave];
        if (actual == null || _valorDisponible(g.clave, actual)) continue;
        _seleccion[g.clave] = g.valores.firstWhere(
          (v) => _valorDisponible(g.clave, v),
          orElse: () => actual,
        );
      }
      final rest = _stockRestante;
      // Cambiar de variante puede pasar de granel a unidad y viceversa: el
      // campo de kilos se limpia para no arrastrar un valor de la anterior.
      if (_esGranel) {
        _cantidadGranelCtrl.clear();
        _cantidad = 0;
        _enfocarGranel();
      } else {
        _cantidad = rest > 0 ? _cantidad.clamp(1, rest) : 0;
      }
    });
    // Cargar niveles de la nueva variante resuelta (si aún no se pidieron).
    _cargarNivelesResuelta();
  }

  void _cambiarCantidad(int delta) {
    final rest = _stockRestante;
    final nueva = (_cantidad + delta).clamp(0, rest);
    if (nueva == _cantidad) return;
    HapticFeedback.lightImpact();
    setState(() => _cantidad = nueva);
  }

  // ---- Granel ---------------------------------------------------------------

  /// La variante resuelta se vende a granel: tiene presentación propia, así
  /// que se cobra en kilos aunque se guarde en gramos. El stepper de +1 no
  /// sirve —nadie toca 1500 veces para vender kilo y medio— y hay que capturar
  /// la cantidad en la unidad de PRESENTACIÓN.
  /// Se vende a granel: hay presentación activa, propia o heredada.
  bool get _esGranel => _presentacion != null;

  /// Precio en la unidad en la que se COBRA. Un granel guardado en gramos
  /// tiene precio 0.015/g: mostrar "S/ 0.01" es un precio que no existe y que
  /// además está redondeado. Se muestra "S/ 15.00 /kg", igual que hace la card
  /// de un producto a granel sin variantes.
  String _precioTexto(double porUnidadDeVenta) {
    final p = _presentacion;
    // `precioTexto` ya trae la moneda y el sufijo de unidad ("S/ 15.00/kg").
    if (p == null) return 'S/ ${porUnidadDeVenta.toStringAsFixed(2)}';
    return p.precioTexto(porUnidadDeVenta);
  }

  /// Stock en la unidad de cobro: "15 kg" en vez de "15000".
  String _stockTexto(int enUnidadDeVenta) {
    final p = _presentacion;
    if (p == null) return '$enUnidadDeVenta';
    return p.cantidadTexto(enUnidadDeVenta);
  }

  /// Presentación de la variante resuelta, con la del PRODUCTO como herencia.
  ///
  /// La herencia importa: con varios sabores conviene configurar "kg ×1000"
  /// una sola vez en el producto en lugar de repetirlo en cada granel. Los
  /// bultos cerrados no la heredan porque tienen unidad propia distinta —esa
  /// es la regla que ya aplica el backend al declarar el comprobante— así que
  /// el saco sigue mostrándose por unidad.
  ///
  /// Null = sin presentación activa; la variante se muestra en su unidad.
  UnidadPresentacion? get _presentacion {
    final v = _varianteResuelta;
    if (v == null) return null;
    final pres = widget.producto.presentacionDeVariante(v);
    return pres.activa ? pres : null;
  }

  /// Lo tecleado (kilos) convertido a unidad atómica (gramos), que es lo que
  /// viaja al carrito y al stock. Se redondea porque el stock es entero: la
  /// balanza entrega gramos enteros de todos modos.
  void _cantidadDesdeTexto(String texto) {
    final p = _presentacion;
    final valor = double.tryParse(texto.trim().replaceAll(',', '.'));
    if (p == null || valor == null) {
      setState(() => _cantidad = 0);
      return;
    }
    final atomica = (valor * p.factor).round();
    // Pidió más de lo que hay suelto: puede haber un bulto cerrado que lo
    // resuelva sin mandar al cliente a otro lado.
    if (atomica > _stockRestante) _consultarBultoParaReponer();
    setState(() => _cantidad = atomica.clamp(0, _stockRestante));
  }

  /// Busca si el granel que se está vendiendo tiene un bulto cerrado con
  /// stock. Una sola vez por sheet y solo bajo demanda: es el POS.
  Future<void> _consultarBultoParaReponer() async {
    if (_bultoConsultado) return;
    _bultoConsultado = true;
    final v = _varianteResuelta;
    if (v == null) return;
    try {
      final resp = await locator<DioClient>().get(
        '/apertura-bulto/disponibles',
        queryParameters: {'sedeId': widget.sedeId},
      );
      Map<String, dynamic>? encontrado;
      for (final e in (resp.data as List<dynamic>? ?? [])) {
        final j = e as Map<String, dynamic>;
        final destino = j['destino'] as Map<String, dynamic>;
        final cerrados = ((j['bulto'] as Map<String, dynamic>)['stock'] as num?)
                ?.toInt() ??
            0;
        if (destino['varianteId'] == v.id && cerrados > 0) {
          encontrado = j;
          break;
        }
      }
      if (!mounted || encontrado == null) return;
      setState(() => _bultoParaReponer = encontrado);
    } catch (_) {
      // Silencioso: es una ayuda, no puede romper una venta en curso.
    }
  }

  /// Abre un bulto sin salir de la venta. Al volver hay que refrescar el
  /// catálogo —el stock del granel cambió— y eso lo hace el caller, así que
  /// el sheet se cierra y avisa.
  Future<void> _abrirDesdeVenta() async {
    final j = _bultoParaReponer!;
    final bulto = j['bulto'] as Map<String, dynamic>;
    final destino = j['destino'] as Map<String, dynamic>;
    final r = await AbrirBultoDialog.show(
      context: context,
      bultoVarianteId: bulto['varianteId'].toString(),
      bultoNombre: bulto['nombre'].toString(),
      destinoNombre: destino['nombre'].toString(),
      destinoFactor: (destino['factorPresentacion'] as num?)?.toDouble(),
      destinoSimbolo: destino['simbolo']?.toString(),
      rendimiento: (j['rendimiento'] as num?)?.toDouble() ?? 0,
      sedeId: widget.sedeId,
      stockBultos: (bulto['stock'] as num?)?.toInt() ?? 0,
      stockDestino: (destino['stock'] as num?)?.toInt() ?? 0,
    );
    if (r == null || !mounted) return;
    widget.onBultoAbierto?.call();
    Navigator.pop(context);
  }

  /// Resetea toda la selección (deselecciona cada atributo), la cantidad y
  /// QUITA del carrito lo ya agregado de este producto. Para empezar de cero
  /// cuando ninguna combinación encaja.
  void _limpiarSeleccion() {
    HapticFeedback.lightImpact();
    // Quitar del carrito cada variante de este producto que tenga unidades.
    if (widget.onQuitarUnidad != null) {
      _enCarrito.forEach((vid, qty) {
        if (qty <= 0) return;
        ProductoVariante? variante;
        for (final v in _variantes) {
          if (v.id == vid) {
            variante = v;
            break;
          }
        }
        if (variante != null) {
          for (var k = 0; k < qty; k++) {
            widget.onQuitarUnidad!(variante);
          }
        }
      });
    }
    setState(() {
      _enCarrito.clear();
      for (final g in _grupos) {
        _seleccion[g.clave] = null;
      }
      _cantidad = 0;
      // Sin nada elegido el acordeón vuelve a empezar por el primer grupo:
      // dejarlo fijado en "diseño" obligaría a subir para elegir el tamaño.
      _grupoExpandido = null;
    });
  }

  void _agregar() {
    final v = _varianteResuelta;
    if (v == null || _cantidad <= 0) return;
    HapticFeedback.mediumImpact();
    widget.onAgregar(v, _cantidad);
    Navigator.pop(context);
  }

  // ---- Precio resuelto ------------------------------------------------------

  ({double? precio, double? base, String? nivel}) _precioInfo() {
    final v = _varianteResuelta;
    if (v == null) return (precio: null, base: null, nivel: null);
    final base = v.precioEfectivoEnSede(widget.sedeId) ??
        v.precioEnSede(widget.sedeId);
    if (base == null) return (precio: null, base: null, nivel: null);
    // La liquidación GANA siempre: si la variante está en liquidación se
    // ignoran los niveles por mayor (aplicar un nivel "Por Mayor S/45" sobre
    // un remate de S/30 lo subiría, contradiciendo la liquidación). Coincide
    // con el guard de VentaDetalleInput.recalcularPrecioPorNiveles.
    final enLiquidacion = v.enLiquidacionEnSede(widget.sedeId);
    final niveles = enLiquidacion
        ? const <PrecioNivel>[]
        : (_niveles[v.id] ?? const <PrecioNivel>[]);
    final nivel = _cantidad > 0 && niveles.isNotEmpty
        ? VentaDetalleInput.nivelAplicableParaCantidad(niveles, _cantidad.toDouble())
        : null;
    if (nivel != null) {
      final precioNivel = nivel.calcularPrecioFinal(base);
      // Un nivel solo aplica si BAJA el precio (igual que el backend que toma
      // el menor). Nunca lo sube.
      if (precioNivel < base) {
        return (precio: precioNivel, base: base, nivel: nivel.nombre);
      }
    }
    return (precio: base, base: null, nivel: null);
  }

  // ---- UI -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final resuelta = _varianteResuelta;
    final precioInfo = _precioInfo();
    final imagen = resuelta?.thumbnailPrincipal;
    final puedeAgregar = resuelta != null && _cantidad > 0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // El teclado numérico tapaba el campo de kilos: el sheet tiene alto fijo
      // y el input vive en el footer, o sea en la parte que el teclado come.
      // Descontando el inset acá, el cuerpo —que ya es Flexible + scroll— se
      // achica y el input queda justo encima del teclado. Animado para que
      // acompañe la entrada del teclado en vez de saltar.
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
        // Altura fija: el cuerpo (Flexible) llena y el footer queda abajo.
        mainAxisSize: MainAxisSize.max,
        // stretch: los hijos ocupan todo el ancho → el cuerpo de atributos
        // alinea a la izquierda real (antes, con el default center, quedaba
        // centrado a su ancho intrínseco y parecía tener padding izquierdo).
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 30,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          _buildHeader(imagen, precioInfo, resuelta),
          const Divider(height: 1),
          // Cuerpo scrolleable: secciones de atributos
          Flexible(
            child: _variantes.isEmpty || _grupos.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(25),
                    child: Text(
                      'No hay variantes disponibles',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppSubtitle(
                              // font: AppFont.amazonEmberBold, 
                              'Elige la variante:',
                              fontSize: 12,
                            ),
                            InkWell(
                              onTap: _limpiarSeleccion,
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.refresh,
                                        size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 3),
                                    AppSubtitle(
                                      font: AppFont.amazonEmberMedium,
                                      'Limpiar',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ..._grupos.map(_buildGrupo),
                      ],
                    ),
                  ),
          ),
          const Divider(height: 1),
          _buildOfrecerAbrir(),
          _buildFooter(resuelta, puedeAgregar),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    String? imagen,
    ({double? precio, double? base, String? nivel}) precioInfo,
    ProductoVariante? resuelta,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
      child: Row(
        children: [
          GestureDetector(
            onLongPress: () => _verImagenCompleta(resuelta, imagen),
            child: imagen != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: imagen,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          width: 100, height: 100, color: Colors.grey.shade100),
                      errorWidget: (_, __, ___) => _placeholderImg(),
                    ),
                  )
                : _placeholderImg(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSubtitle(
                  widget.producto.nombre,
                  fontSize: 12,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_combinacionTexto.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  // La flechita cuelga la combinación del nombre del producto:
                  // deja claro de un vistazo que es una rama de lo de arriba y
                  // no otro dato suelto de la cabecera.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.subdirectory_arrow_right,
                        size: 14,
                        color: AppColors.blue1,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: AppSubtitle(
                          // font: AppFont.amazonEmberBold,
                          _combinacionTexto,
                          fontSize: 10,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          color: AppColors.blue1,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 2),
                if (precioInfo.precio != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppSubtitle(
                        font: AppFont.amazonEmberBold,
                        _precioTexto(precioInfo.precio!),
                        fontSize: 15,
                        color: precioInfo.nivel != null
                            ? AppColors.blue1
                            : Colors.grey.shade800,
                      ),
                      if (precioInfo.base != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          _precioTexto(precioInfo.base!),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  )
                else
                  AppSubtitle(
                    font: AppFont.amazonEmberMedium, 
                    'Selecciona una combinación',
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                if (resuelta != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 14,
                        color: _stockRestante > 0
                            ? Colors.green.shade600
                            : Colors.red.shade400,
                      ),
                      const SizedBox(width: 4),
                      AppSubtitle(
                        // font: AppFont.amazonEmberMedium,
                        _stockRestante > 0
                            ? 'Stock disponible: ${_stockTexto(_stockRestante)}'
                            : 'Sin stock',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _stockRestante > 0
                            ? Colors.green.shade700
                            : Colors.red,
                      ),
                    ],
                  ),
                ],
                if (resuelta != null) _buildBadges(resuelta),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 22),
            color: Colors.grey.shade500,
          ),
        ],
      ),
    );
  }

  Widget _buildBadges(ProductoVariante v) {
    final enLiq = v.enLiquidacionEnSede(widget.sedeId);
    final enOferta = v.enOfertaEnSede(widget.sedeId);
    if (!enLiq && !enOferta) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: enLiq ? Colors.deepOrange.shade700 : Colors.green.shade700,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          enLiq ? 'LIQUIDACIÓN' : 'OFERTA',
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildGrupo(_AtributoGrupo g) {
    final elegido = _seleccion[g.clave];
    // Solo se despliega uno a la vez. Los que faltan elegir se ven como
    // "Elegir…": tras tocar Limpiar quedan los cinco sin valor, y sin esto se
    // dibujarían los cinco `Wrap` juntos, que es exactamente el muro de chips
    // que el acordeón viene a sacar.
    if (g.clave != _claveExpandida) {
      return _buildGrupoColapsado(g, elegido);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppSubtitle(
                g.nombre.toUpperCase(),
                fontSize: 10,
                color: Colors.grey.shade700,
              ),
              AppSubtitle(
                '${_valoresConStock(g)} con stock',
                fontSize: 9,
                color: Colors.grey.shade500,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: g.valores.map((valor) {
              final disponible = _valorDisponible(g.clave, valor);
              final seleccionado = _seleccion[g.clave] == valor;
              return _AtributoValorChip(
                label: valor,
                selected: seleccionado,
                enabled: disponible || seleccionado,
                stock: _stockSiCompleta(g.clave, valor),
                onTap: () => _seleccionar(g.clave, valor),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Grupo cerrado: un renglón con el valor elegido y un lápiz para reabrirlo,
  /// o "Elegir…" si todavía no tiene valor. Es lo que evita que 5 atributos
  /// empujen el botón de agregar fuera de la pantalla.
  Widget _buildGrupoColapsado(_AtributoGrupo g, String? elegido) {
    final resuelto = elegido != null;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _grupoExpandido = g.clave);
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(
              resuelto ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 14,
              color: resuelto ? AppColors.blue1 : Colors.grey.shade400,
            ),
            const SizedBox(width: 7),
            SizedBox(
              width: 78,
              child: AppSubtitle(
                g.nombre.toUpperCase(),
                fontSize: 9,
                color: Colors.grey.shade500,
              ),
            ),
            Expanded(
              child: AppSubtitle(
                font: AppFont.amazonEmberMedium,
                elegido ?? 'Elegir…',
                fontSize: 11,
                fontWeight: resuelto ? FontWeight.w700 : FontWeight.w500,
                color: resuelto ? Colors.grey.shade900 : Colors.grey.shade500,
              ),
            ),
            Icon(
              resuelto ? Icons.edit_outlined : Icons.chevron_right,
              size: resuelto ? 13 : 16,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  /// Campo decimal en la unidad de cobro, con el equivalente atómico debajo:
  /// que se vea "= 1500 g" es lo que evita cargar 1.5 creyendo que son gramos.
  Widget _buildInputGranel(bool puedeAgregar) {
    final p = _presentacion!;
    final restante = _stockRestante;
    return SizedBox(
      width: 132,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            controller: _cantidadGranelCtrl,
            focusNode: _granelFocus,
            enabled: puedeAgregar || restante > 0,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,3}')),
            ],
            suffixText: p.simbolo,
            borderColor: AppColors.blue1,
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            onChanged: _cantidadDesdeTexto,
          ),
          const SizedBox(height: 2),
          Text(
            _cantidad > 0
                ? '= $_cantidad ${_varianteResuelta?.unidadMedida?.displayCorto ?? ''}'
                : 'Disponible ${p.cantidadTexto(restante)}',
            style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  /// "Faltan 3 kg — hay 4 SACO 15KG sin abrir". Avisa y OFRECE; no bloquea la
  /// venta ni abre por su cuenta, que es lo que se decidió con el user: si el
  /// cajero no puede registrarlo pero igual rompe el saco, el sistema miente.
  Widget _buildOfrecerAbrir() {
    final j = _bultoParaReponer;
    if (j == null || !_esGranel) return const SizedBox.shrink();
    final bulto = j['bulto'] as Map<String, dynamic>;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2, size: 16, color: Colors.amber.shade800),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'No alcanza el suelto, pero hay ${bulto['stock']} '
              '${bulto['nombre']} sin abrir.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.amber.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _abrirDesdeVenta,
            child: const Text('Abrir', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ProductoVariante? resuelta, bool puedeAgregar) {
    final sinStock = resuelta != null && _stockRestante <= 0;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Row(
        children: [
          // A granel se teclea la cantidad en la unidad de cobro (kg); por
          // unidad, el stepper de siempre.
          if (_esGranel)
            _buildInputGranel(puedeAgregar)
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _stepBtn(
                    Icons.remove,
                    onTap: puedeAgregar && _cantidad > 1
                        ? () => _cambiarCantidad(-1)
                        : null,
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 36),
                    alignment: Alignment.center,
                    child: Text(
                      '$_cantidad',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _stepBtn(
                    Icons.add,
                    onTap: puedeAgregar && _cantidad < _stockRestante
                        ? () => _cambiarCantidad(1)
                        : null,
                  ),
                ],
              ),
            ),
          const SizedBox(width: 12),
          // Botón agregar (design system)
          Expanded(
            child: CustomButton(
              text: sinStock
                  ? 'Sin stock'
                  : resuelta == null
                      ? 'Elige una combinación'
                      : 'Agregar al carrito',
              onPressed: _agregar,
              enabled: puedeAgregar,
              backgroundColor: AppColors.blue1,
              icon: Icon(
                Icons.add_shopping_cart,
                size: 16,
                color: puedeAgregar ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, {VoidCallback? onTap}) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.blue1 : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _placeholderImg() => Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.blue1.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.style,
            size: 40, color: AppColors.blue1.withValues(alpha: 0.5)),
      );

  void _verImagenCompleta(ProductoVariante? v, String? thumb) {
    final fullUrl = v?.imagenPrincipal ?? thumb;
    if (fullUrl == null) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (_, __, ___) => Scaffold(
          backgroundColor: Colors.black87,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              v?.nombre ?? widget.producto.nombre,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          body: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: fullUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: Colors.white)),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image,
                    size: 48, color: Colors.white54),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip tipo radio para un valor de atributo (mimetiza el patrón de la imagen:
/// círculo radio + label, acento al seleccionar, atenuado si no disponible).
class _AtributoValorChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;

  /// Unidades de la variante que queda al elegir este valor. Solo viene con
  /// número cuando elegirlo COMPLETA la combinación; si no, `null` y no se
  /// dibuja, para no prometer un stock que es la suma de varias variantes.
  final int? stock;
  final VoidCallback onTap;

  const _AtributoValorChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.stock,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.blue1
        : (enabled ? Colors.grey.shade300 : Colors.grey.shade200);
    final textColor = selected
        ? AppColors.blue1
        : (enabled ? Colors.grey.shade800 : Colors.grey.shade400);

    return Opacity(
      opacity: enabled ? 1.0 : 0.6,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.blue1.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: borderColor,
              width: selected ? 1 : 0.6,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _radio(),
              const SizedBox(width: 6),
              AppSubtitle(
                font: AppFont.amazonEmberMedium,
                label,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
                decoration: enabled ? null : TextDecoration.lineThrough,
              ),
              if (stock != null && stock! > 0) ...[
                const SizedBox(width: 5),
                AppSubtitle(
                  '$stock',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.blue1 : Colors.grey.shade500,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _radio() {
    final color = selected
        ? AppColors.blue1
        : (enabled ? Colors.grey.shade400 : Colors.grey.shade300);
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.blue1,
                ),
              ),
            )
          : null,
    );
  }
}
