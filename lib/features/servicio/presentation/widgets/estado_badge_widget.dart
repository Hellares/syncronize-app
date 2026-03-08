import 'package:flutter/material.dart';

class EstadoBadgeWidget extends StatelessWidget {
  final String estado;
  const EstadoBadgeWidget({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: _color,
        ),
      ),
    );
  }

  String get _label {
    const labels = {
      'RECIBIDO': 'Recibido',
      'EN_DIAGNOSTICO': 'En Diagnóstico',
      'ESPERANDO_APROBACION': 'Esperando Aprobación',
      'EN_REPARACION': 'En Reparación',
      'PENDIENTE_PIEZAS': 'Pendiente Piezas',
      'REPARADO': 'Reparado',
      'LISTO_ENTREGA': 'Listo para Entrega',
      'ENTREGADO': 'Entregado',
      'FINALIZADO': 'Finalizado',
      'CANCELADO': 'Cancelado',
    };
    return labels[estado] ?? estado;
  }

  Color get _color {
    switch (estado) {
      case 'RECIBIDO':
        return Colors.blue;
      case 'EN_DIAGNOSTICO':
        return Colors.orange;
      case 'ESPERANDO_APROBACION':
        return Colors.amber.shade800;
      case 'EN_REPARACION':
        return Colors.indigo;
      case 'PENDIENTE_PIEZAS':
        return Colors.deepOrange;
      case 'REPARADO':
        return Colors.teal;
      case 'LISTO_ENTREGA':
        return Colors.green;
      case 'ENTREGADO':
        return Colors.green.shade800;
      case 'FINALIZADO':
        return Colors.grey;
      case 'CANCELADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
