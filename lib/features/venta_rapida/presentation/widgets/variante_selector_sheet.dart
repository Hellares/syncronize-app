import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/busqueda_texto.dart';
import '../../../../core/utils/unidad_presentacion.dart';
import '../../../producto/presentation/widgets/abrir_bulto_dialog.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_search_field.dart';
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

/// Valor sintético para "esta variante NO declara ese atributo".
///
/// Se muestra como "Sin {atributo} asignado" y es elegible: así una variante a
/// la que le falta un dato que sus hermanas sí tienen sigue siendo alcanzable,
/// y de paso se ve cuáles del catálogo quedaron incompletas.
const String _kSinAsignar = '__sin_asignar__';

/// Ancho reservado a la derecha del header para la X y el precio, que flotan
/// sobre el contenido. Las líneas que quedan a esa altura lo descuentan.
const double _anchoFranjaDerecha = 78;

class _VarianteSelectorSheetState extends State<_VarianteSelectorSheet> {
  late final List<ProductoVariante> _variantes;
  late final List<_AtributoGrupo> _grupos;

  /// Valor elegido por clave de atributo (null = sin elegir).
  final Map<String, String?> _seleccion = {};

  /// Última combinación agregada, ya formateada. Como el sheet ya no se cierra
  /// al agregar, sin esto no habría ninguna señal de que la acción ocurrió.
  String? _ultimoAgregado;

  /// Texto del buscador de combinaciones. Un mismo diseño vive en varios
  /// bloques a precios distintos —MICKEY está en 4, entre S/50 y S/84— y por
  /// el acordeón habría que recorrerlos a ciegas para descubrirlo. Buscando
  /// se ven los cuatro juntos, con su stock y su precio.
  final _buscarCtrl = TextEditingController();
  String _query = '';

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
    _seleccionInicialLimpia();
    // Cargar (fresco) los niveles de la variante inicial. Con el sheet limpio
    // no hay ninguna resuelta todavía y esto corta solo; los niveles se piden
    // al completar la combinación.
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
    // 🔴 Si ALGUNAS variantes no declaran el atributo, esa ausencia entra como
    // un valor más: "Sin tamaño de pantalla asignado".
    //
    // Antes esas variantes quedaban inalcanzables —había que elegir un valor
    // del grupo y ninguno les correspondía, así que el sheet decía "sin stock
    // en esta combinación" con el stock ahí—. Y tratar la falta como comodín
    // era peor: dejaba vender "AZUL + 860" contra una variante sin procesador.
    //
    // Nombrarla la vuelve elegible y explica el catálogo: se ve cuáles todavía
    // no tienen ese dato cargado.
    for (final clave in orden) {
      final faltaEnAlguna = variantes.any(
        (v) => !v.atributosValores.any((a) => a.atributo.clave == clave),
      );
      if (faltaEnAlguna) {
        valores[clave]!.add(_kSinAsignar);
      }
    }

    return orden
        .map((c) => _AtributoGrupo(c, nombre[c] ?? c, valores[c]!))
        .toList();
  }

  /// Etiqueta visible de un valor. Solo el centinela necesita traducción.
  String _etiquetaValor(_AtributoGrupo g, String valor) =>
      valor == _kSinAsignar
          ? 'Sin ${g.nombre.toLowerCase()} asignado'
          : valor;

  /// El sheet abre LIMPIO: sin ninguna opción marcada.
  ///
  /// Antes preseleccionaba la primera variante con stock. Con pocos atributos
  /// eso ahorraba taps, pero con cinco (tamaño, temporada, piezas, género,
  /// diseño) proponía una combinación concreta —un diseño puntual entre 37— que
  /// casi nunca es la que el cliente pide, y encima disimulaba el trabajo que
  /// falta: parecía listo para agregar cuando en realidad había que revisar los
  /// cinco grupos. Arrancar vacío hace explícito lo que falta elegir y, con el
  /// acordeón, abre directo en el primer grupo.
  ///
  /// La única excepción es un grupo con UN solo valor posible: ahí no hay nada
  /// que decidir y pedir el tap sería fricción pura.
  void _seleccionInicialLimpia() {
    for (final g in _grupos) {
      _seleccion[g.clave] = g.valores.length == 1 ? g.valores.first : null;
    }
    // Sin combinación resuelta no hay stock que ofrecer; la cantidad la fija
    // el primer `_seleccionar` que complete los cinco grupos.
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
    _buscarCtrl.dispose();
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
  ///
  /// ESTRICTO a propósito: si la variante no declara un atributo que [sel]
  /// exige, NO coincide. Tratarlo como comodín dejaba elegir "AZUL + 860" y
  /// devolvía el stock del azul, que no tiene procesador — peor que el bug
  /// original, porque miente sobre lo que se está vendiendo.
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
      if (valor == _kSinAsignar) {
        // Se pidió "sin asignar": coinciden justamente las que NO lo declaran.
        if (match.isNotEmpty) return false;
        continue;
      }
      if (match.isEmpty || match.first != valor) return false;
    }
    return true;
  }

  /// Las variantes que siguen en carrera con lo elegido hasta ahora.
  List<ProductoVariante> get _candidatas =>
      _variantes.where((v) => _coincide(v, _seleccion)).toList();

  /// ¿Hay que elegir algo en este grupo, con lo que ya está elegido?
  ///
  /// 🔴 Acá está la corrección del gotcha. Un atributo que solo tienen ALGUNAS
  /// variantes no puede ser obligatorio para todas: si a una sola le agregás
  /// PROCESADOR, el grupo aparece en el acordeón y sus hermanas quedaban
  /// inalcanzables —"sin stock en esa combinación" con el stock ahí—.
  ///
  /// El grupo aplica solo si ALGUNA de las candidatas actuales declara ese
  /// atributo. Elegido COLOR = AZUL, si ninguna candidata tiene procesador el
  /// grupo deja de pedirse y la variante se resuelve sola.
  bool _grupoAplica(_AtributoGrupo g) {
    if (g.clave == _kVarianteClave) return true;
    return _candidatas.any(
      (v) => v.atributosValores.any((a) => a.atributo.clave == g.clave),
    );
  }

  /// Variante resuelta cuando ya se eligió todo lo que hacía falta elegir.
  ProductoVariante? get _varianteResuelta {
    final pendientes = _grupos
        .where(_grupoAplica)
        .where((g) => _seleccion[g.clave] == null);
    if (pendientes.isNotEmpty) return null;

    final candidatas = _candidatas;
    if (candidatas.isEmpty) return null;
    // Con varias en carrera gana la más específica: la que declara más
    // atributos es la que mejor describe lo elegido.
    candidatas.sort((a, b) =>
        b.atributosValores.length.compareTo(a.atributosValores.length));
    return candidatas.first;
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
  /// sin elegir —que al abrir es el primero de todos, porque el sheet arranca
  /// limpio ([_seleccionInicialLimpia])—; y si ya está todo elegido, el último,
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

  /// Valores de la variante en el orden en que se ven los grupos.
  List<String> _valoresDe(ProductoVariante v) {
    final out = <String>[];
    for (final g in _grupos) {
      if (g.clave == _kVarianteClave) {
        out.add(v.nombre);
        continue;
      }
      for (final av in v.atributosValores) {
        if (av.atributo.clave == g.clave) {
          out.add(av.valor);
          break;
        }
      }
    }
    return out;
  }

  /// Combinaciones que matchean el buscador, **solo las que tienen stock**:
  /// una tarjeta con 0 unidades no se puede vender y es ruido. Ordenadas por
  /// stock para que lo que más hay quede arriba.
  ///
  /// Se busca sobre el nombre de la variante MÁS sus valores de atributo, con
  /// el mismo criterio que el buscador de productos (sin tildes, por palabras
  /// y exigiéndolas todas), así "mickey invierno" filtra de una.
  List<ProductoVariante> get _resultadosBusqueda {
    final terminos = terminosBusqueda(_query);
    if (terminos.isEmpty) return const [];
    final out = <ProductoVariante>[];
    for (final v in _variantes) {
      if (_stockDisponible(v) <= 0) continue;
      final texto = '${v.nombre} ${_valoresDe(v).join(' ')}';
      if (coincideTodosLosTerminos(texto, terminos)) out.add(v);
    }
    out.sort((a, b) => _stockDisponible(b).compareTo(_stockDisponible(a)));
    return out;
  }

  /// Elegir una combinación desde el buscador: deja el acordeón como si la
  /// hubieras armado a mano, así el pie, los niveles de precio y el input de
  /// granel siguen exactamente el mismo camino que la selección normal.
  void _elegirVariante(ProductoVariante v) {
    HapticFeedback.selectionClick();
    setState(() {
      _ultimoAgregado = null;
      if (_grupos.length == 1 && _grupos.first.clave == _kVarianteClave) {
        _seleccion[_kVarianteClave] = v.nombre;
      } else {
        for (final g in _grupos) {
          _seleccion[g.clave] = null;
        }
        for (final av in v.atributosValores) {
          _seleccion[av.atributo.clave] = av.valor;
        }
      }
      _grupoExpandido = _grupos.isEmpty ? null : _grupos.last.clave;
      _buscarCtrl.clear();
      _query = '';
      final rest = _stockRestante;
      if (_esGranel) {
        _cantidadGranelCtrl.clear();
        _cantidad = 0;
        _enfocarGranel();
      } else {
        _cantidad = rest > 0 ? 1 : 0;
      }
    });
    _cargarNivelesResuelta();
  }

  /// Stock que quedaría al elegir `valor`, **solo para lo que se vende por
  /// peso** y solo si con eso la combinación queda completa.
  ///
  /// 🔑 En lo que se vende por unidad el número se quitó: iba pegado a la
  /// etiqueta, competía con ella —en una larga como "Sin tamaño de pantalla
  /// asignado" se leía como parte del texto— y la cabecera ya muestra el stock
  /// de la combinación resuelta.
  ///
  /// En granel sí se queda: "125 kg" al lado del sabor dice de un vistazo
  /// cuánto queda de ESE, que es lo que se pregunta en mostrador, y al ser
  /// texto con unidad no se confunde con la etiqueta.
  ///
  /// Si todavía faltan atributos devuelve null: el número sería la suma de
  /// varias variantes y prometería un stock que esa combinación no tiene.
  String? _stockSiCompleta(String clave, String valor) {
    final tentativa = <String, String?>{};
    for (final g in _grupos) {
      tentativa[g.clave] = g.clave == clave ? valor : _seleccion[g.clave];
    }
    for (final v in tentativa.values) {
      if (v == null) return null;
    }
    for (final v in _variantes) {
      if (_coincide(v, tentativa)) {
        final s = _stockDisponible(v);
        if (s <= 0) return null;
        final p = _presentacionDe(v);
        // Sin presentación es venta por unidad: ahí no se muestra.
        return p?.cantidadTexto(s);
      }
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
      if (valor == null || valor.isEmpty) continue;
      // El centinela no suma nada al resumen: "AZUL · sin tamaño de pantalla
      // asignado" es ruido justo donde hace falta leer rápido qué se agrega.
      if (valor == _kSinAsignar) continue;
      partes.add(valor);
    }
    return partes.join(' · ');
  }

  void _seleccionar(String clave, String valor) {
    HapticFeedback.selectionClick();
    setState(() {
      // Empezó a armar otra combinación: la confirmación de la anterior ya
      // no corresponde a lo que se ve en pantalla.
      _ultimoAgregado = null;
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
    return v == null ? null : _presentacionDe(v);
  }

  /// Presentación de UNA variante cualquiera, no solo la resuelta. La necesitan
  /// el buscador y los chips, que muestran datos de variantes que todavía no se
  /// eligieron: sin esto un granel se ve "125000" y "S/0.01" —gramos y precio
  /// por gramo— en vez de "125 kg" y "S/10.00/kg".
  UnidadPresentacion? _presentacionDe(ProductoVariante v) {
    final pres = widget.producto.presentacionDeVariante(v);
    return pres.activa ? pres : null;
  }

  /// Stock de `v` en su unidad de cobro: "125 kg" o "7 unidades".
  String _stockTextoDe(ProductoVariante v, int enUnidadDeVenta) {
    final p = _presentacionDe(v);
    if (p != null) return p.cantidadTexto(enUnidadDeVenta);
    return '$enUnidadDeVenta ${enUnidadDeVenta == 1 ? 'unidad' : 'unidades'}';
  }

  /// Precio de `v` en su unidad de cobro: "S/ 10.00/kg" o "S/ 75.00".
  String _precioTextoDe(ProductoVariante v, double porUnidadDeVenta) {
    final p = _presentacionDe(v);
    if (p != null) return p.precioTexto(porUnidadDeVenta);
    return 'S/ ${porUnidadDeVenta.toStringAsFixed(2)}';
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
      // Se vació el carrito de este producto: la confirmación de lo agregado
      // pasaría a mentir.
      _ultimoAgregado = null;
      // Mismo estado que al abrir, para que "Limpiar" y reabrir el sheet se
      // vean igual: vacío, salvo los grupos de un solo valor.
      _seleccionInicialLimpia();
      _cantidad = 0;
      // Sin nada elegido el acordeón vuelve a empezar por el primer grupo:
      // dejarlo fijado en "diseño" obligaría a subir para elegir el tamaño.
      _grupoExpandido = null;
    });
  }

  /// Agrega al carrito y **deja el sheet abierto**.
  ///
  /// Con 76 combinaciones el caso normal es llevarse varias: cerrar en cada
  /// agregado obligaba a reabrir el sheet y volver a buscar desde cero. Ahora
  /// se cierra solo con la X o tocando afuera.
  void _agregar() {
    final v = _varianteResuelta;
    if (v == null || _cantidad <= 0) return;
    HapticFeedback.mediumImpact();
    // El resumen se arma ANTES de limpiar: `_stockTexto` y
    // `_combinacionTexto` dependen de la variante resuelta.
    final resumen = '${_stockTexto(_cantidad)} · $_combinacionTexto';
    widget.onAgregar(v, _cantidad);
    setState(() {
      // Descontar lo agregado del disponible DEL SHEET. Sin esto se podría
      // agregar dos veces la misma unidad, porque `_stockDisponible` resta
      // `_enCarrito` y el sheet ya no se recrea entre agregados.
      _enCarrito[v.id] = (_enCarrito[v.id] ?? 0) + _cantidad;
      _ultimoAgregado = resumen;
      _cantidadGranelCtrl.clear();
      _buscarCtrl.clear();
      _query = '';
      _grupoExpandido = null;
      _seleccionInicialLimpia();
    });
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
        // `expand` para que la Column siga recibiendo restricciones AJUSTADAS
        // como antes: con el `fit` suelto por defecto, su
        // `crossAxisAlignment: stretch` pasaría a medirse contra el hijo más
        // ancho en vez de contra el ancho del sheet.
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
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
                            _buildResultados(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppSubtitle(
                                  // Con resultados a la vista, el divisor
                                  // "o elegí por atributo" ya hace de título.
                                  _hayResultados ? '' : 'Elige la variante:',
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
              _buildUltimoAgregado(),
              _buildOfrecerAbrir(),
              _buildFooter(resuelta, puedeAgregar),
              ],
            ),
            // Flotando sobre el contenido, en la esquina: dentro de la Row del
            // header le comía ancho a la columna del nombre y el precio, que es
            // justo donde entró el buscador.
            Positioned(
              top: 2,
              right: 2,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 22),
                color: Colors.grey.shade500,
                // Área táctil de 48; el ícono es de 22 y sin esto el botón
                // quedaría más chico que el mínimo tocable.
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                tooltip: 'Cerrar',
              ),
            ),
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
      // Antes el margen derecho era 8 para dejar lugar al IconButton de la
      // Row; ahora que flota, el header cierra simétrico.
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Stack(
        children: [
          // El precio flota a la derecha, en la franja que queda entre la X
          // (arriba) y el buscador (abajo). `top: 32` lo deja debajo del
          // nombre —dos líneas de 12— y bien por encima del buscador, que es
          // el último hijo de la columna. Se posiciona a mano y no centrado
          // en el header porque centrarlo lo pondría justo sobre el buscador
          // cuando la columna es corta.
          if (precioInfo.precio != null)
            Positioned(
              top: 25,
              right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSubtitle(
                    font: AppFont.amazonEmberBold,
                    _precioTexto(precioInfo.precio!),
                    fontSize: 15,
                    color: precioInfo.nivel != null
                        ? AppColors.blue1
                        : Colors.grey.shade800,
                  ),
                  if (precioInfo.base != null)
                    Text(
                      _precioTexto(precioInfo.base!),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
            ),
          Row(
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
                // La franja derecha está ocupada: arriba por la X flotante y
                // más abajo por el precio. Las tres líneas que quedan a esa
                // altura la esquivan; el buscador, que va último, usa el ancho
                // completo.
                Padding(
                  padding: const EdgeInsets.only(right: _anchoFranjaDerecha),
                  child: AppSubtitle(
                    widget.producto.nombre,
                    fontSize: 12,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_combinacionTexto.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  // La flechita cuelga la combinación del nombre del producto:
                  // deja claro de un vistazo que es una rama de lo de arriba y
                  // no otro dato suelto de la cabecera.
                  Padding(
                    padding:
                        const EdgeInsets.only(right: _anchoFranjaDerecha),
                    child: Row(
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
                  ),
                ],
                const SizedBox(height: 2),
                // El precio ya no va acá: flota a la derecha. Queda solo el
                // texto de "todavía no elegiste", que aparece justamente
                // cuando NO hay precio, así que nunca se pisan.
                if (precioInfo.precio == null)
                  AppSubtitle(
                    'Selecciona una combinación',
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                if (resuelta != null) ...[
                  const SizedBox(height: 3),
                  Padding(
                    padding:
                        const EdgeInsets.only(right: _anchoFranjaDerecha),
                    child: Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 14,
                          color: _stockRestante > 0
                              ? Colors.green.shade600
                              : Colors.red.shade400,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: AppSubtitle(
                            _stockRestante > 0
                                ? 'Stock disponible: ${_stockTexto(_stockRestante)}'
                                : 'Sin stock',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            color: _stockRestante > 0
                                ? Colors.green.shade700
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (resuelta != null) _buildBadges(resuelta),
                // El buscador va acá, pegado al stock: es lo primero que se
                // mira al abrir el sheet. Los RESULTADOS quedan en el cuerpo
                // porque el header es fijo y una lista tiene que poder
                // scrollear.
                _buildBuscador(),
              ],
            ),
          ),
            ],
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
    // Los valores sin stock NO se dibujan. Tachados ocupaban lo mismo que uno
    // disponible, y con 45 diseños eso es una pared de opciones que no se
    // pueden elegir. El único que sobrevive sin stock es el YA ELEGIDO: si se
    // ocultara, la selección desaparecería de la pantalla sin explicación.
    final visibles = <String>[];
    for (final valor in g.valores) {
      if (_valorDisponible(g.clave, valor) || _seleccion[g.clave] == valor) {
        visibles.add(valor);
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSubtitle(
            g.nombre.toUpperCase(),
            fontSize: 10,
            color: Colors.grey.shade700,
          ),
          const SizedBox(height: 4),
          if (visibles.isEmpty)
            AppSubtitle(
              'Sin stock en esta combinación',
              fontSize: 11,
              color: Colors.grey.shade500,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: visibles.map((valor) {
                final seleccionado = _seleccion[g.clave] == valor;
                return _AtributoValorChip(
                  label: _etiquetaValor(g, valor),
                  selected: seleccionado,
                  // Solo puede venir en false el elegido que se quedó sin
                  // stock; el resto se filtró arriba.
                  enabled: _valorDisponible(g.clave, valor) || seleccionado,
                  // Nunca en el centinela: su etiqueta ya es una frase larga.
                  stock: valor == _kSinAsignar
                      ? null
                      : _stockSiCompleta(g.clave, valor),
                  onTap: () => _seleccionar(g.clave, valor),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  /// Cuántas combinaciones DE ESTE PRODUCTO ya están en el carrito. Se cuentan
  /// combinaciones y no unidades a propósito: en un producto con granel las
  /// cantidades están en unidad atómica y sumar 5000 gramos con 2 sacos daría
  /// un número sin significado.
  int get _combinacionesEnCarrito {
    var n = 0;
    for (final v in _variantes) {
      if ((_enCarrito[v.id] ?? 0) > 0) n++;
    }
    return n;
  }

  /// Confirmación de lo último agregado. Reemplaza a la señal que antes daba
  /// el cierre del sheet.
  Widget _buildUltimoAgregado() {
    final txt = _ultimoAgregado;
    if (txt == null) return const SizedBox.shrink();
    final n = _combinacionesEnCarrito;
    return Container(
      width: double.infinity,
      color: Colors.green.shade50,
      padding: const EdgeInsets.fromLTRB(16, 7, 16, 7),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 15, color: Colors.green.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: AppSubtitle(
              txt,
              fontSize: 11,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              color: Colors.green.shade900,
            ),
          ),
          const SizedBox(width: 8),
          AppSubtitle(
            n == 1 ? '1 en el carrito' : '$n en el carrito',
            fontSize: 10,
            color: Colors.green.shade700,
          ),
        ],
      ),
    );
  }

  /// Hay tarjetas de resultado en pantalla.
  bool get _hayResultados =>
      _query.trim().length >= 2 && _resultadosBusqueda.isNotEmpty;

  /// Buscador de combinaciones. Aparece desde DOS variantes.
  ///
  /// Antes el umbral eran seis, con la idea de que con dos o tres el acordeón
  /// ya se ve entero y el campo sería estorbo. En el mostrador resultó al
  /// revés (decisión del user, 14-08): el campo no quita alto real y tipear
  /// es más rápido que abrir el acordeón y recorrerlo, aunque haya pocas.
  ///
  /// Vive en el header, al lado de la imagen, así que el ancho disponible es
  /// el del producto menos 100 px de foto: va compacto y con hint corto.
  Widget _buildBuscador() {
    // Con una sola variante no hay nada entre qué elegir.
    if (_variantes.length < 2) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: CustomSearchField(
        controller: _buscarCtrl,
        hintText: 'Buscar diseño…',
        // borderColor: AppColors.blue1,
        // Sin debounce, igual que el buscador de productos: acá se filtran
        // las variantes que el sheet ya tiene en memoria, así que esperar
        // 500 ms solo agregaría lag.
        debounceDelay: Duration.zero,
        // Plano: va dentro del header, que ya es una zona densa; la sombra
        // neumórfica lo despegaría del bloque de la foto y el precio.
        showShadow: false,
        // El botón de limpiar lo pone el widget y al tocarlo dispara
        // `onChanged('')`, así que no hace falta manejarlo aparte.
        onChanged: (v) => setState(() => _query = v),
      ),
    );
  }

  /// Resultados del buscador: una tarjeta por combinación CON stock, con su
  /// precio y sus unidades. Tocarla la elige y el acordeón queda armado.
  Widget _buildResultados() {
    if (_query.trim().length < 2) return const SizedBox.shrink();
    final res = _resultadosBusqueda;
    if (res.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: AppSubtitle(
          'Sin combinaciones con stock para "${_query.trim()}"',
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      );
    }
    final unidades = res.fold<int>(0, (s, v) => s + _stockDisponible(v));
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSubtitle(
            '${res.length} ${res.length == 1 ? 'combinación' : 'combinaciones'} · $unidades ${unidades == 1 ? 'unidad' : 'unidades'}',
            fontSize: 10,
            color: Colors.grey.shade700,
          ),
          const SizedBox(height: 6),
          ...res.map(_buildResultado),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: AppSubtitle(
                  'o elegí por atributo',
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultado(ProductoVariante v) {
    final valores = _valoresDe(v);
    // El último grupo es el más granular (el diseño): va como título, y el
    // resto abajo. No se nombra ningún atributo a mano para que sirva igual
    // en un producto con otros atributos.
    final titulo = valores.isEmpty ? v.nombre : valores.last;
    final resto = valores.length > 1
        ? valores.sublist(0, valores.length - 1).join(' · ')
        : '';
    final stock = _stockDisponible(v);
    final precio =
        v.precioEfectivoEnSede(widget.sedeId) ?? v.precioEnSede(widget.sedeId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => _elegirVariante(v),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 10, 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300, width: 0.6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSubtitle(
                      font: AppFont.amazonEmberMedium,
                      titulo,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade900,
                    ),
                    if (resto.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      AppSubtitle(
                        resto,
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (precio != null)
                    AppSubtitle(
                      font: AppFont.amazonEmberMedium,
                      // Por VARIANTE, no por la resuelta: la tarjeta muestra
                      // una que todavía no se eligió.
                      _precioTextoDe(v, precio),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue1,
                    ),
                  const SizedBox(height: 2),
                  AppSubtitle(
                    _stockTextoDe(v, stock),
                    fontSize: 9,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Icon(Icons.add_circle_outline,
                  size: 16, color: AppColors.blue1),
            ],
          ),
        ),
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
                fontWeight: resuelto ? FontWeight.w600 : FontWeight.w500,
                color: resuelto ? AppColors.blue3 : Colors.grey.shade500,
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

  /// Stock formateado CON su unidad ("125 kg"), y solo en lo que se vende por
  /// peso. En venta por unidad viene null: el número pelado competía con la
  /// etiqueta y el stock ya se ve en la cabecera.
  final String? stock;
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
          padding: const EdgeInsets.fromLTRB(4, 4, 6, 4),
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
              const SizedBox(width: 10),
              AppSubtitle(
                font: AppFont.amazonEmberMedium,
                label,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
                decoration: enabled ? null : TextDecoration.lineThrough,
              ),
              // Solo llega con valor en lo que se vende por peso; el filtro de
              // "hay stock" ya lo hizo quien lo arma.
              if (stock != null) ...[
                const SizedBox(width: 5),
                AppSubtitle(
                  stock!,
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
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.2),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 6,
                height: 6,
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
