import '../../domain/entities/categoria_gasto.dart';

class CategoriaGastoModel {
  final String id;
  final String nombre;
  final String tipo;
  final String? icono;
  final String? color;

  const CategoriaGastoModel({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.icono,
    this.color,
  });

  factory CategoriaGastoModel.fromJson(Map<String, dynamic> json) {
    return CategoriaGastoModel(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      tipo: json['tipo'] as String? ?? 'EGRESO',
      icono: json['icono'] as String?,
      color: json['color'] as String?,
    );
  }

  CategoriaGasto toEntity() {
    return CategoriaGasto(
      id: id,
      nombre: nombre,
      tipo: tipo,
      icono: icono,
      color: color,
    );
  }
}
