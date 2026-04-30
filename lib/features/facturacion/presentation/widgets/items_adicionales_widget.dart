import 'package:flutter/material.dart';
import '../../domain/entities/crear_nota_item.dart';

/// Editor de items adicionales para Nota de Débito (cargos extra: intereses,
/// aumento de valor, penalidades). Cada fila permite editar descripción,
/// cantidad, valor unitario y tipo de afectación. IGV/total se recalculan
/// en el cubit.
class ItemsAdicionalesWidget extends StatelessWidget {
  final List<CrearNotaItem> items;
  final void Function(int index, CrearNotaItem item) onEditar;
  final void Function(int index) onEliminar;
  final VoidCallback onAgregar;
  final String moneda;

  const ItemsAdicionalesWidget({
    super.key,
    required this.items,
    required this.onEditar,
    required this.onEliminar,
    required this.onAgregar,
    this.moneda = 'PEN',
  });

  String get _simboloMoneda => moneda == 'USD' ? '\$' : 'S/';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Text(
              'Sin items adicionales. Si no agregas ninguno, el backend copiará los items del comprobante origen (caso ajustes IGV puro).',
              style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++)
                  _ItemRow(
                    key: ValueKey('item-adicional-$i'),
                    item: items[i],
                    moneda: _simboloMoneda,
                    onChanged: (it) => onEditar(i, it),
                    onEliminar: () => onEliminar(i),
                    isLast: i == items.length - 1,
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Agregar item', style: TextStyle(fontSize: 11)),
            onPressed: onAgregar,
          ),
        ),
        if (items.isNotEmpty) _Resumen(items: items, moneda: _simboloMoneda),
      ],
    );
  }
}

class _ItemRow extends StatefulWidget {
  final CrearNotaItem item;
  final String moneda;
  final ValueChanged<CrearNotaItem> onChanged;
  final VoidCallback onEliminar;
  final bool isLast;

  const _ItemRow({
    super.key,
    required this.item,
    required this.moneda,
    required this.onChanged,
    required this.onEliminar,
    required this.isLast,
  });

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  late TextEditingController _descCtrl;
  late TextEditingController _cantCtrl;
  late TextEditingController _valorCtrl;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.item.descripcion);
    _cantCtrl = TextEditingController(text: _formatNum(widget.item.cantidad));
    _valorCtrl =
        TextEditingController(text: _formatNum(widget.item.valorUnitario));
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _cantCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  String _formatNum(double n) =>
      n == n.truncate() ? n.toInt().toString() : n.toString();

  void _emit({
    String? descripcion,
    double? cantidad,
    double? valorUnitario,
    String? tipoAfectacion,
  }) {
    // CrearNotaItem.copyWith no expone descripcion ni tipoAfectacion, así que
    // reconstruimos el item completo cuando alguno de esos cambia.
    widget.onChanged(CrearNotaItem(
      descripcion: descripcion ?? widget.item.descripcion,
      cantidad: cantidad ?? widget.item.cantidad,
      valorUnitario: valorUnitario ?? widget.item.valorUnitario,
      precioUnitario: widget.item.precioUnitario,
      tipoAfectacion: tipoAfectacion ?? widget.item.tipoAfectacion,
      igv: widget.item.igv,
      icbper: widget.item.icbper,
      subtotal: widget.item.subtotal,
      total: widget.item.total,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: !widget.isLast
            ? Border(bottom: BorderSide(color: Colors.grey.shade200))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Descripción + botón eliminar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Ej: Intereses por mora factura F002-100',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 11),
                  onChanged: (v) => _emit(descripcion: v),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 18, color: Colors.red.shade400),
                onPressed: widget.onEliminar,
                tooltip: 'Eliminar item',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Cantidad + Valor unitario + Afectación
          Row(
            children: [
              SizedBox(
                width: 70,
                child: TextField(
                  controller: _cantCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Cant.',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 11),
                  onChanged: (v) {
                    final n = double.tryParse(v.replaceAll(',', '.'));
                    if (n != null && n > 0) _emit(cantidad: n);
                  },
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _valorCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'V. unit. ${widget.moneda}',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 6),
                    border: const OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 11),
                  onChanged: (v) {
                    final n = double.tryParse(v.replaceAll(',', '.'));
                    if (n != null && n >= 0) _emit(valorUnitario: n);
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: widget.item.tipoAfectacion ?? '10',
                  decoration: const InputDecoration(
                    labelText: 'Afectación',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                  items: const [
                    DropdownMenuItem(
                        value: '10',
                        child: Text('Gravado (IGV)',
                            style: TextStyle(fontSize: 11))),
                    DropdownMenuItem(
                        value: '20',
                        child: Text('Exonerado',
                            style: TextStyle(fontSize: 11))),
                    DropdownMenuItem(
                        value: '30',
                        child: Text('Inafecto',
                            style: TextStyle(fontSize: 11))),
                  ],
                  onChanged: (v) {
                    if (v != null) _emit(tipoAfectacion: v);
                  },
                ),
              ),
            ],
          ),
          // Totales calculados
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal: ${widget.moneda}${(widget.item.subtotal ?? 0).toStringAsFixed(2)}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
              ),
              Text(
                'IGV: ${widget.moneda}${(widget.item.igv ?? 0).toStringAsFixed(2)}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
              ),
              Text(
                'Total: ${widget.moneda}${(widget.item.total ?? 0).toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  final List<CrearNotaItem> items;
  final String moneda;
  const _Resumen({required this.items, required this.moneda});

  @override
  Widget build(BuildContext context) {
    final subtotal =
        items.fold<double>(0, (s, it) => s + (it.subtotal ?? 0));
    final igv = items.fold<double>(0, (s, it) => s + (it.igv ?? 0));
    final icbper = items.fold<double>(0, (s, it) => s + (it.icbper ?? 0));
    final total = subtotal + igv + icbper;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Subtotal $moneda${subtotal.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 11)),
          Text('IGV $moneda${igv.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 11)),
          if (icbper > 0)
            Text('ICBPER $moneda${icbper.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 11)),
          Text(
            'Total $moneda${total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

