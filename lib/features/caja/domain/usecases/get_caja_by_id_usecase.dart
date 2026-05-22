import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/caja.dart';
import '../repositories/caja_repository.dart';

/// Carga una caja por id (vista admin desde el monitor — la misma
/// CajaPage del cajero se parametriza con cajaId para operar caja ajena).
@injectable
class GetCajaByIdUseCase {
  final CajaRepository _repository;

  GetCajaByIdUseCase(this._repository);

  Future<Resource<Caja>> call(String id) {
    return _repository.getCajaById(id);
  }
}
