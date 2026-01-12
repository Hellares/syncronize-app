import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/sede_repository.dart';

/// Use case para eliminar una sede (soft delete)
@injectable
class DeleteSedeUseCase {
  final SedeRepository _repository;

  DeleteSedeUseCase(this._repository);

  Future<Resource<void>> call({
    required String empresaId,
    required String sedeId,
  }) async {
    return await _repository.deleteSede(
      empresaId: empresaId,
      sedeId: sedeId,
    );
  }
}
