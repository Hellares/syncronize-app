import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/set_password_response.dart';

part 'set_password_response_model.g.dart';

@JsonSerializable()
class SetPasswordResponseModel {
  final bool success;
  final String message;

  SetPasswordResponseModel({
    required this.success,
    required this.message,
  });

  factory SetPasswordResponseModel.fromJson(Map<String, dynamic> json) =>
      _$SetPasswordResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$SetPasswordResponseModelToJson(this);

  SetPasswordResponse toEntity() => SetPasswordResponse(
        success: success,
        message: message,
      );
}
