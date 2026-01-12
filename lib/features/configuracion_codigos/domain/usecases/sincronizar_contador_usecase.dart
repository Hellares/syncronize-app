import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/configuracion_codigos_repository.dart';

/// UseCase para sincronizar contador con el estado real de la BD
@injectable
class SincronizarContadorUseCase {
  final ConfiguracionCodigosRepository _repository;

  SincronizarContadorUseCase(this._repository);

  Future<Resource<Map<String, dynamic>>> call({
    required String empresaId,
    required String tipo,
  }) {
    return _repository.sincronizarContador(
      empresaId: empresaId,
      tipo: tipo,
    );
  }
}
