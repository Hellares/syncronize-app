import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/prestamo.dart';
import '../repositories/prestamo_repository.dart';

@injectable
class GetResumenPrestamosUseCase {
  final PrestamoRepository _repository;

  GetResumenPrestamosUseCase(this._repository);

  Future<Resource<ResumenPrestamos>> call() {
    return _repository.getResumen();
  }
}
