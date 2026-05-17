import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/network/dio_client.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';

/// Historial de cambios de precio para un ProductoStock específico.
/// Útil para auditar correcciones de `precioCosto` mal cargado, ajustes
/// por proveedor, cambios de competencia, etc.
class HistorialPreciosProductoPage extends StatefulWidget {
  final String productoStockId;
  final String productoNombre;

  const HistorialPreciosProductoPage({
    super.key,
    required this.productoStockId,
    required this.productoNombre,
  });

  @override
  State<HistorialPreciosProductoPage> createState() =>
      _HistorialPreciosProductoPageState();
}

class _HistorialPreciosProductoPageState
    extends State<HistorialPreciosProductoPage> {
  final DioClient _dio = locator<DioClient>();
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _dio.get(
        '/producto-stock/${widget.productoStockId}/precios/historial',
        queryParameters: {'limit': 100},
      );
      final data = response.data;
      List<Map<String, dynamic>> items;
      if (data is List) {
        items = data.cast<Map<String, dynamic>>();
      } else if (data is Map<String, dynamic>) {
        items = ((data['data'] ?? data['historial'] ?? []) as List)
            .cast<Map<String, dynamic>>();
      } else {
        items = const [];
      }
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is DioException
              ? (e.response?.data?['message']?.toString() ??
                  e.message ??
                  'Error al cargar historial')
              : e.toString();
          _loading = false;
        });
      }
    }
  }

  Color _colorTipoCambio(String tipo) {
    switch (tipo) {
      case 'CORRECCION':
        return Colors.red.shade700;
      case 'LIQUIDACION':
        return Colors.deepOrange.shade700;
      case 'OFERTA':
      case 'OFERTA_ACTIVADA':
      case 'OFERTA_DESACTIVADA':
        return Colors.amber.shade800;
      case 'COSTO':
      case 'COSTO_ACTUALIZADO':
        return Colors.indigo.shade700;
      case 'COMPETENCIA':
        return Colors.purple.shade700;
      case 'AJUSTE_MERCADO':
        return Colors.teal.shade700;
      case 'MASIVO':
      case 'AJUSTE_MASIVO':
        return Colors.blueGrey.shade700;
      default:
        return AppColors.blue1;
    }
  }

  String _labelTipoCambio(String tipo) {
    switch (tipo) {
      case 'CORRECCION':
        return 'Corrección';
      case 'LIQUIDACION':
        return 'Liquidación';
      case 'OFERTA':
        return 'Oferta';
      case 'OFERTA_ACTIVADA':
        return 'Oferta activada';
      case 'OFERTA_DESACTIVADA':
        return 'Oferta desactivada';
      case 'COSTO':
      case 'COSTO_ACTUALIZADO':
        return 'Costo actualizado';
      case 'COMPETENCIA':
        return 'Competencia';
      case 'AJUSTE_MERCADO':
        return 'Ajuste mercado';
      case 'MASIVO':
      case 'AJUSTE_MASIVO':
        return 'Masivo';
      case 'MANUAL':
      default:
        return 'Manual';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Historial de precios',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          showLogo: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : _load,
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.productoNombre,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_items.length} cambio(s) registrado(s)',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 40),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, color: Colors.grey.shade400, size: 50),
            const SizedBox(height: 8),
            const Text(
              'Sin cambios de precio registrados',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _buildCard(_items[i]),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final tipo = (item['tipoCambio'] as String?) ?? 'MANUAL';
    final razon = item['razon'] as String?;

    // Distinguir activación vs desactivación de liquidación.
    // El backend usa el mismo tipoCambio=LIQUIDACION para ambas pero
    // la razon arranca con "Liquidación desactivada" cuando se quita.
    final esLiqDesactivada = tipo == 'LIQUIDACION' &&
        razon != null &&
        razon.toLowerCase().contains('desactivada');
    final esLiqActivada =
        tipo == 'LIQUIDACION' && !esLiqDesactivada;

    final color = esLiqDesactivada
        ? Colors.grey.shade600
        : _colorTipoCambio(tipo);
    final label = esLiqDesactivada
        ? 'Liquidación desactivada'
        : (esLiqActivada ? 'Liquidación activada' : _labelTipoCambio(tipo));
    final origen = item['origenModulo'] as String?;
    final usuario = item['usuario'] as Map<String, dynamic>?;
    final persona = usuario?['persona'] as Map<String, dynamic>?;
    final usuarioNombre = persona != null
        ? '${persona['nombres'] ?? ''} ${persona['apellidos'] ?? ''}'.trim()
        : null;
    final creado = item['creadoEn'] != null
        ? DateTime.tryParse(item['creadoEn'] as String)?.toLocal()
        : null;

    // El backend serializa Decimal como string en algunas respuestas,
    // num en otras. _parseDecimal acepta ambos y null.
    final precioAnt = _parseDecimal(item['precioAnterior']);
    final precioNvo = _parseDecimal(item['precioNuevo']);
    final costoAnt = _parseDecimal(item['precioCostoAnterior']);
    final costoNvo = _parseDecimal(item['precioCostoNuevo']);
    final ofertaAnt = _parseDecimal(item['precioOfertaAnterior']);
    final ofertaNvo = _parseDecimal(item['precioOfertaNuevo']);

    final precioCambio = precioAnt != precioNvo;
    final costoCambio = costoAnt != costoNvo;
    final ofertaCambio = ofertaAnt != ofertaNvo;
    final sinCambiosVisibles = !precioCambio && !costoCambio && !ofertaCambio;

    // Liquidación: el backend reusa el slot `precioOfertaNuevo` para el
    // precio de liquidación. Mostramos un layout informativo (base + costo
    // + precio liquidación) en vez del diff genérico "Oferta -→ S/X".
    final esLiquidacion = esLiqActivada;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                if (creado != null)
                  Text(
                    DateFormatter.formatDateTime(creado),
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Modo Liquidación ACTIVADA: layout informativo.
            if (esLiquidacion) ...[
              _infoRow('Precio base', precioNvo, color: AppColors.blue1),
              _infoRow('Costo', costoNvo,
                  color: Colors.grey.shade700),
              _infoRow('Precio liquidación', ofertaNvo,
                  color: Colors.deepOrange.shade700, highlight: true),
            ]
            // Modo Liquidación DESACTIVADA: muestra precio liquidación
            // anterior tachado + el precio base que ahora vuelve a aplicar.
            else if (esLiqDesactivada) ...[
              _diffRow('Precio liquidación', ofertaAnt, ofertaNvo),
              _infoRow('Vuelve a precio base', precioNvo,
                  color: AppColors.blue1, highlight: true),
              if (costoNvo != null && costoNvo > 0)
                _infoRow('Costo', costoNvo, color: Colors.grey.shade700),
            ]
            // Modo genérico: diff anterior → nuevo de cada campo cambiado.
            else if (costoCambio || precioCambio || ofertaCambio) ...[
              if (costoCambio) _diffRow('Costo', costoAnt, costoNvo),
              if (precioCambio) _diffRow('Precio venta', precioAnt, precioNvo),
              if (ofertaCambio) _diffRow('Oferta', ofertaAnt, ofertaNvo),
            ]
            // Sin cambios de precio (ej. solo se cambió el flag enLiquidacion
            // sin tocar montos): mostrar mensaje sutil en lugar de card vacía.
            else if (sinCambiosVisibles) ...[
              Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    'Cambio de configuración (sin diff de precios)',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ],
            if (razon != null && razon.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes,
                        size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        razon,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade800,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (usuarioNombre != null && usuarioNombre.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 12, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    usuarioNombre,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade700),
                  ),
                  if (origen != null) ...[
                    const SizedBox(width: 8),
                    Text('•',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400)),
                    const SizedBox(width: 8),
                    Text(
                      origen,
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Acepta num (int/double) o String (Prisma Decimal serializado).
  /// Devuelve null si el valor es null o no parseable — preserva el
  /// significado "no había valor" vs "era 0".
  double? _parseDecimal(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Row de info simple (label + valor). Usado en modo Liquidación donde
  /// no aplica el diff "anterior → nuevo" sino mostrar el snapshot
  /// completo (base + costo + precio liquidación) al activar.
  Widget _infoRow(String label, double? valor,
      {Color? color, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ),
          Text(
            valor != null ? 'S/ ${valor.toStringAsFixed(2)}' : '—',
            style: TextStyle(
              fontSize: highlight ? 15 : 13,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _diffRow(String label, double? anterior, double? nuevo) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 95,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ),
          Text(
            anterior != null ? 'S/ ${anterior.toStringAsFixed(2)}' : '—',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              decoration: TextDecoration.lineThrough,
              decorationColor: Colors.grey.shade500,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward, size: 12, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Text(
            nuevo != null ? 'S/ ${nuevo.toStringAsFixed(2)}' : '—',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
