import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/categoria_gasto.dart';
import '../repositories/categoria_gasto_repository.dart';

@injectable
class GetCategoriasGastoUseCase {
  final CategoriaGastoRepository _repository;

  GetCategoriasGastoUseCase(this._repository);

  Future<Resource<List<CategoriaGasto>>> call({String? tipo}) {
    return _repository.listar(tipo: tipo);
  }
}
