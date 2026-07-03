import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../bloc/cotizacion_rapida_cubit.dart';

/// Carrito de cotización rápida. Patrón clonado de `VentaRapidaCarritoPage`,
/// con dos diferencias:
/// - Items manuales (sin productoId) muestran "—" en stock + badge "Manual".
/// - Botón SIGUIENTE va directo a la pantalla finalizar (sin dialog de tipo
///   comprobante; cotización no emite comprobante SUNAT).
class CotizacionRapidaCarritoPage extends StatelessWidget {
  const CotizacionRapidaCarritoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: locator<CotizacionRapidaCubit>(),
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
        title: BlocBuilder<CotizacionRapidaCubit, CotizacionRapidaState>(
          builder: (context, state) {
            return Row(
              children: [
                const Text('Total', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Text(
                  'S/ ${state.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ],
            );
          },
        ),
      ),
      body: BlocConsumer<CotizacionRapidaCubit, CotizacionRapidaState>(
        listenWhen: (prev, curr) =>
            (prev.error == null && curr.error != null) ||
            (prev.cotizacionCompletadaId == null &&
                curr.cotizacionCompletadaId != null &&
                curr.modoEdicion),
        listener: (context, state) {
          if (state.error != null) {
            SnackBarHelper.showError(context, state.error!);
            context.read<CotizacionRapidaCubit>().clearError();
          }
          // Solo el flujo de EDICIÓN cierra desde aquí. La creación nueva
          // se cierra desde la pantalla finalizar.
          if (state.modoEdicion && state.cotizacionCompletadaId != null) {
            final id = state.cotizacionCompletadaId!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Cambios guardados'),
                backgroundColor: Colors.green.shade600,
              ),
            );
            context.read<CotizacionRapidaCubit>().resetCompletada();
            // Stack post-edición: dashboard → cotizaciones → detalle.
            // (a) Detalle nuevo se monta fresh con los items actualizados.
            // (b) Back desde detalle → lista; desde lista → dashboard (no
            // sale de la app). Mismo patrón que post-venta de Venta Rápida.
            context.go('/empresa/dashboard');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              context.push('/empresa/cotizaciones');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                context.push('/empresa/cotizaciones/$id');
              });
            });
          }
        },
        builder: (context, state) {
          if (state.items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_cart_outlined,
                        size: 64, color: Colors.grey),
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
              // Banner: tipo + convertibilidad
              Container(
                color: state.tipoCotizacion == TipoCotizacionRapida.paraVenta
                    ? Colors.green.shade50
                    : Colors.blue.shade50,
                padding: const EdgeInsets.symmetric(
                    vertical: 6, horizontal: 12),
                child: Row(
                  children: [
                    Icon(
                      state.tipoCotizacion == TipoCotizacionRapida.paraVenta
                          ? Icons.shopping_cart_outlined
                          : Icons.description_outlined,
                      size: 14,
                      color: state.tipoCotizacion ==
                              TipoCotizacionRapida.paraVenta
                          ? Colors.green.shade700
                          : Colors.blue.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.tipoCotizacion == TipoCotizacionRapida.paraVenta
                          ? 'Para Venta — convertible directo'
                          : 'Cotización Simple',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: state.tipoCotizacion ==
                                TipoCotizacionRapida.paraVenta
                            ? Colors.green.shade800
                            : Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              // Header tabla
              Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: const Row(
                  children: [
                    SizedBox(width: 135, child: _Th('PRODUCTO')),
                    Expanded(child: Center(child: _Th('PRE'))),
                    SizedBox(width: 50, child: Center(child: _Th('STOCK'))),
                    Expanded(flex: 2, child: Center(child: _Th('CANT.'))),
                    Expanded(flex: 2, child: Center(child: _Th('TOTAL'))),
                  ],
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (_) {
                    final rows = _buildRows(state.items);
                    return ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, i) {
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
                            onEliminar: () => context
                                .read<CotizacionRapidaCubit>()
                                .eliminarCombo(row.comboId!),
                          );
                        }
                        final item = row.item!;
                        if (item.origenComboId != null) {
                          return Container(
                            color: Colors.amber.shade50,
                            child: _ItemRow(
                              index: row.index!,
                              item: item,
                              readonly: true,
                            ),
                          );
                        }
                        return Dismissible(
                          key: ValueKey(
                              '${item.productoId ?? 'manual'}_${item.varianteId ?? ''}_${row.index}'),
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
                                .read<CotizacionRapidaCubit>()
                                .eliminarItem(row.index!);
                          },
                          child: _ItemRow(
                            index: row.index!,
                            item: item,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // Totales: botón de descuento global + IGV + ahorro visible
              // (precio regular tachado) para que el vendedor arme la oferta
              // "por mayor" y el cliente vea cuánto ahorra.
              Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 16),
                child: Builder(builder: (context) {
                  // Precio regular = SIN descuento manual y al precio BASE
                  // (antes del nivel/VIP). Así el ahorro mostrado suma ambos
                  // efectos: nivel por mayor + descuento del vendedor.
                  final regular = state.items.fold<double>(
                      0,
                      (s, i) => s +
                          i
                              .copyWith(
                                precioUnitario:
                                    i.precioBase ?? i.precioUnitario,
                                descuento: 0,
                              )
                              .total);
                  final ahorro = regular - state.total;
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () =>
                                _dialogDescuentoGlobal(context),
                            icon: const Icon(Icons.percent,
                                size: 14, color: AppColors.blue1),
                            label: const Text(
                              'Descuento global',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.blue1,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6),
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'IGV (${state.impuestoPorcentaje.toStringAsFixed(0)}%)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.blue1,
                                ),
                              ),
                              Text('S/ ${state.igv.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      if (ahorro > 0.005) ...[
                        Divider(height: 10, color: Colors.grey.shade300),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Precio regular: S/ ${regular.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            Text(
                              'Cliente ahorra S/ ${ahorro.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                }),
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
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'VACIAR',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: state.procesando
                              ? null
                              : () {
                                  if (state.modoEdicion) {
                                    context
                                        .read<CotizacionRapidaCubit>()
                                        .guardarEdicion();
                                  } else {
                                    context.push(
                                        '/empresa/cotizaciones/nueva/finalizar');
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade500,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: state.procesando
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  state.modoEdicion
                                      ? 'GUARDAR CAMBIOS'
                                      : 'CONTINUAR',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
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

  /// Descuento GLOBAL (S/ o %) prorrateado entre las líneas. Reemplaza los
  /// descuentos por item existentes (se avisa en el dialog).
  Future<void> _dialogDescuentoGlobal(BuildContext context) async {
    final cubit = context.read<CotizacionRapidaCubit>();
    final bruto = cubit.brutoDescontable;
    if (bruto <= 0) return;
    final descActual = cubit.state.items
        .where((i) => i.origenComboId == null)
        .fold<double>(0, (s, i) => s + i.descuento);
    // Cuántas líneas ya llevan un beneficio de precio (nivel/VIP u OFERTA
    // pública) — aviso opción C antes de descontar encima.
    final conNivel = cubit.state.items
        .where((i) =>
            i.origenComboId == null &&
            (i.nivelAplicado != null || i.enOferta == true))
        .length;

    var esPorcentaje = false;
    final controller = TextEditingController(
      text: descActual > 0 ? descActual.toStringAsFixed(2) : '',
    );

    final monto = await showDialog<double>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => StyledDialog(
          accentColor: AppColors.blue1,
          icon: Icons.percent,
          titulo: 'Descuento global',
          content: [
            Text(
              'Importe de los items: S/ ${bruto.toStringAsFixed(2)}\n'
              'Se prorratea entre los items (reemplaza los descuentos por item).',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            if (conNivel > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 14, color: Colors.orange.shade800),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        conNivel == 1
                            ? '1 item ya tiene precio rebajado (por mayor/VIP u oferta). El descuento se aplicará ENCIMA de ese precio.'
                            : '$conNivel items ya tienen precio rebajado (por mayor/VIP u oferta). El descuento se aplicará ENCIMA de esos precios.',
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.3,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setSheet(() => esPorcentaje = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !esPorcentaje
                            ? AppColors.blue1
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text('S/',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: !esPorcentaje
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            )),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setSheet(() => esPorcentaje = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: esPorcentaje
                            ? AppColors.blue1
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text('%',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: esPorcentaje
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            )),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            CustomText(
              controller: controller,
              label: esPorcentaje ? 'Descuento %' : 'Descuento S/',
              hintText: esPorcentaje ? '0' : '0.00',
              borderColor: AppColors.blue1,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
          actions: [
            if (descActual > 0)
              Expanded(
                child: CustomButton(
                  text: 'Quitar',
                  isOutlined: true,
                  borderColor: Colors.red.shade300,
                  textColor: Colors.red.shade700,
                  enableShadows: false,
                  // 0.0 (double): pop(0) con int crashea el navigator
                  // (showDialog<double> castea el result) y congela la app.
                  onPressed: () => Navigator.of(ctx).pop(0.0),
                ),
              ),
            Expanded(
              child: CustomButton(
                text: 'Cancelar',
                isOutlined: true,
                borderColor: Colors.grey.shade400,
                textColor: Colors.grey.shade700,
                enableShadows: false,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
            Expanded(
              child: CustomButton(
                text: 'Aplicar',
                backgroundColor: AppColors.blue1,
                textColor: Colors.white,
                onPressed: () {
                  final v = double.tryParse(
                          controller.text.replaceAll(',', '.')) ??
                      0;
                  final calculado =
                      esPorcentaje ? bruto * (v / 100) : v;
                  if (esPorcentaje && v > 100) {
                    SnackBarHelper.showError(
                        ctx, 'El porcentaje no puede superar 100%');
                    return;
                  }
                  if (calculado >= bruto) {
                    SnackBarHelper.showError(ctx,
                        'El descuento no puede ser igual o mayor al importe');
                    return;
                  }
                  Navigator.of(ctx).pop(calculado);
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (monto == null) return;
    cubit.aplicarDescuentoGlobal(monto);
  }

  Future<void> _confirmarVaciar(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vaciar carrito'),
        content: const Text('¿Seguro que querés vaciar el carrito?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Vaciar')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<CotizacionRapidaCubit>().vaciarCarrito();
      context.pop();
    }
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

  @override
  void initState() {
    super.initState();
    _cantCtrl =
        TextEditingController(text: widget.item.cantidad.toStringAsFixed(0));
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) return;
    final esperado = widget.item.cantidad.toStringAsFixed(0);
    if (esperado != _cantCtrl.text) {
      _cantCtrl.value = TextEditingValue(
        text: esperado,
        selection: TextSelection.collapsed(offset: esperado.length),
      );
    }
  }

  @override
  void didUpdateWidget(_ItemRow old) {
    super.didUpdateWidget(old);
    final esperado = widget.item.cantidad.toStringAsFixed(0);
    if (esperado != _cantCtrl.text) {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    // Items manuales no tienen stockDisponible — se distinguen por productoId nulo.
    final esManual = item.productoId == null &&
        item.varianteId == null &&
        item.servicioId == null;
    final stock = item.stockDisponible ?? 0;
    final excedeStock = !esManual && item.cantidad > stock;
    // Ahorro por unidad de la OFERTA pública (precio normal − precio oferta):
    // el precio de oferta vive en precioBase/precioUnitario.
    final double? antesOferta = (item.precioAntesOferta as num?)?.toDouble();
    final double precioOfertado =
        ((item.precioBase ?? item.precioUnitario) as num).toDouble();
    final double ahorroOfertaUnit =
        (item.enOferta == true && antesOferta != null && antesOferta > precioOfertado)
            ? antesOferta - precioOfertado
            : 0;

    return InkWell(
      // Tap en la fila = descuento de la línea (mismo gesto que la tabla
      // de cobrar cotización). Las filas readonly (combos) no aplican.
      onTap: widget.readonly ? null : () => _dialogDescuentoItem(context),
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
                if (esManual) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: Colors.purple.shade300, width: 0.5),
                    ),
                    child: Text(
                      'Manual',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.purple.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (item.nivelAplicado != null) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: Colors.green.shade300, width: 0.5),
                    ),
                    child: Text(
                      '${item.nivelAplicado} '
                      '−${(item.descuentoNivelPct ?? 0).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                // El precio ya viene rebajado por una OFERTA pública de la
                // sede — el vendedor debe saberlo antes de descontar encima.
                // Muestra el ahorro por unidad (precio normal − oferta).
                if (item.enOferta == true) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: Colors.orange.shade300, width: 0.5),
                    ),
                    child: Text(
                      ahorroOfertaUnit > 0.005
                          ? 'OFERTA −S/ ${ahorroOfertaUnit.toStringAsFixed(2)} c/u'
                          : 'OFERTA',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                if (!widget.readonly && item.descuento > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Desc. −S/ ${item.descuento.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Referencia tachada: el precio NORMAL (antes de la
                  // oferta) si hay oferta, o el precio base si hay nivel.
                  if (ahorroOfertaUnit > 0.005)
                    Text(
                      antesOferta!.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        decoration: TextDecoration.lineThrough,
                      ),
                    )
                  else if (item.nivelAplicado != null &&
                      item.precioBase != null)
                    Text(
                      item.precioBase!.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    item.precioUnitario.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          (item.nivelAplicado != null || ahorroOfertaUnit > 0.005)
                              ? FontWeight.w600
                              : FontWeight.normal,
                      color: item.nivelAplicado != null
                          ? Colors.green.shade700
                          : (ahorroOfertaUnit > 0.005
                              ? Colors.orange.shade800
                              : null),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: Center(
              child: Text(
                esManual ? '—' : '$stock',
                style: TextStyle(
                  fontSize: 12,
                  color: excedeStock ? Colors.red : Colors.black87,
                  fontWeight:
                      excedeStock ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: widget.readonly
                  ? Text(
                      item.cantidad.toStringAsFixed(0),
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
                        fieldType: FieldType.number,
                        borderColor:
                            excedeStock ? Colors.red : AppColors.blue1,
                        height: 27,
                        onSubmitted: (v) {
                          final n = double.tryParse(v) ?? 0;
                          context
                              .read<CotizacionRapidaCubit>()
                              .actualizarCantidad(widget.index, n);
                        },
                        onChanged: (v) {
                          final n = double.tryParse(v) ?? 0;
                          context
                              .read<CotizacionRapidaCubit>()
                              .actualizarCantidad(widget.index, n);
                        },
                      ),
                    ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                'S/ ${item.total.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  /// Descuento de la línea (S/ o %) — mismo patrón del dialog de descuento
  /// de la tabla de cobrar cotización.
  Future<void> _dialogDescuentoItem(BuildContext context) async {
    final cubit = context.read<CotizacionRapidaCubit>();
    final item = widget.item;
    final bruto = (item.cantidad as double) * (item.precioUnitario as double);
    if (bruto <= 0) return;
    final double actual = item.descuento as double;
    // Ahorro unitario de la OFERTA pública (para el aviso con montos).
    final double? antesOferta = (item.precioAntesOferta as num?)?.toDouble();
    final double precioOfertado =
        ((item.precioBase ?? item.precioUnitario) as num).toDouble();
    final double ahorroOfertaUnit = (item.enOferta == true &&
            antesOferta != null &&
            antesOferta > precioOfertado)
        ? antesOferta - precioOfertado
        : 0;

    var esPorcentaje = false;
    final controller = TextEditingController(
      text: actual > 0 ? actual.toStringAsFixed(2) : '',
    );

    final monto = await showDialog<double>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => StyledDialog(
          accentColor: AppColors.blue1,
          icon: Icons.discount_outlined,
          titulo: 'Descuento — ${item.descripcion}',
          content: [
            Text(
              'Importe de la línea: S/ ${bruto.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            // Opción C: se permite descontar sobre precio por mayor/VIP u
            // OFERTA, pero avisando — el cliente ya está beneficiado.
            if (item.nivelAplicado != null || item.enOferta == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 14, color: Colors.orange.shade800),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.nivelAplicado != null
                            ? 'Esta línea ya tiene precio por mayor '
                                '(${item.nivelAplicado} −${(item.descuentoNivelPct ?? 0).toStringAsFixed(0)}%). '
                                'El descuento se aplicará ENCIMA de ese precio.'
                            : 'Este producto está EN OFERTA'
                                '${ahorroOfertaUnit > 0.005 ? ' (normal S/ ${antesOferta!.toStringAsFixed(2)} → oferta S/ ${precioOfertado.toStringAsFixed(2)})' : ''}: '
                                'su precio ya viene rebajado. El descuento '
                                'se aplicará ENCIMA del precio de oferta.',
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.3,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setSheet(() => esPorcentaje = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !esPorcentaje
                            ? AppColors.blue1
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text('S/',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: !esPorcentaje
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            )),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setSheet(() => esPorcentaje = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: esPorcentaje
                            ? AppColors.blue1
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text('%',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: esPorcentaje
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            )),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            CustomText(
              controller: controller,
              label: esPorcentaje ? 'Descuento %' : 'Descuento S/',
              hintText: esPorcentaje ? '0' : '0.00',
              borderColor: AppColors.blue1,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
          actions: [
            if (actual > 0)
              Expanded(
                child: CustomButton(
                  text: 'Quitar',
                  isOutlined: true,
                  borderColor: Colors.red.shade300,
                  textColor: Colors.red.shade700,
                  enableShadows: false,
                  // 0.0 (double): pop(0) con int crashea el navigator
                  // (showDialog<double> castea el result) y congela la app.
                  onPressed: () => Navigator.of(ctx).pop(0.0),
                ),
              ),
            Expanded(
              child: CustomButton(
                text: 'Cancelar',
                isOutlined: true,
                borderColor: Colors.grey.shade400,
                textColor: Colors.grey.shade700,
                enableShadows: false,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
            Expanded(
              child: CustomButton(
                text: 'Aplicar',
                backgroundColor: AppColors.blue1,
                textColor: Colors.white,
                onPressed: () {
                  final v = double.tryParse(
                          controller.text.replaceAll(',', '.')) ??
                      0;
                  final calculado =
                      esPorcentaje ? bruto * (v / 100) : v;
                  if (esPorcentaje && v > 100) {
                    SnackBarHelper.showError(
                        ctx, 'El porcentaje no puede superar 100%');
                    return;
                  }
                  if (calculado > bruto) {
                    SnackBarHelper.showError(ctx,
                        'El descuento supera el importe de la línea');
                    return;
                  }
                  Navigator.of(ctx).pop(calculado);
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (monto == null || !context.mounted) return;
    cubit.actualizarDescuentoItem(widget.index, monto);
  }
}

class _CarritoRow {
  final bool isHeader;
  final String? comboId;
  final String? comboNombre;
  final double? comboTotal;
  final double? comboAhorro;
  final dynamic item;
  final int? index;

  const _CarritoRow.header({
    required String this.comboId,
    required String this.comboNombre,
    required double this.comboTotal,
    required double this.comboAhorro,
  })  : isHeader = true,
        item = null,
        index = null;

  const _CarritoRow.item({
    required this.item,
    required int this.index,
    this.comboId,
  })  : isHeader = false,
        comboNombre = null,
        comboTotal = null,
        comboAhorro = null;
}

List<_CarritoRow> _buildRows(List items) {
  final rows = <_CarritoRow>[];
  String? lastCombo;
  for (var i = 0; i < items.length; i++) {
    final it = items[i];
    final origen = it.origenComboId as String?;
    if (origen != null && origen != lastCombo) {
      double total = 0;
      double ahorro = 0;
      for (final x in items) {
        if (x.origenComboId == origen) {
          total += x.total as double;
          ahorro += x.descuento as double;
        }
      }
      rows.add(_CarritoRow.header(
        comboId: origen,
        comboNombre: (it.origenComboNombre as String?) ?? 'Combo',
        comboTotal: total,
        comboAhorro: ahorro,
      ));
      lastCombo = origen;
    }
    if (origen == null) lastCombo = null;
    rows.add(_CarritoRow.item(item: it, index: i, comboId: origen));
  }
  return rows;
}

class _ComboHeaderTile extends StatelessWidget {
  final String nombre;
  final double total;
  final double ahorro;
  final VoidCallback onEliminar;

  const _ComboHeaderTile({
    required this.nombre,
    required this.total,
    required this.ahorro,
    required this.onEliminar,
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
              Expanded(
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
