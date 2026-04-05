import 'package:flutter/material.dart';
import '../../domain/entities/cotizacion.dart';

/// Chip coloreado que muestra el estado de una cotizacion
class CotizacionEstadoChip extends StatelessWidget {
  final EstadoCotizacion estado;

  const CotizacionEstadoChip({
    super.key,
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado.label,
        style: TextStyle(
          color: _textColor,
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Color get _backgroundColor {
    switch (estado) {
      case EstadoCotizacion.borrador:
        return Colors.grey.shade100;
      case EstadoCotizacion.pendiente:
        return Colors.orange.shade100;
      case EstadoCotizacion.aprobada:
        return Colors.green.shade100;
      case EstadoCotizacion.rechazada:
        return Colors.red.shade100;
      case EstadoCotizacion.vencida:
        return Colors.brown.shade100;
      case EstadoCotizacion.convertida:
        return Colors.blue.shade100;
    }
  }

  Color get _textColor {
    switch (estado) {
      case EstadoCotizacion.borrador:
        return Colors.grey.shade700;
      case EstadoCotizacion.pendiente:
        return Colors.orange.shade700;
      case EstadoCotizacion.aprobada:
        return Colors.green.shade700;
      case EstadoCotizacion.rechazada:
        return Colors.red.shade700;
      case EstadoCotizacion.vencida:
        return Colors.brown.shade700;
      case EstadoCotizacion.convertida:
        return Colors.blue.shade700;
    }
  }
}
