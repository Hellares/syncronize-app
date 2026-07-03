import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
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
import '../../../producto/presentation/bloc/producto_list/producto_list_cubit.dart';
import '../../../producto/presentation/bloc/producto_list/producto_list_state.dart';
import '../../../venta/domain/entities/venta_detalle_input.dart';
import '../services/calculo_mostrador_esc_pos_generator.dart';

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

  String? _sedeId;
  String _query = '';
  final List<VentaDetalleInput> _items = [];
  bool _imprimiendo = false;

  @override
  void initState() {
    super.initState();
    _productosCubit = locator<ProductoListCubit>();
    // Contexto: empresa + sede activa global (los providers de main están
    // por encima del navigator raíz).
    final ctxState = context.read<EmpresaContextCubit>().state;
    final sede = context.read<SedeActivaCubit>().state.activa;
    _sedeId = sede?.id;
    if (ctxState is EmpresaContextLoaded && _sedeId != null) {
      _productosCubit.loadProductos(
        empresaId: ctxState.context.empresa.id,
        sedeId: _sedeId,
        filtros: const ProductoFiltros(isActive: true, esInsumo: false),
      );
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _productosCubit.close();
    super.dispose();
  }

  double get _total => _items.fold(0, (s, i) => s + i.total);

  // ── Agregar / quitar / cantidades ──────────────────────────────────

  Future<void> _agregar(ProductoListItem p, {ProductoVariante? v}) async {
    final sedeId = _sedeId!;
    // Ambos mezclan StockPorSedeMixin (precio/oferta/stock por sede).
    final StockPorSedeMixin fuente = v ?? p;
    final precio =
        fuente.precioEfectivoEnSede(sedeId) ?? fuente.precioEnSede(sedeId) ?? 0;
    if (precio <= 0) return;

    // Dedupe: mismo producto/variante → +1 cantidad.
    final idx = _items.indexWhere(
        (i) => i.productoId == p.id && i.varianteId == (v?.id));
    if (idx >= 0) {
      setState(() {
        _items[idx] =
            _items[idx].recalcularPrecioPorNiveles(_items[idx].cantidad + 1);
      });
      _limpiarBusqueda();
      return;
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
      precioAntesOferta:
          (enOferta || enLiquidacion) ? fuente.precioEnSede(sedeId) : null,
    ).recalcularPrecioPorNiveles(1);

    if (!mounted) return;
    setState(() => _items.add(item));
    _limpiarBusqueda();
  }

  void _limpiarBusqueda() {
    _searchCtrl.clear();
    setState(() => _query = '');
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
      final v = await _elegirVariante(p, variantes);
      if (v != null) await _agregar(p, v: v);
    } else {
      await _agregar(p);
    }
  }

  Future<ProductoVariante?> _elegirVariante(
      ProductoListItem p, List<ProductoVariante> variantes) {
    final sedeId = _sedeId!;
    return showModalBottomSheet<ProductoVariante>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(p.nombre,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: variantes.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (_, i) {
                  final v = variantes[i];
                  final precio = v.precioEfectivoEnSede(sedeId) ??
                      v.precioEnSede(sedeId) ??
                      0;
                  final stock = v.stockEnSede(sedeId) ?? 0;
                  return ListTile(
                    dense: true,
                    title: Text(v.nombre,
                        style: const TextStyle(fontSize: 12.5)),
                    subtitle: Text('Stock: $stock',
                        style: TextStyle(
                            fontSize: 10.5, color: Colors.grey.shade600)),
                    trailing: Text('S/ ${precio.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    onTap: () => Navigator.pop(ctx, v),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Imprimir ───────────────────────────────────────────────────────

  Future<void> _imprimir() async {
    if (_items.isEmpty || _imprimiendo) return;
    setState(() => _imprimiendo = true);
    try {
      final manager = locator<ImpresorasManager>();
      final principal = await manager.getPrincipal();
      if (!mounted) return;
      if (principal == null) {
        _snack('No hay impresora principal configurada', warn: true);
        return;
      }
      final ctxState = context.read<EmpresaContextCubit>().state;
      final sede = context.read<SedeActivaCubit>().state.activa;
      final bytes = await CalculoMostradorEscPosGenerator.generate(
        items: _items,
        empresaNombre: ctxState is EmpresaContextLoaded
            ? ctxState.context.empresa.nombre
            : '',
        sedeNombre: sede?.nombre,
        paperWidth: principal.anchoPapel.mm,
      );
      final ok = await manager.imprimirEnPrincipal(bytes);
      if (!mounted) return;
      _snack(ok ? 'Lista impresa' : 'No se pudo imprimir', warn: !ok);
    } catch (e) {
      if (mounted) _snack('Error al imprimir', warn: true);
    } finally {
      if (mounted) setState(() => _imprimiendo = false);
    }
  }

  void _snack(String msg, {bool warn = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: warn ? Colors.orange.shade700 : Colors.green.shade600,
      duration: const Duration(seconds: 2),
    ));
  }

  // ── UI ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.92,
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
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Buscar producto por nombre o código…',
                  hintStyle:
                      TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: _limpiarBusqueda,
                        )
                      : null,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.blueborder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.blueborder),
                  ),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Expanded(
              child: _query.length >= 2 ? _resultados() : _lista(),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.blue1.withValues(alpha: 0.06),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(Icons.calculate_outlined, color: AppColors.blue1, size: 22),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Calculadora de precios',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
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
                  child: CircularProgressIndicator(strokeWidth: 2)));
        }
        final q = _query.toLowerCase();
        final matches = state.productos
            .where((p) =>
                !p.esCombo &&
                (p.nombre.toLowerCase().contains(q) ||
                    p.codigoEmpresa.toLowerCase().contains(q) ||
                    (p.variantes ?? [])
                        .any((v) => v.nombre.toLowerCase().contains(q))))
            .take(15)
            .toList();
        if (matches.isEmpty) {
          return Center(
            child: Text('Sin resultados para "$_query"',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          );
        }
        final sedeId = _sedeId!;
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: matches.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: Colors.grey.shade100),
          itemBuilder: (_, i) {
            final p = matches[i];
            final precio = p.tieneVariantes
                ? null
                : (p.precioEfectivoEnSede(sedeId) ?? p.precioEnSede(sedeId));
            final stock = p.tieneVariantes
                ? p.stockConsolidadoEnSede(sedeId)
                : (p.stockEnSede(sedeId) ?? 0);
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(p.nombre,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${p.codigoEmpresa} · Stock: $stock'
                '${p.tieneVariantes ? ' · ${p.variantes?.length ?? 0} variantes' : ''}',
                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
              ),
              trailing: precio != null
                  ? Text('S/ ${precio.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700))
                  : const Icon(Icons.chevron_right, size: 18),
              onTap: () => _seleccionar(p),
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
            Icon(Icons.calculate_outlined,
                size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text('Busca productos y ve sumando precios',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500)),
            Text('La lista se imprime como cotización de mostrador',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ],
        ),
      );
    }
    return ListView.separated(
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
    final muestraTachado = (item.enOferta || item.enLiquidacion) &&
        antes != null &&
        antes > item.precioUnitario + 0.005;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            child: Text('${i + 1}',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.descripcion,
                    style: const TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
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
                      final precioNivel = n.precio ??
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
                Text(antes.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 9.5,
                      color: Colors.grey.shade400,
                      decoration: TextDecoration.lineThrough,
                    )),
              Text('S/ ${item.precioUnitario.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: tieneEspecial
                        ? Colors.green.shade700
                        : (item.enOferta || item.enLiquidacion)
                            ? Colors.orange.shade800
                            : null,
                  )),
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
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              _stepBtn(Icons.add, () => _cambiarCantidad(i, 1)),
            ],
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 58,
            child: Text('S/ ${item.total.toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blue1)),
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
      child: Text(text,
          style: TextStyle(
              fontSize: 8.5, fontWeight: FontWeight.w700, color: color)),
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

  Widget _footer() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          14, 10, 14, 10 + MediaQuery.of(context).viewPadding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                '${_items.length} producto${_items.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const Spacer(),
              const Text('TOTAL  ',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
              Text('S/ ${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blue1)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _items.isEmpty
                      ? null
                      : () => setState(() => _items.clear()),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Limpiar', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed:
                      _items.isEmpty || _imprimiendo ? null : _imprimir,
                  icon: _imprimiendo
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.print_outlined, size: 16),
                  label: const Text('Imprimir lista',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue1,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
