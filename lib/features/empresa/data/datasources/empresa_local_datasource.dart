import 'package:injectable/injectable.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/constants/storage_constants.dart';
import '../models/empresa_context_model.dart';
import 'dart:convert';

/// Data source local para operaciones de empresa (caché)
@lazySingleton
class EmpresaLocalDataSource {
  final LocalStorageService _localStorage;

  EmpresaLocalDataSource(this._localStorage);

  static const String _empresaContextKey = 'empresa_context_cache';

  /// Guarda el contexto de empresa en caché local
  Future<void> cacheEmpresaContext(EmpresaContextModel context) async {
    try {
      final jsonString = json.encode(context.toJson());
      await _localStorage.setString(_empresaContextKey, jsonString);
    } catch (e) {
      throw Exception('Error al guardar contexto en caché: $e');
    }
  }

  /// Obtiene el contexto de empresa desde el caché local
  Future<EmpresaContextModel?> getCachedEmpresaContext() async {
    try {
      final jsonString = _localStorage.getString(_empresaContextKey);
      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return EmpresaContextModel.fromJson(jsonMap);
    } catch (e) {
      // Si hay error al parsear, eliminar el caché corrupto
      await clearEmpresaContext();
      return null;
    }
  }

  /// Limpia el contexto de empresa del caché
  Future<void> clearEmpresaContext() async {
    try {
      await _localStorage.remove(_empresaContextKey);
    } catch (e) {
      throw Exception('Error al limpiar contexto de empresa: $e');
    }
  }

  /// Guarda la información de la empresa seleccionada
  Future<void> saveSelectedEmpresa({
    required String empresaId,
    required String empresaNombre,
  }) async {
    try {
      await _localStorage.setString(StorageConstants.tenantId, empresaId);
      await _localStorage.setString(StorageConstants.tenantName, empresaNombre);
    } catch (e) {
      throw Exception('Error al guardar empresa seleccionada: $e');
    }
  }

  /// Obtiene el ID de la empresa actualmente seleccionada
  String? getSelectedEmpresaId() {
    return _localStorage.getString(StorageConstants.tenantId);
  }

  /// Limpia toda la información relacionada con la empresa
  Future<void> clearAllEmpresaData() async {
    try {
      await Future.wait([
        clearEmpresaContext(),
        _localStorage.remove(StorageConstants.tenantId),
        _localStorage.remove(StorageConstants.tenantName),
        _localStorage.remove(StorageConstants.tenantRole),
      ]);
    } catch (e) {
      throw Exception('Error al limpiar datos de empresa: $e');
    }
  }
}
