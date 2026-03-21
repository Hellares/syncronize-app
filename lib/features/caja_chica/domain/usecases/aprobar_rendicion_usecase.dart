import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/caja_chica_repository.dart';

@injectable
class AprobarRendicionUseCase {
  final CajaChicaRepository _repository;

  AprobarRendicionUseCase(this._repository);

  Future<Resource<void>> call({
    required String rendicionId,
    String? observaciones,
  }) {
    return _repository.aprobarRendicion(
      rendicionId: rendicionId,
      observaciones: observaciones,
    );
  }
}
