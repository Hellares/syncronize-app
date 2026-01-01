import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/politica_descuento.dart';
import '../../domain/repositories/descuento_repository.dart';
import '../datasources/descuento_remote_datasource.dart';
import '../models/politica_descuento_model.dart';

@LazySingleton(as: DescuentoRepository)
class DescuentoRepositoryImpl implements DescuentoRepository {
  final DescuentoRemoteDataSource _remoteDataSource;

  DescuentoRepositoryImpl(this._remoteDataSource);

  @override
  Future<Resource<Map<String, dynamic>>> getPoliticas({
    String? tipoDescuento,
    bool? isActive,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _remoteDataSource.getPoliticasDescuento(
        tipoDescuento: tipoDescuento,
        isActive: isActive,
        page: page,
        limit: limit,
      );

      // El response ya viene como Map con 'data' y 'meta'
      final data = response['data'] as List;
      final politicas = data
          .map((json) => PoliticaDescuentoModel.fromJson(json as Map<String, dynamic>).toEntity())
          .toList();

      return Success({
        'data': politicas,
        'total': response['meta']?['total'] ?? politicas.length,
        'page': page,
        'limit': limit,
      });
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<PoliticaDescuento>> getPoliticaById(String id) async {
    try {
      final politica = await _remoteDataSource.getPoliticaById(id);
      return Success(politica.toEntity());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<PoliticaDescuento>> createPolitica({
    required String nombre,
    String? descripcion,
    required TipoDescuento tipoDescuento,
    required TipoCalculoDescuento tipoCalculo,
    required double valorDescuento,
    double? descuentoMaximo,
    double? montoMinCompra,
    int? cantidadMaxUsos,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool? aplicarATodos,
    int? prioridad,
    int? maxFamiliaresPorTrabajador,
  }) async {
    try {
      final data = <String, dynamic>{
        'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        'tipoDescuento': _serializeTipoDescuento(tipoDescuento),
        'tipoCalculo': _serializeTipoCalculo(tipoCalculo),
        'valorDescuento': valorDescuento,
        if (descuentoMaximo != null) 'descuentoMaximo': descuentoMaximo,
        if (montoMinCompra != null) 'montoMinCompra': montoMinCompra,
        if (cantidadMaxUsos != null) 'cantidadMaxUsos': cantidadMaxUsos,
        if (fechaInicio != null) 'fechaInicio': fechaInicio.toIso8601String(),
        if (fechaFin != null) 'fechaFin': fechaFin.toIso8601String(),
        if (aplicarATodos != null) 'aplicarATodos': aplicarATodos,
        if (prioridad != null) 'prioridad': prioridad,
        if (maxFamiliaresPorTrabajador != null)
          'maxFamiliaresPorTrabajador': maxFamiliaresPorTrabajador,
      };

      final politica = await _remoteDataSource.createPolitica(data);
      return Success(politica.toEntity());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<PoliticaDescuento>> updatePolitica({
    required String id,
    String? nombre,
    String? descripcion,
    TipoDescuento? tipoDescuento,
    TipoCalculoDescuento? tipoCalculo,
    double? valorDescuento,
    double? descuentoMaximo,
    double? montoMinCompra,
    int? cantidadMaxUsos,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool? aplicarATodos,
    int? prioridad,
    int? maxFamiliaresPorTrabajador,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{
        if (nombre != null) 'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        if (tipoDescuento != null)
          'tipoDescuento': _serializeTipoDescuento(tipoDescuento),
        if (tipoCalculo != null)
          'tipoCalculo': _serializeTipoCalculo(tipoCalculo),
        if (valorDescuento != null) 'valorDescuento': valorDescuento,
        if (descuentoMaximo != null) 'descuentoMaximo': descuentoMaximo,
        if (montoMinCompra != null) 'montoMinCompra': montoMinCompra,
        if (cantidadMaxUsos != null) 'cantidadMaxUsos': cantidadMaxUsos,
        if (fechaInicio != null) 'fechaInicio': fechaInicio.toIso8601String(),
        if (fechaFin != null) 'fechaFin': fechaFin.toIso8601String(),
        if (aplicarATodos != null) 'aplicarATodos': aplicarATodos,
        if (prioridad != null) 'prioridad': prioridad,
        if (maxFamiliaresPorTrabajador != null)
          'maxFamiliaresPorTrabajador': maxFamiliaresPorTrabajador,
        if (isActive != null) 'isActive': isActive,
      };

      final politica = await _remoteDataSource.updatePolitica(id, data);
      return Success(politica.toEntity());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<void>> deletePolitica(String id) async {
    try {
      await _remoteDataSource.deletePolitica(id);
      return Success(null);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<List<Map<String, dynamic>>>> asignarUsuarios({
    required String politicaId,
    required List<String> usuariosIds,
    int? limiteMensualUsos,
  }) async {
    try {
      final result = await _remoteDataSource.asignarUsuarios(
        politicaId,
        usuariosIds,
        limiteMensualUsos: limiteMensualUsos,
      );
      return Success(result.map((m) => m.toJson()).toList());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<List<String>>> obtenerUsuariosAsignados(String politicaId) async {
    try {
      final result = await _remoteDataSource.obtenerUsuariosAsignados(politicaId);
      return Success(result);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<void>> removerUsuario({
    required String politicaId,
    required String usuarioId,
  }) async {
    try {
      await _remoteDataSource.removerUsuario(politicaId, usuarioId);
      return Success(null);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> agregarFamiliar({
    required String trabajadorId,
    required String familiarUsuarioId,
    required Parentesco parentesco,
    int? limiteMensualUsos,
    String? documentoVerificacion,
  }) async {
    try {
      final data = <String, dynamic>{
        'familiarUsuarioId': familiarUsuarioId,
        'parentesco': _serializeParentesco(parentesco),
        if (limiteMensualUsos != null) 'limiteMensualUsos': limiteMensualUsos,
        if (documentoVerificacion != null)
          'documentoVerificacion': documentoVerificacion,
      };

      final result = await _remoteDataSource.agregarFamiliar(
        trabajadorId,
        data,
      );
      return Success(result.toJson());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<List<Map<String, dynamic>>>> obtenerFamiliares(
      String trabajadorId) async {
    try {
      final result = await _remoteDataSource.obtenerFamiliares(trabajadorId);
      return Success(result.map((m) => m.toJson()).toList());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<void>> removerFamiliar({
    required String trabajadorId,
    required String familiarId,
  }) async {
    try {
      await _remoteDataSource.removerFamiliar(trabajadorId, familiarId);
      return Success(null);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<List<Map<String, dynamic>>>> asignarProductos({
    required String politicaId,
    required List<Map<String, dynamic>> productos,
  }) async {
    try {
      final result = await _remoteDataSource.asignarProductos(
        politicaId,
        productos,
      );
      return Success(result);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<List<Map<String, dynamic>>>> asignarCategorias({
    required String politicaId,
    required List<Map<String, dynamic>> categorias,
  }) async {
    try {
      final result = await _remoteDataSource.asignarCategorias(
        politicaId,
        categorias,
      );
      return Success(result);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> calcularDescuento({
    required String usuarioId,
    required String productoId,
    String? varianteId,
    required int cantidad,
    required double precioBase,
  }) async {
    try {
      final result = await _remoteDataSource.calcularDescuento(
        usuarioId: usuarioId,
        productoId: productoId,
        varianteId: varianteId,
        cantidad: cantidad,
        precioBase: precioBase,
      );
      return Success(result.toJson());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<List<Map<String, dynamic>>>> obtenerHistorialUso(
      String politicaId) async {
    try {
      final result = await _remoteDataSource.obtenerHistorialUso(politicaId);
      return Success(result);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  // Helper methods para serializar enums a formato backend
  String _serializeTipoDescuento(TipoDescuento tipo) {
    switch (tipo) {
      case TipoDescuento.trabajador:
        return 'TRABAJADOR';
      case TipoDescuento.familiarTrabajador:
        return 'FAMILIAR_TRABAJADOR';
      case TipoDescuento.vip:
        return 'VIP';
      case TipoDescuento.promocional:
        return 'PROMOCIONAL';
      case TipoDescuento.lealtad:
        return 'LEALTAD';
      case TipoDescuento.cumpleanios:
        return 'CUMPLEANIOS';
    }
  }

  String _serializeTipoCalculo(TipoCalculoDescuento tipo) {
    switch (tipo) {
      case TipoCalculoDescuento.porcentaje:
        return 'PORCENTAJE';
      case TipoCalculoDescuento.montoFijo:
        return 'MONTO_FIJO';
    }
  }

  String _serializeParentesco(Parentesco parentesco) {
    switch (parentesco) {
      case Parentesco.conyuge:
        return 'CONYUGE';
      case Parentesco.hijo:
        return 'HIJO';
      case Parentesco.hija:
        return 'HIJA';
      case Parentesco.padre:
        return 'PADRE';
      case Parentesco.madre:
        return 'MADRE';
      case Parentesco.hermano:
        return 'HERMANO';
      case Parentesco.hermana:
        return 'HERMANA';
      case Parentesco.abuelo:
        return 'ABUELO';
      case Parentesco.abuela:
        return 'ABUELA';
      case Parentesco.nieto:
        return 'NIETO';
      case Parentesco.nieta:
        return 'NIETA';
      case Parentesco.tio:
        return 'TIO';
      case Parentesco.tia:
        return 'TIA';
      case Parentesco.sobrino:
        return 'SOBRINO';
      case Parentesco.sobrina:
        return 'SOBRINA';
      case Parentesco.primo:
        return 'PRIMO';
      case Parentesco.prima:
        return 'PRIMA';
    }
  }
}
