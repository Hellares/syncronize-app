import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/inventario.dart';
import '../repositories/inventario_repository.dart';

@injectable
class CrearInventarioUseCase {
  final InventarioRepository _repository;

  CrearInventarioUseCase(this._repository);

  Future<Resource<Inventario>> call({
    required Map<String, dynamic> data,
  }) {
    return _repository.crear(data: data);
  }
}
