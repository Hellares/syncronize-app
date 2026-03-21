import '../../../../core/utils/resource.dart';
import '../entities/caja.dart';
import '../entities/caja_monitor.dart';
import '../entities/movimiento_caja.dart';
import '../entities/resumen_caja.dart';

/// Repository interface para operaciones de caja
abstract class CajaRepository {
  Future<Resource<Caja>> abrirCaja({
    required String sedeId,
    required double montoApertura,
    String? observaciones,
  });

  Future<Resource<Caja?>> getCajaActiva();

  Future<Resource<void>> crearMovimiento({
    required String cajaId,
    required TipoMovimientoCaja tipo,
    required CategoriaMovimientoCaja categoria,
    required MetodoPago metodoPago,
    required double monto,
    String? descripcion,
    String? categoriaGastoId,
  });

  Future<Resource<List<MovimientoCaja>>> getMovimientos({
    required String cajaId,
  });

  Future<Resource<void>> cerrarCaja({
    required String cajaId,
    required List<Map<String, dynamic>> conteos,
    String? observaciones,
  });

  Future<Resource<List<Caja>>> getHistorial({
    String? sedeId,
    String? fechaDesde,
    String? fechaHasta,
  });

  Future<Resource<ResumenCaja>> getResumen({
    required String cajaId,
  });

  Future<Resource<void>> anularMovimiento({
    required String cajaId,
    required String movimientoId,
    required String autorizadoPorId,
    required String motivo,
  });

  Future<Resource<CajaMonitorData>> getMonitor({String? sedeId});
}
