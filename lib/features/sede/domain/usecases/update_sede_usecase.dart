import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../../empresa/domain/entities/sede.dart';
import '../repositories/sede_repository.dart';

/// Use case para actualizar una sede existente
@injectable
class UpdateSedeUseCase {
  final SedeRepository _repository;

  UpdateSedeUseCase(this._repository);

  Future<Resource<Sede>> call({
    required String empresaId,
    required String sedeId,
    required Map<String, dynamic> data,
  }) async {
    return await _repository.updateSede(
      empresaId: empresaId,
      sedeId: sedeId,
      data: data,
    );
  }
}
