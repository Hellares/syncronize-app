import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/available_company.dart';

part 'available_company_model.g.dart';

@JsonSerializable()
class AvailableCompanyModel {
  final String id;
  final String nombre;
  final String subdominio;
  final String? logo;
  final List<String> roles;

  AvailableCompanyModel({
    required this.id,
    required this.nombre,
    required this.subdominio,
    this.logo,
    required this.roles,
  });

  factory AvailableCompanyModel.fromJson(Map<String, dynamic> json) =>
      _$AvailableCompanyModelFromJson(json);

  Map<String, dynamic> toJson() => _$AvailableCompanyModelToJson(this);

  AvailableCompany toEntity() {
    return AvailableCompany(
      id: id,
      nombre: nombre,
      subdominio: subdominio,
      logo: logo,
      roles: roles,
    );
  }

  factory AvailableCompanyModel.fromEntity(AvailableCompany company) {
    return AvailableCompanyModel(
      id: company.id,
      nombre: company.nombre,
      subdominio: company.subdominio,
      logo: company.logo,
      roles: company.roles,
    );
  }
}
