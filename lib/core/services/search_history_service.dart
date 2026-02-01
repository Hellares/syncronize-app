import 'package:injectable/injectable.dart';
import '../storage/local_storage_service.dart';

/// Servicio para manejar historial de búsquedas
/// Puede ser usado por múltiples SearchDelegates en la app
@lazySingleton
class SearchHistoryService {
  final LocalStorageService _storageService;

  static const int _maxHistoryItems = 10;

  SearchHistoryService(this._storageService);

  /// Clave para almacenar el historial (se puede personalizar por feature)
  String _getKey(String feature) => 'search_history_$feature';

  /// Obtiene el historial de búsquedas
  List<String> getHistory(String feature) {
    try {
      final history = _storageService.getStringList(_getKey(feature));
      return history ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Agrega una búsqueda al historial
  Future<void> addToHistory(String feature, String query) async {
    if (query.trim().isEmpty) return;

    try {
      final history = getHistory(feature);

      // Remover duplicados (si ya existe, moverlo al principio)
      history.remove(query);

      // Agregar al inicio
      history.insert(0, query);

      // Limitar el tamaño del historial
      if (history.length > _maxHistoryItems) {
        history.removeRange(_maxHistoryItems, history.length);
      }

      await _storageService.setStringList(_getKey(feature), history);
    } catch (e) {
      // Silently fail - no es crítico
    }
  }

  /// Elimina una búsqueda específica del historial
  Future<void> removeFromHistory(String feature, String query) async {
    try {
      final history = getHistory(feature);
      history.remove(query);
      await _storageService.setStringList(_getKey(feature), history);
    } catch (e) {
      // Silently fail
    }
  }

  /// Limpia todo el historial
  Future<void> clearHistory(String feature) async {
    try {
      await _storageService.remove(_getKey(feature));
    } catch (e) {
      // Silently fail
    }
  }
}
