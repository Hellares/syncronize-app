import 'package:equatable/equatable.dart';
import 'configuracion_campo.dart';

class PlantillaServicio extends Equatable {
  final String id;
  final String empresaId;
  final String nombre;
  final String? descripcion;
  final bool isActive;
  final DateTime creadoEn;
  final DateTime actualizadoEn;
  final List<ConfiguracionCampo> campos;
  final int? serviciosCount;

  const PlantillaServicio({
    required this.id,
    required this.empresaId,
    required this.nombre,
    this.descripcion,
    this.isActive = true,
    required this.creadoEn,
    required this.actualizadoEn,
    this.campos = const [],
    this.serviciosCount,
  });

  @override
  List<Object?> get props => [id, nombre, isActive];
}
