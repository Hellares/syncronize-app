import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// Servicio para almacenamiento seguro (tokens, contraseñas, etc.)
@lazySingleton
class SecureStorageService {
  final FlutterSecureStorage _secureStorage;

  SecureStorageService(this._secureStorage);

  /// Guardar un valor de forma segura
  Future<void> write({
    required String key,
    required String value,
  }) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      throw Exception('Error al guardar dato seguro: $e');
    }
  }

  /// Leer un valor seguro
  Future<String?> read({required String key}) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      throw Exception('Error al leer dato seguro: $e');
    }
  }

  /// Eliminar un valor seguro
  Future<void> delete({required String key}) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      throw Exception('Error al eliminar dato seguro: $e');
    }
  }

  /// Eliminar todos los valores seguros
  Future<void> deleteAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      throw Exception('Error al eliminar todos los datos seguros: $e');
    }
  }

  /// Verificar si existe un valor
  Future<bool> containsKey({required String key}) async {
    try {
      return await _secureStorage.containsKey(key: key);
    } catch (e) {
      return false;
    }
  }

  /// Leer todos los valores seguros
  Future<Map<String, String>> readAll() async {
    try {
      return await _secureStorage.readAll();
    } catch (e) {
      throw Exception('Error al leer todos los datos seguros: $e');
    }
  }
}
