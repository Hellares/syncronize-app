import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/resumen_caja.dart';
import '../repositories/caja_repository.dart';

@injectable
class GetResumenUseCase {
  final CajaRepository _repository;

  GetResumenUseCase(this._repository);

  Future<Resource<ResumenCaja>> call({required String cajaId}) {
    return _repository.getResumen(cajaId: cajaId);
  }
}
