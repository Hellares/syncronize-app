import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/arqueo_caja.dart';
import '../repositories/caja_repository.dart';

@injectable
class GetArqueosUseCase {
  final CajaRepository _repository;

  GetArqueosUseCase(this._repository);

  Future<Resource<List<ArqueoCaja>>> call({required String cajaId}) {
    return _repository.getArqueos(cajaId: cajaId);
  }
}
