import '../../../../core/utils/resource.dart';
import '../entities/prestamo.dart';

/// Repository interface para operaciones de prestamos
abstract class PrestamoRepository {
  Future<Resource<List<Prestamo>>> listar({String? estado});

  Future<Resource<ResumenPrestamos>> getResumen();

  Future<Resource<Prestamo>> crear({
    required String tipo,
    required String entidadPrestamo,
    String? descripcion,
    required double montoOriginal,
    double? tasaInteres,
    String? moneda,
    int? cantidadCuotas,
    double? montoCuota,
    required String fechaDesembolso,
    String? fechaVencimiento,
    String? observaciones,
  });

  Future<Resource<Prestamo>> registrarPago({
    required String prestamoId,
    required String metodoPago,
    required double monto,
    String? referencia,
  });
}
