import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/tipo_cambio.dart';
import '../repositories/tipo_cambio_repository.dart';

@injectable
class GetTipoCambioHoyUseCase {
  final TipoCambioRepository _repository;
  GetTipoCambioHoyUseCase(this._repository);

  Future<Resource<TipoCambio>> call() {
    return _repository.getHoy();
  }
}
