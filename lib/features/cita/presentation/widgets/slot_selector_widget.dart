import 'package:flutter/material.dart';
import '../../domain/entities/slot_disponibilidad.dart';

class SlotSelectorWidget extends StatelessWidget {
  final List<SlotDisponibilidad> slots;
  final String? selectedSlot;
  final ValueChanged<SlotDisponibilidad> onSlotSelected;

  const SlotSelectorWidget({
    super.key,
    required this.slots,
    this.selectedSlot,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No hay horarios disponibles para esta fecha'),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) {
        final isSelected = selectedSlot == slot.horaInicio;
        final isAvailable = slot.disponible;

        return ChoiceChip(
          label: Text(slot.horaInicio),
          selected: isSelected,
          onSelected: isAvailable
              ? (_) => onSlotSelected(slot)
              : null,
          backgroundColor: isAvailable
              ? Colors.green.withOpacity(0.08)
              : Colors.grey.withOpacity(0.08),
          selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          labelStyle: TextStyle(
            color: isAvailable
                ? (isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.green.shade700)
                : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
          side: BorderSide(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : (isAvailable ? Colors.green.shade200 : Colors.grey.shade300),
          ),
        );
      }).toList(),
    );
  }
}
