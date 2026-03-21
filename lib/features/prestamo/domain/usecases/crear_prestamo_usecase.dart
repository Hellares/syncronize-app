import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/prestamo.dart';
import '../repositories/prestamo_repository.dart';

@injectable
class CrearPrestamoUseCase {
  final PrestamoRepository _repository;

  CrearPrestamoUseCase(this._repository);

  Future<Resource<Prestamo>> call({
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
  }) {
    return _repository.crear(
      tipo: tipo,
      entidadPrestamo: entidadPrestamo,
      descripcion: descripcion,
      montoOriginal: montoOriginal,
      tasaInteres: tasaInteres,
      moneda: moneda,
      cantidadCuotas: cantidadCuotas,
      montoCuota: montoCuota,
      fechaDesembolso: fechaDesembolso,
      fechaVencimiento: fechaVencimiento,
      observaciones: observaciones,
    );
  }
}
