import 'package:equatable/equatable.dart';
import 'available_company.dart';

/// Opción de modo de login (marketplace o management)
class ModeOption extends Equatable {
  /// Tipo de modo: 'marketplace' o 'management'
  final String type;

  /// Etiqueta a mostrar al usuario
  final String label;

  /// Descripción del modo
  final String description;

  /// Empresas disponibles (solo para tipo 'management')
  final List<AvailableCompany>? availableCompanies;

  const ModeOption({
    required this.type,
    required this.label,
    required this.description,
    this.availableCompanies,
  });

  /// Indica si es modo marketplace
  bool get isMarketplace => type == 'marketplace';

  /// Indica si es modo management
  bool get isManagement => type == 'management';

  @override
  List<Object?> get props => [type, label, description, availableCompanies];

  @override
  String toString() => 'ModeOption(type: $type, label: $label)';
}
