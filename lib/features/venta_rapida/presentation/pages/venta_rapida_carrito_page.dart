import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/autorizacion_dialog.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/utils/unidad_presentacion.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../../../core/widgets/producto_sede_selector/producto_sede_selector.dart';
import '../../../producto/domain/entities/producto_list_item.dart';
import '../../../producto/domain/entities/producto_variante.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../../venta/data/datasources/venta_remote_datasource.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../bloc/venta_rapida_cubit.dart';
import '../widgets/escaner_identificadores_sheet.dart';
import '../widgets/ordenes_cobrables_sheet.dart';
import '../widgets/tipo_comprobante_dialog.dart';

class VentaRapidaCarritoPage extends StatelessWidget {
  const VentaRapidaCarritoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: locator<VentaRapidaCubit>(),
      child: const _CarritoView(),
    );
  }
}

class _CarritoView extends StatelessWidget {
  const _CarritoView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: BlocBuilder<VentaRapidaCubit, VentaRapidaState>(
          builder: (context, state) {
            return Row(
              children: [
                const Text('Total', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Text(
                  'S/ ${state.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                // Con adelantos de órdenes aplicados, lo que se cobra HOY
                // es menos que el total del comprobante.
                if (state.adelantoAplicado > 0) ...[
                  const SizedBox(width: 10),
                  Text(
                    'A cobrar S/ ${state.totalACobrar.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.white70),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          // Cobrar una orden de servicio terminada como línea de la venta.
          IconButton(
            tooltip: 'Cobrar servicio',
            icon: const Icon(Icons.home_repair_service_outlined),
            onPressed: () => _cobrarServicio(context),
          ),
        ],
      ),
      body: BlocBuilder<VentaRapidaCubit, VentaRapidaState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Carrito vacío',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Header de tabla
              Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: const Row(
                  children: [
                    SizedBox(width: 135, child: _Th('PRODUCTO')),
                    Expanded(child: Center(child: _Th('PRE'))),
                    // Stock: ancho fijo, suficiente para hasta 3 dígitos.
                    SizedBox(width: 50, child: Center(child: _Th('STOCK'))),
                    // Cantidad con más espacio (input editable).
                    Expanded(flex: 2, child: Center(child: _Th('CANT.'))),
                    // Más ancho para que montos altos no salten de línea.
                    Expanded(flex: 2, child: Center(child: _Th('TOTAL'))),
                  ],
                ),
              ),
              // Lista (con headers de combo intercalados)
              Expanded(
                child: Builder(
                  builder: (_) {
                    final rows = _buildRows(state.items);
                    return ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, i) {
                        // No mostrar separador entre header de combo y su primer item
                        // ni entre items de un mismo combo.
                        final r = rows[i];
                        final next = i + 1 < rows.length ? rows[i + 1] : null;
                        final mismoCombo = r.comboId != null &&
                            next?.comboId != null &&
                            r.comboId == next!.comboId;
                        if (mismoCombo) return const SizedBox.shrink();
                        return Divider(height: 1, color: Colors.grey.shade300);
                      },
                      itemBuilder: (_, i) {
                        final row = rows[i];
                        if (row.isHeader) {
                          return _ComboHeaderTile(
                            nombre: row.comboNombre!,
                            total: row.comboTotal!,
                            ahorro: row.comboAhorro!,
                            modificado: row.comboModificado,
                            onEliminar: () => context
                                .read<VentaRapidaCubit>()
                                .eliminarCombo(row.comboId!),
                            onAgregarComponente: () => _agregarComponente(
                                context, row.comboId!, state),
                          );
                        }
                        final item = row.item!;
                        // Items del combo: cantidad editable (re-precia el
                        // combo), swipe para quitar, y mantené pulsado para
                        // sustituir / aplicar descuento.
                        if (item.origenComboId != null) {
                          return Dismissible(
                            key: ValueKey(
                                'combo_${item.productoId}_${item.varianteId ?? ''}_${row.index}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red.shade400,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(Icons.delete, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Quitar',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            onDismissed: (_) => context
                                .read<VentaRapidaCubit>()
                                .quitarComponenteCombo(row.index!),
                            child: GestureDetector(
                              onLongPress: () => _mostrarMenuComponente(
                                  context, row.index!, item, state),
                              child: Container(
                                color: Colors.amber.shade50,
                                child: _ItemRow(
                                  index: row.index!,
                                  item: item,
                                  readonly: false,
                                ),
                              ),
                            ),
                          );
                        }
                        return Dismissible(
                          key: ValueKey(
                              '${item.ordenServicioId ?? item.productoId}_${item.varianteId ?? ''}_${row.index}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red.shade400,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(Icons.delete, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Quitar',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          onDismissed: (_) {
                            context
                                .read<VentaRapidaCubit>()
                                .eliminarItem(row.index!);
                          },
                          child: GestureDetector(
                            // Líneas de orden: sin descuento de línea (vive
                            // en la orden de servicio, no en la venta).
                            onLongPress: item.esOrdenServicio
                                ? null
                                : () => _mostrarDescuentoItem(
                                      context, row.index!, item,
                                    ),
                            child: item.esOrdenServicio
                                ? Container(
                                    color: Colors.blue.shade50,
                                    child: _ItemRow(
                                      index: row.index!,
                                      item: item,
                                      readonly: true,
                                    ),
                                  )
                                : _ItemRow(
                                    index: row.index!,
                                    item: item,
                                  ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // Footer: Descuento + IGV + botones
              Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Column(
                  children: [
                    // Botón descuento global
                    GestureDetector(
                      onTap: () => _mostrarDescuentoGlobal(context, state),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(
                          color: state.descuentoTotal > 0
                              ? Colors.red.shade50
                              : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: state.descuentoTotal > 0
                                ? Colors.red.shade300
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.discount_outlined,
                              size: 16,
                              color: state.descuentoTotal > 0
                                  ? Colors.red.shade700
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              state.descuentoTotal > 0
                                  ? 'Descuento: -S/ ${state.descuentoTotal.toStringAsFixed(2)}'
                                  : 'Aplicar Descuento',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: state.descuentoTotal > 0
                                    ? Colors.red.shade700
                                    : Colors.grey.shade700,
                              ),
                            ),
                            if (state.descuentoTotal > 0) ...[
                              const Spacer(),
                              GestureDetector(
                                onTap: () => context.read<VentaRapidaCubit>().limpiarDescuentos(),
                                child: Icon(Icons.close, size: 16, color: Colors.red.shade400),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // IGV
                    Text(
                      state.tipoComprobante == 'TICKET'
                          ? 'IGV INCLUIDO'
                          : 'IGV IMPUESTO GENERAL A LAS VENTAS',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('S/ ${state.igv.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _confirmarVaciar(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'VACIAR CARRITO',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _siguiente(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade500,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'SIGUIENTE',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Abre el selector de órdenes cobrables y agrega la elegida al carrito.
  /// El cubit pre-carga el cliente de la orden en la venta.
  Future<void> _cobrarServicio(BuildContext context) async {
    final cubit = context.read<VentaRapidaCubit>();
    // La sede de la venta en curso: no se cobran órdenes de otra sede.
    final orden = await showOrdenesCobrablesSheet(
      context,
      sedeId: cubit.state.sedeId,
    );
    if (orden == null || !context.mounted) return;
    final ok = cubit.agregarOrdenServicio(orden);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Orden ${orden.codigo} agregada — cliente: ${orden.clienteNombre}'
              : (cubit.state.error ?? 'No se pudo agregar la orden'),
        ),
        backgroundColor: ok ? Colors.green.shade600 : Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _esAdmin(BuildContext context) {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      return empresaState.context.permissions.canManageDiscounts;
    }
    return false;
  }

  Future<void> _mostrarDescuentoItem(BuildContext context, int index, dynamic item) async {
    if (!_esAdmin(context)) {
      final auth = await showAutorizacionDialog(
        context,
        operacion: 'APLICAR_DESCUENTO',
        titulo: 'Autorizar descuento',
        descripcion: 'Un administrador debe autorizar la aplicación de descuentos.',
      );
      if (auth == null || !context.mounted) return;
    }
    if (!context.mounted) return;
    // En líneas de combo el dialog edita el descuento MANUAL (la parte
    // apilada sobre el prorrateo), por eso prefill con descuentoManual.
    final esCombo = (item.origenComboId as String?) != null;
    _showDescuentoDialog(
      context,
      titulo: item.descripcion as String,
      bruto: (item.cantidad as double) * (item.precioUnitario as double),
      descuentoActual:
          esCombo ? (item.descuentoManual as double) : (item.descuento as double),
      onAplicar: (monto) {
        context.read<VentaRapidaCubit>().actualizarDescuentoMonto(index, monto);
      },
    );
  }

  /// Menú de edición de un componente de combo (mantené pulsado): sustituir,
  /// aplicar descuento o quitar.
  Future<void> _mostrarMenuComponente(
    BuildContext context,
    int index,
    dynamic item,
    VentaRapidaState state,
  ) async {
    final accion = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.tune, size: 16, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.descripcion as String,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.swap_horiz, color: AppColors.blue1),
              title: const Text('Sustituir componente'),
              onTap: () => Navigator.pop(ctx, 'sustituir'),
            ),
            ListTile(
              leading: Icon(Icons.discount_outlined, color: Colors.orange.shade700),
              title: const Text('Aplicar descuento'),
              onTap: () => Navigator.pop(ctx, 'descuento'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade600),
              title: const Text('Quitar componente'),
              onTap: () => Navigator.pop(ctx, 'quitar'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (accion == null || !context.mounted) return;
    final cubit = context.read<VentaRapidaCubit>();
    switch (accion) {
      case 'quitar':
        cubit.quitarComponenteCombo(index);
        break;
      case 'descuento':
        await _mostrarDescuentoItem(context, index, item);
        break;
      case 'sustituir':
        final sel = await _pickProducto(context, state,
            titulo: 'Sustituir por...');
        if (sel == null || !context.mounted) return;
        cubit.sustituirComponenteCombo(index, sel.producto,
            variante: sel.variante);
        break;
    }
  }

  /// Abre el selector de producto para sumar un componente nuevo al combo.
  Future<void> _agregarComponente(
    BuildContext context,
    String comboId,
    VentaRapidaState state,
  ) async {
    final sel = await _pickProducto(context, state, titulo: 'Agregar componente');
    if (sel == null || !context.mounted) return;
    context
        .read<VentaRapidaCubit>()
        .agregarComponenteACombo(comboId, sel.producto, variante: sel.variante);
  }

  /// Modal con [ProductoSedeSelector] (sede fija = la de la venta) que
  /// devuelve el producto + variante elegidos.
  Future<({ProductoListItem producto, ProductoVariante? variante})?>
      _pickProducto(
    BuildContext context,
    VentaRapidaState state, {
    required String titulo,
  }) async {
    final empresaId = state.empresaId;
    final sedeId = state.sedeId;
    if (empresaId == null || sedeId == null) return null;
    return showModalBottomSheet<
        ({ProductoListItem producto, ProductoVariante? variante})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: SizedBox(
          // Alto fijo al 40% de la pantalla — deja aire para el dropdown
          // de resultados del selector.
          height: MediaQuery.of(sheetCtx).size.height * 0.4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ProductoSedeSelector(
                  empresaId: empresaId,
                  sedeIdInicial: sedeId,
                  mostrarSelectorSede: false,
                  label: 'Producto',
                  hintText: 'Buscar producto...',
                  onProductoSeleccionado: ({
                    required producto,
                    required sedeId,
                    variante,
                  }) {
                    Navigator.pop(
                        sheetCtx, (producto: producto, variante: variante));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarDescuentoGlobal(BuildContext context, VentaRapidaState state) async {
    if (!_esAdmin(context)) {
      final auth = await showAutorizacionDialog(
        context,
        operacion: 'APLICAR_DESCUENTO',
        titulo: 'Autorizar descuento',
        descripcion: 'Un administrador debe autorizar la aplicación de descuentos.',
      );
      if (auth == null || !context.mounted) return;
    }
    if (!context.mounted) return;
    final brutoTotal = state.items
        .where((i) => i.origenComboId == null)
        .fold(0.0, (sum, i) => sum + i.cantidad * i.precioUnitario);
    _showDescuentoDialog(
      context,
      titulo: 'Descuento Global',
      bruto: brutoTotal,
      descuentoActual: state.descuentoTotal,
      onAplicar: (monto) {
        final porcentaje = brutoTotal > 0 ? (monto / brutoTotal) * 100 : 0.0;
        context.read<VentaRapidaCubit>().aplicarDescuentoGlobal(porcentaje);
      },
    );
  }

  void _showDescuentoDialog(
    BuildContext context, {
    required String titulo,
    required double bruto,
    required double descuentoActual,
    required void Function(double monto) onAplicar,
  }) {
    final pctCtrl = TextEditingController(
      text: descuentoActual > 0 && bruto > 0
          ? ((descuentoActual / bruto) * 100).toStringAsFixed(1)
          : '',
    );
    final montoCtrl = TextEditingController(
      text: descuentoActual > 0 ? descuentoActual.toStringAsFixed(2) : '',
    );
    bool esPorcentaje = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return StyledDialog(
            accentColor: Colors.orange.shade700,
            icon: Icons.discount_outlined,
            titulo: titulo,
            content: [
              // Subtotal
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    Text('S/ ${bruto.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Toggle % / S/
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => esPorcentaje = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: esPorcentaje ? Colors.orange.shade700 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text('%',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: esPorcentaje ? Colors.white : Colors.grey.shade600,
                              )),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => esPorcentaje = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !esPorcentaje ? Colors.orange.shade700 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text('S/',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: !esPorcentaje ? Colors.white : Colors.grey.shade600,
                              )),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Input
              if (esPorcentaje)
                CustomText(
                  controller: pctCtrl,
                  label: 'Porcentaje',
                  suffixText: '%',
                  borderColor: Colors.orange.shade700,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) {
                    final pct = double.tryParse(v) ?? 0;
                    montoCtrl.text = (bruto * pct / 100).toStringAsFixed(2);
                    setDialogState(() {});
                  },
                )
              else
                CustomText(
                  controller: montoCtrl,
                  label: 'Monto',
                  prefixText: 'S/ ',
                  borderColor: Colors.orange.shade700,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) {
                    final m = double.tryParse(v) ?? 0;
                    pctCtrl.text = bruto > 0 ? ((m / bruto) * 100).toStringAsFixed(1) : '0';
                    setDialogState(() {});
                  },
                ),
              const SizedBox(height: 6),
              // Preview
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  esPorcentaje
                      ? 'Descuento: S/ ${montoCtrl.text.isEmpty ? "0.00" : montoCtrl.text}'
                      : 'Equivale a ${pctCtrl.text.isEmpty ? "0" : pctCtrl.text}%',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ),
            ],
            actions: [
              if (descuentoActual > 0)
                Expanded(
                  child: CustomButton(
                    text: 'Quitar',
                    isOutlined: true,
                    borderColor: Colors.red.shade400,
                    textColor: Colors.red.shade600,
                    enableShadows: false,
                    onPressed: () {
                      onAplicar(0);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              Expanded(
                child: CustomButton(
                  text: 'Cancelar',
                  isOutlined: true,
                  borderColor: Colors.grey.shade400,
                  textColor: Colors.grey.shade700,
                  enableShadows: false,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              Expanded(
                child: CustomButton(
                  text: 'Aplicar',
                  backgroundColor: Colors.orange.shade700,
                  textColor: Colors.white,
                  onPressed: () {
                    final monto = double.tryParse(montoCtrl.text) ?? 0;
                    // Aviso: el descuento no puede superar el precio de la línea
                    // (si no, quedaría negativa y SUNAT rechaza la boleta).
                    if (monto > bruto + 0.001) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.orange.shade800,
                          content: Text(
                            'El descuento (S/ ${monto.toStringAsFixed(2)}) supera el '
                            'precio (S/ ${bruto.toStringAsFixed(2)}). Se aplicó el máximo.',
                          ),
                        ),
                      );
                    }
                    onAplicar(monto.clamp(0, bruto));
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmarVaciar(BuildContext context) async {
    final ok = await ConfirmDialog.show(
      context: context,
      type: ConfirmDialogType.destructive,
      title: 'Vaciar carrito',
      message: '¿Seguro que querés vaciar el carrito? '
          'Se perderán todos los items agregados.',
      confirmText: 'Vaciar',
    );
    if (ok == true && context.mounted) {
      context.read<VentaRapidaCubit>().vaciarCarrito();
      context.pop();
    }
  }

  Future<void> _siguiente(BuildContext context) async {
    final cubit = context.read<VentaRapidaCubit>();

    // 🔴 Se frena ACÁ y no al cobrar: el IMEI no se puede completar después,
    // porque para entonces la boleta ya salió impresa y declarada. El backend
    // lo rechaza igual, pero recién con la venta armada.
    final incompletos = cubit.state.items
        .where((i) => i.identificadoresIncompletos)
        .toList();
    if (incompletos.isNotEmpty) {
      final detalle = incompletos.map((i) {
        final etiqueta = i.etiquetaIdentificador ?? 'N° de serie';
        final cargados =
            i.identificadores.where((e) => e.trim().isNotEmpty).length;
        return '• ${i.descripcion}\n   $cargados de '
            '${i.cantidad.round()} $etiqueta';
      }).join('\n');
      await StyledDialog.show<void>(
        context,
        accentColor: Colors.red.shade700,
        backgroundColor: Colors.white,
        icon: Icons.pin_outlined,
        titulo: 'Faltan datos del equipo',
        content: [
          Text(
            'Estos productos necesitan un identificador por cada unidad y '
            'todavía falta cargarlo:\n\n$detalle',
            style: const TextStyle(fontSize: 12),
          ),
        ],
        actions: [
          Expanded(
            child: CustomButton(
              text: 'Completar',
              backgroundColor: Colors.red.shade700,
              textColor: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      );
      return;
    }

    // Sin facturación electrónica configurada (ningún emisor ACTIVO) no
    // hay nada que elegir: directo al cobro como Nota de venta, sin
    // dialog. Si la consulta falla, también Ticket — el backend
    // rechazaría igual una boleta sin configuración.
    var facturacionActiva = false;
    try {
      final emisores =
          await locator<VentaRemoteDataSource>().listarEmisores();
      final activos = emisores.where((e) => e.activo).toList();
      facturacionActiva = activos.isNotEmpty;
      if (activos.isNotEmpty) cubit.setEmisores(activos);
    } catch (_) {}
    if (!context.mounted) return;

    String? tipo = 'TICKET';
    if (facturacionActiva) {
      tipo = await showDialog<String>(
        context: context,
        builder: (_) => const TipoComprobanteDialog(),
      );
      if (tipo == null) return;
    }
    cubit.setTipoComprobante(tipo);
    if (!context.mounted) return;
    context.push('/empresa/venta-rapida/cobro');
  }
}

class _Th extends StatelessWidget {
  final String text;
  const _Th(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade700,
      ),
    );
  }
}

class _ItemRow extends StatefulWidget {
  final int index;
  final dynamic item; // VentaDetalleInput
  /// Cuando true, no se permite editar la cantidad (caso item dentro de un combo).
  final bool readonly;

  const _ItemRow({
    required this.index,
    required this.item,
    this.readonly = false,
  });

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  late TextEditingController _cantCtrl;
  late FocusNode _focusNode;

  /// Un controller por casilla de identificador, indexado por posición.
  final Map<int, TextEditingController> _identCtrls = {};

  /// Ídem para la nota opcional de cada unidad.
  final Map<int, TextEditingController> _notaCtrls = {};

  /// Alto del campo y alto de la fila que lo contiene. La diferencia es el
  /// aire entre casillas, y es por donde pasa la vertical del conector: si
  /// fueran iguales, las ramas quedarían pegadas sin respiro.
  static const _hCampoIdent = 32.0;
  static const _hFilaIdent = 38.0;

  /// La cantidad viaja en unidad de venta (1500 g) y se muestra/escribe en
  /// presentación (1.5 kg). Sin presentación configurada el factor es 1 y el
  /// texto queda igual que siempre.
  UnidadPresentacion get _pres => widget.item.presentacion;

  /// Lo que debe verse en el campo para la cantidad actual del state.
  String get _textoCantidad =>
      _pres.cantidadTexto(widget.item.cantidad, conSimbolo: false);

  /// Lo tecleado está en presentación (1.5 kg) y el carrito guarda unidad de
  /// venta (1500 g). Sin convertir, vender 1.5 kg descontaría 1.5 gramos.
  void _aplicarCantidad(BuildContext context, String texto) {
    final escrito = double.tryParse(texto.replaceAll(',', '.')) ?? 0;
    // MULTIPLICA (1.5 kg → 1500 g). El precio va al revés; usar el método del
    // precio acá convertía 1 kg en 0.001 g y el campo se iba a cero.
    context.read<VentaRapidaCubit>().actualizarCantidad(
          widget.index,
          _pres.cantidadAUnidadDeVenta(escrito),
        );
  }

  @override
  void initState() {
    super.initState();
    _cantCtrl = TextEditingController(text: _textoCantidad);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  /// Al perder foco, si el cajero borró el campo o quedó inválido, re-sincroniza
  /// el TextField con la cantidad real del state. Evita inconsistencia visual
  /// (campo vacío pero state con cantidad anterior).
  void _onFocusChange() {
    if (_focusNode.hasFocus) return;
    final esperado = _textoCantidad;
    if (esperado != _cantCtrl.text) {
      _cantCtrl.value = TextEditingValue(
        text: esperado,
        selection: TextSelection.collapsed(offset: esperado.length),
      );
    }
  }

  /// True si lo tecleado ya representa la cantidad del state.
  ///
  /// Se comparan VALORES y no strings: mientras escribís "1.5" el campo pasa
  /// por "1." , que vale 1 igual que "1". Comparando texto, el re-sync te
  /// borraba el punto apenas lo tocabas y era imposible escribir decimales.
  bool get _textoYaCoincide {
    final tecleado = double.tryParse(_cantCtrl.text.replaceAll(',', '.'));
    if (tecleado == null) return false;
    final esperado = _pres.cantidad(widget.item.cantidad);
    return (tecleado - esperado).abs() < 1e-9;
  }

  @override
  void didUpdateWidget(_ItemRow old) {
    super.didUpdateWidget(old);
    final esperado = _textoCantidad;
    if (esperado != _cantCtrl.text && !_textoYaCoincide) {
      // Mantener el cursor al final tras un cap (state.cantidad < lo tipeado).
      _cantCtrl.value = TextEditingValue(
        text: esperado,
        selection: TextSelection.collapsed(offset: esperado.length),
      );
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _cantCtrl.dispose();
    for (final c in _identCtrls.values) {
      c.dispose();
    }
    for (final c in _notaCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    // Líneas de orden de servicio no manejan stock.
    final esOrden = item.ordenServicioId != null;
    final stock = item.stockDisponible ?? 0;
    final excedeStock = !esOrden && item.cantidad > stock;

    final pideIdentificador =
        (widget.item.requiereIdentificador as bool?) ?? false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Nombre + badge de nivel aplicado (si existe)
          SizedBox(
            width: 130,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.descripcion,
                  style: const TextStyle(fontSize: 11),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.nivelAplicado != null) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      // Precio VIP en ámbar; nivel por mayor en verde.
                      color: item.esPrecioVip
                          ? Colors.amber.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: item.esPrecioVip
                              ? Colors.amber.shade400
                              : Colors.green.shade300,
                          width: 0.5),
                    ),
                    child: Text(
                      '${item.nivelAplicado} '
                      '−${(item.descuentoNivelPct ?? 0).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 9,
                        color: item.esPrecioVip
                            ? Colors.amber.shade900
                            : Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (item.enLiquidacion) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: Colors.deepOrange.shade300, width: 0.5),
                    ),
                    child: Text(
                      'LIQUIDACIÓN',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.deepOrange.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                if (item.descuento > 0) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: Colors.red.shade300, width: 0.5),
                    ),
                    child: Text(
                      '-S/ ${item.descuento.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Precio (con base tachado si hay nivel aplicado)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.precioBase != null &&
                      item.precioBase! > item.precioUnitario + 0.001)
                    Text(
                      _pres.precio(item.precioBase!).toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    // Precio en la unidad en la que se cobra: S/0.008 el gramo
                    // se lee "0.01" y en realidad son S/8.00 el kilo.
                    _pres.precio(item.precioUnitario).toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          (item.nivelAplicado != null || item.enLiquidacion)
                              ? FontWeight.w600
                              : FontWeight.normal,
                      color: item.enLiquidacion
                          ? Colors.deepOrange.shade700
                          : (item.nivelAplicado != null
                              ? Colors.green.shade700
                              : null),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Stock — ancho fijo alineado con el header (hasta 3 dígitos).
          // Líneas de orden de servicio: sin stock ("—").
          SizedBox(
            width: 50,
            child: Center(
              child: Text(
                esOrden ? '—' : _pres.cantidadTexto(stock),
                style: TextStyle(
                  fontSize: 12,
                  color: excedeStock ? Colors.red : Colors.black87,
                  fontWeight: excedeStock ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
          // Cantidad: editable para items sueltos, solo texto para items de combo.
          Expanded(
            flex: 2,
            child: Center(
              child: widget.readonly
                  ? Text(
                      _pres.cantidadTexto(item.cantidad),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : SizedBox(
                      width: 70,
                      child: CustomText(
                        controller: _cantCtrl,
                        focusNode: _focusNode,
                        // Con presentación se escriben kilos y hay que poder
                        // tipear "1.5". `FieldType.number` NO sirve acá: su
                        // NumberFormatter hace replaceAll(RegExp('[^\\d]'))
                        // y se come el punto, aunque el teclado lo muestre.
                        fieldType: _pres.activa
                            ? FieldType.text
                            : FieldType.number,
                        keyboardType: _pres.activa
                            ? const TextInputType.numberWithOptions(
                                decimal: true)
                            : TextInputType.number,
                        inputFormatters: _pres.activa
                            ? [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.,]')),
                              ]
                            : null,
                        borderColor: excedeStock ? Colors.red : AppColors.blue1,
                        height: 27,
                        onSubmitted: (v) => _aplicarCantidad(context, v),
                        onChanged: (v) => _aplicarCantidad(context, v),
                      ),
                    ),
            ),
          ),
          // Total — flex 2 alineado con el header para acomodar montos altos
          // sin saltar a la siguiente línea.
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                'S/ ${item.total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
              ),
            ),
          ),
        ],
      ),
        ),
        if (pideIdentificador) _buildIdentificadores(),
      ],
    );
  }

  /// Campos de identificador por unidad (IMEI, N° de serie, placa).
  ///
  /// Van DEBAJO de la fila y no como columna: son tantos como unidades, y
  /// quince dígitos no entran al lado de cantidad y precio. Se muestran solo
  /// para los productos que lo piden, así el resto del carrito no cambia.
  Widget _buildIdentificadores() {
    final item = widget.item;
    final etiqueta =
        (item.etiquetaIdentificador as String?) ?? 'N° de serie';
    final unidades = (item.cantidad as double).round();
    if (unidades <= 0) return const SizedBox.shrink();

    final valores = List<String>.from(item.identificadores as List);
    final notas = List<String>.from(item.notasIdentificador as List);

    // Sin recuadro ni encabezado: el hint del campo ya dice qué se escribe, y
    // una caja de color competía visualmente con la fila del producto. El
    // conector de árbol alcanza para leer que estas casillas cuelgan de ella.
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 4, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Una casilla por unidad. Al subir la cantidad aparecen más, y las
          // ya tipeadas se conservan porque se indexan por posición.
          for (var i = 0; i < unidades; i++)
            SizedBox(
              height: _hFilaIdent,
              child: Row(
                // stretch para que el conector reciba el alto COMPLETO de la
                // fila: es lo que permite que la vertical de una enganche con
                // la de la siguiente y se lea como una sola rama continua.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 18,
                    child: CustomPaint(
                      painter: _RamaPainter(
                        esUltimo: i == unidades - 1,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  // El identificador casi siempre se timbra, así que se lee
                  // poco: el reparto le da más ancho a la nota, que sí se
                  // escribe a mano.
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: SizedBox(
                        height: _hCampoIdent,
                        child: CustomText(
                          controller: _identCtrl(i, valores),
                          hintText: etiqueta,
                          textCase: TextCase.upper,
                          height: _hCampoIdent,
                          onChanged: (v) => _guardarIdentificador(i, v),
                          // El IMEI viene impreso como código de barras en la
                          // caja del equipo: timbrarlo evita tipear 15 dígitos
                          // y, sobre todo, evita el dedazo en un dato que
                          // después no se puede corregir sin anular la boleta.
                          // Igual queda editable a mano para los que no traen
                          // código o no leen.
                          // Abre el escáner CONTINUO: queda en media
                          // pantalla y va llenando las casillas siguientes,
                          // en vez de entrar y salir una vez por equipo.
                          suffixIcon: GestureDetector(
                            onTap: () => _abrirEscaner(i),
                            child: const Padding(
                              padding: EdgeInsets.only(right: 2),
                              child: Icon(Icons.qr_code_scanner,
                                  size: 17, color: AppColors.blue1),
                            ),
                          ),
                          // El estado vive en el borde del campo: es lo único
                          // que queda ahora que no hay recuadro.
                          borderColor: (i < valores.length &&
                                  valores[i].trim().isNotEmpty)
                              ? Colors.green.shade400
                              : Colors.red.shade300,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          textStyle: const TextStyle(fontSize: 11),
                          hintStyle:
                              TextStyle(fontSize: 10, color: Colors.grey[500]),
                          showValidationIndicator: false,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  // Nota OPCIONAL: no bloquea el cobro y no entra al array de
                  // identificadores. El backend la pone entre paréntesis solo
                  // en el texto del comprobante, así el IMEI queda limpio para
                  // buscarlo exacto ante un reclamo de garantía.
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: SizedBox(
                        height: _hCampoIdent,
                        child: CustomText(
                          controller: _notaCtrl(i, notas),
                          hintText: 'nota',
                          textCase: TextCase.upper,
                          height: _hCampoIdent,
                          onChanged: (v) => _guardarNota(i, v),
                          borderColor: AppColors.blue1Alpha40,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          textStyle: const TextStyle(fontSize: 11),
                          hintStyle:
                              TextStyle(fontSize: 10, color: Colors.grey[500]),
                          showValidationIndicator: false,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Un controller por casilla, memorizado para que no se pierda el cursor en
  /// cada rebuild del carrito (que ocurre con cada tecla).
  TextEditingController _identCtrl(int i, List<String> valores) {
    final actual = i < valores.length ? valores[i] : '';
    final ctrl = _identCtrls.putIfAbsent(
      i,
      () => TextEditingController(text: actual),
    );
    // Se sincroniza solo si cambió desde afuera (ej. se limpió el carrito):
    // asignar en cada build mandaría el cursor al inicio mientras se escribe.
    if (ctrl.text != actual && !ctrl.selection.isValid) {
      ctrl.text = actual;
    }
    return ctrl;
  }

  /// Abre el escáner continuo desde la casilla [desde].
  void _abrirEscaner(int desde) {
    final item = widget.item;
    mostrarEscanerIdentificadores(
      context,
      etiqueta: (item.etiquetaIdentificador as String?) ?? 'N° de serie',
      unidades: (item.cantidad as double).round(),
      actuales: List<String>.from(item.identificadores as List),
      indiceInicial: desde,
      onCapturado: _escanearIdentificador,
    );
  }

  /// Escaneo: escribe en el campo y en el state de una.
  ///
  /// Hay que tocar el controller a mano porque el valor no viene del teclado y
  /// `onChanged` no se dispara solo; sin esto el número quedaba guardado pero
  /// la casilla se veía vacía.
  void _escanearIdentificador(int i, String codigo) {
    final valor = codigo.trim();
    if (valor.isEmpty) return;
    final ctrl = _identCtrls[i];
    if (ctrl != null) {
      ctrl.text = valor;
      ctrl.selection = TextSelection.collapsed(offset: valor.length);
    }
    _guardarIdentificador(i, valor);
  }

  /// Controller de la nota, con el mismo criterio que el del identificador:
  /// memorizado para no perder el cursor en cada rebuild del carrito.
  TextEditingController _notaCtrl(int i, List<String> notas) {
    final actual = i < notas.length ? notas[i] : '';
    final ctrl = _notaCtrls.putIfAbsent(
      i,
      () => TextEditingController(text: actual),
    );
    if (ctrl.text != actual && !ctrl.selection.isValid) {
      ctrl.text = actual;
    }
    return ctrl;
  }

  void _guardarNota(int i, String valor) {
    final item = widget.item;
    final unidades = (item.cantidad as double).round();
    final actuales = List<String>.from(item.notasIdentificador as List);
    while (actuales.length < unidades) {
      actuales.add('');
    }
    if (actuales.length > unidades) {
      actuales.removeRange(unidades, actuales.length);
    }
    if (i < actuales.length) actuales[i] = valor;
    context
        .read<VentaRapidaCubit>()
        .actualizarNotasIdentificador(widget.index, actuales);
  }

  void _guardarIdentificador(int i, String valor) {
    final item = widget.item;
    final unidades = (item.cantidad as double).round();
    final actuales = List<String>.from(item.identificadores as List);
    while (actuales.length < unidades) {
      actuales.add('');
    }
    if (actuales.length > unidades) actuales.removeRange(unidades, actuales.length);
    if (i < actuales.length) actuales[i] = valor;
    context
        .read<VentaRapidaCubit>()
        .actualizarIdentificadores(widget.index, actuales);
  }
}

/// Representa una fila del carrito: o el header de un combo, o un item normal.
/// Pre-procesado en `_buildRows` para que el ListView simplemente itere.
class _CarritoRow {
  final bool isHeader;
  final String? comboId;
  final String? comboNombre;
  final double? comboTotal;
  final double? comboAhorro;
  final bool comboModificado;
  final dynamic item; // VentaDetalleInput
  final int? index; // índice en state.items (para callbacks que esperan index)

  const _CarritoRow.header({
    required String this.comboId,
    required String this.comboNombre,
    required double this.comboTotal,
    required double this.comboAhorro,
    required this.comboModificado,
  })  : isHeader = true,
        item = null,
        index = null;

  const _CarritoRow.item({
    required this.item,
    required int this.index,
    this.comboId, // si pertenece a un combo
  })  : isHeader = false,
        comboNombre = null,
        comboTotal = null,
        comboAhorro = null,
        comboModificado = false;
}

/// Construye la lista de rows agrupando items por `origenComboId`.
/// Asume que los items del mismo combo están contiguos en `state.items`
/// (lo que está garantizado porque `_agregarCombo` los agrega de una).
List<_CarritoRow> _buildRows(List items) {
  final rows = <_CarritoRow>[];
  String? lastCombo;
  for (var i = 0; i < items.length; i++) {
    final it = items[i];
    final origen = it.origenComboId as String?;
    if (origen != null && origen != lastCombo) {
      // Header del combo: calcular total y ahorro sumando todos sus items.
      // Ahorro = Σ descuentos por línea (cada item lleva el descuento
      // prorrateado que el cubit calculó al expandir el combo).
      double total = 0;
      double ahorro = 0;
      bool modificado = false;
      for (final x in items) {
        if (x.origenComboId == origen) {
          total += x.total as double;
          ahorro += x.descuento as double;
          if (x.comboModificado == true) modificado = true;
        }
      }
      rows.add(_CarritoRow.header(
        comboId: origen,
        comboNombre: (it.origenComboNombre as String?) ?? 'Combo',
        comboTotal: total,
        comboAhorro: ahorro,
        comboModificado: modificado,
      ));
      lastCombo = origen;
    }
    if (origen == null) lastCombo = null;
    rows.add(_CarritoRow.item(item: it, index: i, comboId: origen));
  }
  return rows;
}

/// Header visual de un combo en el carrito. Muestra ícono + nombre + total
/// y un botón "X" para eliminar el combo entero (todos sus componentes).
/// Si hay ahorro (descuento prorrateado entre componentes > 0), también lo
/// muestra abajo en verde como "Ahorro S/X.XX".
class _ComboHeaderTile extends StatelessWidget {
  final String nombre;
  final double total;
  final double ahorro;
  final bool modificado;
  final VoidCallback onEliminar;
  final VoidCallback onAgregarComponente;

  const _ComboHeaderTile({
    required this.nombre,
    required this.total,
    required this.ahorro,
    required this.modificado,
    required this.onEliminar,
    required this.onAgregarComponente,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.amber.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_offer, size: 16, color: Colors.amber.shade800),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  nombre.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber.shade900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (modificado) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.shade50,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.deepOrange.shade200),
                  ),
                  child: Text(
                    'Modificado',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Colors.deepOrange.shade700,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                'S/ ${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.amber.shade900,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onAgregarComponente,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.add_circle_outline,
                      size: 18, color: AppColors.blue1),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: onEliminar,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child:
                      Icon(Icons.close, size: 16, color: Colors.red.shade700),
                ),
              ),
            ],
          ),
          if (ahorro > 0) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Text(
                'Ahorro S/ ${ahorro.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Conector de árbol que cuelga cada casilla de identificador de la línea del
/// producto: `├─▸` en las intermedias y `└─▸` en la última.
///
/// Dibujado y no compuesto con caracteres o Containers: así el codo sale
/// redondeado, la punta de flecha queda prolija y todo escala con la fila sin
/// que haya que recalcular píxeles a mano.
class _RamaPainter extends CustomPainter {
  /// Última casilla del grupo: la vertical corta en el codo en vez de seguir
  /// hasta abajo. Es lo que cierra visualmente la rama.
  final bool esUltimo;
  final Color color;

  const _RamaPainter({required this.esUltimo, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final trazo = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    const x = 5.0; // por dónde baja la vertical
    const radio = 5.0; // curvatura del codo
    final y = size.height / 2; // el codo sale a la altura del campo
    final xPunta = size.width - 2;

    // Vertical. En las intermedias sigue hasta el borde inferior para
    // engancharse con la de la fila siguiente; en la última muere en el codo.
    canvas.drawLine(
      const Offset(x, 0),
      Offset(x, esUltimo ? y - radio : size.height),
      trazo,
    );

    // Codo redondeado + tramo horizontal hasta la punta.
    canvas.drawPath(
      Path()
        ..moveTo(x, y - radio)
        ..quadraticBezierTo(x, y, x + radio, y)
        ..lineTo(xPunta, y),
      trazo,
    );

    // Punta de flecha, abierta (dos trazos) para que quede liviana.
    canvas.drawPath(
      Path()
        ..moveTo(xPunta - 3.5, y - 3)
        ..lineTo(xPunta, y)
        ..lineTo(xPunta - 3.5, y + 3),
      trazo,
    );
  }

  @override
  bool shouldRepaint(_RamaPainter viejo) =>
      viejo.esUltimo != esUltimo || viejo.color != color;
}
