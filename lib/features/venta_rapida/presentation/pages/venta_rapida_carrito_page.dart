import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../bloc/venta_rapida_cubit.dart';
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
              ],
            );
          },
        ),
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
                            onEliminar: () => context
                                .read<VentaRapidaCubit>()
                                .eliminarCombo(row.comboId!),
                          );
                        }
                        final item = row.item!;
                        // Items del combo NO son dismissibles: solo se eliminan
                        // desde el header (botón "X" del combo). Son readonly:
                        // no se puede editar cantidad — para cambiar el combo
                        // hay que eliminarlo y volver a tocarlo.
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
                          key: ValueKey(item.productoId ?? 'item_${row.index}'),
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
              // Footer: IGV + botones
              Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Center(
                  child: Column(
                    children: [
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
                      const SizedBox(height: 4),
                      Text('S/ ${state.igv.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
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

  Future<void> _confirmarVaciar(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vaciar carrito'),
        content: const Text('¿Seguro que querés vaciar el carrito?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Vaciar')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<VentaRapidaCubit>().vaciarCarrito();
      context.pop();
    }
  }

  Future<void> _siguiente(BuildContext context) async {
    final cubit = context.read<VentaRapidaCubit>();
    final tipo = await showDialog<String>(
      context: context,
      builder: (_) => const TipoComprobanteDialog(),
    );
    if (tipo == null) return;
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

  @override
  void initState() {
    super.initState();
    _cantCtrl = TextEditingController(text: widget.item.cantidad.toStringAsFixed(0));
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  /// Al perder foco, si el cajero borró el campo o quedó inválido, re-sincroniza
  /// el TextField con la cantidad real del state. Evita inconsistencia visual
  /// (campo vacío pero state con cantidad anterior).
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final stock = item.stockDisponible ?? 0;
    final excedeStock = item.cantidad > stock;

    return Padding(
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
              ],
            ),
          ),
          // Precio (con base tachado si hay nivel aplicado)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.nivelAplicado != null && item.precioBase != null)
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
                      fontWeight: item.nivelAplicado != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: item.nivelAplicado != null
                          ? Colors.green.shade700
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Stock — ancho fijo alineado con el header (hasta 3 dígitos).
          SizedBox(
            width: 50,
            child: Center(
              child: Text(
                '$stock',
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
                        borderColor: excedeStock ? Colors.red : AppColors.blue1,
                        height: 27,
                        onSubmitted: (v) {
                          final n = double.tryParse(v) ?? 0;
                          context
                              .read<VentaRapidaCubit>()
                              .actualizarCantidad(widget.index, n);
                        },
                        onChanged: (v) {
                          final n = double.tryParse(v) ?? 0;
                          context
                              .read<VentaRapidaCubit>()
                              .actualizarCantidad(widget.index, n);
                        },
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
    );
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
  final dynamic item; // VentaDetalleInput
  final int? index; // índice en state.items (para callbacks que esperan index)

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
    this.comboId, // si pertenece a un combo
  })  : isHeader = false,
        comboNombre = null,
        comboTotal = null,
        comboAhorro = null;
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

/// Header visual de un combo en el carrito. Muestra ícono + nombre + total
/// y un botón "X" para eliminar el combo entero (todos sus componentes).
/// Si hay ahorro (descuento prorrateado entre componentes > 0), también lo
/// muestra abajo en verde como "Ahorro S/X.XX".
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
