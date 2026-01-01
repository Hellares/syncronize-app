import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/combo.dart';
import '../repositories/combo_repository.dart';

@injectable
class GetCombosUseCase {
  final ComboRepository repository;

  GetCombosUseCase(this.repository);

  Future<Resource<List<Combo>>> call({
    required String empresaId,
  }) {
    return repository.getCombos(
      empresaId: empresaId,
    );
  }
}
