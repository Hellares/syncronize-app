import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/resource.dart';
import '../entities/user.dart';
import '../../data/datasources/auth_local_datasource.dart';

/// Caso de uso para obtener el usuario guardado localmente
@injectable
class GetLocalUserUseCase implements UseCase<User?, NoParams> {
  final AuthLocalDataSource localDataSource;

  GetLocalUserUseCase(this.localDataSource);

  @override
  Future<Resource<User?>> call(NoParams params) async {
    try {
      // Obtener usuario guardado en cache local
      final userModel = await localDataSource.getUserInfo();

      if (userModel != null) {
        return Success(userModel.toEntity());
      } else {
        return Success(null);
      }
    } catch (e) {
      // Si hay error leyendo cache, devolver null
      return Success(null);
    }
  }
}
