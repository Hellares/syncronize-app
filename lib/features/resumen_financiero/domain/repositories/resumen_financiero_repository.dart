import '../../../../core/utils/resource.dart';
import '../entities/resumen_financiero.dart';

abstract class ResumenFinancieroRepository {
  Future<Resource<ResumenFinanciero>> getResumen({
    String? fechaDesde,
    String? fechaHasta,
    String? sedeId,
  });

  Future<Resource<GraficoDiario>> getGraficoDiario({
    String? fechaDesde,
    String? fechaHasta,
    String? sedeId,
  });

  Future<Resource<List<int>>> exportLibroContable({
    required int mes,
    required int anio,
    void Function(int, int)? onReceiveProgress,
  });

  Future<Resource<List<int>>> exportCuentasCobrar({
    void Function(int, int)? onReceiveProgress,
  });

  Future<Resource<List<int>>> exportCuentasPagar({
    void Function(int, int)? onReceiveProgress,
  });
}
