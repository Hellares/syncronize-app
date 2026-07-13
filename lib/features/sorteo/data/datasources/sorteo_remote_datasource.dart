import 'dart:io';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/dio_client.dart';
import '../models/sorteo_model.dart';

@lazySingleton
class SorteoRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/sorteos';

  SorteoRemoteDataSource(this._dioClient);

  /// GET /sorteos
  Future<List<SorteoModel>> getSorteos({String? estado}) async {
    final response = await _dioClient.get(
      _basePath,
      queryParameters: {if (estado != null) 'estado': estado},
    );
    final responseData = response.data;
    final List items;
    if (responseData is Map && responseData['data'] is List) {
      items = responseData['data'] as List;
    } else if (responseData is List) {
      items = responseData;
    } else {
      items = [];
    }
    return items
        .map((e) => SorteoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /sorteos
  Future<SorteoModel> crearSorteo(Map<String, dynamic> data) async {
    final response = await _dioClient.post(_basePath, data: data);
    return SorteoModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /sorteos/:id — detalle con premios y tickets
  Future<SorteoModel> getSorteoDetalle(String id) async {
    final response = await _dioClient.get('$_basePath/$id');
    return SorteoModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// PATCH /sorteos/:id
  Future<SorteoModel> actualizarSorteo(
      String id, Map<String, dynamic> data) async {
    final response = await _dioClient.patch('$_basePath/$id', data: data);
    return SorteoModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /sorteos/:id/premios — registrar ganador + premio
  Future<SorteoPremioModel> registrarPremio(
      String sorteoId, Map<String, dynamic> data) async {
    final response =
        await _dioClient.post('$_basePath/$sorteoId/premios', data: data);
    return SorteoPremioModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /sorteos/participantes/pendientes — cola global de jugadores
  /// con pago por validar (sorteos/dinámicas abiertos), con su sorteo.
  Future<List<Map<String, dynamic>>> getParticipantesPendientes() async {
    final response =
        await _dioClient.get('$_basePath/participantes/pendientes');
    final data = response.data;
    return data is List ? data.cast<Map<String, dynamic>>() : const [];
  }

  /// PATCH /sorteos/participantes/:id/estado — validar/rechazar
  /// participante del bot (ACTIVO asigna ticket y confirma por WhatsApp;
  /// en dinámicas además crea el premio automático)
  Future<void> cambiarEstadoParticipante(
      String participanteId, String estado) async {
    await _dioClient.patch(
      '$_basePath/participantes/$participanteId/estado',
      data: {'estado': estado},
    );
  }

  /// PATCH /sorteos/premios/:premioId/estado
  Future<SorteoPremioModel> cambiarEstadoPremio(
      String premioId, Map<String, dynamic> data) async {
    final response = await _dioClient
        .patch('$_basePath/premios/$premioId/estado', data: data);
    return SorteoPremioModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// PATCH /sorteos/premios/:premioId/entrega — corregir modalidad y/o
  /// agencia (solo antes del despacho).
  Future<SorteoPremioModel> editarEntregaPremio(
      String premioId, Map<String, dynamic> data) async {
    final response = await _dioClient
        .patch('$_basePath/premios/$premioId/entrega', data: data);
    return SorteoPremioModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /sorteos/ganadores/ultima-entrega?dni= — última entrega por
  /// agencia del DNI (prellenado de ganadores repetidos); null si nunca
  /// tuvo un envío con agencia.
  Future<Map<String, dynamic>?> getUltimaEntregaGanador(String dni) async {
    final response = await _dioClient.get(
      '$_basePath/ganadores/ultima-entrega',
      queryParameters: {'dni': dni},
    );
    final data = response.data;
    return data is Map<String, dynamic> ? data : null;
  }

  /// PATCH /sorteos/premios/:premioId/rotulo-impreso
  Future<void> marcarRotuloImpreso(String premioId) async {
    await _dioClient.patch('$_basePath/premios/$premioId/rotulo-impreso');
  }

  /// POST /sorteos/premios/:premioId/ticket-envio (multipart).
  /// Devuelve true si el backend además lo envió por WhatsApp al ganador
  /// (empresa con WhatsApp vinculado vía Evolution).
  Future<bool> subirTicketEnvio(String premioId, File file) async {
    final response =
        await _subirArchivo('$_basePath/premios/$premioId/ticket-envio', file);
    final data = response.data;
    return data is Map && data['whatsappEnviado'] == true;
  }

  /// POST /sorteos/premios/:premioId/foto-premio (multipart)
  Future<void> subirFotoPremio(String premioId, File file) =>
      _subirArchivo('$_basePath/premios/$premioId/foto-premio', file);

  /// POST /sorteos/:id/imagen — imagen promocional del sorteo (multipart)
  Future<void> subirImagenSorteo(String sorteoId, File file) =>
      _subirArchivo('$_basePath/$sorteoId/imagen', file);

  Future<Response> _subirArchivo(String path, File file) async {
    final fileName = file.path.split('/').last.isNotEmpty
        ? file.path.split('/').last
        : file.path.split('\\').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });
    return _dioClient.post(
      path,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }
}
