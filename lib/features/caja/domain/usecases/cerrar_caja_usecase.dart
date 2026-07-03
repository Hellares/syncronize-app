import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/caja.dart';
import '../repositories/caja_repository.dart';

@injectable
class CerrarCajaUseCase {
  final CajaRepository _repository;

  CerrarCajaUseCase(this._repository);

  Future<Resource<Caja>> call({
    required String cajaId,
    required List<Map<String, dynamic>> conteos,
    String? observaciones,
    Map<String, int>? desgloseEfectivo,
  }) {
    return _repository.cerrarCaja(
      cajaId: cajaId,
      conteos: conteos,
      observaciones: observaciones,
      desgloseEfectivo: desgloseEfectivo,
    );
  }
}
