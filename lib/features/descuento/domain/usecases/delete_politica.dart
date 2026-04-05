import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/descuento_repository.dart';

/// Use case para eliminar una política de descuento
@injectable
class DeletePolitica {
  final DescuentoRepository _repository;

  DeletePolitica(this._repository);

  Future<Resource<void>> call(String id) async {
    return await _repository.deletePolitica(id);
  }
}
