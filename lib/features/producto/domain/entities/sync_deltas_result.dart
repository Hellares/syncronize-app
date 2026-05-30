import 'package:equatable/equatable.dart';
import 'producto_list_item.dart';

/// Resultado del endpoint `GET /productos/sync` — sync diferencial.
///
/// - Si `fullSyncRequired == true`, el cliente debe descartar los
///   deltas y hacer un `getProductos` completo (cache muy viejo /
///   cliente nuevo / demasiados cambios).
/// - Caso contrario aplica deltas: reemplaza/agrega por id los
///   `updated`, elimina los `deleted` y guarda `serverTime` como
///   nuevo `lastSync`.
class SyncDeltasResult extends Equatable {
  final List<ProductoListItem> updated;
  final List<String> deleted;
  final String serverTime;
  final bool fullSyncRequired;

  /// Total autoritativo de productos del catálogo base (server). Null si el
  /// backend no lo envía (versión vieja) — el cliente cae a un conteo local.
  final int? total;

  const SyncDeltasResult({
    required this.updated,
    required this.deleted,
    required this.serverTime,
    required this.fullSyncRequired,
    this.total,
  });

  @override
  List<Object?> get props =>
      [updated, deleted, serverTime, fullSyncRequired, total];
}
