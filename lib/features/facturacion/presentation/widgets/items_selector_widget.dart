import 'package:flutter/material.dart';
import '../../domain/entities/crear_nota_item.dart';

class ItemsSelectorWidget extends StatelessWidget {
  final List<CrearNotaItem> items;
  final List<bool> incluidos;
  final Map<int, double> cantidadesEditadas;
  final void Function(int index, bool incluido) onToggle;
  final void Function(int index, double cantidad) onCantidadChanged;

  const ItemsSelectorWidget({
    super.key,
    required this.items,
    required this.incluidos,
    required this.cantidadesEditadas,
    required this.onToggle,
    required this.onCantidadChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          'No hay items disponibles del comprobante origen.',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++)
            _ItemRow(
              index: i,
              item: items[i],
              incluido: incluidos.length > i ? incluidos[i] : true,
              cantidadEditada: cantidadesEditadas[i],
              onToggle: (v) => onToggle(i, v),
              onCantidadChanged: (v) => onCantidadChanged(i, v),
              isLast: i == items.length - 1,
            ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final int index;
  final CrearNotaItem item;
  final bool incluido;
  final double? cantidadEditada;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double> onCantidadChanged;
  final bool isLast;

  const _ItemRow({
    required this.index,
    required this.item,
    required this.incluido,
    required this.cantidadEditada,
    required this.onToggle,
    required this.onCantidadChanged,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final cantidadActual = cantidadEditada ?? item.cantidad;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: !isLast ? Border(bottom: BorderSide(color: Colors.grey.shade200)) : null,
        color: incluido ? null : Colors.grey.shade50,
      ),
      child: Row(
        children: [
          Checkbox(
            value: incluido,
            onChanged: (v) => onToggle(v ?? false),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.descripcion,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: incluido ? Colors.black87 : Colors.grey,
                    decoration: incluido ? null : TextDecoration.lineThrough,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Original: ${item.cantidad} × S/${item.valorUnitario.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 70,
            child: TextFormField(
              enabled: incluido,
              initialValue: cantidadActual.toString(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Cant.',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 11),
              onChanged: (v) {
                final n = double.tryParse(v.replaceAll(',', '.'));
                if (n != null && n > 0) onCantidadChanged(n);
              },
            ),
          ),
        ],
      ),
    );
  }
}
