import 'dart:async';

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
import '../../../balanza/presentation/widgets/balanza_boton.dart';
import '../../../balanza/presentation/widgets/balanza_visor_sheet.dart';
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

  /// Puede descontar sin que un superior lo autorice.
  ///
  /// `canDescuentoLibre` ya viene resuelto del backend: es admin **o** tiene el
  /// permiso especial `venta.descuento-libre`. Antes acá se miraba
  /// `canManageDiscounts`, que es solo-admin, así que un vendedor de confianza
  /// tenía que hacer venir a un administrador en cada venta y el permiso
  /// especial —que existía en la pantalla de usuarios— no hacía nada.
  bool _puedeDescontarSinAutorizacion(BuildContext context) {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      return empresaState.context.permissions.canDescuentoLibre;
    }
    return false;
  }

  Future<void> _mostrarDescuentoItem(BuildContext context, int index, dynamic item) async {
    if (!_puedeDescontarSinAutorizacion(context)) {
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
    if (!_puedeDescontarSinAutorizacion(context)) {
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
        // UNIDADES cubiertas, no códigos cargados: una unidad con dos IMEI
        // sigue siendo una sola unidad resuelta.
        final cargados = i.identificadoresPorUnidad
            .where((codigos) => codigos.isNotEmpty)
            .length;
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

  /// Un controller por casilla de identificador, con clave `"unidad:codigo"`:
  /// una unidad puede tener más de una casilla (los dos IMEI de un dual SIM),
  /// así que la posición sola ya no alcanza para identificarla.
  final Map<String, TextEditingController> _identCtrls = {};

  /// Techo de códigos por unidad. Espeja el del backend
  /// (`MAX_CODIGOS_POR_UNIDAD`): si acá se dejaran agregar más, el rechazo
  /// llegaría recién al cobrar, con la venta ya armada.
  static const _maxCodigosPorUnidad = 5;

  /// Ídem para la nota opcional de cada casilla, con la misma clave.
  final Map<String, TextEditingController> _notaCtrls = {};

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

  /// Cuándo se avisó por última vez que la cantidad no entra en el stock.
  ///
  /// `onChanged` dispara por TECLA: al escribir "25" sobre un stock de 1, el
  /// cap actúa en cada dígito y sin este freno el aviso parpadearía una vez
  /// por tecla para un solo error.
  DateTime? _ultimoAvisoStock;

  /// Lo tecleado está en presentación (1.5 kg) y el carrito guarda unidad de
  /// venta (1500 g). Sin convertir, vender 1.5 kg descontaría 1.5 gramos.
  void _aplicarCantidad(BuildContext context, String texto) {
    final escrito = double.tryParse(texto.replaceAll(',', '.')) ?? 0;
    // MULTIPLICA (1.5 kg → 1500 g). El precio va al revés; usar el método del
    // precio acá convertía 1 kg en 0.001 g y el campo se iba a cero.
    final pedido = _pres.cantidadAUnidadDeVenta(escrito);
    // El recorte al stock lo hace el cubit; acá solo se avisa. Antes recortaba
    // en silencio y el campo volvía solo al máximo sin decir por qué, que se
    // lee como que el teclado falló.
    _avisarSiExcedeStock(context, pedido);
    context.read<VentaRapidaCubit>().actualizarCantidad(
          widget.index,
          pedido,
        );
  }

  /// Avisa que lo tecleado excede el stock. No frena nada —el cap sigue siendo
  /// del cubit—: solo le pone voz.
  void _avisarSiExcedeStock(BuildContext context, double pedido) {
    // Las líneas de orden de servicio no manejan stock (cantidad fija 1), y sin
    // stock conocido no hay techo contra el cual avisar.
    if (widget.item.ordenServicioId != null) return;
    final num? stock = widget.item.stockDisponible as num?;
    if (stock == null || pedido <= stock) return;

    final ahora = DateTime.now();
    final ultimo = _ultimoAvisoStock;
    if (ultimo != null &&
        ahora.difference(ultimo) < const Duration(milliseconds: 1200)) {
      return;
    }
    _ultimoAvisoStock = ahora;

    _AvisoSuperior.mostrar(
      context,
      'Solo hay ${_pres.cantidadTexto(stock)} en stock. '
      'Se ajustó la cantidad al máximo.',
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
                // MAYOREO COMBINADO: por qué esta línea de 1 unidad bajó de
                // precio ("Mayoreo: 3 de 3"), o cuánto falta para que baje
                // ("Falta 1 para S/ 72.00") — el chip con el que se cierra la
                // venta. También es la red contra el grupo que se rompe: si a
                // una variante le cambian el mayor, el "2 de 3" que nunca
                // llega a 3 lo hace visible acá.
                if (item.mayoreo != null) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: item.mayoreo!.alcanzado
                          ? Colors.green.shade50
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: item.mayoreo!.alcanzado
                              ? Colors.green.shade300
                              : Colors.blue.shade300,
                          width: 0.5),
                    ),
                    child: Text(
                      item.mayoreo!.etiqueta,
                      style: TextStyle(
                        fontSize: 9,
                        color: item.mayoreo!.alcanzado
                            ? Colors.green.shade700
                            : Colors.blue.shade700,
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
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // `Flexible` y no `SizedBox` a secas: con el ícono de
                        // la balanza al lado, en pantallas angostas el campo se
                        // achica en vez de desbordar la fila.
                        Flexible(
                          child: SizedBox(
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
                        // Pesar en vez de teclear. Solo en lo que se pesa y
                        // solo si hay balanza configurada: el botón se esconde
                        // solo. Escribe en el MISMO campo y pasa por el MISMO
                        // `_aplicarCantidad`, que es el que convierte a unidad
                        // de venta.
                        if (presentacionEsPesable(_pres))
                          BalanzaBoton(
                            presentacion: _pres,
                            iconSize: 15,
                            boxSize: 26,
                            onPeso: (kilos) {
                              final texto = kilos
                                  .toStringAsFixed(3)
                                  .replaceFirst(RegExp(r'\.?0+$'), '');
                              _cantCtrl.text = texto;
                              _aplicarCantidad(context, texto);
                            },
                          ),
                      ],
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

    final grupos = _gruposVisibles();
    final notas = _notasVisibles(grupos);
    final ultimaUnidad = grupos.length - 1;

    // Sin recuadro ni encabezado: el hint del campo ya dice qué se escribe, y
    // una caja de color competía visualmente con la fila del producto. El
    // conector de árbol alcanza para leer que estas casillas cuelgan de ella.
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 4, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Una casilla por unidad —el equipo— y colgando de ELLA las extra que
          // se hayan agregado con "+". Son dos niveles a propósito: con todas
          // al mismo nivel, el segundo IMEI del primer equipo se leía igual que
          // el IMEI principal del segundo, y no había forma de saber qué código
          // era de qué aparato.
          for (var u = 0; u < grupos.length; u++)
            for (var k = 0; k < grupos[u].length; k++)
              SizedBox(
                height: _hFilaIdent,
                child: Row(
                  // stretch para que el conector reciba el alto COMPLETO de la
                  // fila: es lo que permite que la vertical de una enganche con
                  // la de la siguiente y se lea como una sola rama continua.
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Carril del EQUIPO: el tramo de tronco que le toca a esta
                    // sección va de SU color, igual que el codo. El color
                    // cambia justo donde empieza el equipo siguiente, así que
                    // cada sección se lee como un bloque propio.
                    //
                    // Ancho fijo aunque no dibuje nada: si colapsara a 0, los
                    // hijos del último equipo se correrían a la izquierda y la
                    // sangría dejaría de estar alineada entre secciones.
                    SizedBox(
                      width: 18,
                      child: k == 0
                          ? CustomPaint(
                              painter: _RamaPainter(
                                // Cierra la rama solo la ÚLTIMA casilla de todo
                                // el bloque: mientras cuelguen códigos hijos, la
                                // vertical tiene que seguir bajando.
                                esUltimo: u == ultimaUnidad &&
                                    grupos[u].length == 1,
                                color: _colorUnidad(u),
                              ),
                            )
                          // En una fila hija el tronco solo continúa si abajo
                          // viene OTRO equipo.
                          : (u < ultimaUnidad
                              ? CustomPaint(
                                  painter: _RielPainter(color: _colorUnidad(u)),
                                )
                              : const SizedBox.shrink()),
                    ),
                    // Sangría del hijo: su propio codo, del color del equipo al
                    // que pertenece.
                    if (k > 0) ...[
                      const SizedBox(width: 2),
                      SizedBox(
                        width: 14,
                        child: CustomPaint(
                          painter: _RamaPainter(
                            esUltimo: k == grupos[u].length - 1,
                            color: _colorUnidad(u),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 2),
                    // El identificador casi siempre se timbra, así que se lee
                    // poco: el reparto le da más ancho a la nota, que sí se
                    // escribe a mano.
                    Expanded(flex: 2, child: _campoCodigo(u, k, grupos, etiqueta)),
                    const SizedBox(width: 5),
                    // Nota OPCIONAL: no bloquea el cobro y no entra al array de
                    // identificadores. El backend la pone entre paréntesis solo
                    // en el texto del comprobante, así el IMEI queda limpio para
                    // buscarlo exacto ante un reclamo de garantía.
                    //
                    // Una por CÓDIGO: los dos IMEI de un dual SIM pueden querer
                    // distinguirse ("SIM1" / "SIM2").
                    Expanded(flex: 3, child: _campoNota(u, k, notas)),
                    _botonCodigo(u, k, grupos),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  /// Los grupos tal como se DIBUJAN: uno por unidad vendida y con al menos una
  /// casilla, aunque todavía no se haya tipeado nada.
  ///
  /// Se recorta a la cantidad ACTUAL a propósito: si el cajero cargó tres IMEI
  /// y después bajó la cantidad a dos, el tercero ya no es de esta venta y
  /// mandarlo hacía que el backend rechazara el cobro por sobrar un dato.
  List<List<String>> _gruposVisibles() {
    final unidades = (widget.item.cantidad as double).round();
    final guardados = widget.item.identificadores as List;
    return List.generate(unidades < 0 ? 0 : unidades, (i) {
      final grupo = i < guardados.length
          ? List<String>.from(guardados[i] as List)
          : <String>[];
      if (grupo.isEmpty) grupo.add('');
      return grupo;
    });
  }

  /// Un color por EQUIPO. Pinta TODA la sección: el tronco, el codo del
  /// principal, los codos de sus hijos y el borde de sus campos.
  ///
  /// Cicla: lo que importa es que dos secciones vecinas nunca compartan color.
  ///
  /// 🔴 El rojo NO está en la paleta y no puede estar: es el único color que
  /// quedó significando algo —"falta este código y bloquea el cobro"— y se
  /// impone sobre el color de la sección. Ver [_campoCodigo].
  static const _coloresUnidad = <Color>[
    AppColors.blue1,
    Color(0xFF2E7D32), // green 800
    Color(0xFF8E24AA), // purple 600
    Color(0xFFEF6C00), // orange 800
  ];

  Color _colorUnidad(int u) =>
      _coloresUnidad[u % _coloresUnidad.length];

  /// Las notas con la MISMA forma que las casillas de código: una por casilla,
  /// rellenando con vacío lo que falte. Alinearlas acá es lo que hace que la
  /// nota de una casilla no termine en la de al lado.
  List<List<String>> _notasVisibles(List<List<String>> grupos) {
    final guardadas = widget.item.notasIdentificador as List;
    return List.generate(grupos.length, (u) {
      final fila = u < guardadas.length
          ? List<String>.from(guardadas[u] as List)
          : <String>[];
      while (fila.length < grupos[u].length) {
        fila.add('');
      }
      return fila;
    });
  }

  Widget _campoCodigo(
    int u,
    int k,
    List<List<String>> grupos,
    String etiqueta,
  ) {
    final valor = grupos[u][k];
    return Center(
      child: SizedBox(
        height: _hCampoIdent,
        child: CustomText(
          controller: _identCtrl(u, k, valor),
          // Las casillas extra se numeran ("IMEI 2") para que se lea que son
          // del MISMO aparato y no de otra unidad.
          hintText: k == 0 ? etiqueta : '$etiqueta ${k + 1}',
          textCase: TextCase.upper,
          height: _hCampoIdent,
          onChanged: (v) => _guardarIdentificador(u, k, v),
          // El IMEI viene impreso como código de barras en la caja del
          // equipo: timbrarlo evita tipear 15 dígitos y, sobre todo, evita
          // el dedazo en un dato que después no se puede corregir sin anular
          // la boleta. Igual queda editable a mano para los que no traen
          // código o no leen.
          // Abre el escáner CONTINUO: queda en media pantalla y va llenando
          // las casillas siguientes, en vez de entrar y salir una vez por
          // equipo.
          suffixIcon: GestureDetector(
            onTap: () => _abrirEscaner(u, k),
            child: Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Icon(Icons.qr_code_scanner,
                  size: 17, color: _colorUnidad(u)),
            ),
          ),
          // El borde dice a qué EQUIPO pertenece el campo…
          //
          // 🔴 …salvo cuando falta un código obligatorio: ahí gana el rojo. Es
          // lo único que le avisa al cajero por qué no puede cobrar, así que se
          // impone sobre el color de la sección. Las casillas extra son
          // opcionales: vacías no son un error y se quedan con su color.
          //
          // El verde de "ya cargado" lo reemplaza el color del equipo: que el
          // campo tenga texto ya se ve sin pintarlo.
          borderColor: (k == 0 && valor.trim().isEmpty)
              ? Colors.red.shade300
              : _colorUnidad(u),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          textStyle: const TextStyle(fontSize: 11),
          hintStyle: TextStyle(fontSize: 10, color: Colors.grey[500]),
          showValidationIndicator: false,
        ),
      ),
    );
  }

  Widget _campoNota(int u, int k, List<List<String>> notas) {
    return Center(
      child: SizedBox(
        height: _hCampoIdent,
        child: CustomText(
          controller: _notaCtrl(u, k, notas[u][k]),
          hintText: 'nota',
          textCase: TextCase.upper,
          height: _hCampoIdent,
          onChanged: (v) => _guardarNota(u, k, v),
          // El color del equipo, pero atenuado: la nota es el campo secundario
          // de la fila y con el mismo peso que el código competían.
          borderColor: _colorUnidad(u).withValues(alpha: 0.45),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          textStyle: const TextStyle(fontSize: 11),
          hintStyle: TextStyle(fontSize: 10, color: Colors.grey[500]),
          showValidationIndicator: false,
        ),
      ),
    );
  }

  /// `+` en la casilla principal de la unidad —agrega otro código al MISMO
  /// aparato, que es el caso del celular dual SIM— y `−` en las extra.
  ///
  /// `GestureDetector` y no `IconButton`: en Material 3 el IconButton reserva
  /// ~48 px de área táctil aunque se le achiquen los constraints, y desarma
  /// esta fila de 38.
  Widget _botonCodigo(int u, int k, List<List<String>> grupos) {
    final esPrincipal = k == 0;
    final habilitado =
        !esPrincipal || grupos[u].length < _maxCodigosPorUnidad;
    return GestureDetector(
      // opaque: hace tocable TODO el ancho reservado, no solo los píxeles del
      // ícono.
      behavior: HitTestBehavior.opaque,
      onTap: !habilitado
          ? null
          : (esPrincipal ? () => _agregarCodigo(u) : () => _quitarCodigo(u, k)),
      child: SizedBox(
        width: 28,
        child: Center(
          child: Icon(
            esPrincipal
                ? Icons.add_circle_outline
                : Icons.remove_circle_outline,
            size: 18,
            color: !habilitado
                ? Colors.grey.shade300
                // El "+" toma el color del equipo —refuerza de quién va a
                // colgar el código nuevo—; el "−" queda rojo porque ahí lo que
                // importa es que borra.
                : (esPrincipal ? _colorUnidad(u) : Colors.red.shade300),
          ),
        ),
      ),
    );
  }

  /// Suma una casilla vacía a ESA unidad (el segundo IMEI del aparato).
  void _agregarCodigo(int u) {
    final grupos = _gruposVisibles();
    if (u >= grupos.length || grupos[u].length >= _maxCodigosPorUnidad) return;
    grupos[u].add('');
    context
        .read<VentaRapidaCubit>()
        .actualizarIdentificadores(widget.index, grupos);
  }

  void _quitarCodigo(int u, int k) {
    final grupos = _gruposVisibles();
    if (u >= grupos.length || k >= grupos[u].length) return;
    final notas = _notasVisibles(grupos);
    grupos[u].removeAt(k);
    // La nota se va CON su código: dejarla movería la de abajo al código de
    // arriba, y eso termina impreso en el comprobante.
    if (k < notas[u].length) notas[u].removeAt(k);
    // La unidad siempre conserva su casilla principal, aunque quede vacía.
    if (grupos[u].isEmpty) {
      grupos[u].add('');
      notas[u].add('');
    }
    // Al sacar una casilla del medio las de abajo se renumeran, así que los
    // controllers de la unidad ya no corresponden a lo que muestran: se
    // descartan y se reconstruyen desde el state.
    _olvidarControllersDe(u);
    final cubit = context.read<VentaRapidaCubit>();
    cubit.actualizarIdentificadores(widget.index, grupos);
    cubit.actualizarNotasIdentificador(widget.index, notas);
  }

  /// Suelta los controllers —código y nota— de una unidad para que se rearmen
  /// desde el state.
  ///
  /// Se liberan DESPUÉS del frame: en este momento los `TextField` siguen
  /// montados con ellos y un `dispose()` en el acto revienta al reconstruir.
  void _olvidarControllersDe(int u) {
    final viejos = <TextEditingController>[];
    for (final mapa in [_identCtrls, _notaCtrls]) {
      for (final clave in mapa.keys.where((c) => c.startsWith('$u:')).toList()) {
        viejos.add(mapa.remove(clave)!);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final ctrl in viejos) {
        ctrl.dispose();
      }
    });
  }

  /// Un controller por casilla, memorizado para que no se pierda el cursor en
  /// cada rebuild del carrito (que ocurre con cada tecla).
  TextEditingController _identCtrl(int u, int k, String actual) {
    final ctrl = _identCtrls.putIfAbsent(
      '$u:$k',
      () => TextEditingController(text: actual),
    );
    // Se sincroniza solo si cambió desde afuera (ej. se limpió el carrito):
    // asignar en cada build mandaría el cursor al inicio mientras se escribe.
    if (ctrl.text != actual && !ctrl.selection.isValid) {
      ctrl.text = actual;
    }
    return ctrl;
  }

  /// Las casillas aplanadas en el orden en que se ven: `(unidad, código)`.
  ///
  /// El sheet del escáner trabaja con un índice plano —numera casillas, no
  /// unidades—, así que hace falta poder ir y volver entre las dos formas.
  List<(int, int)> _casillas(List<List<String>> grupos) {
    return [
      for (var u = 0; u < grupos.length; u++)
        for (var k = 0; k < grupos[u].length; k++) (u, k),
    ];
  }

  /// Abre el escáner continuo parado en la casilla `(u, k)`.
  void _abrirEscaner(int u, int k) {
    final item = widget.item;
    final grupos = _gruposVisibles();
    final casillas = _casillas(grupos);
    final desde = casillas.indexWhere((c) => c.$1 == u && c.$2 == k);
    mostrarEscanerIdentificadores(
      context,
      etiqueta: (item.etiquetaIdentificador as String?) ?? 'N° de serie',
      // CASILLAS, no unidades: con un dual SIM hay más casillas que aparatos,
      // y el escáner las tiene que llenar todas antes de cerrarse.
      unidades: casillas.length,
      actuales: [for (final c in casillas) grupos[c.$1][c.$2]],
      indiceInicial: desde < 0 ? 0 : desde,
      onCapturado: (plano, valor) =>
          _escanearIdentificador(casillas, plano, valor),
    );
  }

  /// Escaneo: escribe en el campo y en el state de una.
  ///
  /// Hay que tocar el controller a mano porque el valor no viene del teclado y
  /// `onChanged` no se dispara solo; sin esto el número quedaba guardado pero
  /// la casilla se veía vacía.
  void _escanearIdentificador(
    List<(int, int)> casillas,
    int plano,
    String codigo,
  ) {
    final valor = codigo.trim();
    if (valor.isEmpty || plano < 0 || plano >= casillas.length) return;
    final (u, k) = casillas[plano];
    final ctrl = _identCtrls['$u:$k'];
    if (ctrl != null) {
      ctrl.text = valor;
      ctrl.selection = TextSelection.collapsed(offset: valor.length);
    }
    _guardarIdentificador(u, k, valor);
  }

  /// Controller de la nota, con el mismo criterio que el del identificador:
  /// memorizado para no perder el cursor en cada rebuild del carrito.
  TextEditingController _notaCtrl(int u, int k, String actual) {
    final ctrl = _notaCtrls.putIfAbsent(
      '$u:$k',
      () => TextEditingController(text: actual),
    );
    if (ctrl.text != actual && !ctrl.selection.isValid) {
      ctrl.text = actual;
    }
    return ctrl;
  }

  void _guardarNota(int u, int k, String valor) {
    final notas = _notasVisibles(_gruposVisibles());
    if (u >= notas.length) return;
    while (notas[u].length <= k) {
      notas[u].add('');
    }
    notas[u][k] = valor;
    context
        .read<VentaRapidaCubit>()
        .actualizarNotasIdentificador(widget.index, notas);
  }

  void _guardarIdentificador(int u, int k, String valor) {
    final grupos = _gruposVisibles();
    if (u >= grupos.length) return;
    while (grupos[u].length <= k) {
      grupos[u].add('');
    }
    grupos[u][k] = valor;
    context
        .read<VentaRapidaCubit>()
        .actualizarIdentificadores(widget.index, grupos);
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

  /// Color de la sección: pinta la vertical, el codo y la punta. Toda la rama
  /// de un equipo va del mismo color, y el cambio de color marca dónde empieza
  /// el siguiente.
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

/// Solo la vertical del tronco, sin codo ni punta.
///
/// Es lo que va detrás de las filas HIJAS: dice "el bloque sigue, abajo viene
/// otro equipo". Sin esto el tronco quedaba cortado a la altura de cada código
/// extra y el bloque se leía como varios grupos sueltos.
class _RielPainter extends CustomPainter {
  final Color color;

  const _RielPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      const Offset(5, 0),
      Offset(5, size.height),
      Paint()
        ..color = color
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_RielPainter viejo) => viejo.color != color;
}

/// Aviso breve anclado ARRIBA, apenas debajo del AppBar.
///
/// No es un `SnackBar` a propósito: ese sale por abajo, que es justo donde el
/// cajero tiene el teclado abierto mientras teclea la cantidad — el aviso
/// quedaba pegado al pulgar o directamente tapado. Vive en el `Overlay`, así
/// que no empuja la lista del carrito ni la reconstruye.
class _AvisoSuperior {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void mostrar(BuildContext context, String mensaje) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    // Un aviso a la vez: el nuevo reemplaza al anterior en vez de encimarse.
    _quitar();

    final topeSuperior = MediaQuery.of(context).padding.top + kToolbarHeight + 8;
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        top: topeSuperior,
        left: 16,
        right: 16,
        // Deja pasar los toques: el aviso no debe bloquear el carrito debajo.
        child: IgnorePointer(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 180),
            builder: (_, t, hijo) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, -8 * (1 - t)),
                child: hijo,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade800,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        mensaje,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(const Duration(seconds: 2), _quitar);
  }

  /// Se anula la referencia ANTES de sacarlo del overlay: así un segundo
  /// llamado no puede intentar removerlo dos veces (eso sí revienta).
  static void _quitar() {
    _timer?.cancel();
    _timer = null;
    final entry = _entry;
    _entry = null;
    entry?.remove();
  }
}
