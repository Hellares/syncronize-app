import '../../../../core/utils/resource.dart';
import '../entities/libro_contable.dart';

abstract class LibroContableRepository {
  Future<Resource<LibroContable>> getLibro({
    required int mes,
    required int anio,
  });
}
