import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/caja_repository.dart';

@injectable
class CerrarCajaUseCase {
  final CajaRepository _repository;

  CerrarCajaUseCase(this._repository);

  Future<Resource<void>> call({
    required String cajaId,
    required List<Map<String, dynamic>> conteos,
    String? observaciones,
  }) {
    return _repository.cerrarCaja(
      cajaId: cajaId,
      conteos: conteos,
      observaciones: observaciones,
    );
  }
}
