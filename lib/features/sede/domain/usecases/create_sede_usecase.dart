import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../../empresa/domain/entities/sede.dart';
import '../repositories/sede_repository.dart';

/// Use case para crear una nueva sede
@injectable
class CreateSedeUseCase {
  final SedeRepository _repository;

  CreateSedeUseCase(this._repository);

  Future<Resource<Sede>> call({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    return await _repository.createSede(
      empresaId: empresaId,
      data: data,
    );
  }
}
