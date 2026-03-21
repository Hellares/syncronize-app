import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/checkout.dart';
import '../repositories/checkout_repository.dart';

@injectable
class GetOpcionesEnvioUseCase {
  final CheckoutRepository _repository;
  GetOpcionesEnvioUseCase(this._repository);

  Future<Resource<OpcionesEnvio>> call({required String empresaId}) {
    return _repository.getOpcionesEnvio(empresaId: empresaId);
  }
}
