import 'package:injectable/injectable.dart';
import '../../../../core/storage/local_storage_service.dart';

/// Data source local para operaciones de catálogos (caché)
@lazySingleton
class CatalogoLocalDataSource {
  final LocalStorageService _localStorage;

  CatalogoLocalDataSource(this._localStorage);

  // TODO: Implementar caché de catálogos si es necesario
  // Por ahora, este datasource está disponible para futuras implementaciones
  // de caché local

  /// Limpia el caché de catálogos
  Future<void> clearCache() async {
    // Implementar cuando se agregue soporte de caché
  }
}
