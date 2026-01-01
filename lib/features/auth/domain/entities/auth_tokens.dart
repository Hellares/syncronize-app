import 'package:equatable/equatable.dart';

/// Entidad de tokens de autenticación
class AuthTokens extends Equatable {
  final String accessToken;
  final String refreshToken;
  final String expiresIn;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresIn];
}
