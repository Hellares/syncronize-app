import '../../../../core/utils/resource.dart';
import '../entities/arqueo_caja.dart';
import '../entities/caja.dart';
import '../entities/caja_auditoria.dart';
import '../entities/caja_monitor.dart';
import '../entities/movimiento_caja.dart';
import '../entities/resumen_caja.dart';

/// Repository interface para operaciones de caja
abstract class CajaRepository {
  Future<Resource<Caja>> abrirCaja({
    required String sedeId,
    required double montoApertura,
    String? observaciones,
    String? sedeFacturacionId,
  });

  Future<Resource<Caja?>> getCajaActiva();

  /// Devuelve una caja por id (vista admin desde el monitor, para que
  /// reusemos la misma CajaPage del cajero parametrizada).
  Future<Resource<Caja>> getCajaById(String id);

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

  /// Devuelve la caja recien cerrada con su `cierre` incluido (para
  /// que la UI pueda imprimir el resumen de cierre inmediatamente).
  Future<Resource<Caja>> cerrarCaja({
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

  /// Crear arqueo de caja (conteo intermedio sin cerrar).
  Future<Resource<ArqueoCaja>> crearArqueo({
    required String cajaId,
    required TipoArqueoCaja tipo,
    required List<Map<String, dynamic>> conteos,
    String? observaciones,
    String? autorizadoPorId,
    String? turnoEntregadoAId,
    Map<String, int>? desgloseEfectivo,
  });

  /// Listar arqueos de una caja.
  Future<Resource<List<ArqueoCaja>>> getArqueos({required String cajaId});

  /// Auditoría completa (apertura → cierre): caja + cierre + arqueos + TODOS
  /// los movimientos (incluye anulados y contrapartidas con flags).
  Future<Resource<CajaAuditoria>> getAuditoria({required String cajaId});
}
