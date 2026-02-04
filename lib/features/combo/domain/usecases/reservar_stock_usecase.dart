import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/combo_repository.dart';

@injectable
class ReservarStockUseCase {
  final ComboRepository repository;

  ReservarStockUseCase(this.repository);

  Future<Resource<int>> call({
    required String comboId,
    required String sedeId,
    required int cantidad,
  }) {
    return repository.reservarStock(
      comboId: comboId,
      sedeId: sedeId,
      cantidad: cantidad,
    );
  }
}
