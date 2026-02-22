import 'package:equatable/equatable.dart';

/// Regla de compatibilidad entre atributos de productos
class ReglaCompatibilidad extends Equatable {
  final String id;
  final String empresaId;
  final String nombre;
  final String? descripcion;
  final String atributoOrigenClave;
  final String categoriaOrigenId;
  final String atributoDestinoClave;
  final String categoriaDestinoId;
  final String tipoValidacion; // 'IGUAL' | 'INCLUYE_EN'
  final Map<String, List<String>>? mapeoValores;
  final bool isActive;
  final String? categoriaOrigenNombre;
  final String? categoriaDestinoNombre;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  const ReglaCompatibilidad({
    required this.id,
    required this.empresaId,
    required this.nombre,
    this.descripcion,
    required this.atributoOrigenClave,
    required this.categoriaOrigenId,
    required this.atributoDestinoClave,
    required this.categoriaDestinoId,
    required this.tipoValidacion,
    this.mapeoValores,
    required this.isActive,
    this.categoriaOrigenNombre,
    this.categoriaDestinoNombre,
    this.creadoEn,
    this.actualizadoEn,
  });

  @override
  List<Object?> get props => [
        id,
        empresaId,
        nombre,
        descripcion,
        atributoOrigenClave,
        categoriaOrigenId,
        atributoDestinoClave,
        categoriaDestinoId,
        tipoValidacion,
        mapeoValores,
        isActive,
        categoriaOrigenNombre,
        categoriaDestinoNombre,
        creadoEn,
        actualizadoEn,
      ];
}
