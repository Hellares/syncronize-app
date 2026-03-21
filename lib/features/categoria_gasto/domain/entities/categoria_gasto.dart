import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class CategoriaGasto extends Equatable {
  final String id;
  final String nombre;
  final String tipo; // INGRESO or EGRESO
  final String? icono;
  final String? color;

  const CategoriaGasto({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.icono,
    this.color,
  });

  IconData get iconData {
    if (icono == null) return Icons.category;
    final codePoint = int.tryParse(icono!);
    if (codePoint == null) return Icons.category;
    return IconData(codePoint, fontFamily: 'MaterialIcons');
  }

  Color get colorValue {
    if (color == null) return Colors.grey;
    final hex = color!.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  List<Object?> get props => [id, nombre, tipo, icono, color];
}
