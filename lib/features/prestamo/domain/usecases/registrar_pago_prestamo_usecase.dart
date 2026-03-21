import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/prestamo.dart';
import '../repositories/prestamo_repository.dart';

@injectable
class RegistrarPagoPrestamoUseCase {
  final PrestamoRepository _repository;

  RegistrarPagoPrestamoUseCase(this._repository);

  Future<Resource<Prestamo>> call({
    required String prestamoId,
    required String metodoPago,
    required double monto,
    String? referencia,
  }) {
    return _repository.registrarPago(
      prestamoId: prestamoId,
      metodoPago: metodoPago,
      monto: monto,
      referencia: referencia,
    );
  }
}
