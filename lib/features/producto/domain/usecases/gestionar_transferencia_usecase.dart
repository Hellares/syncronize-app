import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/transferencia_stock.dart';
import '../repositories/transferencia_stock_repository.dart';

/// Use case para obtener detalle de transferencia
@injectable
class ObtenerTransferenciaUseCase {
  final TransferenciaStockRepository _repository;

  ObtenerTransferenciaUseCase(this._repository);

  Future<Resource<TransferenciaStock>> call({
    required String transferenciaId,
    required String empresaId,
  }) async {
    return await _repository.obtenerTransferencia(
      transferenciaId: transferenciaId,
      empresaId: empresaId,
    );
  }
}

/// Use case para aprobar transferencia
@injectable
class AprobarTransferenciaUseCase {
  final TransferenciaStockRepository _repository;

  AprobarTransferenciaUseCase(this._repository);

  Future<Resource<TransferenciaStock>> call({
    required String transferenciaId,
    required String empresaId,
    String? observaciones,
  }) async {
    return await _repository.aprobarTransferencia(
      transferenciaId: transferenciaId,
      empresaId: empresaId,
      observaciones: observaciones,
    );
  }
}

/// Use case para enviar transferencia
@injectable
class EnviarTransferenciaUseCase {
  final TransferenciaStockRepository _repository;

  EnviarTransferenciaUseCase(this._repository);

  Future<Resource<TransferenciaStock>> call({
    required String transferenciaId,
    required String empresaId,
  }) async {
    return await _repository.enviarTransferencia(
      transferenciaId: transferenciaId,
      empresaId: empresaId,
    );
  }
}

/// Use case para recibir transferencia
@injectable
class RecibirTransferenciaUseCase {
  final TransferenciaStockRepository _repository;

  RecibirTransferenciaUseCase(this._repository);

  Future<Resource<TransferenciaStock>> call({
    required String transferenciaId,
    required String empresaId,
    required int cantidadRecibida,
    String? ubicacion,
    String? observaciones,
  }) async {
    return await _repository.recibirTransferencia(
      transferenciaId: transferenciaId,
      empresaId: empresaId,
      cantidadRecibida: cantidadRecibida,
      ubicacion: ubicacion,
      observaciones: observaciones,
    );
  }
}

/// Use case para rechazar transferencia
@injectable
class RechazarTransferenciaUseCase {
  final TransferenciaStockRepository _repository;

  RechazarTransferenciaUseCase(this._repository);

  Future<Resource<TransferenciaStock>> call({
    required String transferenciaId,
    required String empresaId,
    required String motivo,
  }) async {
    return await _repository.rechazarTransferencia(
      transferenciaId: transferenciaId,
      empresaId: empresaId,
      motivo: motivo,
    );
  }
}

/// Use case para cancelar transferencia
@injectable
class CancelarTransferenciaUseCase {
  final TransferenciaStockRepository _repository;

  CancelarTransferenciaUseCase(this._repository);

  Future<Resource<TransferenciaStock>> call({
    required String transferenciaId,
    required String empresaId,
    required String motivo,
  }) async {
    return await _repository.cancelarTransferencia(
      transferenciaId: transferenciaId,
      empresaId: empresaId,
      motivo: motivo,
    );
  }
}
