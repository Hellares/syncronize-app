import 'package:equatable/equatable.dart';

/// Información de sesión activa
class SessionInfo extends Equatable {
  final String sessionId;
  final String deviceInfo;
  final String ipAddress;
  final DateTime createdAt;
  final DateTime lastActivityAt;
  final bool isCurrentSession;

  const SessionInfo({
    required this.sessionId,
    required this.deviceInfo,
    required this.ipAddress,
    required this.createdAt,
    required this.lastActivityAt,
    required this.isCurrentSession,
  });

  @override
  List<Object?> get props => [
        sessionId,
        deviceInfo,
        ipAddress,
        createdAt,
        lastActivityAt,
        isCurrentSession,
      ];
}
