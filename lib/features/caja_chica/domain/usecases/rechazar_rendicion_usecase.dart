import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/caja_chica_repository.dart';

@injectable
class RechazarRendicionUseCase {
  final CajaChicaRepository _repository;

  RechazarRendicionUseCase(this._repository);

  Future<Resource<void>> call({
    required String rendicionId,
    required String observaciones,
  }) {
    return _repository.rechazarRendicion(
      rendicionId: rendicionId,
      observaciones: observaciones,
    );
  }
}
