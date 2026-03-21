import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/caja_chica.dart';
import '../repositories/caja_chica_repository.dart';

@injectable
class GetCajaChicaUseCase {
  final CajaChicaRepository _repository;

  GetCajaChicaUseCase(this._repository);

  Future<Resource<CajaChica>> call({required String id}) {
    return _repository.getCajaChica(id: id);
  }
}
