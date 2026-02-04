import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/combo_repository.dart';

@injectable
class LiberarReservaUseCase {
  final ComboRepository repository;

  LiberarReservaUseCase(this.repository);

  Future<Resource<void>> call({
    required String comboId,
    required String sedeId,
  }) {
    return repository.liberarReserva(
      comboId: comboId,
      sedeId: sedeId,
    );
  }
}
