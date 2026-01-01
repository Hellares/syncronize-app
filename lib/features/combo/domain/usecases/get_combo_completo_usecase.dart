import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/combo.dart';
import '../repositories/combo_repository.dart';

@injectable
class GetComboCompletoUseCase {
  final ComboRepository repository;

  GetComboCompletoUseCase(this.repository);

  Future<Resource<Combo>> call({
    required String comboId,
    required String empresaId,
  }) {
    return repository.getComboCompleto(
      comboId: comboId,
      empresaId: empresaId,
    );
  }
}
