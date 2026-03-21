import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/prestamo.dart';
import '../repositories/prestamo_repository.dart';

@injectable
class GetPrestamosUseCase {
  final PrestamoRepository _repository;

  GetPrestamosUseCase(this._repository);

  Future<Resource<List<Prestamo>>> call({String? estado}) {
    return _repository.listar(estado: estado);
  }
}
