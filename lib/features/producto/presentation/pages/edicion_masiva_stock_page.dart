import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_search_field.dart';
import '../../../../core/widgets/custom_sede_selector.dart';
import '../../../../core/utils/unidad_presentacion.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/bulk_editar_stock_precios.dart';
import '../../domain/entities/producto_variante.dart';
import '../../domain/entities/stock_por_sede_info.dart';
import '../widgets/filtro_variantes.dart';
import '../bloc/edicion_masiva_stock/edicion_masiva_stock_cubit.dart';
import '../bloc/edicion_masiva_stock/edicion_masiva_stock_state.dart';

/// Grilla tipo excel para editar stock y precios de todas las variantes
/// de un producto en una sede, en bloque. Cada ajuste de stock genera
/// movimiento de kardex y cada cambio de precio queda en el historial.
///
/// Todo lo que se ve y se escribe está en la unidad en la que se habla: un
/// granel guardado en gramos se lee y se edita en KILOS. Sin eso la pantalla
/// era inservible justo para esos productos — mostraba "15000" y "0.01" (un
/// precio redondeado que no existe) y el campo, de 2 decimales, no dejaba
/// escribir 0.015. La conversión pasa solo en los bordes: al pintar y al
/// guardar.
///
/// El margen va debajo del nombre y no como columna: en un teléfono no entra
/// una sexta columna sin dejar el nombre de la variante en dos letras.
class EdicionMasivaStockPage extends StatelessWidget {
  final String productoId;
  final String productoNombre;
  final String? sedeIdInicial;

  const EdicionMasivaStockPage({
    super.key,
    required this.productoId,
    required this.productoNombre,
    this.sedeIdInicial,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<EdicionMasivaStockCubit>(),
      child: _EdicionMasivaView(
        productoId: productoId,
        productoNombre: productoNombre,
        sedeIdInicial: sedeIdInicial,
      ),
    );
  }
}

class _EdicionMasivaView extends StatefulWidget {
  final String productoId;
  final String productoNombre;
  final String? sedeIdInicial;

  const _EdicionMasivaView({
    required this.productoId,
    required this.productoNombre,
    this.sedeIdInicial,
  });

  @override
  State<_EdicionMasivaView> createState() => _EdicionMasivaViewState();
}

/// Qué tiene de malo el precio por mayor tecleado en una fila.
///
/// [bajoCosto] es el que motivó todo esto: un precio por mayor plano aplicado
/// a variantes de costos distintos deja vendiendo bajo costo justo a las caras,
/// y no se nota porque en las baratas el nivel ni siquiera llega a aplicar.
enum _ProblemaMayor {
  bajoCosto,
  noBaja,
  incompleto,
  cantidadInvalida;

  /// Los que impiden guardar. `noBaja` no bloquea: el nivel es inofensivo
  /// (gana el menor), solo inútil, y puede ser intencional mientras se ajustan
  /// los precios de lista.
  bool get bloquea => this != _ProblemaMayor.noBaja;

  String get mensaje => switch (this) {
        _ProblemaMayor.bajoCosto => 'El precio por mayor está bajo el costo',
        _ProblemaMayor.noBaja =>
          'El precio por mayor no baja del precio de lista: no se aplicaría',
        _ProblemaMayor.incompleto =>
          'Faltan la cantidad mínima o el precio por mayor',
        _ProblemaMayor.cantidadInvalida =>
          'La cantidad mínima del precio por mayor debe ser al menos 2',
      };
}

/// Controllers de una fila de la grilla (una variante).
class _FilaEdicion {
  final stock = TextEditingController();
  final precio = TextEditingController();
  final costo = TextEditingController();

  /// Cantidad desde la que aplica el precio por mayor, y ese precio.
  /// El nivel es GLOBAL a la variante (no por sede) — ver el aviso de la barra.
  final mayorDesde = TextEditingController();
  final mayorPrecio = TextEditingController();

  /// Un foco por celda editable. Sirve para pintar la celda tocada y, sobre
  /// todo, la FILA entera: con la columna de nombre congelada, resaltar el
  /// renglón es lo que dice sobre qué variante se está escribiendo cuando la
  /// grilla está corrida a la derecha.
  final fStock = FocusNode();
  final fPrecio = FocusNode();
  final fCosto = FocusNode();
  final fMayorDesde = FocusNode();
  final fMayorPrecio = FocusNode();

  List<FocusNode> get focos =>
      [fStock, fPrecio, fCosto, fMayorDesde, fMayorPrecio];

  bool get estaEnfocada => focos.any((f) => f.hasFocus);

  bool get tieneCambios =>
      stock.text.trim().isNotEmpty ||
      precio.text.trim().isNotEmpty ||
      costo.text.trim().isNotEmpty ||
      mayorDesde.text.trim().isNotEmpty ||
      mayorPrecio.text.trim().isNotEmpty;

  void limpiar() {
    stock.clear();
    precio.clear();
    costo.clear();
    mayorDesde.clear();
    mayorPrecio.clear();
  }

  void dispose() {
    stock.dispose();
    precio.dispose();
    costo.dispose();
    mayorDesde.dispose();
    mayorPrecio.dispose();
    for (final f in focos) {
      f.dispose();
    }
  }
}

class _EdicionMasivaViewState extends State<_EdicionMasivaView> {
  String? _empresaId;
  String? _sedeId;
  List<dynamic> _sedes = [];
  final Map<String, _FilaEdicion> _filas = {};

  /// Buscador + filtro numérico. Existe porque el bloque que se quiere editar
  /// junto casi nunca se puede nombrar: "las de S/83" son 12 variantes de
  /// cinco diseños distintos, y la de S/112 —la que se vendería bajo costo—
  /// queda afuera sola. Buscar por texto no puede separarlas.
  final _filtro = FiltroVariantes();

  /// Total sin filtrar, para el "N de M". Lo setea el build con la lista que
  /// llega del cubit: el filtro no puede contar lo que ya descartó.
  int _totalVariantes = 0;

  // ── Cachés ─────────────────────────────────────────────────────────
  //
  // Cada tecla en cualquier celda dispara `setState` y reconstruye la página
  // entera. Sin esto, UNA pulsación recalculaba el problema de mayoreo de las
  // 91 variantes —la barra inferior las recorre todas para contar las
  // bloqueantes— más otra vez por cada mitad de cada fila visible.
  //
  // Sobreviven entre builds a propósito: al teclear en una fila solo cambia
  // ESA, así que se invalida esa sola y las otras 90 se reusan.
  final Map<String, _ProblemaMayor?> _cacheProblema = {};
  final Map<String, StockPorSedeInfo?> _cacheStock = {};

  /// Identidad de los datos de fondo. Si cambia la sede o llega otra lista de
  /// variantes (un reload tras guardar), lo cacheado dejó de valer.
  String? _claveDatos;

  void _revisarCaches(List<ProductoVariante> variantes) {
    final clave = '${identityHashCode(variantes)}|$_sedeId';
    if (clave == _claveDatos) return;
    _claveDatos = clave;
    _cacheStock.clear();
    _cacheProblema.clear();
  }

  /// Lo tecleado en [varianteId] cambió: su problema hay que recalcularlo.
  /// El stock no, que no depende de lo que se escribe.
  void _invalidarFila(String varianteId) => _cacheProblema.remove(varianteId);

  /// Fila de stock de la variante en la sede activa.
  ///
  /// Va cacheada porque `stockSedeInfo` resuelve con `firstWhere` dentro de un
  /// try/catch —o sea, **excepción como control de flujo** cada vez que la
  /// variante no tiene fila en esa sede— y se consultaba hasta cuatro veces
  /// por fila entre el nombre, los datos y el filtro.
  StockPorSedeInfo? _stockDe(ProductoVariante v) {
    if (_sedeId == null) return null;
    return _cacheStock.putIfAbsent(v.id, () => v.stockSedeInfo(_sedeId!));
  }

  /// El valor del campo pedido, en unidad de PRESENTACIÓN — la misma en la
  /// que se ve en la grilla y en la que se teclea el filtro.
  double? _valorDelCampo(ProductoVariante v, CampoPrecio campo) {
    final u = _presentacionDe(v);
    final info = _stockDe(v);
    switch (campo) {
      case CampoPrecio.venta:
        return info?.precio != null ? u.precio(info!.precio!) : null;
      case CampoPrecio.costo:
        return info?.precioCosto != null ? u.precio(info!.precioCosto!) : null;
      case CampoPrecio.mayor:
        final n = v.nivelPorMayor;
        return n?.precio != null ? u.precio(n!.precio!) : null;
    }
  }

  /// La columna del nombre queda CONGELADA a la izquierda (tipo excel) y solo
  /// scrollea en horizontal la zona numérica. Con 91 variantes cuyo nombre son
  /// cinco atributos encadenados, perder de vista cuál se está editando al
  /// llegar a la columna de mayoreo era el problema real.
  static const _wNombre = 190.0;

  /// Ancho del numerador dentro de la columna congelada. 20 entra hasta 999
  /// con la tipografía de 9 y cifras tabulares.
  static const _wNumero = 18.0;
  static const _wStockActual = 35.0;
  static const _wAgregarStock = 60.0;
  static const _wPrecio = 70.0;
  static const _wCosto = 70.0;
  static const _wMayorDesde = 50.0;
  static const _wMayorPrecio = 70.0;

  static const _anchoDatos = _wStockActual +
      _wAgregarStock +
      _wPrecio +
      _wCosto +
      _wMayorDesde +
      _wMayorPrecio +
      24; // padding horizontal de la fila

  /// Alto fijo de fila. Es lo que hace posible congelar la columna: las dos
  /// listas (nombres y datos) se sincronizan por OFFSET, así que si una fila
  /// midiera distinto de un lado que del otro, los renglones se desalinearían
  /// al scrollear. Con `itemExtent` además el scroll de 91 filas es más barato.
  static const _hFila = 50.0;

  /// El encabezado también va a alto fijo: son dos Containers distintos (uno
  /// por mitad) y tienen que arrancar los renglones a la misma altura.
  static const _hHeader = 30.0;

  /// Alto de la fila de sede + acciones.
  static const _hBarra = 32.0;

  /// 🔴 En Material 3 `padding: EdgeInsets.zero` + `constraints` NO encogen un
  /// IconButton: el mínimo de ~48px lo impone el `ButtonStyle` vía
  /// `tapTargetSize`, y sobra como separación fantasma arriba y abajo del
  /// selector de sede. La única vía es el estilo.
  /// El fondo es el MISMO que el del contador al lado del buscador
  /// (`blue1` al 8%), porque el `filledTonal` de M3 pinta con
  /// `secondaryContainer` — lavanda con el tema por defecto — y encima le
  /// mete elevación. Las dos cosas desentonaban en una barra que es toda azul.
  static ButtonStyle _estiloIcono({required bool activo}) =>
      IconButton.styleFrom(
        minimumSize: Size.zero,
        fixedSize: const Size(_hBarra, _hBarra),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        // Activo va más saturado: al sacar el `isSelected` de M3, este tinte
        // es lo único —junto al ícono lleno— que distingue el filtro puesto.
        backgroundColor: AppColors.blue1.withValues(alpha: activo ? 0.20 : 0.08),
        foregroundColor: AppColors.blue1,
        disabledBackgroundColor: Colors.grey.withValues(alpha: 0.08),
        disabledForegroundColor: Colors.grey.shade400,
        elevation: 0,
        shadowColor: Colors.transparent,
      );

  /// Verticales de la columna congelada y de la zona de datos, mantenidos en
  /// el mismo offset a mano. El horizontal NO necesita sincronía: el
  /// encabezado de datos vive dentro del mismo scroll horizontal que las filas.
  final _vNombres = ScrollController();
  final _vDatos = ScrollController();
  bool _sincronizando = false;

  /// Espeja el offset de una lista en la otra. El flag corta el rebote: sin
  /// él, el jumpTo del destino dispara su propio listener y vuelve al origen.
  void _sincronizar(ScrollController origen, ScrollController destino) {
    if (_sincronizando || !destino.hasClients || !origen.hasClients) return;
    if (destino.offset == origen.offset) return;
    _sincronizando = true;
    destino.jumpTo(origen.offset);
    _sincronizando = false;
  }

  @override
  void initState() {
    super.initState();
    _vNombres.addListener(() => _sincronizar(_vNombres, _vDatos));
    _vDatos.addListener(() => _sincronizar(_vDatos, _vNombres));
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _empresaId = empresaState.context.empresa.id;
      // Copia tipada como List<dynamic>: la lista original es List<SedeModel>
      // y un orElse que devuelve dynamic rompería firstWhere en runtime.
      _sedes =
          List<dynamic>.from(empresaState.context.sedes.where((s) => s.isActive));
      if (widget.sedeIdInicial != null &&
          _sedes.any((s) => s.id == widget.sedeIdInicial)) {
        _sedeId = widget.sedeIdInicial;
      } else if (_sedes.isNotEmpty) {
        _sedeId = _sedes
            .firstWhere((s) => s.esPrincipal, orElse: () => _sedes.first)
            .id;
      }
    }

    if (_empresaId != null) {
      context.read<EdicionMasivaStockCubit>().loadVariantes(
            productoId: widget.productoId,
            empresaId: _empresaId!,
          );
    }
  }

  @override
  void dispose() {
    for (final fila in _filas.values) {
      fila.dispose();
    }
    _filtro.dispose();
    _vNombres.dispose();
    _vDatos.dispose();
    super.dispose();
  }

  _FilaEdicion _filaDe(String varianteId) =>
      _filas.putIfAbsent(varianteId, () {
        final fila = _FilaEdicion();
        // Repintar al entrar y al salir de una celda. El listener se engancha
        // una sola vez, acá, porque `_filaDe` se llama en cada build.
        for (final foco in fila.focos) {
          foco.addListener(() {
            if (mounted) setState(() {});
          });
        }
        return fila;
      });

  int get _totalCambios => _filas.values.where((f) => f.tieneCambios).length;

  /// Qué le pasa al precio por mayor tecleado en esta fila. Todo en unidad de
  /// PRESENTACIÓN, que es en la que se teclea y en la que se muestra el costo.
  ///
  /// `null` = no hay nada que objetar (o no se tecleó nada).
  _ProblemaMayor? _problemaMayor(ProductoVariante v) =>
      _cacheProblema.putIfAbsent(v.id, () => _calcularProblemaMayor(v));

  _ProblemaMayor? _calcularProblemaMayor(ProductoVariante v) {
    final fila = _filas[v.id];
    if (fila == null) return null;

    final desdeTxt = fila.mayorDesde.text.trim();
    final precioTxt = fila.mayorPrecio.text.trim();
    if (desdeTxt.isEmpty && precioTxt.isEmpty) return null;

    // Las dos mitades o ninguna: un precio sin cantidad no se sabe desde
    // cuándo aplica, y una cantidad sin precio no crea ningún nivel.
    if (desdeTxt.isEmpty || precioTxt.isEmpty) {
      return _ProblemaMayor.incompleto;
    }

    final desde = _parseNum(desdeTxt);
    final precioMayor = _parseNum(precioTxt);
    if (desde == null || desde < 2) return _ProblemaMayor.cantidadInvalida;
    if (precioMayor == null) return _ProblemaMayor.incompleto;

    final u = _presentacionDe(v);
    final stockInfo = _stockDe(v);

    // El costo efectivo es el tecleado en ESTA fila si lo hay; si no, el
    // vigente. Comparar contra el viejo dejaría pasar un mayorista bajo costo
    // cuando se cargan los dos juntos.
    final costo = _parseNum(fila.costo.text) ??
        (stockInfo?.precioCosto != null ? u.precio(stockInfo!.precioCosto!) : null);
    if (costo != null && precioMayor < costo) return _ProblemaMayor.bajoCosto;

    // Un nivel solo entra si BAJA el precio ("gana el menor"), así que uno por
    // encima del precio de lista no hace absolutamente nada. No es peligroso,
    // pero el usuario cree que dejó un mayorista cargado.
    final precioLista = _parseNum(fila.precio.text) ??
        (stockInfo?.precio != null ? u.precio(stockInfo!.precio!) : null);
    if (precioLista != null && precioMayor >= precioLista) {
      return _ProblemaMayor.noBaja;
    }

    return null;
  }

  /// Variantes visibles cuyo precio por mayor NO se puede guardar.
  List<ProductoVariante> _bloqueantes(List<ProductoVariante> variantes) {
    return variantes.where((v) {
      final p = _problemaMayor(v);
      return p != null && p.bloquea;
    }).toList();
  }

  /// Cuántas variantes quedan a la vista y cuánto stock suman.
  ///
  /// 🔴 El stock solo se suma si TODAS comparten presentación: sumar 5000 g de
  /// un granel con 2 sacos da un número que no significa nada. Con
  /// presentaciones mezcladas devuelve el conteo y el stock en null.
  ({int cantidad, String? stock}) _resumenVisible(List<ProductoVariante> vis) {
    if (vis.isEmpty) return (cantidad: 0, stock: null);

    final u0 = _presentacionDe(vis.first);
    var total = 0.0;
    var mismaUnidad = true;

    for (final v in vis) {
      final u = _presentacionDe(v);
      if (u.factor != u0.factor || u.simboloVisible != u0.simboloVisible) {
        mismaUnidad = false;
      }
      final info = _stockDe(v);
      total += info?.cantidad ?? 0;
    }

    if (!mismaUnidad) return (cantidad: vis.length, stock: null);

    // Sin presentación `cantidadTexto` devuelve el número pelado; se le agrega
    // "u" para que no se confunda con el conteo de variantes de arriba.
    final texto = u0.cantidadTexto(total);
    return (
      cantidad: vis.length,
      stock: u0.simboloVisible == null ? '$texto u' : texto,
    );
  }

  /// Texto y precio se combinan con Y: "kitty" + "= 112" es una intersección.
  ///
  /// Memoización: el build se dispara con CADA tecla de CUALQUIER celda, y sin
  /// esto se re-normalizaban y re-comparaban las 91 variantes en cada
  /// pulsación aunque la búsqueda no hubiera cambiado. La clave incluye la
  /// identidad de la lista, así que un reload post-guardado recalcula.
  List<ProductoVariante> _filtrar(List<ProductoVariante> variantes) {
    final clave = '${identityHashCode(variantes)}|$_sedeId|${_filtro.clave}';
    if (clave == _claveFiltro) return _visiblesCache;

    final resultado = _filtro.filtrar(variantes, _valorDelCampo);
    _claveFiltro = clave;
    _visiblesCache = resultado;
    return resultado;
  }

  String? _claveFiltro;
  List<ProductoVariante> _visiblesCache = const [];

  void _limpiarEdiciones() {
    for (final fila in _filas.values) {
      fila.limpiar();
    }
    // Se borró lo tecleado de TODAS, así que no queda ningún problema válido.
    _cacheProblema.clear();
    setState(() {});
  }

  Future<void> _cambiarSede(String? nuevaSedeId) async {
    if (nuevaSedeId == null || nuevaSedeId == _sedeId) return;

    if (_totalCambios > 0) {
      final confirmar = await StyledDialog.show<bool>(
        context,
        accentColor: Colors.orange,
        backgroundColor: Colors.white,
        icon: Icons.store_outlined,
        titulo: 'Cambiar de sede',
        content: [
          const Text(
            'Tienes cambios sin guardar. Al cambiar de sede se descartarán. ¿Continuar?',
            style: TextStyle(fontSize: 13),
          ),
        ],
        actions: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),
          Expanded(
            child: CustomButton(
              text: 'Descartar',
              backgroundColor: Colors.orange,
              textColor: Colors.white,
              onPressed: () => Navigator.pop(context, true),
            ),
          ),
        ],
      );
      if (confirmar != true) return;
      _limpiarEdiciones();
    }

    setState(() => _sedeId = nuevaSedeId);
  }

  Future<void> _aplicarATodas(List<ProductoVariante> visibles) async {
    final stockCtrl = TextEditingController();
    final precioCtrl = TextEditingController();
    final costoCtrl = TextEditingController();
    final mayorDesdeCtrl = TextEditingController();
    final mayorPrecioCtrl = TextEditingController();

    final aplicar = await StyledDialog.show<bool>(
      context,
      accentColor: AppColors.blue1,
      backgroundColor: Colors.white,
      icon: Icons.copy_all,
      titulo: 'Aplicar a ${visibles.length} variante(s)',
      content: [
        const Text(
          'Los campos vacíos no se aplican. Afecta solo a las variantes '
          'visibles (según el filtro).\n\n'
          'Cada valor se toma en la unidad de SU variante: un mismo "15.00" es '
          'S/15 por kilo en un granel y S/15 por unidad en un saco.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 14),
        CustomText(
          controller: stockCtrl,
          label: 'Agregar stock (+/-)',
          hintText: '0',
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          inputFormatters: [_soloEnteroConSigno],
          borderColor: AppColors.blue1.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 10),
        CustomText(
          controller: precioCtrl,
          label: 'Precio (S/)',
          hintText: '0.00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [_soloDecimal],
          borderColor: AppColors.blue1.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 10),
        CustomText(
          controller: costoCtrl,
          label: 'Costo (S/)',
          hintText: '0.00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [_soloDecimal],
          borderColor: AppColors.blue1.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.public, size: 14, color: Colors.orange.shade800),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                'El precio por mayor NO es por sede: se aplica a todas. '
                'Las variantes cuyo precio quede bajo costo se marcan y no '
                'dejan guardar.',
                style: TextStyle(
                    fontSize: 11, color: Colors.orange.shade900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: CustomText(
                controller: mayorDesdeCtrl,
                label: 'Desde (cant.)',
                hintText: '3',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_soloDecimal],
                borderColor: AppColors.blue1.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: CustomText(
                controller: mayorPrecioCtrl,
                label: 'Precio por mayor (S/)',
                hintText: '0.00',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_soloDecimal],
                borderColor: AppColors.blue1.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ],
      actions: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
        Expanded(
          child: CustomButton(
            text: 'Aplicar',
            backgroundColor: AppColors.blue1,
            textColor: Colors.white,
            onPressed: () => Navigator.pop(context, true),
          ),
        ),
      ],
    );

    if (aplicar == true) {
      for (final v in visibles) {
        final fila = _filaDe(v.id);
        if (stockCtrl.text.trim().isNotEmpty) fila.stock.text = stockCtrl.text.trim();
        if (precioCtrl.text.trim().isNotEmpty) fila.precio.text = precioCtrl.text.trim();
        if (costoCtrl.text.trim().isNotEmpty) fila.costo.text = costoCtrl.text.trim();
        if (mayorDesdeCtrl.text.trim().isNotEmpty) {
          fila.mayorDesde.text = mayorDesdeCtrl.text.trim();
        }
        if (mayorPrecioCtrl.text.trim().isNotEmpty) {
          fila.mayorPrecio.text = mayorPrecioCtrl.text.trim();
        }
      }
      // Se escribió sobre muchas filas de una: se recalculan todas.
      _cacheProblema.clear();
      setState(() {});
    }

    stockCtrl.dispose();
    precioCtrl.dispose();
    costoCtrl.dispose();
    mayorDesdeCtrl.dispose();
    mayorPrecioCtrl.dispose();
  }

  Future<void> _guardar(List<ProductoVariante> variantes) async {
    if (_sedeId == null || _empresaId == null) return;

    // Nada se guarda si hay un precio por mayor inválido: la transacción del
    // backend es todo-o-nada, así que dejarlo llegar solo cambia un error de
    // pantalla por un 400 con las demás filas sin aplicar.
    final bloqueantes = _bloqueantes(variantes);
    if (bloqueantes.isNotEmpty) {
      final detalle = bloqueantes.take(5).map((v) {
        final p = _problemaMayor(v)!;
        return '• ${v.nombre}\n   ${p.mensaje}';
      }).join('\n');
      final resto = bloqueantes.length > 5
          ? '\n\n…y ${bloqueantes.length - 5} más.'
          : '';
      await StyledDialog.show<void>(
        context,
        accentColor: Colors.red.shade700,
        backgroundColor: Colors.white,
        icon: Icons.price_check,
        titulo: 'Revisá el precio por mayor',
        content: [
          Text(
            'No se guardó nada. ${bloqueantes.length} variante(s) tienen un '
            'precio por mayor que no se puede aplicar:\n\n$detalle$resto',
            style: const TextStyle(fontSize: 12),
          ),
        ],
        actions: [
          Expanded(
            child: CustomButton(
              text: 'Entendido',
              backgroundColor: Colors.red.shade700,
              textColor: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      );
      return;
    }

    final items = <BulkEditarItem>[];
    for (final v in variantes) {
      final fila = _filas[v.id];
      if (fila == null || !fila.tieneCambios) continue;

      // Lo tecleado viene en unidad de PRESENTACIÓN (kilos); el backend
      // trabaja en unidad de venta (gramos). La conversión pasa solo acá.
      final u = _presentacionDe(v);
      final agregarPres = _parseNum(fila.stock.text);
      final precioPres = _parseNum(fila.precio.text);
      final costoPres = _parseNum(fila.costo.text);

      // El precio por mayor sigue la misma regla que el precio de lista, y la
      // cantidad mínima la del stock: "desde 3 kg" son 3000 g en unidad de
      // venta, que es contra lo que el backend compara la cantidad vendida.
      final mayorDesdePres = _parseNum(fila.mayorDesde.text);
      final mayorPrecioPres = _parseNum(fila.mayorPrecio.text);

      final item = BulkEditarItem(
        varianteId: v.id,
        // El stock es entero en unidad de venta: 1.5 kg son 1500 g.
        agregarStock:
            agregarPres == null ? null : (agregarPres * u.factor).round(),
        precio: precioPres == null ? null : precioPres / u.factor,
        precioCosto: costoPres == null ? null : costoPres / u.factor,
        mayorCantidadMinima:
            mayorDesdePres == null ? null : (mayorDesdePres * u.factor).round(),
        mayorPrecio:
            mayorPrecioPres == null ? null : mayorPrecioPres / u.factor,
      );
      if (item.tieneCambios) items.add(item);
    }

    if (items.isEmpty) return;

    final sedeNombre =
        _sedes.firstWhere((s) => s.id == _sedeId, orElse: () => null)?.nombre ??
            '';

    final confirmar = await StyledDialog.show<bool>(
      context,
      accentColor: AppColors.blue1,
      backgroundColor: Colors.white,
      icon: Icons.save_outlined,
      titulo: 'Confirmar cambios',
      content: [
        Text(
          'Se aplicarán cambios a ${items.length} variante(s) en la sede "$sedeNombre".\n\n'
          'Los ajustes de stock quedarán registrados en el kardex y los '
          'cambios de precio en el historial.',
          style: const TextStyle(fontSize: 13),
        ),
        // El stock y los precios son por sede; el nivel por mayor NO. Si no se
        // dice acá, se descubre el día que la empresa abre una segunda sede.
        if (items.any((i) => i.mayorPrecio != null)) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.public, size: 15, color: Colors.orange.shade800),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'El precio por mayor de '
                    '${items.where((i) => i.mayorPrecio != null).length} '
                    'variante(s) se aplica a TODAS las sedes, no solo a '
                    '"$sedeNombre".',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
      actions: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
        Expanded(
          child: CustomButton(
            text: 'Guardar',
            icon: const Icon(Icons.save_outlined, size: 14, color: Colors.white),
            backgroundColor: AppColors.blue1,
            textColor: Colors.white,
            onPressed: () => Navigator.pop(context, true),
          ),
        ),
      ],
    );

    if (confirmar != true || !mounted) return;

    context.read<EdicionMasivaStockCubit>().guardarCambios(
          sedeId: _sedeId!,
          empresaId: _empresaId!,
          productoId: widget.productoId,
          items: items,
          motivo: 'Edición masiva de inventario',
        );
  }

  static final _soloEnteroConSigno =
      FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'));
  /// Con presentación el stock se escribe en kilos y ahí sí hacen falta
  /// decimales: "1.5" son 1500 g. Sin presentación se sigue exigiendo entero,
  /// porque medio saco no existe.
  static final _decimalConSigno =
      FilteringTextInputFormatter.allow(RegExp(r'^-?\d*[.,]?\d{0,3}'));
  static final _soloDecimal =
      FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}'));

  /// El teclado numérico deja escribir coma: "0,5" tiene que valer lo mismo
  /// que "0.5" y no caerse a null.
  static double? _parseNum(String texto) {
    final t = texto.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  /// En qué unidad se lee y se escribe esta variante.
  ///
  /// Presentación propia (el granel: kg ×1000) → esa. Si no, su unidad propia
  /// (el saco: `und`, factor 1). Si no tiene ninguna de las dos, hereda la del
  /// producto y esta pantalla no la conoce —el cubit carga variantes, no el
  /// producto—, así que se muestra el número crudo sin símbolo, igual que
  /// antes.
  UnidadPresentacion _presentacionDe(ProductoVariante v) {
    if (v.tienePresentacionPropia) {
      return UnidadPresentacion(
        factor: v.factorPresentacion!,
        simbolo: v.unidadPresentacionSimbolo,
      );
    }
    return UnidadPresentacion(
      factor: 1,
      simbolo: v.unidadMedidaId != null ? v.unidadMedida?.displayCorto : null,
    );
  }

  /// Margen sobre costo en %. Es un RATIO, así que da igual en qué unidad
  /// estén los dos números mientras sea la misma.
  double? _margenPct(double? precio, double? costo) {
    if (precio == null || costo == null || costo <= 0) return null;
    return ((precio - costo) / costo) * 100;
  }

  /// Rojo bajo cero (se vende perdiendo), ámbar hasta 15% (flaco) y verde
  /// arriba. Los cortes son para que salte a la vista, no una regla contable.
  Color _colorMargen(double pct) {
    if (pct < 0) return Colors.red.shade700;
    if (pct < 15) return Colors.orange.shade800;
    return Colors.green.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Edición masiva',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white)),
            Text(
              widget.productoNombre,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: AppColors.white),
            ),
          ],
        ),
      ),
      // Tocar cualquier lado suelta el foco y baja el teclado. En una grilla
      // de 30 cajas de texto, sin esto el teclado tapa media pantalla y para
      // cerrarlo hay que ir al botón de atrás del sistema —que además se lleva
      // el foco puesto y deja la fila resaltada como si se siguiera editando.
      //
      // `translucent` y no `opaque`: así los hijos siguen recibiendo sus taps
      // normalmente y esto solo engancha lo que caiga en zona muerta.
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: BlocConsumer<EdicionMasivaStockCubit, EdicionMasivaStockState>(
        listener: (context, state) {
          if (state is EdicionMasivaStockSuccess) {
            _limpiarEdiciones();
            final r = state.resumen;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text([
                  'Guardado: ${r.stockAjustado} ajuste(s) de stock',
                  '${r.preciosActualizados} precio(s) actualizados',
                  if (r.nivelesActualizados > 0)
                    '${r.nivelesActualizados} precio(s) por mayor',
                  if (r.nivelesEliminados > 0)
                    '${r.nivelesEliminados} nivel(es) eliminados',
                ].join(', ')),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is EdicionMasivaStockError &&
              state.variantes.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is EdicionMasivaStockLoading ||
              state is EdicionMasivaStockInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EdicionMasivaStockError && state.variantes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(state.message),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => context
                        .read<EdicionMasivaStockCubit>()
                        .loadVariantes(
                          productoId: widget.productoId,
                          empresaId: _empresaId!,
                        ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final variantes = switch (state) {
            EdicionMasivaStockLoaded s => s.variantes,
            EdicionMasivaStockSaving s => s.variantes,
            EdicionMasivaStockSuccess s => s.variantes,
            EdicionMasivaStockError s => s.variantes,
            _ => <ProductoVariante>[],
          };
          _revisarCaches(variantes);
          _totalVariantes = variantes.length;
          final visibles = _filtrar(variantes);
          final guardando = state is EdicionMasivaStockSaving;

          return Column(
            children: [
              _buildBarraSuperior(visibles),
              const Divider(height: 1),
              Expanded(
                child: visibles.isEmpty
                    ? const Center(child: Text('Sin variantes que mostrar'))
                    : Row(
                        children: [
                          // ── Columna CONGELADA ────────────────────────────
                          SizedBox(
                            width: _wNombre,
                            child: Column(
                              children: [
                                _buildHeaderNombre(),
                                Expanded(
                                  child: ListView.builder(
                                    controller: _vNombres,
                                    itemExtent: _hFila,
                                    itemCount: visibles.length,
                                    itemBuilder: (context, i) =>
                                        _buildCeldaNombre(visibles[i], i),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Sombra al borde del congelado: sin ella no se
                          // entiende que lo de la derecha se puede correr.
                          Container(
                            width: 4,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.12),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          // ── Zona que scrollea ────────────────────────────
                          // El encabezado va DENTRO de este scroll horizontal,
                          // junto con las filas, así que se corren juntos sin
                          // necesidad de sincronizar nada.
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: _anchoDatos,
                                child: Column(
                                  children: [
                                    _buildHeaderDatos(),
                                    Expanded(
                                      child: ListView.builder(
                                        controller: _vDatos,
                                        itemExtent: _hFila,
                                        itemCount: visibles.length,
                                        itemBuilder: (context, i) =>
                                            _buildCeldaDatos(visibles[i], i),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              _buildBarraGuardar(variantes, guardando),
            ],
          );
        },
        ),
      ),
    );
  }

  Widget _buildBarraSuperior(List<ProductoVariante> visibles) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Column(
        children: [
          // Alto fijo en la FILA, no solo en los hijos: así ningún control que
          // se agregue después puede volver a estirarla.
          SizedBox(
            height: _hBarra,
            child: Row(
            children: [
              Icon(Icons.store, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              const Text('Sede:',
                  style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              if (_sedes.isNotEmpty)
                CustomSedeSelector(
                  sedes: _sedes,
                  currentSede: _sedes.firstWhere(
                    (s) => s.id == _sedeId,
                    orElse: () => _sedes.first,
                  ),
                  onSelected: _cambiarSede,
                ),
              const Spacer(),
              // Sin badge de conteo: el resumen al lado del buscador ya lo
              // dice, y dos números iguales en la misma pantalla confunden.
              // Que el ícono esté lleno alcanza para saber que hay filtro.
              IconButton.filledTonal(
                style: _estiloIcono(activo: _filtro.filtraPrecio),
                tooltip: _filtro.filtraPrecio
                    ? '${visibles.length} de $_totalVariantes variantes'
                    : 'Filtrar por precio',
                icon: Icon(
                  _filtro.filtraPrecio
                      ? Icons.filter_alt
                      : Icons.filter_alt_outlined,
                  size: 16,
                ),
                onPressed: () => setState(() {
                  _filtro.abierto = !_filtro.abierto;
                  // Al cerrarlo se limpia: un filtro activo pero invisible
                  // haría creer que faltan variantes.
                  if (!_filtro.abierto) {
                    _filtro.desde.clear();
                    _filtro.hasta.clear();
                  }
                }),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                style: _estiloIcono(activo: false),
                tooltip: 'Aplicar valor a todas las visibles',
                icon: const Icon(Icons.copy_all, size: 16),
                onPressed:
                    visibles.isEmpty ? null : () => _aplicarATodas(visibles),
              ),
            ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildResumenVisible(visibles),
              const SizedBox(width: 8),
              Expanded(
                child: CustomSearchField(
                  borderColor: AppColors.blue1Alpha40,
                  controller: _filtro.busqueda,
                  hintText: 'Buscar por nombre o SKU...',
                  debounceDelay: const Duration(milliseconds: 400),
                  onChanged: (_) => setState(() {}),
                  onClear: () => setState(() {}),
                ),
              ),
            ],
          ),
          if (_filtro.abierto)
            FilaFiltroPrecio(
              filtro: _filtro,
              alto: _hCampo,
              onCambio: () => setState(() {}),
            ),
        ],
      ),
    );
  }

  /// Filtro numérico: campo + comparador + valor(es). Filtrar y después
  /// "aplicar a todas las visibles" es el flujo que reemplaza cargar 31
  /// niveles a mano.
  /// Cuántas variantes se están viendo y cuánto stock suman. Va pegado al
  /// buscador porque es la respuesta a lo que se acaba de escribir.
  Widget _buildResumenVisible(List<ProductoVariante> visibles) {
    final r = _resumenVisible(visibles);
    return ResumenVariantes(
      cantidad: r.cantidad,
      total: _totalVariantes,
      stock: r.stock,
      filtrando: _filtro.activo,
    );
  }

  static const _estiloHeader =
      TextStyle(fontSize: 10, fontWeight: FontWeight.w600);

  /// Encabezado de la columna congelada. Va aparte del de datos para que los
  /// dos midan lo mismo de alto sin depender de un Row compartido.
  Widget _buildHeaderNombre() {
    return Container(
      height: _hHeader,
      alignment: Alignment.centerLeft,
      color: AppColors.blue1.withValues(alpha: 0.08),
      padding: const EdgeInsets.fromLTRB(2, 0, 8, 0),
      child: Row(
        children: [
          SizedBox(
            width: _wNumero,
            child: Text('#',
                textAlign: TextAlign.right,
                style: _estiloHeader.copyWith(color: Colors.grey[600])),
          ),
          const SizedBox(width: 4),
          const Text('Variante', style: _estiloHeader),
        ],
      ),
    );
  }

  Widget _buildHeaderDatos() {
    return Container(
      height: _hHeader,
      color: AppColors.blue1.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: const Row(
        children: [
          SizedBox(
              width: _wStockActual,
              child: Text('Stock',
                  style: _estiloHeader, textAlign: TextAlign.center)),
          SizedBox(
              width: _wAgregarStock,
              child: Text('+ Stock',
                  style: _estiloHeader, textAlign: TextAlign.center)),
          SizedBox(
              width: _wPrecio,
              child: Text('P.Venta S/',
                  style: _estiloHeader, textAlign: TextAlign.center)),
          SizedBox(
              width: _wCosto,
              child: Text('Costo S/',
                  style: _estiloHeader, textAlign: TextAlign.center)),
          SizedBox(
              width: _wMayorDesde,
              child: Text('Desde',
                  style: _estiloHeader, textAlign: TextAlign.center)),
          SizedBox(
              width: _wMayorPrecio,
              child: Text('Mayor S/',
                  style: _estiloHeader, textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  /// Fondo de la fila. Lo usan las DOS mitades: si difirieran, las rayas
  /// dejarían de coincidir a los lados de la línea de congelado.
  Color _fondoFila(ProductoVariante variante, int index) {
    final fila = _filas[variante.id];
    // El foco gana sobre "editada": mientras se escribe, lo que importa es
    // saber en qué renglón se está parado.
    if (fila != null && fila.estaEnfocada) {
      return AppColors.blue1.withValues(alpha: 0.16);
    }
    if (fila != null && fila.tieneCambios) {
      return Colors.amber.withValues(alpha: 0.12);
    }
    return index.isEven ? Colors.transparent : Colors.grey.withValues(alpha: 0.05);
  }

  /// Mitad congelada: nombre, SKU y margen. El motivo del bloqueo va acá
  /// porque esta columna está SIEMPRE a la vista — con la grilla corrida a la
  /// derecha, la celda en rojo puede quedar fuera de pantalla.
  Widget _buildCeldaNombre(ProductoVariante variante, int index) {
    final fila = _filaDe(variante.id);
    final stockInfo = _stockDe(variante);
    final u = _presentacionDe(variante);
    final problema = _problemaMayor(variante);

    // El margen se calcula sobre lo que QUEDARÍA: si ya se tecleó un precio o
    // un costo nuevo, manda ese. Así se ve el efecto antes de guardar.
    final precioEfectivo = _parseNum(fila.precio.text) ??
        (stockInfo?.precio != null ? u.precio(stockInfo!.precio!) : null);
    final costoEfectivo = _parseNum(fila.costo.text) ??
        (stockInfo?.precioCosto != null ? u.precio(stockInfo!.precioCosto!) : null);
    final margen = _margenPct(precioEfectivo, costoEfectivo);

    // Sin `alignment` a propósito: con él el Container afloja las constraints
    // y el Flexible del sku pasaría a medirse por ancho intrínseco. Así la
    // Column recibe el alto tight de `itemExtent` y centra sola.
    return Container(
      color: _fondoFila(variante, index),
      padding: const EdgeInsets.fromLTRB(2, 4, 6, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Numerador. Se numera la POSICIÓN en lo que se está viendo, no un
          // id fijo: si el buscador dice 32 resultados, la última fila dice 32.
          // Es la comprobación de que el conteo de arriba no miente.
          SizedBox(
            width: _wNumero,
            child: Text(
              '${index + 1}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.grey[500],
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Text.rich(
            TextSpan(
              children: _filtro.resaltar(
                variante.nombre,
                const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w500),
              ),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // El motivo REEMPLAZA la línea de sku/margen en vez de sumarse: la
          // fila es de alto fijo (lo que permite congelar la columna), así que
          // una tercera línea desbordaría.
          if (problema != null)
            Text(
              problema.mensaje,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: problema.bloquea
                    ? Colors.red.shade700
                    : Colors.orange.shade800,
              ),
            )
          else
            Row(
              children: [
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: _filtro.resaltar(
                        variante.sku,
                        TextStyle(fontSize: 9, color: Colors.grey[600]),
                        // Con la consulta ENTERA, igual que como se filtra.
                        // Con las palabras sueltas pintaba el "3" de "3 pzs"
                        // dentro de VAR-000230, justo el match que no
                        // queríamos.
                        esSku: true,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (margen != null) ...[
                  const SizedBox(width: 5),
                  Text(
                    '${margen >= 0 ? '+' : ''}${margen.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: _colorMargen(margen),
                    ),
                  ),
                ],
              ],
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Mitad que scrollea: todo lo numérico.
  Widget _buildCeldaDatos(ProductoVariante variante, int index) {
    final fila = _filaDe(variante.id);
    final stockInfo = _stockDe(variante);
    final stockActual = stockInfo?.cantidad;
    final precioActual = stockInfo?.precio;
    final costoActual = stockInfo?.precioCosto;
    final u = _presentacionDe(variante);
    final nivel = variante.nivelPorMayor;
    final problema = _problemaMayor(variante);

    return Container(
      color: _fondoFila(variante, index),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: _wStockActual,
            child: Text(
              stockActual == null ? '—' : u.cantidadTexto(stockActual),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: (stockActual ?? 0) == 0 ? Colors.red : AppColors.greendark,
              ),
            ),
          ),
          SizedBox(
            width: _wAgregarStock,
            child: _celdaEditable(
              varianteId: variante.id,
              controller: fila.stock,
              foco: fila.fStock,
              hint: '0',
              // Con presentación el stock se teclea en kilos y admite
              // decimales; sin ella sigue siendo entero.
              formatter: u.activa ? _decimalConSigno : _soloEnteroConSigno,
              signed: true,
            ),
          ),
          SizedBox(
            width: _wPrecio,
            child: _celdaEditable(
              varianteId: variante.id,
              controller: fila.precio,
              foco: fila.fPrecio,
              hint: precioActual == null
                  ? '—'
                  : u.precio(precioActual).toStringAsFixed(2),
              formatter: _soloDecimal,
            ),
          ),
          SizedBox(
            width: _wCosto,
            child: _celdaEditable(
              varianteId: variante.id,
              controller: fila.costo,
              foco: fila.fCosto,
              hint: costoActual == null
                  ? '—'
                  : u.precio(costoActual).toStringAsFixed(2),
              formatter: _soloDecimal,
            ),
          ),
          SizedBox(
            width: _wMayorDesde,
            child: _celdaEditable(
              varianteId: variante.id,
              controller: fila.mayorDesde,
              foco: fila.fMayorDesde,
              // El hint muestra el nivel VIGENTE: sin esto no se distingue
              // "no tiene mayorista" de "ya tiene uno y lo estoy pisando".
              hint: nivel == null
                  ? '—'
                  : u.cantidadTexto(nivel.cantidadMinima).replaceAll(' ', ''),
              formatter: _soloDecimal,
            ),
          ),
          SizedBox(
            width: _wMayorPrecio,
            child: _celdaEditable(
              varianteId: variante.id,
              controller: fila.mayorPrecio,
              foco: fila.fMayorPrecio,
              hint: nivel?.precio == null
                  ? '—'
                  : u.precio(nivel!.precio!).toStringAsFixed(2),
              formatter: _soloDecimal,
              errorColor: problema != null && problema.bloquea,
            ),
          ),
        ],
      ),
    );
  }

  /// Alto del campo dentro de la celda. Tiene que ser FIJO y estar acotado
  /// por un SizedBox: `CustomText` devuelve una Column (campo + indicador de
  /// voz + helper + error) con `mainAxisSize.max`, así que si se la deja
  /// crecer toma todo el alto de la fila y apila desde ARRIBA — el campo
  /// quedaba pegado al techo con el espacio muerto abajo, no centrado.
  ///
  /// 36 y no 34: borde (1.6×2) + padding (8×2) + línea de 11px dan ~35, y con
  /// 34 la Column desbordaba el SizedBox. En una fila de 54 sigue centrado.
  static const _hCampo = 32.0;

  Widget _celdaEditable({
    required TextEditingController controller,
    required String hint,
    required TextInputFormatter formatter,
    required String varianteId,
    FocusNode? foco,
    bool signed = false,
    bool errorColor = false,
  }) {
    final activa = foco?.hasFocus ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Center(
        child: SizedBox(
          height: _hCampo,
          child: CustomText(
            controller: controller,
            focusNode: foco,
            hintText: hint,
            // Solo se invalida ESTA fila: el problema de mayoreo de las otras
            // 90 no cambió porque acá se tecleó un dígito.
            onChanged: (_) => setState(() => _invalidarFila(varianteId)),
            keyboardType: TextInputType.numberWithOptions(
                signed: signed, decimal: !signed),
            inputFormatters: [formatter],
            height: _hCampo,
            // La celda tocada se marca con borde lleno; el error manda sobre
            // el foco, porque un campo en rojo enfocado sigue estando mal.
            borderColor: errorColor
                ? Colors.red.shade600
                : activa
                    ? AppColors.blue1
                    : AppColors.blue1Alpha40,
            borderWidth: activa || errorColor ? 1 : 0.6,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            textStyle: const TextStyle(fontSize: 11),
            hintStyle: TextStyle(fontSize: 10, color: Colors.grey[400]),
            showValidationIndicator: false,
          ),
        ),
      ),
    );
  }

  Widget _buildBarraGuardar(List<ProductoVariante> variantes, bool guardando) {
    final cambios = _totalCambios;
    // Se cuenta sobre TODAS las variantes, no sobre las visibles: una fila con
    // problema puede quedar escondida por el filtro y el botón tiene que
    // seguir explicando por qué no guarda.
    final bloqueantes = _bloqueantes(variantes).length;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (cambios > 0)
              TextButton.icon(
                onPressed: guardando ? null : _limpiarEdiciones,
                icon: const Icon(Icons.undo, size: 16),
                label: const Text('Descartar', style: TextStyle(fontSize: 12)),
              ),
            const Spacer(),
            if (bloqueantes > 0) ...[
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 15, color: Colors.red.shade700),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '$bloqueantes con precio por mayor inválido',
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            FilledButton.icon(
              // Azul de la app en vez del primary del tema (lavanda de M3),
              // igual que el resto de la barra. Deshabilitado va gris y no
              // azul apagado: tiene que leerse como "no se puede", no como
              // "guardá acá".
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue1,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
              ),
              onPressed: cambios == 0 || guardando || bloqueantes > 0
                  ? null
                  : () => _guardar(variantes),
              icon: guardando
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save, size: 18),
              label: Text(
                guardando ? 'Guardando...' : 'Guardar ($cambios)',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
