import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para almacenamiento local no sensible (preferencias, configuraciones)
@lazySingleton
class LocalStorageService {
  final SharedPreferences _preferences;

  LocalStorageService(this._preferences);

  /// Guardar un String
  Future<bool> setString(String key, String value) async {
    try {
      return await _preferences.setString(key, value);
    } catch (e) {
      throw Exception('Error al guardar string: $e');
    }
  }

  /// Obtener un String
  String? getString(String key) {
    try {
      return _preferences.getString(key);
    } catch (e) {
      return null;
    }
  }

  /// Guardar un int
  Future<bool> setInt(String key, int value) async {
    try {
      return await _preferences.setInt(key, value);
    } catch (e) {
      throw Exception('Error al guardar int: $e');
    }
  }

  /// Obtener un int
  int? getInt(String key) {
    try {
      return _preferences.getInt(key);
    } catch (e) {
      return null;
    }
  }

  /// Guardar un bool
  Future<bool> setBool(String key, bool value) async {
    try {
      return await _preferences.setBool(key, value);
    } catch (e) {
      throw Exception('Error al guardar bool: $e');
    }
  }

  /// Obtener un bool
  bool? getBool(String key) {
    try {
      return _preferences.getBool(key);
    } catch (e) {
      return null;
    }
  }

  /// Guardar un double
  Future<bool> setDouble(String key, double value) async {
    try {
      return await _preferences.setDouble(key, value);
    } catch (e) {
      throw Exception('Error al guardar double: $e');
    }
  }

  /// Obtener un double
  double? getDouble(String key) {
    try {
      return _preferences.getDouble(key);
    } catch (e) {
      return null;
    }
  }

  /// Guardar una lista de Strings
  Future<bool> setStringList(String key, List<String> value) async {
    try {
      return await _preferences.setStringList(key, value);
    } catch (e) {
      throw Exception('Error al guardar lista de strings: $e');
    }
  }

  /// Obtener una lista de Strings
  List<String>? getStringList(String key) {
    try {
      return _preferences.getStringList(key);
    } catch (e) {
      return null;
    }
  }

  /// Eliminar una clave
  Future<bool> remove(String key) async {
    try {
      return await _preferences.remove(key);
    } catch (e) {
      throw Exception('Error al eliminar clave: $e');
    }
  }

  /// Limpiar todo el almacenamiento
  Future<bool> clear() async {
    try {
      return await _preferences.clear();
    } catch (e) {
      throw Exception('Error al limpiar almacenamiento: $e');
    }
  }

  /// Verificar si existe una clave
  bool containsKey(String key) {
    try {
      return _preferences.containsKey(key);
    } catch (e) {
      return false;
    }
  }

  /// Obtener todas las claves
  Set<String> getKeys() {
    try {
      return _preferences.getKeys();
    } catch (e) {
      return {};
    }
  }
}
