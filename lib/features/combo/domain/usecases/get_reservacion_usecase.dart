import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/combo_repository.dart';

@injectable
class GetReservacionUseCase {
  final ComboRepository repository;

  GetReservacionUseCase(this.repository);

  Future<Resource<int>> call({
    required String comboId,
    required String sedeId,
  }) {
    return repository.getReservacion(
      comboId: comboId,
      sedeId: sedeId,
    );
  }
}
