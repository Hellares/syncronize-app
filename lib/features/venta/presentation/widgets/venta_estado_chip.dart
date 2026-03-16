import 'package:flutter/material.dart';
import '../../domain/entities/venta.dart';

class VentaEstadoChip extends StatelessWidget {
  final EstadoVenta estado;

  const VentaEstadoChip({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final (color, bgColor) = _getColors();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado.label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, Color) _getColors() {
    switch (estado) {
      case EstadoVenta.borrador:
        return (Colors.grey.shade700, Colors.grey.shade200);
      case EstadoVenta.confirmada:
        return (Colors.blue.shade700, Colors.blue.shade50);
      case EstadoVenta.pagadaParcial:
        return (Colors.orange.shade700, Colors.orange.shade50);
      case EstadoVenta.pagadaCompleta:
        return (Colors.green.shade700, Colors.green.shade50);
      case EstadoVenta.anulada:
        return (Colors.red.shade700, Colors.red.shade50);
    }
  }
}
