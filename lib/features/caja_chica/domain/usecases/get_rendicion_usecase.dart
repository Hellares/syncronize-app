import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/rendicion_caja_chica.dart';
import '../repositories/caja_chica_repository.dart';

@injectable
class GetRendicionUseCase {
  final CajaChicaRepository _repository;

  GetRendicionUseCase(this._repository);

  Future<Resource<RendicionCajaChica>> call({required String rendicionId}) {
    return _repository.getRendicion(rendicionId: rendicionId);
  }
}
