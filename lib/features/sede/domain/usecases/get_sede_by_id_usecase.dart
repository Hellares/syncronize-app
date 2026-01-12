import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../../empresa/domain/entities/sede.dart';
import '../repositories/sede_repository.dart';

/// Use case para obtener los detalles de una sede específica
@injectable
class GetSedeByIdUseCase {
  final SedeRepository _repository;

  GetSedeByIdUseCase(this._repository);

  Future<Resource<Sede>> call({
    required String empresaId,
    required String sedeId,
  }) async {
    return await _repository.getSedeById(
      empresaId: empresaId,
      sedeId: sedeId,
    );
  }
}
