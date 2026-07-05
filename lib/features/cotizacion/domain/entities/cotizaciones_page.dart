import 'cotizacion.dart';

/// Página de cotizaciones (paginación por cursor).
///
/// Patrón estándar para listas transaccionales que crecen sin techo:
/// primera página chica → scroll infinito appendea con `nextCursor`.
class CotizacionesPage {
  final List<Cotizacion> cotizaciones;
  final bool hasMore;

  /// Cursor (id de la última fila) para pedir la siguiente página.
  /// null cuando ya no hay más.
  final String? nextCursor;

  const CotizacionesPage({
    required this.cotizaciones,
    required this.hasMore,
    this.nextCursor,
  });
}
