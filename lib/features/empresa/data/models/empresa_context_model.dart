import '../../domain/entities/empresa_context.dart';
import 'empresa_info_model.dart';
import 'empresa_permissions_model.dart';
import 'empresa_statistics_model.dart';
import 'sede_model.dart';
import 'user_role_info_model.dart';

class EmpresaContextModel extends EmpresaContext {
  const EmpresaContextModel({
    required super.empresa,
    required super.userRoles,
    required super.sedes,
    required super.permissions,
    required super.statistics,
  });

  factory EmpresaContextModel.fromJson(Map<String, dynamic> json) {
    return EmpresaContextModel(
      empresa: EmpresaInfoModel.fromJson(
        json['empresa'] as Map<String, dynamic>,
      ),
      userRoles: (json['userRoles'] as List<dynamic>)
          .map((e) => UserRoleInfoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      sedes: (json['sedes'] as List<dynamic>)
          .map((e) => SedeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      permissions: EmpresaPermissionsModel.fromJson(
        json['permissions'] as Map<String, dynamic>,
      ),
      statistics: EmpresaStatisticsModel.fromJson(
        json['statistics'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'empresa': EmpresaInfoModel.fromEntity(empresa).toJson(),
      'userRoles': userRoles
          .map((e) => UserRoleInfoModel.fromEntity(e).toJson())
          .toList(),
      'sedes': sedes.map((e) => SedeModel.fromEntity(e).toJson()).toList(),
      'permissions':
          EmpresaPermissionsModel.fromEntity(permissions).toJson(),
      'statistics':
          EmpresaStatisticsModel.fromEntity(statistics).toJson(),
    };
  }

  EmpresaContext toEntity() => this;

  factory EmpresaContextModel.fromEntity(EmpresaContext entity) {
    return EmpresaContextModel(
      empresa: entity.empresa,
      userRoles: entity.userRoles,
      sedes: entity.sedes,
      permissions: entity.permissions,
      statistics: entity.statistics,
    );
  }
}
