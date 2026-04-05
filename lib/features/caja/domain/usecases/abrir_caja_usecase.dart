import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/caja.dart';
import '../repositories/caja_repository.dart';

@injectable
class AbrirCajaUseCase {
  final CajaRepository _repository;

  AbrirCajaUseCase(this._repository);

  Future<Resource<Caja>> call({
    required String sedeId,
    required double montoApertura,
    String? observaciones,
    String? sedeFacturacionId,
  }) {
    return _repository.abrirCaja(
      sedeId: sedeId,
      montoApertura: montoApertura,
      observaciones: observaciones,
      sedeFacturacionId: sedeFacturacionId,
    );
  }
}
