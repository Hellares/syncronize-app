import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/caja_chica.dart';
import '../repositories/caja_chica_repository.dart';

@injectable
class ListarCajasChicasUseCase {
  final CajaChicaRepository _repository;

  ListarCajasChicasUseCase(this._repository);

  Future<Resource<List<CajaChica>>> call({String? sedeId}) {
    return _repository.listarCajasChicas(sedeId: sedeId);
  }
}
