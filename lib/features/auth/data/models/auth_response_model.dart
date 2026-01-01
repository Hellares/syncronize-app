import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/auth_response.dart';
import 'auth_tokens_model.dart';
import 'mode_option_model.dart';
import 'tenant_model.dart';
import 'user_model.dart';

part 'auth_response_model.g.dart';

@JsonSerializable(explicitToJson: true)
class AuthResponseModel {
  final UserModel user;
  final TenantModel? tenant;
  final String? accessToken;
  final String? refreshToken;
  final String? expiresIn;
  final String? sessionId;

  // Campo mode para identificar el tipo de login
  final String? mode; // 'marketplace' | 'management'

  // Campos para selección de modo
  final bool? requiresSelection;
  final String? message;
  final List<ModeOptionModel>? options;

  AuthResponseModel({
    required this.user,
    this.tenant,
    this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.sessionId,
    this.mode,
    this.requiresSelection,
    this.message,
    this.options,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseModelToJson(this);

  AuthResponse toEntity() {
    return AuthResponse(
      user: user.toEntity(),
      tenant: tenant?.toEntity(),
      tokens: (accessToken != null && refreshToken != null && expiresIn != null)
          ? AuthTokensModel(
              accessToken: accessToken!,
              refreshToken: refreshToken!,
              expiresIn: expiresIn!,
            ).toEntity()
          : null,
      mode: mode,
      requiresSelection: requiresSelection,
      message: message,
      options: options?.map((o) => o.toEntity()).toList(),
    );
  }
}
