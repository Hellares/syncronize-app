import '../../../../core/utils/resource.dart';
import '../entities/flujo_proyectado.dart';

abstract class FlujoProyectadoRepository {
  Future<Resource<List<PeriodoFlujo>>> getProyeccion({int? meses});
}
