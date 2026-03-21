import '../../../../core/utils/resource.dart';
import '../entities/cuenta_por_cobrar.dart';

abstract class CuentasCobrarRepository {
  Future<Resource<List<CuentaPorCobrar>>> listar({String? estado});
  Future<Resource<ResumenCuentasCobrar>> getResumen();
}
