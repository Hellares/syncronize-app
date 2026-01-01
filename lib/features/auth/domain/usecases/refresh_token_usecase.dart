import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/resource.dart';
import '../entities/auth_tokens.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para refrescar el token de acceso
@injectable
class RefreshTokenUseCase implements UseCase<AuthTokens, RefreshTokenParams> {
  final AuthRepository repository;

  RefreshTokenUseCase(this.repository);

  @override
  Future<Resource<AuthTokens>> call(RefreshTokenParams params) async {
    return await repository.refreshToken(
      refreshToken: params.refreshToken,
    );
  }
}

/// Parámetros para refrescar token
class RefreshTokenParams extends Equatable {
  final String refreshToken;

  const RefreshTokenParams({
    required this.refreshToken,
  });

  @override
  List<Object?> get props => [refreshToken];
}
