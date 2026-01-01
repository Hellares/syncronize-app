import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/mode_option.dart';
import 'available_company_model.dart';

part 'mode_option_model.g.dart';

/// Modelo de opción de modo de login
@JsonSerializable(explicitToJson: true)
class ModeOptionModel {
  /// Tipo de modo: 'marketplace' o 'management'
  final String type;

  /// Etiqueta a mostrar al usuario
  final String label;

  /// Descripción del modo
  final String description;

  /// Empresas disponibles (solo para tipo 'management')
  final List<AvailableCompanyModel>? availableCompanies;

  const ModeOptionModel({
    required this.type,
    required this.label,
    required this.description,
    this.availableCompanies,
  });

  factory ModeOptionModel.fromJson(Map<String, dynamic> json) =>
      _$ModeOptionModelFromJson(json);

  Map<String, dynamic> toJson() => _$ModeOptionModelToJson(this);

  /// Convierte el modelo a entidad de dominio
  ModeOption toEntity() {
    return ModeOption(
      type: type,
      label: label,
      description: description,
      availableCompanies:
          availableCompanies?.map((c) => c.toEntity()).toList(),
    );
  }

  /// Crea un modelo desde una entidad de dominio
  factory ModeOptionModel.fromEntity(ModeOption entity) {
    return ModeOptionModel(
      type: entity.type,
      label: entity.label,
      description: entity.description,
      availableCompanies: entity.availableCompanies
          ?.map((c) => AvailableCompanyModel.fromEntity(c))
          .toList(),
    );
  }
}
