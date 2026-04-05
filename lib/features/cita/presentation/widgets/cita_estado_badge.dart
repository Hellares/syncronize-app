import 'package:flutter/material.dart';
import '../../../../core/fonts/app_fonts.dart';

class CitaEstadoBadge extends StatelessWidget {
  final String estado;

  const CitaEstadoBadge({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color.withValues(alpha: 0.3), width: 0.6),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 10,
          fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
          color: _color,
        ),
      ),
    );
  }

  String get _label {
    const labels = {
      'PENDIENTE': 'Pendiente',
      'CONFIRMADA': 'Confirmada',
      'EN_PROCESO': 'En Proceso',
      'COMPLETADA': 'Completada',
      'CANCELADA': 'Cancelada',
      'NO_ASISTIO': 'No Asistió',
    };
    return labels[estado] ?? estado;
  }

  Color get _color {
    switch (estado) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'CONFIRMADA':
        return Colors.blue;
      case 'EN_PROCESO':
        return Colors.indigo;
      case 'COMPLETADA':
        return Colors.green;
      case 'CANCELADA':
        return Colors.red;
      case 'NO_ASISTIO':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
