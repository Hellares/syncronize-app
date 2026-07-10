import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/barcode_scanner_button.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_search_field.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../empresa/presentation/bloc/sede_activa/sede_activa_cubit.dart';
import '../../../impresoras/domain/services/impresoras_manager.dart';
import '../../../producto/domain/entities/precio_nivel.dart';
import '../../../producto/domain/entities/producto_filtros.dart';
import '../../../producto/domain/entities/producto_list_item.dart';
import '../../../producto/domain/entities/producto_variante.dart';
import '../../../producto/domain/entities/stock_por_sede_mixin.dart';
import '../../../producto/domain/services/precio_nivel_cache_service.dart';
import '../../../producto/domain/usecases/get_productos_usecase.dart';
import '../../../producto/presentation/bloc/producto_list/producto_list_cubit.dart';
import '../../../producto/presentation/bloc/producto_list/producto_list_state.dart';
import '../../../venta/data/datasources/venta_remote_datasource.dart';
import '../../../venta/domain/entities/venta_detalle_input.dart';
import '../../../venta_rapida/presentation/bloc/venta_rapida_cubit.dart';
import '../../../venta_rapida/presentation/widgets/variante_selector_sheet.dart';
import '../services/calculo_mostrador_esc_pos_generator.dart';
import '../services/listas_mostrador_store.dart';

/// Calculadora de MOSTRADOR: el cliente pregunta precios de varios
/// productos y el vendedor los busca (catálogo local de la sede activa,
/// mismo storage/deltas que Venta Rápida), los va sumando en una lista
/// enumerada — con oferta/liquidación y precios por mayor visibles — y
/// al final imprime la lista calculada en la ticketera. NO toca stock,
/// NO crea documentos: es una herramienta 100% local.
class CalculadoraMostradorSheet extends StatefulWidget {
  const CalculadoraMostradorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CalculadoraMostradorSheet(),
    );
  }

  @override
  State<CalculadoraMostradorSheet> createState() =>
      _CalculadoraMostradorSheetState();
}

class _CalculadoraMostradorSheetState extends State<CalculadoraMostradorSheet> {
  final _searchCtrl = TextEditingController();
  final _nivelCache = locator<PrecioNivelCacheService>();
  late final ProductoListCubit _productosCubit;

  /// Cubit del catálogo COMPARTIDO entre aperturas del sheet (warm
  /// start): crear uno nuevo por apertura re-hidrataba la biblioteca y
  /// releía el snapshot de disco cada vez → el buscador arrancaba en
  /// frío (notablemente más lento que VR, que mantiene su cubit mientras
  /// la página vive). Se conserva vivo con la clave empresa|sede y el
  /// loadProductos de cada reapertura pasa a ser revalidación por deltas
  /// sobre el catálogo ya en memoria.
  static ProductoListCubit? _cubitWarm;
  static String? _cubitWarmKey;

  String? _sedeId;
  String _query = '';

  /// Query resuelta en el SERVIDOR (matchea codigoBarras/sku/
  /// codigoEmpresa exactos — el catálogo local no trae codigoBarras del
  /// producto base). Se activa al escanear o al tipear algo "tipo
  /// código". Null = búsqueda local normal por nombre.
  String? _serverQuery;

  /// true = la búsqueda server vino del ESCÁNER: si devuelve 1 producto
  /// se agrega solo. Tipeado manual solo muestra resultados.
  bool _autoAgregarDeScan = false;

  Timer? _serverDebounce;
  final List<VentaDetalleInput> _items = [];

  /// Selección múltiple en resultados: productos SIN variantes marcados
  /// con checkbox para agregarlos de un golpe ("peluche lucifer" tiene
  /// varios modelos → marcar 4 y Agregar, en vez de 4 búsquedas). La
  /// selección SOBREVIVE entre búsquedas (se puede marcar de búsquedas
  /// distintas y agregar todo junto).
  final Map<String, ProductoListItem> _seleccionados = {};

  /// Cache de los ProductoListItem de todo lo agregado en ESTA sesión de
  /// la calculadora. "Pasar a Venta Rápida" necesita el objeto completo
  /// (no solo el id) y el catálogo del cubit es paginado/puede estar
  /// recargándose justo después de agregar — buscar ahí fallaba con
  /// "no se pudo pasar ningún producto". El catálogo queda como fallback
  /// para listas guardadas re-abiertas.
  final Map<String, ProductoListItem> _productosDeItems = {};
  bool _imprimiendo = false;

  /// Lista guardada actualmente ABIERTA (via historial): al volver a
  /// guardar se ofrece actualizarla en vez de duplicarla. Se limpia al
  /// Limpiar la lista o cambiar de sede.
  String? _listaCargadaId;
  String? _listaCargadaNombre;
  DateTime? _listaCargadaFecha;

  /// Resultado de la última impresión (mensaje, éxito) — banner en el sheet.
  (String, bool)? _msgImpresion;

  @override
  void initState() {
    super.initState();
    // Contexto: empresa + sede activa global (los providers de main están
    // por encima del navigator raíz).
    final ctxState = context.read<EmpresaContextCubit>().state;
    final sede = context.read<SedeActivaCubit>().state.activa;
    _sedeId = sede?.id;
    final empresaId =
        ctxState is EmpresaContextLoaded ? ctxState.context.empresa.id : null;

    final key = '$empresaId|$_sedeId';
    if (_cubitWarm != null && !_cubitWarm!.isClosed && _cubitWarmKey == key) {
      // Reapertura con el mismo contexto: catálogo ya en memoria.
      _productosCubit = _cubitWarm!;
    } else {
      _cubitWarm?.close();
      _productosCubit = locator<ProductoListCubit>();
      _cubitWarm = _productosCubit;
      _cubitWarmKey = key;
    }

    if (empresaId != null && _sedeId != null) {
      // Warm: stale-while-revalidate (pinta lo previo al instante y
      // revalida con deltas en background). Frío: carga completa.
      _productosCubit.loadProductos(
        empresaId: empresaId,
        sedeId: _sedeId,
        filtros: const ProductoFiltros(isActive: true, esInsumo: false),
      );
    }
  }

  @override
  void dispose() {
    _serverDebounce?.cancel();
    _searchCtrl.dispose();
    // OJO: el cubit NO se cierra — queda warm para la próxima apertura
    // (es la clave de que el buscador arranque instantáneo).
    super.dispose();
  }

  double get _total => _items.fold(0, (s, i) => s + i.total);

  /// Nombre de la sede SELECCIONADA en la calculadora (puede diferir de
  /// la sede activa global) — para el ticket/PDF/WhatsApp.
  String? get _sedeNombre {
    final st = context.read<SedeActivaCubit>().state;
    for (final s in st.operables) {
      if (s.id == _sedeId) return s.nombre;
    }
    return st.activa?.nombre;
  }

  /// Dirección completa de la sede seleccionada (null si no configurada)
  /// — encabezado del ticket "SEDE: dirección".
  String? get _sedeDireccion {
    final st = context.read<SedeActivaCubit>().state;
    for (final s in st.operables) {
      if (s.id == _sedeId) {
        final dir = s.direccionCompleta;
        return dir == 'Sin dirección' ? null : dir;
      }
    }
    return null;
  }

  // ── Agregar / quitar / cantidades ──────────────────────────────────

  /// Devuelve true si el producto entró a la lista (false = sin precio
  /// en la sede). [limpiarBusqueda] false para agregados en LOTE (la
  /// selección múltiple limpia una sola vez al final).
  Future<bool> _agregar(
    ProductoListItem p, {
    ProductoVariante? v,
    double cantidad = 1,
    bool limpiarBusqueda = true,
  }) async {
    final sedeId = _sedeId!;
    // Ambos mezclan StockPorSedeMixin (precio/oferta/stock por sede).
    final StockPorSedeMixin fuente = v ?? p;
    final precio =
        fuente.precioEfectivoEnSede(sedeId) ?? fuente.precioEnSede(sedeId) ?? 0;
    if (precio <= 0) return false;

    // Dedupe: mismo producto/variante → suma la cantidad.
    final idx = _items.indexWhere(
      (i) => i.productoId == p.id && i.varianteId == (v?.id),
    );
    if (idx >= 0) {
      setState(() {
        _items[idx] = _items[idx].recalcularPrecioPorNiveles(
          _items[idx].cantidad + cantidad,
        );
      });
      _productosDeItems[p.id] = p;
      if (limpiarBusqueda) _limpiarBusqueda();
      return true;
    }

    final enOferta = fuente.enOfertaEnSede(sedeId);
    final enLiquidacion = fuente.enLiquidacionEnSede(sedeId);
    // Niveles por mayor (cache local, mismo servicio que VR/cotización).
    List<PrecioNivel> niveles = const [];
    try {
      niveles = v != null
          ? await _nivelCache.getNivelesVariante(v.id)
          : await _nivelCache.getNiveles(p.id);
    } catch (_) {}

    final item = VentaDetalleInput(
      productoId: p.id,
      varianteId: v?.id,
      descripcion: v != null ? '${p.nombre} — ${v.nombre}' : p.nombre,
      cantidad: 1,
      precioUnitario: precio,
      precioBase: precio,
      // El precio de vitrina YA incluye IGV según la config de la sede —
      // sin esto el total sumaba 18% encima (30 → 35.40).
      precioIncluyeIgv: fuente.precioIncluyeIgvEnSede(sedeId),
      stockDisponible: fuente.stockEnSede(sedeId),
      niveles: niveles,
      enOferta: enOferta,
      enLiquidacion: enLiquidacion,
      precioAntesOferta: (enOferta || enLiquidacion)
          ? fuente.precioEnSede(sedeId)
          : null,
    ).recalcularPrecioPorNiveles(cantidad);

    if (!mounted) return false;
    setState(() => _items.add(item));
    _productosDeItems[p.id] = p;
    if (limpiarBusqueda) _limpiarBusqueda();
    return true;
  }

  // ── Selección múltiple en resultados ───────────────────────────────

  void _toggleSeleccion(ProductoListItem p) {
    setState(() {
      if (_seleccionados.containsKey(p.id)) {
        _seleccionados.remove(p.id);
      } else {
        _seleccionados[p.id] = p;
      }
    });
  }

  /// Agrega TODOS los seleccionados de un golpe y limpia la búsqueda una
  /// sola vez. Los que no tienen precio en la sede se saltan (se avisa).
  Future<void> _agregarSeleccionados() async {
    final pendientes = _seleccionados.values.toList();
    if (pendientes.isEmpty) return;
    var agregados = 0;
    for (final p in pendientes) {
      if (await _agregar(p, limpiarBusqueda: false)) agregados++;
      if (!mounted) return;
    }
    setState(() => _seleccionados.clear());
    _limpiarBusqueda();
    final saltados = pendientes.length - agregados;
    _feedback(
      saltados == 0
          ? '$agregados producto${agregados == 1 ? '' : 's'} agregado${agregados == 1 ? '' : 's'}'
          : '$agregados agregados — $saltados sin precio en esta sede',
      ok: agregados > 0,
    );
  }

  void _limpiarBusqueda() {
    _serverDebounce?.cancel();
    _searchCtrl.clear();
    final habiaServer = _serverQuery != null;
    setState(() {
      _query = '';
      _serverQuery = null;
      _autoAgregarDeScan = false;
    });
    if (habiaServer) _restaurarCatalogo();
  }

  /// Vuelve al catálogo completo tras una búsqueda por código (el filtro
  /// server-side quedaría pegado y la búsqueda local operaría sobre él).
  void _restaurarCatalogo() {
    _productosCubit.applyFiltros(
      const ProductoFiltros(isActive: true, esInsumo: false),
    );
  }

  /// Heurística "esto parece un código, no un nombre": sin espacios y
  /// con al menos un dígito (barras/sku/código interno).
  bool _pareceCodigo(String q) =>
      q.length >= 4 && !q.contains(' ') && RegExp(r'[0-9]').hasMatch(q);

  /// Lanza la búsqueda por código en el SERVIDOR.
  void _buscarServer(String code, {required bool autoAgregar}) {
    setState(() {
      _serverQuery = code;
      _autoAgregarDeScan = autoAgregar;
    });
    _productosCubit.applyFiltros(
      ProductoFiltros(search: code, isActive: true, esInsumo: false),
    );
  }

  /// Código de barras escaneado con la cámara.
  void _onCodigoEscaneado(String code) {
    final codeTrim = code.trim();
    if (codeTrim.isEmpty) return;
    _serverDebounce?.cancel();
    _searchCtrl.text = codeTrim;
    setState(() => _query = codeTrim);
    _buscarServer(codeTrim, autoAgregar: true);
  }

  /// Si el scan devolvió EXACTAMENTE 1 producto, agregarlo solo (con la
  /// variante que matchea el código, si aplica). 0 o >1 → el vendedor
  /// elige de la lista.
  void _autoAgregarSiUnico(ProductoListLoaded state) {
    if (!_autoAgregarDeScan) return;
    final code = _serverQuery;
    if (code == null) return;
    if (state.isFiltering) return; // esperar la respuesta final
    if (state.filtros.search != code) return; // respuesta de otro filtro
    if (state.productos.length != 1) return; // ambiguo → elegir manual
    final p = state.productos.first;
    _serverQuery = null;
    _autoAgregarDeScan = false;
    _searchCtrl.clear();
    _query = '';
    if (p.tieneVariantes && (p.variantes ?? []).isNotEmpty) {
      final match = p.variantes!.cast<ProductoVariante?>().firstWhere(
        (v) =>
            v!.codigoBarras != null &&
            v.codigoBarras!.toLowerCase() == code.toLowerCase(),
        orElse: () => null,
      );
      if (match != null) {
        _agregar(p, v: match);
      } else {
        _seleccionar(p); // abre el selector de variantes
      }
    } else {
      _agregar(p);
    }
    _restaurarCatalogo();
  }

  void _cambiarCantidad(int index, double delta) {
    final nueva = _items[index].cantidad + delta;
    setState(() {
      if (nueva <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = _items[index].recalcularPrecioPorNiveles(nueva);
      }
    });
  }

  Future<void> _seleccionar(ProductoListItem p) async {
    if (_sedeId == null) return;
    final variantes = (p.variantes ?? [])
        .where((v) => v.isActive != false)
        .toList();
    if (p.tieneVariantes && variantes.isNotEmpty) {
      // Mismo selector por ATRIBUTOS que Venta Rápida: chips por Talla/
      // Color/…, imagen, precio con niveles, stock por sede y stepper de
      // cantidad. Se le pasa lo ya sumado en la lista para que el stock
      // disponible descuente lo que el cliente ya pidió.
      final cantidadesEnLista = <String, int>{
        for (final i in _items)
          if (i.productoId == p.id && i.varianteId != null)
            i.varianteId!: i.cantidad.toInt(),
      };
      await showVarianteSelectorSheet(
        context: context,
        producto: p,
        sedeId: _sedeId!,
        cantidadesEnCarrito: cantidadesEnLista,
        onAgregar: (v, cantidad) =>
            _agregar(p, v: v, cantidad: cantidad.toDouble()),
      );
    } else {
      await _agregar(p);
    }
  }

  // ── Pasar a Venta Rápida ───────────────────────────────────────────

  /// Último recurso del lookup: busca el producto en el SERVER por su
  /// nombre (para variantes, la parte antes del " — ") y matchea por id.
  /// null si no aparece (producto desactivado/eliminado).
  Future<ProductoListItem?> _buscarEnServerPorNombre(
      VentaDetalleInput it, String empresaId) async {
    final nombre = it.descripcion.split(' — ').first.trim();
    if (nombre.isEmpty) return null;
    try {
      final result = await locator<GetProductosUseCase>()(
        empresaId: empresaId,
        sedeId: _sedeId,
        filtros:
            ProductoFiltros(search: nombre, isActive: true, esInsumo: false),
      );
      if (result is Success<ProductosPaginados>) {
        for (final c in result.data.data) {
          if (c.id == it.productoId) return c;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Vuelca la lista al carrito GLOBAL de Venta Rápida ("ya, me llevo
  /// estas") y navega al carrito. Los items se re-agregan por los métodos
  /// canónicos del cubit — así la venta sale con IGV/afectación/ICBPER/
  /// costo/VIP correctos y precios VIGENTES del catálogo (una lista
  /// guardada vieja se re-precia: esto ya es una venta, no un registro).
  Future<void> _pasarAVentaRapida() async {
    if (_items.isEmpty) return;

    // La venta DEBE salir por la sede activa global: la página de VR
    // re-contextualiza con ella y un carrito de otra sede se vaciaría.
    final activa = context.read<SedeActivaCubit>().state.activa;
    if (activa == null || activa.id != _sedeId) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => StyledDialog(
          accentColor: Colors.orange.shade800,
          icon: Icons.storefront_outlined,
          titulo: 'Sede distinta',
          content: [
            Text(
              'Esta lista está cotizada con precios de "${_sedeNombre ?? 'otra sede'}", '
              'pero tu sede activa es "${activa?.nombre ?? '—'}". Cambia la '
              'sede activa (o re-cotiza en ella) para pasarla a Venta Rápida.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
          actions: [
            Expanded(
              child: CustomButton(
                text: 'Entendido',
                backgroundColor: Colors.orange.shade800,
                textColor: Colors.white,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      );
      return;
    }

    final ctxState = context.read<EmpresaContextCubit>().state;
    final authState = context.read<AuthBloc>().state;
    final empresaId =
        ctxState is EmpresaContextLoaded ? ctxState.context.empresa.id : null;
    final vendedorId = authState is Authenticated ? authState.user.id : null;
    if (empresaId == null || vendedorId == null) {
      _feedback('Falta contexto de empresa/vendedor', ok: false);
      return;
    }

    // Catálogo como FALLBACK (listas guardadas re-abiertas: sus productos
    // no pasaron por _agregar en esta sesión). Si el cubit está en medio
    // de una recarga (pasa justo tras agregar, al restaurar el catálogo),
    // esperar a que termine antes de darlo por vacío.
    var prodState = _productosCubit.state;
    final faltaCatalogo =
        _items.any((it) => !_productosDeItems.containsKey(it.productoId));
    if (faltaCatalogo && prodState is! ProductoListLoaded) {
      try {
        prodState = await _productosCubit.stream
            .firstWhere((s) => s is ProductoListLoaded)
            .timeout(const Duration(seconds: 3));
      } catch (_) {}
      if (!mounted) return;
    }
    final catalogo = prodState is ProductoListLoaded
        ? prodState.productos
        : const <ProductoListItem>[];
    debugPrint(
        '[CalcMostrador] pasarVR: items=${_items.length} cache=${_productosDeItems.length} '
        'vistos=${_productosCubit.vistosCache.length} catalogo=${catalogo.length} '
        '(${prodState.runtimeType})');

    final cubit = locator<VentaRapidaCubit>();
    // Mismo patrón que el cobro de OS desde su detalle: contextualizar
    // ANTES de tocar el carrito (si el carrito era de otra sede, esto lo
    // vacía — semántica estándar del cubit).
    cubit.setContexto(
      empresaId: empresaId,
      sedeId: _sedeId!,
      vendedorId: vendedorId,
    );

    if (cubit.state.items.isNotEmpty) {
      if (!mounted) return;
      final sumar = await showModalBottomSheet<bool>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'El carrito de Venta Rápida ya tiene '
                  '${cubit.state.items.length} item${cubit.state.items.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              ListTile(
                dense: true,
                leading:
                    Icon(Icons.add_shopping_cart, color: AppColors.blue1),
                title: const Text('Sumar a lo que ya está',
                    style: TextStyle(fontSize: 12.5)),
                subtitle: Text('La lista se agrega encima del carrito actual',
                    style: TextStyle(
                        fontSize: 10.5, color: Colors.grey.shade600)),
                onTap: () => Navigator.pop(ctx, true),
              ),
              ListTile(
                dense: true,
                leading: Icon(Icons.remove_shopping_cart_outlined,
                    color: Colors.orange.shade800),
                title: const Text('Vaciar y pasar solo esta lista',
                    style: TextStyle(fontSize: 12.5)),
                subtitle: Text('Lo que había en el carrito se descarta',
                    style: TextStyle(
                        fontSize: 10.5, color: Colors.grey.shade600)),
                onTap: () => Navigator.pop(ctx, false),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      );
      if (sumar == null || !mounted) return;
      if (!sumar) cubit.vaciarCarrito();
    }

    var pasados = 0;
    final noEncontrados = <String>[];
    for (final it in _items) {
      // El cubit necesita el ProductoListItem completo (campos fiscales).
      // Lookup en 3 niveles: agregados en esta sesión → biblioteca de
      // vistos (persistida en disco: cubre listas GUARDADAS re-abiertas,
      // el state.productos paginado no las tenía) → catálogo del state.
      ProductoListItem? p = _productosDeItems[it.productoId] ??
          _productosCubit.vistosCache[it.productoId];
      if (p == null) {
        for (final c in catalogo) {
          if (c.id == it.productoId) {
            p = c;
            break;
          }
        }
      }
      // Último recurso (lista guardada vieja fuera de biblioteca):
      // buscarlo en el SERVER por nombre y matchear por id.
      p ??= await _buscarEnServerPorNombre(it, empresaId);
      if (p == null) {
        debugPrint(
            '[CalcMostrador] pasarVR: producto NO hallado ${it.productoId} (${it.descripcion})');
        noEncontrados.add(it.descripcion);
        continue;
      }
      ProductoVariante? v;
      if (it.varianteId != null) {
        for (final x in p.variantes ?? const <ProductoVariante>[]) {
          if (x.id == it.varianteId) {
            v = x;
            break;
          }
        }
        if (v == null) {
          noEncontrados.add(it.descripcion);
          continue;
        }
      }
      // El cubit agrega +1 (o suma +1 si ya estaba): fijar después la
      // cantidad total = lo que había + lo cotizado. Buscar SIEMPRE por
      // productoId+varianteId (gotcha: solo productoId toca la variante
      // equivocada).
      bool match(VentaDetalleInput i) =>
          i.productoId == p!.id &&
          i.varianteId == it.varianteId &&
          i.origenComboId == null;
      final prevIdx = cubit.state.items.indexWhere(match);
      final prev = prevIdx >= 0 ? cubit.state.items[prevIdx].cantidad : 0.0;
      if (v != null) {
        cubit.agregarVariante(p, v);
      } else {
        cubit.agregarProducto(p);
      }
      final idx = cubit.state.items.indexWhere(match);
      final target = prev + it.cantidad;
      if (idx >= 0 && cubit.state.items[idx].cantidad != target) {
        // actualizarCantidad capea al stock disponible (venta real).
        cubit.actualizarCantidad(idx, target);
      }
      pasados++;
    }

    if (!mounted) return;
    if (pasados == 0) {
      _feedback('No se pudo pasar ningún producto al carrito', ok: false);
      return;
    }

    if (noEncontrados.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => StyledDialog(
          accentColor: Colors.orange.shade800,
          icon: Icons.info_outline,
          titulo: 'Pasados $pasados de ${_items.length}',
          content: [
            Text(
              'No se encontraron en el catálogo:\n'
              '${noEncontrados.map((d) => '• $d').join('\n')}',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
            ),
          ],
          actions: [
            Expanded(
              child: CustomButton(
                text: 'Ir al carrito',
                backgroundColor: AppColors.blue1,
                textColor: Colors.white,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      );
      if (!mounted) return;
    }

    // Cerrar la calculadora y aterrizar en el carrito ya cargado.
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push('/empresa/venta-rapida/carrito');
  }

  // ── Listas guardadas (solo en el celular) ──────────────────────────

  String _fmtFecha(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year} '
      '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';

  /// Guarda la lista actual en el celular (SharedPreferences) con fecha/
  /// hora y un nombre opcional. NO toca el backend. Si la lista actual
  /// vino del historial, primero ofrece ACTUALIZAR la guardada.
  Future<void> _guardarLista() async {
    if (_items.isEmpty) return;

    if (_listaCargadaId != null) {
      final etiqueta = _listaCargadaNombre ??
          (_listaCargadaFecha != null
              ? 'Lista del ${_fmtFecha(_listaCargadaFecha!)}'
              : 'lista guardada');
      final actualizar = await showModalBottomSheet<bool>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Esta lista vino de "$etiqueta"',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ),
              ListTile(
                dense: true,
                leading: Icon(Icons.save_outlined, color: AppColors.blue1),
                title: const Text('Actualizar la guardada',
                    style: TextStyle(fontSize: 12.5)),
                subtitle: Text(
                    'Reemplaza "$etiqueta" con los cambios de ahora',
                    style: TextStyle(
                        fontSize: 10.5, color: Colors.grey.shade600)),
                onTap: () => Navigator.pop(ctx, true),
              ),
              ListTile(
                dense: true,
                leading:
                    Icon(Icons.bookmark_add_outlined, color: AppColors.blue1),
                title: const Text('Guardar como lista nueva',
                    style: TextStyle(fontSize: 12.5)),
                subtitle: Text('La guardada original queda intacta',
                    style: TextStyle(
                        fontSize: 10.5, color: Colors.grey.shade600)),
                onTap: () => Navigator.pop(ctx, false),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      );
      if (actualizar == null || !mounted) return;
      if (actualizar) {
        final lista = ListaMostradorGuardada(
          id: _listaCargadaId!,
          // Fecha = última modificación (la lista sube al tope).
          fecha: DateTime.now(),
          nombre: _listaCargadaNombre,
          sedeId: _sedeId,
          sedeNombre: _sedeNombre,
          items: List.of(_items),
        );
        await ListasMostradorStore.actualizar(lista);
        if (!mounted) return;
        _listaCargadaFecha = lista.fecha;
        _feedback('Lista "$etiqueta" actualizada ✓', ok: true);
        return;
      }
      // false → cae al flujo normal de "guardar como nueva".
    }
    final nombreCtrl = TextEditingController();
    final guardar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StyledDialog(
        accentColor: AppColors.blue1,
        icon: Icons.bookmark_add_outlined,
        titulo: 'Guardar lista',
        content: [
          Text(
            'Se guarda en este celular con la fecha y hora de hoy. '
            'Podrás re-abrirla desde el ícono de historial.',
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 10),
          CustomText(
            controller: nombreCtrl,
            label: 'Nombre (opcional)',
            hintText: 'ej. Cliente Juan / obra San Martín',
            borderColor: AppColors.blue1,
          ),
        ],
        actions: [
          Expanded(
            child: CustomButton(
              text: 'Cancelar',
              isOutlined: true,
              borderColor: Colors.grey.shade400,
              textColor: Colors.grey.shade700,
              enableShadows: false,
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
          ),
          Expanded(
            child: CustomButton(
              text: 'Guardar',
              backgroundColor: AppColors.blue1,
              textColor: Colors.white,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ),
        ],
      ),
    );
    if (guardar != true || !mounted) return;

    final nombre = nombreCtrl.text.trim();
    final lista = ListaMostradorGuardada(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fecha: DateTime.now(),
      nombre: nombre.isEmpty ? null : nombre,
      sedeId: _sedeId,
      sedeNombre: _sedeNombre,
      items: List.of(_items),
    );
    await ListasMostradorStore.guardar(lista);
    if (!mounted) return;
    // A partir de aquí se trabaja "sobre" esta lista: el próximo guardar
    // ofrecerá actualizarla.
    _listaCargadaId = lista.id;
    _listaCargadaNombre = lista.nombre;
    _listaCargadaFecha = lista.fecha;
    _feedback(
      'Lista guardada${nombre.isEmpty ? '' : ' — "$nombre"'} ✓',
      ok: true,
    );
  }

  /// Historial de listas guardadas: abrir una (reemplaza la actual) o
  /// eliminarla.
  Future<void> _verListasGuardadas() async {
    var listas = await ListasMostradorStore.cargar();
    if (!mounted) return;
    final elegida = await showModalBottomSheet<ListaMostradorGuardada>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Listas guardadas${listas.isEmpty ? '' : ' (${listas.length})'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (listas.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    child: Text(
                      'Aún no hay listas guardadas. Arma una lista y tócale '
                      'el ícono de guardar.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: listas.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (_, i) {
                        final l = listas[i];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.receipt_long_outlined,
                            size: 18,
                            color: AppColors.blue1,
                          ),
                          title: Text(
                            l.nombre ?? 'Lista del ${_fmtFecha(l.fecha)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${l.nombre != null ? '${_fmtFecha(l.fecha)} · ' : ''}'
                            '${l.sedeNombre != null ? '${l.sedeNombre} · ' : ''}'
                            '${l.items.length} producto${l.items.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'S/ ${l.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.blue1,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.red.shade400,
                                ),
                                onPressed: () async {
                                  final ok = await ConfirmDialog.show(
                                    context: ctx,
                                    type: ConfirmDialogType.destructive,
                                    title: 'Eliminar lista',
                                    message:
                                        '¿Eliminar "${l.nombre ?? 'Lista del ${_fmtFecha(l.fecha)}'}"? '
                                        'Esta acción no se puede deshacer.',
                                    confirmText: 'Eliminar',
                                    icon: Icons.delete_outline,
                                  );
                                  if (ok != true) return;
                                  await ListasMostradorStore.eliminar(l.id);
                                  setLocal(
                                    () =>
                                        listas = List.of(listas)
                                          ..removeWhere((x) => x.id == l.id),
                                  );
                                },
                              ),
                            ],
                          ),
                          onTap: () => Navigator.pop(ctx, l),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
    if (elegida == null || !mounted) return;
    await _cargarLista(elegida);
  }

  /// Restaura una lista guardada como lista actual (los precios son el
  /// snapshot del momento en que se guardó). Si la sede guardada sigue
  /// operable y es otra, se cambia y recarga el catálogo de esa sede.
  Future<void> _cargarLista(ListaMostradorGuardada l) async {
    if (_items.isNotEmpty) {
      final ok = await ConfirmDialog.show(
        context: context,
        type: ConfirmDialogType.destructive,
        title: 'Abrir lista guardada',
        message:
            'La lista actual (${_items.length} '
            'producto${_items.length == 1 ? '' : 's'}) se reemplazará. '
            '¿Continuar?',
        confirmText: 'Abrir',
        icon: Icons.folder_open_outlined,
      );
      if (ok != true || !mounted) return;
    }

    setState(() {
      _items
        ..clear()
        ..addAll(l.items);
      _seleccionados.clear();
      // Recordar de qué lista guardada viene → guardar ofrece actualizar.
      _listaCargadaId = l.id;
      _listaCargadaNombre = l.nombre;
      _listaCargadaFecha = l.fecha;
      _query = '';
      _serverQuery = null;
      _autoAgregarDeScan = false;
    });
    _searchCtrl.clear();

    // Volver a la sede con la que se cotizó (si sigue siendo operable).
    if (l.sedeId != null && l.sedeId != _sedeId) {
      final operables = context.read<SedeActivaCubit>().state.operables;
      if (operables.any((s) => s.id == l.sedeId)) {
        setState(() => _sedeId = l.sedeId);
        final ctxState = context.read<EmpresaContextCubit>().state;
        if (ctxState is EmpresaContextLoaded) {
          _productosCubit.loadProductos(
            empresaId: ctxState.context.empresa.id,
            sedeId: l.sedeId,
            filtros: const ProductoFiltros(isActive: true, esInsumo: false),
          );
        }
      }
    }
    _feedback(
      'Lista del ${_fmtFecha(l.fecha)} abierta '
      '(${l.items.length} producto${l.items.length == 1 ? '' : 's'})',
      ok: true,
    );
  }

  // ── Imprimir ───────────────────────────────────────────────────────

  /// Cache de nombre comercial + teléfono efectivos para el encabezado
  /// del ticket (evita pegarle al server en cada impresión).
  String? _empNombreTicket;
  String? _empTelefonoTicket;
  String? _empDatosSedeId;

  /// Nombre comercial y teléfono EFECTIVOS (config sede > empresa) —
  /// mismo origen que el ticket de venta (getConfiguracionSunat), con
  /// fallback a la entidad Empresa si el server no responde.
  Future<(String?, String?)> _datosEmpresaTicket() async {
    if (_empDatosSedeId == _sedeId &&
        (_empNombreTicket != null || _empTelefonoTicket != null)) {
      return (_empNombreTicket, _empTelefonoTicket);
    }
    // Fallbacks locales ANTES del await (evita usar context tras el gap).
    String? nombre;
    String? telefono;
    final ctxState = context.read<EmpresaContextCubit>().state;
    if (ctxState is EmpresaContextLoaded) {
      nombre = ctxState.context.empresa.nombre;
      telefono = ctxState.context.empresa.telefono;
    }
    try {
      final config = await locator<VentaRemoteDataSource>()
          .getConfiguracionSunat(sedeId: _sedeId);
      final nc = config['nombreComercial'] as String?;
      final tel = config['telefono'] as String?;
      if (nc != null && nc.isNotEmpty) nombre = nc;
      if (tel != null && tel.isNotEmpty) telefono = tel;
    } catch (_) {}
    _empNombreTicket = nombre;
    _empTelefonoTicket = telefono;
    _empDatosSedeId = _sedeId;
    return (nombre, telefono);
  }

  /// Texto de la lista para WhatsApp (mismo contenido que el ticket).
  String _textoLista(bool conPrecios) {
    final sedeNombre = _sedeNombre;
    final now = DateTime.now();
    final fecha =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final b = StringBuffer();
    b.writeln('*COTIZACION DE PRECIOS*');
    if (sedeNombre != null) b.writeln('$sedeNombre - $fecha');
    b.writeln();
    var i = 0;
    for (final item in _items) {
      i++;
      final cant = item.cantidad % 1 == 0
          ? item.cantidad.toStringAsFixed(0)
          : item.cantidad.toStringAsFixed(2);
      if (conPrecios) {
        final etiquetas = <String>[
          if (item.enLiquidacion) 'LIQUIDACION',
          if (item.enOferta) 'OFERTA',
          if (item.nivelAplicado != null) 'X MAYOR',
        ];
        b.writeln('$i. ${item.descripcion}');
        b.writeln(
          '    $cant x S/ ${item.precioUnitario.toStringAsFixed(2)} = S/ ${item.total.toStringAsFixed(2)}'
          '${etiquetas.isNotEmpty ? ' (${etiquetas.join('/')})' : ''}',
        );
      } else {
        b.writeln('$i. ${item.descripcion} - $cant und');
      }
    }
    b.writeln();
    b.writeln('*TOTAL: S/ ${_total.toStringAsFixed(2)}*');
    b.writeln();
    b.write('Precios referenciales del dia. No es comprobante de pago.');
    return b.toString();
  }

  /// PDF de la lista (A5 vertical): tabla con o sin precios + total.
  Future<Uint8List> _generarPdf(bool conPrecios) async {
    final sedeNombre = _sedeNombre;
    final now = DateTime.now();
    final fecha =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final doc = pw.Document();

    pw.Widget celda(
      String t, {
      bool bold = false,
      pw.TextAlign align = pw.TextAlign.left,
    }) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        child: pw.Text(
          t,
          textAlign: align,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'COTIZACIÓN DE PRECIOS',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Center(
              child: pw.Text(
                CalculoMostradorEscPosGenerator.sanitize(
                  '${sedeNombre != null ? '$sedeNombre - ' : ''}$fecha',
                ),
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: PdfColors.grey700,
                ),
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: conPrecios
                  ? {
                      0: const pw.FlexColumnWidth(5),
                      1: const pw.FlexColumnWidth(1.2),
                      2: const pw.FlexColumnWidth(1.6),
                      3: const pw.FlexColumnWidth(1.8),
                    }
                  : {
                      0: const pw.FlexColumnWidth(6),
                      1: const pw.FlexColumnWidth(1.2),
                    },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    celda('PRODUCTO', bold: true),
                    celda('CANT.', bold: true, align: pw.TextAlign.center),
                    if (conPrecios)
                      celda('PRECIO', bold: true, align: pw.TextAlign.right),
                    if (conPrecios)
                      celda('TOTAL', bold: true, align: pw.TextAlign.right),
                  ],
                ),
                ...List.generate(_items.length, (i) {
                  final item = _items[i];
                  final cant = item.cantidad % 1 == 0
                      ? item.cantidad.toStringAsFixed(0)
                      : item.cantidad.toStringAsFixed(2);
                  final etiquetas = <String>[
                    if (item.enLiquidacion) 'LIQUIDACIÓN',
                    if (item.enOferta) 'OFERTA',
                    if (item.nivelAplicado != null) 'X MAYOR',
                  ];
                  return pw.TableRow(
                    children: [
                      celda(
                        CalculoMostradorEscPosGenerator.sanitize(
                          '${i + 1}. ${item.descripcion}'
                          '${conPrecios && etiquetas.isNotEmpty ? '  (${etiquetas.join('/')})' : ''}',
                        ),
                      ),
                      celda(cant, align: pw.TextAlign.center),
                      if (conPrecios)
                        celda(
                          item.precioUnitario.toStringAsFixed(2),
                          align: pw.TextAlign.right,
                        ),
                      if (conPrecios)
                        celda(
                          item.total.toStringAsFixed(2),
                          align: pw.TextAlign.right,
                        ),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'TOTAL: S/ ${_total.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Center(
              child: pw.Text(
                'Precios referenciales del día. NO es comprobante de pago.',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  /// Compartir la lista: como TEXTO directo al WhatsApp del cliente
  /// (celular +51) o como PDF (hoja de compartir del sistema — ahí se
  /// elige WhatsApp y el contacto; wa.me no permite adjuntar archivos).
  Future<void> _compartirWhatsApp() async {
    final telCtrl = TextEditingController();
    var conPrecios = true;
    var comoPdf = true;
    const verde = Color(0xFF25D366);
    final enviar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => StyledDialog(
          accentColor: verde,
          icon: Icons.share,
          titulo: 'Compartir lista',
          content: [
            // Formato: PDF (share sheet) o texto directo al número.
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('PDF', style: TextStyle(fontSize: 11)),
                    selected: comoPdf,
                    selectedColor: verde.withValues(alpha: 0.15),
                    onSelected: (_) => setLocal(() => comoPdf = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text(
                      'Texto al número',
                      style: TextStyle(fontSize: 11),
                    ),
                    selected: !comoPdf,
                    selectedColor: verde.withValues(alpha: 0.15),
                    onSelected: (_) => setLocal(() => comoPdf = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text(
                      'Con precios',
                      style: TextStyle(fontSize: 11),
                    ),
                    selected: conPrecios,
                    selectedColor: verde.withValues(alpha: 0.15),
                    onSelected: (_) => setLocal(() => conPrecios = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text(
                      'Solo productos',
                      style: TextStyle(fontSize: 11),
                    ),
                    selected: !conPrecios,
                    selectedColor: verde.withValues(alpha: 0.15),
                    onSelected: (_) => setLocal(() => conPrecios = false),
                  ),
                ),
              ],
            ),
            if (!comoPdf) ...[
              const SizedBox(height: 10),
              CustomText(
                controller: telCtrl,
                label: 'Celular del cliente (+51)',
                hintText: '9XXXXXXXX',
                borderColor: verde,
                keyboardType: TextInputType.phone,
              ),
            ],
          ],
          actions: [
            Expanded(
              child: CustomButton(
                text: 'Cancelar',
                isOutlined: true,
                borderColor: Colors.grey.shade400,
                textColor: Colors.grey.shade700,
                enableShadows: false,
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            ),
            Expanded(
              child: CustomButton(
                text: 'Enviar',
                backgroundColor: verde,
                textColor: Colors.white,
                onPressed: () {
                  if (!comoPdf) {
                    final digits = telCtrl.text.replaceAll(
                      RegExp(r'[^0-9]'),
                      '',
                    );
                    if (digits.length != 9) return;
                  }
                  Navigator.of(ctx).pop(true);
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (enviar != true || !mounted) return;

    try {
      if (comoPdf) {
        final bytes = await _generarPdf(conPrecios);
        final dir = await getTemporaryDirectory();
        final file = File(
          '${dir.path}/cotizacion_precios_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Cotización de precios');
      } else {
        final digits = telCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
        final texto = Uri.encodeComponent(_textoLista(conPrecios));
        await launchUrl(
          Uri.parse('https://wa.me/51$digits?text=$texto'),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {
      if (mounted) _feedback('No se pudo compartir la lista', ok: false);
    }
  }

  /// Elegir qué imprimir: lista completa (con precios por item), completa
  /// + niveles por mayor, o "muda" (solo productos + total general).
  Future<void> _elegirImpresion() async {
    final modo = await showModalBottomSheet<_ModoImpresion>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                '¿Qué imprimir?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              dense: true,
              leading: Icon(Icons.receipt_long, color: AppColors.blue1),
              title: const Text(
                'Lista completa',
                style: TextStyle(fontSize: 12.5),
              ),
              subtitle: Text(
                'Precio y total por producto',
                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
              ),
              onTap: () => Navigator.pop(ctx, _ModoImpresion.completa),
            ),
            ListTile(
              dense: true,
              leading: Icon(Icons.sell_outlined, color: AppColors.blue1),
              title: const Text(
                'Completa + precios por mayor',
                style: TextStyle(fontSize: 12.5),
              ),
              subtitle: Text(
                'Cada producto con sus precios de nivel (3+, 12+…)',
                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
              ),
              onTap: () => Navigator.pop(ctx, _ModoImpresion.conMayor),
            ),
            ListTile(
              dense: true,
              leading: Icon(Icons.checklist, color: AppColors.blue1),
              title: const Text(
                'Solo productos y total',
                style: TextStyle(fontSize: 12.5),
              ),
              subtitle: Text(
                'Sin precios por item — solo el total general',
                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
              ),
              onTap: () => Navigator.pop(ctx, _ModoImpresion.muda),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
    if (modo == null || !mounted) return;
    await _imprimir(
      conPrecios: modo != _ModoImpresion.muda,
      conNiveles: modo == _ModoImpresion.conMayor,
    );
  }

  Future<void> _imprimir(
      {required bool conPrecios, bool conNiveles = false}) async {
    if (_items.isEmpty || _imprimiendo) return;
    setState(() {
      _imprimiendo = true;
      _msgImpresion = null;
    });
    try {
      final manager = locator<ImpresorasManager>();
      final principal = await manager.getPrincipal();
      if (!mounted) return;
      if (principal == null) {
        _feedback('No hay impresora principal configurada', ok: false);
        return;
      }
      final (nombreEmp, telEmp) = await _datosEmpresaTicket();
      if (!mounted) return;
      final bytes = await CalculoMostradorEscPosGenerator.generate(
        items: _items,
        sedeNombre: _sedeNombre,
        sedeDireccion: _sedeDireccion,
        paperWidth: principal.anchoPapel.mm,
        conPrecios: conPrecios,
        conNiveles: conNiveles,
        empresaNombre: nombreEmp,
        empresaTelefono: telEmp,
      );
      final ok = await manager.imprimirEnPrincipal(bytes);
      if (!mounted) return;
      _feedback(
        ok
            ? 'Lista impresa'
            : 'No se pudo conectar a "${principal.nombre}" — verifica que esté encendida y cerca',
        ok: ok,
      );
    } catch (e) {
      if (mounted) _feedback('Error al imprimir: $e', ok: false);
    } finally {
      if (mounted) setState(() => _imprimiendo = false);
    }
  }

  /// Feedback DENTRO del sheet: un snackbar del root queda tapado por el
  /// modal (parecía que "no hacía nada"). Banner sobre el footer.
  void _feedback(String msg, {required bool ok}) {
    setState(() => _msgImpresion = (msg, ok));
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _msgImpresion?.$1 == msg) {
        setState(() => _msgImpresion = null);
      }
    });
  }

  // ── UI ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.92,
      // Tocar cualquier zona "muerta" del sheet cierra el teclado y
      // saca el foco del buscador (los taps sobre filas/botones los
      // consumen ellos mismos y no llegan aquí).
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _header(),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: CustomSearchField(
                  controller: _searchCtrl,
                  borderColor: AppColors.blue1,
                  hintText: 'Buscar por nombre, código o escanear…',
                  debounceDelay: const Duration(milliseconds: 200),
                  onChanged: (v) {
                    _serverDebounce?.cancel();
                    final q = v.trim();
                    final habiaServer = _serverQuery != null;
                    setState(() {
                      _query = q;
                      _serverQuery = null;
                      _autoAgregarDeScan = false;
                    });
                    if (_pareceCodigo(q)) {
                      // Tipear un código a mano también busca en el server
                      // (codigoBarras no vive en el catálogo local).
                      _serverDebounce = Timer(
                        const Duration(milliseconds: 350),
                        () {
                          if (mounted && _query == q) {
                            _buscarServer(q, autoAgregar: false);
                          }
                        },
                      );
                    } else if (q.length >= 3) {
                      // Búsqueda HÍBRIDA por nombre: lo local pinta al
                      // instante, pero el catálogo local se llena en
                      // background (prefetch por lotes) y puede no tener
                      // aún todos los productos — el server completa.
                      _serverDebounce = Timer(
                        const Duration(milliseconds: 450),
                        () {
                          if (mounted && _query == q) {
                            _buscarServer(q, autoAgregar: false);
                          }
                        },
                      );
                    } else if (habiaServer) {
                      _restaurarCatalogo();
                    }
                  },
                  onClear: _limpiarBusqueda,
                  actionButtons: [
                    BarcodeScannerButton(
                      onScanned: _onCodigoEscaneado,
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
              Expanded(child: _query.length >= 2 ? _resultados() : _lista()),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final sedeState = context.watch<SedeActivaCubit>().state;
    final sedeNombre =
        sedeState.operables
            .where((s) => s.id == _sedeId)
            .map((s) => s.nombre)
            .firstOrNull ??
        sedeState.activa?.nombre ??
        '';
    final puedeElegir = sedeState.operables.length > 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.blue1.withValues(alpha: 0.06),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Row(
        children: [
          Icon(Icons.calculate_outlined, color: AppColors.blue1, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Calculadora de precios',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                // Sede de donde salen precios y stock. Cambiarla aquí es
                // LOCAL a la calculadora (no toca la sede activa global).
                InkWell(
                  onTap: puedeElegir ? _elegirSede : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 11,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          sedeNombre,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (puedeElegir)
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 13,
                          color: Colors.grey.shade600,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Acción de selección múltiple SIEMPRE a la vista (el teclado
          // tapa el pie del sheet mientras se busca). Cuando no hay
          // selección activa pero SÍ lista armada, su lugar lo ocupa el
          // guardar rápido (mismo motivo: el footer queda tapado/copado).
          if (_seleccionados.isNotEmpty) ...[
            _pillAgregarSeleccion(),
            const SizedBox(width: 4),
          ] else if (_items.isNotEmpty)
            IconButton(
              icon: Icon(Icons.bookmark_add_outlined,
                  size: 20, color: AppColors.blue1),
              tooltip: 'Guardar lista',
              onPressed: _guardarLista,
            ),
          IconButton(
            icon: Icon(Icons.history, size: 20, color: AppColors.blue1),
            tooltip: 'Listas guardadas',
            onPressed: _verListasGuardadas,
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Cambiar la sede de la calculadora: precios/stock pasan a ser de esa
  /// sede. Si ya hay items en la lista se limpia (fueron cotizados con
  /// los precios de la sede anterior).
  Future<void> _elegirSede() async {
    final operables = context.read<SedeActivaCubit>().state.operables;
    final elegida = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Sede de precios y stock',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
            ...operables.map(
              (s) => ListTile(
                dense: true,
                leading: Icon(
                  s.id == _sedeId
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 18,
                  color: s.id == _sedeId ? AppColors.blue1 : Colors.grey,
                ),
                title: Text(s.nombre, style: const TextStyle(fontSize: 12.5)),
                onTap: () => Navigator.pop(ctx, s.id),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
    if (elegida == null || elegida == _sedeId || !mounted) return;

    if (_items.isNotEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StyledDialog(
          accentColor: Colors.orange.shade800,
          icon: Icons.storefront_outlined,
          titulo: 'Cambiar de sede',
          content: [
            Text(
              'La lista actual se cotizó con los precios de la otra sede '
              'y se limpiará. ¿Continuar?',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
          actions: [
            Expanded(
              child: CustomButton(
                text: 'Cancelar',
                isOutlined: true,
                borderColor: Colors.grey.shade400,
                textColor: Colors.grey.shade700,
                enableShadows: false,
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            ),
            Expanded(
              child: CustomButton(
                text: 'Cambiar',
                backgroundColor: Colors.orange.shade800,
                textColor: Colors.white,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }

    setState(() {
      _sedeId = elegida;
      _items.clear();
      // Los seleccionados pendientes también son de la sede anterior.
      _seleccionados.clear();
      _productosDeItems.clear();
      _listaCargadaId = null;
      _listaCargadaNombre = null;
      _listaCargadaFecha = null;
      _query = '';
      _serverQuery = null;
      _autoAgregarDeScan = false;
    });
    _searchCtrl.clear();
    // Recargar el catálogo de la nueva sede (precios/stock por sede).
    final ctxState = context.read<EmpresaContextCubit>().state;
    if (ctxState is EmpresaContextLoaded) {
      // El cubit warm ahora queda cargado con esta sede.
      _cubitWarmKey = '${ctxState.context.empresa.id}|$elegida';
      _productosCubit.loadProductos(
        empresaId: ctxState.context.empresa.id,
        sedeId: elegida,
        filtros: const ProductoFiltros(isActive: true, esInsumo: false),
      );
    }
  }

  /// Resultados de búsqueda sobre el catálogo LOCAL ya cargado.
  Widget _resultados() {
    return BlocBuilder<ProductoListCubit, ProductoListState>(
      bloc: _productosCubit,
      builder: (context, state) {
        if (state is! ProductoListLoaded) {
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        // Búsqueda por código (escaneada o tipeada): el server ya filtró
        // exacto — mostrar tal cual (el filtro local por nombre
        // descartaría el match) y auto-agregar solo si vino del escáner.
        if (_serverQuery != null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _autoAgregarSiUnico(state),
          );
        }
        final q = _query.toLowerCase();
        // ¿La respuesta del SERVER para esta búsqueda ya llegó? Mientras
        // está en vuelo, state.productos sigue siendo el catálogo previo →
        // se filtra LOCAL (respuesta instantánea) y se marca "buscando…".
        final serverListo =
            _serverQuery != null &&
            state.filtros.search == _serverQuery &&
            !state.isFiltering;
        final esperandoServer = _serverQuery != null && !serverListo;
        final matches = serverListo
            ? state.productos.where((p) => !p.esCombo).take(15).toList()
            : state.productos
                  .where(
                    (p) =>
                        !p.esCombo &&
                        (p.nombre.toLowerCase().contains(q) ||
                            p.codigoEmpresa.toLowerCase().contains(q) ||
                            (p.variantes ?? []).any(
                              (v) => v.nombre.toLowerCase().contains(q),
                            )),
                  )
                  .take(15)
                  .toList();
        if (matches.isEmpty) {
          // Con el server aún buscando no se afirma "sin resultados":
          // el catálogo local puede no tener el producto todavía.
          return Center(
            child: esperandoServer
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Sin resultados para "$_query"',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
          );
        }
        final sedeId = _sedeId!;
        return ListView.separated(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: matches.length + (esperandoServer ? 1 : 0),
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: Colors.grey.shade100),
          itemBuilder: (_, i) {
            // Fila extra al final mientras el server completa la búsqueda.
            if (i >= matches.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Buscando más resultados…',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            }
            final p = matches[i];
            final precio = p.tieneVariantes
                ? null
                : (p.precioEfectivoEnSede(sedeId) ?? p.precioEnSede(sedeId));
            final stock = p.tieneVariantes
                ? p.stockConsolidadoEnSede(sedeId)
                : (p.stockEnSede(sedeId) ?? 0);
            // ¿Ya está en la lista? A nivel PRODUCTO (agrega todas sus
            // variantes): con nombres parecidos el vendedor necesita ver
            // de un vistazo cuáles ya sumó. El detalle por variante se ve
            // dentro del selector de variantes.
            final itemsDeEste = _items
                .where((it) => it.productoId == p.id)
                .toList();
            final enLista = itemsDeEste.isNotEmpty;
            final cantEnLista = itemsDeEste.fold<double>(
              0,
              (s, it) => s + it.cantidad,
            );
            final cantTxt = cantEnLista % 1 == 0
                ? cantEnLista.toStringAsFixed(0)
                : cantEnLista.toStringAsFixed(2);
            // Checkbox de selección múltiple solo para productos SIN
            // variantes (una variante se elige en su selector). Con
            // selección activa, tocar la fila también marca/desmarca.
            final seleccionable = !p.tieneVariantes;
            final seleccionado = _seleccionados.containsKey(p.id);
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 6),
              minLeadingWidth: 28,
              horizontalTitleGap: 4,
              leading: seleccionable
                  ? SizedBox(
                      width: 28,
                      height: 28,
                      child: Checkbox(
                        value: seleccionado,
                        activeColor: AppColors.blue1,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide(
                          color: Colors.grey.shade400,
                          width: 1.2,
                        ),
                        onChanged: (_) => _toggleSeleccion(p),
                      ),
                    )
                  : const SizedBox(width: 28),
              tileColor: seleccionado
                  ? AppColors.blue1.withValues(alpha: 0.06)
                  : enLista
                  ? Colors.green.shade50.withValues(alpha: 0.6)
                  : null,
              title: Row(
                children: [
                  if (enLista) ...[
                    Icon(
                      Icons.check_circle,
                      size: 13,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      p.nombre,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text.rich(
                TextSpan(
                  text:
                      '${p.codigoEmpresa} · Stock: $stock'
                      '${p.tieneVariantes ? ' · ${p.variantes?.length ?? 0} variantes' : ''}',
                  children: [
                    if (enLista)
                      TextSpan(
                        text: p.tieneVariantes && itemsDeEste.length > 1
                            ? ' · En lista: ${itemsDeEste.length} variantes ($cantTxt und)'
                            : ' · En lista: $cantTxt und',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
              ),
              trailing: precio != null
                  ? Text(
                      'S/ ${precio.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : const Icon(Icons.chevron_right, size: 18),
              onTap: () {
                // En "modo selección" (hay marcados) tocar la fila
                // marca/desmarca; sin selección, agrega directo como
                // siempre. Variantes siempre abren su selector.
                if (_seleccionados.isNotEmpty && seleccionable) {
                  _toggleSeleccion(p);
                } else {
                  _seleccionar(p);
                }
              },
            );
          },
        );
      },
    );
  }

  /// Lista enumerada de lo que el cliente va preguntando.
  Widget _lista() {
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calculate_outlined,
              size: 52,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 10),
            Text(
              'Busca productos y ve sumando precios',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
            ),
            Text(
              'La lista se imprime como cotización de mostrador',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      itemCount: _items.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: Colors.grey.shade100),
      itemBuilder: (_, i) => _itemRow(i),
    );
  }

  Widget _itemRow(int i) {
    final item = _items[i];
    final tieneEspecial = item.nivelAplicado != null;
    final antes = item.precioAntesOferta;
    final muestraTachado =
        (item.enOferta || item.enLiquidacion) &&
        antes != null &&
        antes > item.precioUnitario + 0.005;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '${i + 1}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.descripcion,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    if (item.enLiquidacion)
                      _chip('LIQUIDACIÓN', Colors.red.shade700),
                    if (item.enOferta) _chip('OFERTA', Colors.orange.shade800),
                    if (tieneEspecial)
                      _chip(item.nivelAplicado!, Colors.green.shade700),
                    // Niveles por mayor como labels informativos.
                    ...item.niveles.take(3).map((n) {
                      final precioNivel =
                          n.precio ??
                          ((item.precioBase ?? item.precioUnitario) *
                              (1 - (n.porcentajeDesc ?? 0) / 100));
                      return _chip(
                        '${n.cantidadMinima}+ → S/ ${precioNivel.toStringAsFixed(2)}',
                        AppColors.blue1,
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (muestraTachado)
                Text(
                  antes.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Colors.grey.shade400,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              Text(
                'S/ ${item.precioUnitario.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: tieneEspecial
                      ? Colors.green.shade700
                      : (item.enOferta || item.enLiquidacion)
                      ? Colors.orange.shade800
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Stepper de cantidad
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _stepBtn(Icons.remove, () => _cambiarCantidad(i, -1)),
              SizedBox(
                width: 26,
                child: Center(
                  child: Text(
                    item.cantidad % 1 == 0
                        ? item.cantidad.toStringAsFixed(0)
                        : item.cantidad.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              _stepBtn(Icons.add, () => _cambiarCantidad(i, 1)),
            ],
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 55,
            child: Text(
              'S/ ${item.total.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.blue1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: Icon(icon, size: 14, color: Colors.grey.shade700),
      ),
    );
  }

  /// Píldora "Agregar (N) | ✕" en el HEADER mientras hay seleccionados:
  /// siempre visible aunque el teclado esté abierto (la barra al pie
  /// quedaba tapada y el footer ya está copado de botones).
  Widget _pillAgregarSeleccion() {
    final n = _seleccionados.length;
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.blue1,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue1.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(15),
            ),
            onTap: _agregarSeleccionados,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 8, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.playlist_add, size: 15, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'Agregar ($n)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 1,
            height: 16,
            color: Colors.white.withValues(alpha: 0.35),
          ),
          // Cancelar la selección sin agregar.
          InkWell(
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(15),
            ),
            onTap: () => setState(() => _seleccionados.clear()),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 7),
              child: Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        8,
        14,
        10 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_msgImpresion != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _msgImpresion!.$2
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _msgImpresion!.$2
                      ? Colors.green.shade300
                      : Colors.orange.shade300,
                  width: 0.6,
                ),
              ),
              child: Text(
                _msgImpresion!.$1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _msgImpresion!.$2
                      ? Colors.green.shade800
                      : Colors.orange.shade900,
                ),
              ),
            ),
          Row(
            children: [
              Text(
                '${_items.length} producto${_items.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const Spacer(),
              const Text(
                'TOTAL  ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'S/ ${_total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blue1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _items.isEmpty
                      ? null
                      : () => setState(() {
                            _items.clear();
                            // Lista nueva desde cero: soltar el vínculo
                            // con la guardada que estaba abierta.
                            _listaCargadaId = null;
                            _listaCargadaNombre = null;
                            _listaCargadaFecha = null;
                          }),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Limpiar', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Guardar la lista en el celular (historial local)
              SizedBox(
                width: 46,
                child: OutlinedButton(
                  onPressed: _items.isEmpty ? null : _guardarLista,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blue1,
                    side: const BorderSide(color: AppColors.blue1),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Icon(Icons.bookmark_add_outlined, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              // Compartir por WhatsApp (celular del cliente)
              SizedBox(
                width: 46,
                child: OutlinedButton(
                  onPressed: _items.isEmpty ? null : _compartirWhatsApp,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF25D366),
                    side: const BorderSide(color: Color(0xFF25D366)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Icon(Icons.share, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _items.isEmpty || _imprimiendo
                      ? null
                      : _elegirImpresion,
                  icon: _imprimiendo
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.print_outlined, size: 16),
                  label: const Text(
                    'Imprimir lista',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue1,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Cierra el ciclo cotización → venta: "ya, me llevo estas".
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _items.isEmpty ? null : _pasarAVentaRapida,
              icon: const Icon(Icons.point_of_sale, size: 16),
              label: const Text(
                'Pasar a Venta Rápida',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modo del ticket de la calculadora: completa, completa con niveles por
/// mayor, o "muda" (solo productos + total).
enum _ModoImpresion { completa, conMayor, muda }
