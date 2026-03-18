import 'package:equatable/equatable.dart';

class DireccionPersona extends Equatable {
  final String id;
  final String personaId;
  final String tipo;
  final String? etiqueta;
  final String direccion;
  final String? referencia;
  final String? distrito;
  final String? provincia;
  final String? departamento;
  final String? pais;
  final Map<String, dynamic>? coordenadas;
  final bool esPredeterminada;
  final DateTime creadoEn;

  const DireccionPersona({
    required this.id,
    required this.personaId,
    required this.tipo,
    this.etiqueta,
    required this.direccion,
    this.referencia,
    this.distrito,
    this.provincia,
    this.departamento,
    this.pais,
    this.coordenadas,
    required this.esPredeterminada,
    required this.creadoEn,
  });

  double? get lat => (coordenadas?['lat'] as num?)?.toDouble();
  double? get lng => ((coordenadas?['lng'] ?? coordenadas?['lon']) as num?)?.toDouble();
  bool get tieneCoordenadas => lat != null && lng != null;

  String get displayName => etiqueta ?? tipoLabel;

  String get tipoLabel {
    switch (tipo) {
      case 'ENVIO': return 'Envío';
      case 'FISCAL': return 'Fiscal';
      case 'TRABAJO': return 'Trabajo';
      default: return 'Otra';
    }
  }

  String get direccionCompleta {
    return [direccion, distrito, provincia, departamento]
        .where((e) => e != null && e.isNotEmpty)
        .join(', ');
  }

  @override
  List<Object?> get props => [id, esPredeterminada, coordenadas];
}
