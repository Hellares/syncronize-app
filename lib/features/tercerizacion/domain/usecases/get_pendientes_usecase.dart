import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/tercerizacion.dart';
import '../repositories/tercerizacion_repository.dart';

@injectable
class GetPendientesUseCase {
  final TercerizacionRepository _repository;

  GetPendientesUseCase(this._repository);

  Future<Resource<List<TercerizacionServicio>>> call() async {
    return await _repository.getPendientes();
  }
}
