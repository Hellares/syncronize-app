import '../../../../core/utils/resource.dart';
import '../entities/cuenta_por_pagar.dart';

abstract class CuentasPagarRepository {
  Future<Resource<List<CuentaPorPagar>>> listar({String? estado});
  Future<Resource<ResumenCuentasPagar>> getResumen();
}
