import '../../../../core/utils/resource.dart';
import '../entities/meta_financiera.dart';

abstract class MetaFinancieraRepository {
  Future<Resource<List<MetaFinanciera>>> getResumen();

  Future<Resource<MetaFinanciera>> crear({
    required String tipo,
    required String nombre,
    required double montoMeta,
    required DateTime fechaInicio,
    required DateTime fechaFin,
  });
}
