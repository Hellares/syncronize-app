import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/session_info.dart';

part 'session_info_model.g.dart';

@JsonSerializable()
class SessionInfoModel {
  final String sessionId;
  final String deviceInfo;
  final String ipAddress;
  final DateTime createdAt;
  final DateTime lastActivityAt;
  final bool isCurrentSession;

  SessionInfoModel({
    required this.sessionId,
    required this.deviceInfo,
    required this.ipAddress,
    required this.createdAt,
    required this.lastActivityAt,
    required this.isCurrentSession,
  });

  factory SessionInfoModel.fromJson(Map<String, dynamic> json) =>
      _$SessionInfoModelFromJson(json);

  Map<String, dynamic> toJson() => _$SessionInfoModelToJson(this);

  SessionInfo toEntity() {
    return SessionInfo(
      sessionId: sessionId,
      deviceInfo: deviceInfo,
      ipAddress: ipAddress,
      createdAt: createdAt,
      lastActivityAt: lastActivityAt,
      isCurrentSession: isCurrentSession,
    );
  }
}
