import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/descuento_repository.dart';

/// Use case para quitar una categoría de una política de descuento
@injectable
class RemoverCategoriaPolitica {
  final DescuentoRepository _repository;

  RemoverCategoriaPolitica(this._repository);

  Future<Resource<void>> call({
    required String politicaId,
    required String categoriaId,
  }) async {
    return await _repository.removerCategoriaDePolitica(
      politicaId: politicaId,
      categoriaId: categoriaId,
    );
  }
}
