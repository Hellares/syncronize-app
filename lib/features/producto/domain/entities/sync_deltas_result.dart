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

  const SyncDeltasResult({
    required this.updated,
    required this.deleted,
    required this.serverTime,
    required this.fullSyncRequired,
  });

  @override
  List<Object?> get props => [updated, deleted, serverTime, fullSyncRequired];
}
