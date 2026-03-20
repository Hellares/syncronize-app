import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/caja.dart';
import '../repositories/caja_repository.dart';

@injectable
class GetCajaActivaUseCase {
  final CajaRepository _repository;

  GetCajaActivaUseCase(this._repository);

  Future<Resource<Caja?>> call() {
    return _repository.getCajaActiva();
  }
}
