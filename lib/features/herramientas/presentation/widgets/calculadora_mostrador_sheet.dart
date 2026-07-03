import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_search_field.dart';
import '../../../../core/widgets/styled_dialog.dart';
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

  /// Resultado de la última impresión (mensaje, éxito) — banner en el sheet.
  (String, bool)? _msgImpresion;

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
                      fontSize: 9, fontWeight: FontWeight.w600)),
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
                        style: const TextStyle(fontSize: 11)),
                    subtitle: Text('Stock: $stock',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade600)),
                    trailing: Text('S/ ${precio.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w600)),
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

  /// Texto de la lista para WhatsApp (mismo contenido que el ticket).
  String _textoLista(bool conPrecios) {
    final sede = context.read<SedeActivaCubit>().state.activa;
    final now = DateTime.now();
    final fecha =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final b = StringBuffer();
    b.writeln('*COTIZACION DE PRECIOS*');
    if (sede != null) b.writeln('${sede.nombre} - $fecha');
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
            '${etiquetas.isNotEmpty ? ' (${etiquetas.join('/')})' : ''}');
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
    final sede = context.read<SedeActivaCubit>().state.activa;
    final now = DateTime.now();
    final fecha =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final doc = pw.Document();

    pw.Widget celda(String t,
        {bool bold = false, pw.TextAlign align = pw.TextAlign.left}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        child: pw.Text(t,
            textAlign: align,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            )),
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
              child: pw.Text('COTIZACIÓN DE PRECIOS',
                  style: pw.TextStyle(
                      fontSize: 13, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Center(
              child: pw.Text(
                CalculoMostradorEscPosGenerator.sanitize(
                    '${sede != null ? '${sede.nombre} - ' : ''}$fecha'),
                style: const pw.TextStyle(
                    fontSize: 8.5, color: PdfColors.grey700),
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
                  decoration:
                      const pw.BoxDecoration(color: PdfColors.grey200),
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
                  return pw.TableRow(children: [
                    celda(
                        CalculoMostradorEscPosGenerator.sanitize(
                            '${i + 1}. ${item.descripcion}'
                            '${conPrecios && etiquetas.isNotEmpty ? '  (${etiquetas.join('/')})' : ''}')),
                    celda(cant, align: pw.TextAlign.center),
                    if (conPrecios)
                      celda(item.precioUnitario.toStringAsFixed(2),
                          align: pw.TextAlign.right),
                    if (conPrecios)
                      celda(item.total.toStringAsFixed(2),
                          align: pw.TextAlign.right),
                  ]);
                }),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('TOTAL: S/ ${_total.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 14),
            pw.Center(
              child: pw.Text(
                'Precios referenciales del día. NO es comprobante de pago.',
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColors.grey700),
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
                    label:
                        const Text('PDF', style: TextStyle(fontSize: 11)),
                    selected: comoPdf,
                    selectedColor: verde.withValues(alpha: 0.15),
                    onSelected: (_) => setLocal(() => comoPdf = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Texto al número',
                        style: TextStyle(fontSize: 11)),
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
                    label: const Text('Con precios',
                        style: TextStyle(fontSize: 11)),
                    selected: conPrecios,
                    selectedColor: verde.withValues(alpha: 0.15),
                    onSelected: (_) => setLocal(() => conPrecios = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Solo productos',
                        style: TextStyle(fontSize: 11)),
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
                    final digits =
                        telCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
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
            '${dir.path}/cotizacion_precios_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Cotización de precios',
        );
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

  /// Elegir qué imprimir: lista completa (con precios por item) o "muda"
  /// (solo productos + cantidad y el total general).
  Future<void> _elegirImpresion() async {
    final conPrecios = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('¿Qué imprimir?',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
            ListTile(
              dense: true,
              leading: Icon(Icons.receipt_long, color: AppColors.blue1),
              title: const Text('Lista completa',
                  style: TextStyle(fontSize: 12.5)),
              subtitle: Text('Precio y total por producto',
                  style:
                      TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
              onTap: () => Navigator.pop(ctx, true),
            ),
            ListTile(
              dense: true,
              leading: Icon(Icons.checklist, color: AppColors.blue1),
              title: const Text('Solo productos y total',
                  style: TextStyle(fontSize: 12.5)),
              subtitle: Text('Sin precios por item — solo el total general',
                  style:
                      TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
              onTap: () => Navigator.pop(ctx, false),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
    if (conPrecios == null || !mounted) return;
    await _imprimir(conPrecios: conPrecios);
  }

  Future<void> _imprimir({required bool conPrecios}) async {
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
      final sede = context.read<SedeActivaCubit>().state.activa;
      final bytes = await CalculoMostradorEscPosGenerator.generate(
        items: _items,
        sedeNombre: sede?.nombre,
        paperWidth: principal.anchoPapel.mm,
        conPrecios: conPrecios,
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
                hintText: 'Buscar producto por nombre o código…',
                debounceDelay: const Duration(milliseconds: 200),
                onChanged: (v) => setState(() => _query = v.trim()),
                onClear: _limpiarBusqueda,
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Row(
        children: [
          Icon(Icons.calculate_outlined, color: AppColors.blue1, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Calculadora de precios',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
                      fontSize: 10, fontWeight: FontWeight.w500)),
              subtitle: Text(
                '${p.codigoEmpresa} · Stock: $stock'
                '${p.tieneVariantes ? ' · ${p.variantes?.length ?? 0} variantes' : ''}',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
              ),
              trailing: precio != null
                  ? Text('S/ ${precio.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600))
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
                        fontSize: 10, fontWeight: FontWeight.w500),
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
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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
            width: 55,
            child: Text('S/ ${item.total.toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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
          14, 8, 14, 10 + MediaQuery.of(context).viewPadding.bottom),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
