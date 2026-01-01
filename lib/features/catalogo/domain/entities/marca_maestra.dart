import 'package:equatable/equatable.dart';

/// Entity que representa una marca maestra del catálogo global
class MarcaMaestra extends Equatable {
  final String id;
  final String nombre;
  final String slug;
  final String? descripcion;
  final String? logo;
  final String? sitioWeb;
  final String? paisOrigen;
  final bool esPopular;
  final bool isActive;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  const MarcaMaestra({
    required this.id,
    required this.nombre,
    required this.slug,
    this.descripcion,
    this.logo,
    this.sitioWeb,
    this.paisOrigen,
    required this.esPopular,
    required this.isActive,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  @override
  List<Object?> get props => [
        id,
        nombre,
        slug,
        descripcion,
        logo,
        sitioWeb,
        paisOrigen,
        esPopular,
        isActive,
        creadoEn,
        actualizadoEn,
      ];
}
