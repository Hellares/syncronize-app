import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../../empresa/domain/entities/sede.dart';
import '../repositories/sede_repository.dart';

/// Use case para obtener todas las sedes de una empresa
@injectable
class GetSedesUseCase {
  final SedeRepository _repository;

  GetSedesUseCase(this._repository);

  Future<Resource<List<Sede>>> call(String empresaId) async {
    return await _repository.getSedes(empresaId);
  }
}
