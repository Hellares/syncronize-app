import 'package:equatable/equatable.dart';
import 'categoria_maestra.dart';

/// Entity que representa una categoría activada para una empresa
/// Puede ser una referencia a una categoría maestra o una categoría personalizada
class EmpresaCategoria extends Equatable {
  final String id;
  final String empresaId;
  final String? categoriaMaestraId;

  // Campos para categorías personalizadas
  final String? nombrePersonalizado;
  final String? descripcionPersonalizada;
  final String? padreId;

  // Personalización del nombre maestro
  final String? nombreLocal;

  // Configuración
  final int? orden;
  final bool isVisible;
  final bool isActive;
  final DateTime? deletedAt;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  // Relación
  final CategoriaMaestra? categoriaMaestra;

  const EmpresaCategoria({
    required this.id,
    required this.empresaId,
    this.categoriaMaestraId,
    this.nombrePersonalizado,
    this.descripcionPersonalizada,
    this.padreId,
    this.nombreLocal,
    this.orden,
    required this.isVisible,
    required this.isActive,
    this.deletedAt,
    required this.creadoEn,
    required this.actualizadoEn,
    this.categoriaMaestra,
  });

  /// Verifica si es una categoría personalizada (no maestra)
  bool get esPersonalizada => categoriaMaestraId == null;

  /// Obtiene el nombre a mostrar (prioridad: nombreLocal > categoriaMaestra.nombre > nombrePersonalizado)
  String get nombreDisplay {
    if (nombreLocal != null && nombreLocal!.isNotEmpty) {
      return nombreLocal!;
    }
    if (categoriaMaestra != null) {
      return categoriaMaestra!.nombre;
    }
    return nombrePersonalizado ?? '';
  }

  /// Obtiene la descripción a mostrar
  String? get descripcionDisplay {
    return categoriaMaestra?.descripcion ?? descripcionPersonalizada;
  }

  /// Obtiene el icono (solo categorías maestras)
  String? get icono => categoriaMaestra?.icono;

  /// Obtiene el slug (solo categorías maestras)
  String? get slug => categoriaMaestra?.slug;

  @override
  List<Object?> get props => [
        id,
        empresaId,
        categoriaMaestraId,
        nombrePersonalizado,
        descripcionPersonalizada,
        padreId,
        nombreLocal,
        orden,
        isVisible,
        isActive,
        deletedAt,
        creadoEn,
        actualizadoEn,
        categoriaMaestra,
      ];
}
