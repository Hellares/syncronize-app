import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/auth_methods_response.dart';

part 'auth_methods_response_model.g.dart';

@JsonSerializable()
class AuthMethodsResponseModel {
  final String email;
  final bool exists;
  final List<String> methods;
  final int? authMethodsCount;

  AuthMethodsResponseModel({
    required this.email,
    required this.exists,
    required this.methods,
    this.authMethodsCount,
  });

  factory AuthMethodsResponseModel.fromJson(Map<String, dynamic> json) =>
      _$AuthMethodsResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$AuthMethodsResponseModelToJson(this);

  AuthMethodsResponse toEntity() => AuthMethodsResponse(
        email: email,
        exists: exists,
        methods: methods,
        authMethodsCount: authMethodsCount,
      );
}
