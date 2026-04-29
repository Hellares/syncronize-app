import 'package:flutter/material.dart';
import '../../domain/entities/venta.dart';

class MetodoPagoSelector extends StatelessWidget {
  final MetodoPago? selected;
  final ValueChanged<MetodoPago?> onChanged;

  const MetodoPagoSelector({
    super.key,
    this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MetodoPago.values
          // MIXTO no es elegible manualmente — se deriva al sumar varios pagos.
          .where((m) => m != MetodoPago.mixto)
          .map((metodo) {
        final isSelected = selected == metodo;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIcon(metodo),
                size: 16,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              const SizedBox(width: 4),
              Text(metodo.label),
            ],
          ),
          selected: isSelected,
          onSelected: (val) => onChanged(val ? metodo : null),
          selectedColor: _getColor(metodo),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 12,
          ),
        );
      }).toList(),
    );
  }

  IconData _getIcon(MetodoPago metodo) {
    switch (metodo) {
      case MetodoPago.efectivo:
        return Icons.payments_outlined;
      case MetodoPago.tarjeta:
        return Icons.credit_card;
      case MetodoPago.yape:
        return Icons.phone_android;
      case MetodoPago.plin:
        return Icons.phone_android;
      case MetodoPago.transferencia:
        return Icons.account_balance;
      case MetodoPago.credito:
        return Icons.schedule;
      case MetodoPago.mixto:
        return Icons.shuffle;
    }
  }

  Color _getColor(MetodoPago metodo) {
    switch (metodo) {
      case MetodoPago.efectivo:
        return Colors.green.shade600;
      case MetodoPago.tarjeta:
        return Colors.blue.shade600;
      case MetodoPago.yape:
        return Colors.purple.shade600;
      case MetodoPago.plin:
        return Colors.teal.shade600;
      case MetodoPago.transferencia:
        return Colors.indigo.shade600;
      case MetodoPago.credito:
        return Colors.orange.shade600;
      case MetodoPago.mixto:
        return Colors.deepPurple.shade600;
    }
  }
}
