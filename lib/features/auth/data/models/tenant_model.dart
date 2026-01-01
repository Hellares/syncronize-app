import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/tenant.dart';

part 'tenant_model.g.dart';

@JsonSerializable()
class TenantModel {
  final String id;
  final String name;
  final String role;

  TenantModel({
    required this.id,
    required this.name,
    required this.role,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) =>
      _$TenantModelFromJson(json);

  Map<String, dynamic> toJson() => _$TenantModelToJson(this);

  Tenant toEntity() {
    return Tenant(
      id: id,
      name: name,
      role: role,
    );
  }

  factory TenantModel.fromEntity(Tenant tenant) {
    return TenantModel(
      id: tenant.id,
      name: tenant.name,
      role: tenant.role,
    );
  }
}
