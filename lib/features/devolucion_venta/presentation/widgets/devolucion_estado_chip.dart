import 'package:flutter/material.dart';
import '../../domain/entities/devolucion_venta.dart';

class DevolucionEstadoChip extends StatelessWidget {
  final EstadoDevolucion estado;

  const DevolucionEstadoChip({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final (color, bgColor) = _getColors();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(estado.label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  (Color, Color) _getColors() {
    switch (estado) {
      case EstadoDevolucion.pendiente: return (Colors.orange.shade700, Colors.orange.shade50);
      case EstadoDevolucion.aprobada: return (Colors.blue.shade700, Colors.blue.shade50);
      case EstadoDevolucion.procesada: return (Colors.green.shade700, Colors.green.shade50);
      case EstadoDevolucion.rechazada: return (Colors.red.shade700, Colors.red.shade50);
      case EstadoDevolucion.cancelada: return (Colors.grey.shade700, Colors.grey.shade200);
    }
  }
}
