import 'package:equatable/equatable.dart';
import 'marca_maestra.dart';

/// Entity que representa una marca activada para una empresa
/// Puede ser una referencia a una marca maestra o una marca personalizada
class EmpresaMarca extends Equatable {
  final String id;
  final String empresaId;
  final String? marcaMaestraId;

  // Campos para marcas personalizadas
  final String? nombrePersonalizado;
  final String? descripcionPersonalizada;
  final String? logoPersonalizado;
  final String? sitioWebPersonalizado;

  // Personalización
  final String? nombreLocal;

  // Configuración
  final int? orden;
  final bool isVisible;
  final bool isActive;
  final DateTime? deletedAt;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  // Relación
  final MarcaMaestra? marcaMaestra;

  const EmpresaMarca({
    required this.id,
    required this.empresaId,
    this.marcaMaestraId,
    this.nombrePersonalizado,
    this.descripcionPersonalizada,
    this.logoPersonalizado,
    this.sitioWebPersonalizado,
    this.nombreLocal,
    this.orden,
    required this.isVisible,
    required this.isActive,
    this.deletedAt,
    required this.creadoEn,
    required this.actualizadoEn,
    this.marcaMaestra,
  });

  /// Verifica si es una marca personalizada (no maestra)
  bool get esPersonalizada => marcaMaestraId == null;

  /// Obtiene el nombre a mostrar
  String get nombreDisplay {
    if (nombreLocal != null && nombreLocal!.isNotEmpty) {
      return nombreLocal!;
    }
    if (marcaMaestra != null) {
      return marcaMaestra!.nombre;
    }
    return nombrePersonalizado ?? '';
  }

  /// Obtiene la descripción a mostrar
  String? get descripcionDisplay {
    return marcaMaestra?.descripcion ?? descripcionPersonalizada;
  }

  /// Obtiene el logo a mostrar
  String? get logoDisplay {
    return logoPersonalizado ?? marcaMaestra?.logo;
  }

  /// Obtiene el sitio web a mostrar
  String? get sitioWebDisplay {
    return sitioWebPersonalizado ?? marcaMaestra?.sitioWeb;
  }

  @override
  List<Object?> get props => [
        id,
        empresaId,
        marcaMaestraId,
        nombrePersonalizado,
        descripcionPersonalizada,
        logoPersonalizado,
        sitioWebPersonalizado,
        nombreLocal,
        orden,
        isVisible,
        isActive,
        deletedAt,
        creadoEn,
        actualizadoEn,
        marcaMaestra,
      ];
}
