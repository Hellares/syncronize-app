import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/transferencia_stock.dart';
import '../../domain/repositories/transferencia_stock_repository.dart';
import '../datasources/transferencia_stock_remote_datasource.dart';

@LazySingleton(as: TransferenciaStockRepository)
class TransferenciaStockRepositoryImpl implements TransferenciaStockRepository {
  final TransferenciaStockRemoteDataSource _remoteDataSource;

  TransferenciaStockRepositoryImpl(this._remoteDataSource);

  @override
  Future<Resource<TransferenciaStock>> crearTransferencia({
    required String empresaId,
    required String sedeOrigenId,
    required String sedeDestinoId,
    String? productoId,
    String? varianteId,
    required int cantidad,
    String? motivo,
    String? observaciones,
  }) async {
    try {
      final transferencia = await _remoteDataSource.crearTransferencia(
        empresaId: empresaId,
        sedeOrigenId: sedeOrigenId,
        sedeDestinoId: sedeDestinoId,
        productoId: productoId,
        varianteId: varianteId,
        cantidad: cantidad,
        motivo: motivo,
        observaciones: observaciones,
      );
      return Success(transferencia);
    } catch (e) {
      return Error(e.toString());
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> crearTransferenciasMultiples({
    required String empresaId,
    required String sedeOrigenId,
    required String sedeDestinoId,
    required List<Map<String, dynamic>> productos,
    String? motivoGeneral,
    String? observaciones,
  }) async {
    try {
      final result = await _remoteDataSource.crearTransferenciasMultiples(
        empresaId: empresaId,
        sedeOrigenId: sedeOrigenId,
        sedeDestinoId: sedeDestinoId,
        productos: productos,
        motivoGeneral: motivoGeneral,
        observaciones: observaciones,
      );
      return Success(result);
    } catch (e) {
      return Error(e.toString());
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> listarTransferencias({
    required String empresaId,
    String? sedeId,
    EstadoTransferencia? estado,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final result = await _remoteDataSource.listarTransferencias(
        empresaId: empresaId,
        sedeId: sedeId,
        estado: estado,
        page: page,
        limit: limit,
      );
      return Success(result);
    } catch (e) {
      return Error(e.toString());
    }
  }

  @override
  Future<Resource<TransferenciaStock>> obtenerTransferencia({
    required String transferenciaId,
    required String empresaId,
  }) async {
    try {
      final transferencia = await _remoteDataSource.obtenerTransferencia(
        transferenciaId: transferenciaId,
        empresaId: empresaId,
      );
      return Success(transferencia);
    } catch (e) {
      return Error(e.toString());
    }
  }

  @override
  Future<Resource<TransferenciaStock>> aprobarTransferencia({
    required String transferenciaId,
    required String empresaId,
    String? observaciones,
  }) async {
    try {
      final transferencia = await _remoteDataSource.aprobarTransferencia(
        transferenciaId: transferenciaId,
        empresaId: empresaId,
        observaciones: observaciones,
      );
      return Success(transferencia);
    } catch (e) {
      return Error(e.toString());
    }
  }

  @override
  Future<Resource<TransferenciaStock>> enviarTransferencia({
    required String transferenciaId,
    required String empresaId,
  }) async {
    try {
      final transferencia = await _remoteDataSource.enviarTransferencia(
        transferenciaId: transferenciaId,
        empresaId: empresaId,
      );
      return Success(transferencia);
    } catch (e) {
      return Error(e.toString());
    }
  }

  @override
  Future<Resource<TransferenciaStock>> recibirTransferencia({
    required String transferenciaId,
    required String empresaId,
    required int cantidadRecibida,
    String? ubicacion,
    String? observaciones,
  }) async {
    try {
      final transferencia = await _remoteDataSource.recibirTransferencia(
        transferenciaId: transferenciaId,
        empresaId: empresaId,
        cantidadRecibida: cantidadRecibida,
        ubicacion: ubicacion,
        observaciones: observaciones,
      );
      return Success(transferencia);
    } catch (e) {
      return Error(e.toString());
    }
  }

  @override
  Future<Resource<TransferenciaStock>> rechazarTransferencia({
    required String transferenciaId,
    required String empresaId,
    required String motivo,
  }) async {
    try {
      final transferencia = await _remoteDataSource.rechazarTransferencia(
        transferenciaId: transferenciaId,
        empresaId: empresaId,
        motivo: motivo,
      );
      return Success(transferencia);
    } catch (e) {
      return Error(e.toString());
    }
  }

  @override
  Future<Resource<TransferenciaStock>> cancelarTransferencia({
    required String transferenciaId,
    required String empresaId,
    required String motivo,
  }) async {
    try {
      final transferencia = await _remoteDataSource.cancelarTransferencia(
        transferenciaId: transferenciaId,
        empresaId: empresaId,
        motivo: motivo,
      );
      return Success(transferencia);
    } catch (e) {
      return Error(e.toString());
    }
  }

  @override
  Future<Resource<TransferenciaStock>> procesarCompletoTransferencia({
    required String transferenciaId,
    required String empresaId,
    String? ubicacion,
    String? observaciones,
  }) async {
    try {
      final transferencia =
          await _remoteDataSource.procesarCompletoTransferencia(
        transferenciaId: transferenciaId,
        empresaId: empresaId,
        ubicacion: ubicacion,
        observaciones: observaciones,
      );
      return Success(transferencia);
    } catch (e) {
      return Error(e.toString());
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> crearIncidenciaPosterior({
    required String transferenciaId,
    required String empresaId,
    required String itemId,
    required String tipo,
    required int cantidadAfectada,
    String? descripcion,
    List<String>? evidenciasUrls,
    String? observaciones,
  }) async {
    try {
      final result = await _remoteDataSource.crearIncidenciaPosterior(
        transferenciaId: transferenciaId,
        empresaId: empresaId,
        itemId: itemId,
        tipo: tipo,
        cantidadAfectada: cantidadAfectada,
        descripcion: descripcion,
        evidenciasUrls: evidenciasUrls,
        observaciones: observaciones,
      );
      return Success(result);
    } catch (e) {
      return Error(e.toString());
    }
  }
}
