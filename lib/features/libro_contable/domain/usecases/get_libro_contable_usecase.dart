import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/libro_contable.dart';
import '../repositories/libro_contable_repository.dart';

@injectable
class GetLibroContableUseCase {
  final LibroContableRepository _repository;

  GetLibroContableUseCase(this._repository);

  Future<Resource<LibroContable>> call({
    required int mes,
    required int anio,
  }) {
    return _repository.getLibro(mes: mes, anio: anio);
  }
}
