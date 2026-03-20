import 'dart:io';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/mis_pedidos_repository.dart';

@injectable
class SubirComprobanteUseCase {
  final MisPedidosRepository _repository;

  SubirComprobanteUseCase(this._repository);

  Future<Resource<String>> call({
    required String pedidoId,
    required File file,
  }) {
    return _repository.subirComprobante(pedidoId, file);
  }
}
