import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/descuento_repository.dart';

/// Use case para remover un familiar de un trabajador
@injectable
class RemoverFamiliar {
  final DescuentoRepository _repository;

  RemoverFamiliar(this._repository);

  Future<Resource<void>> call({
    required String trabajadorId,
    required String familiarId,
  }) async {
    return await _repository.removerFamiliar(
      trabajadorId: trabajadorId,
      familiarId: familiarId,
    );
  }
}
