import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/tesoreria.dart';
import '../repositories/caja_repository.dart';

@injectable
class GetTesoreriaResumenUseCase {
  final CajaRepository _repository;

  GetTesoreriaResumenUseCase(this._repository);

  Future<Resource<TesoreriaResumen>> call(String sedeId) {
    return _repository.getTesoreriaResumen(sedeId);
  }
}
