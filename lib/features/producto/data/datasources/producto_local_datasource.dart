import 'package:injectable/injectable.dart';
import '../../../../core/storage/local_storage_service.dart';

/// Data source local para operaciones de productos (caché)
@lazySingleton
class ProductoLocalDataSource {
  final LocalStorageService _localStorage;

  ProductoLocalDataSource(this._localStorage);

  // TODO: Implementar caché de productos si es necesario
  // Por ahora, este datasource está disponible para futuras implementaciones
  // de caché local

  /// Limpia el caché de productos
  Future<void> clearCache() async {
    // Implementar cuando se agregue soporte de caché
  }
}
