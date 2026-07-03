import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/widgets/custom_loading.dart';
import '../../../../core/widgets/smart_appbar.dart';

/// TODAS las cotizaciones dirigidas al cliente del marketplace: las que
/// respondieron sus solicitudes + las que una empresa le creó DIRECTAMENTE
/// asignándolo como cliente (match por su Persona/DNI). Tap → detalle con
/// aceptar/rechazar/pagar (CotizacionClientePage por cotizacionId).
class MisCotizacionesPage extends StatefulWidget {
  const MisCotizacionesPage({super.key});

  @override
  State<MisCotizacionesPage> createState() => _MisCotizacionesPageState();
}

class _MisCotizacionesPageState extends State<MisCotizacionesPage> {
  List<dynamic> _cotizaciones = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final resp = await locator<DioClient>().get('/marketplace/cotizaciones');
      if (mounted) {
        setState(() {
          _cotizaciones = resp.data as List<dynamic>? ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudieron cargar tus cotizaciones';
          _isLoading = false;
        });
      }
    }
  }

  double _n(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      style: GradientStyle.minimal,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const SmartAppBar(title: 'Mis Cotizaciones'),
        body: _isLoading
            ? CustomLoading.small(message: 'Cargando...')
            : _error != null
                ? Center(child: Text(_error!))
                : _cotizaciones.isEmpty
                    ? _empty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _cotizaciones.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => _card(
                              _cotizaciones[i] as Map<String, dynamic>),
                        ),
                      ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.request_quote_outlined,
              size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('Aún no tienes cotizaciones',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(
            'Cuando una tienda te cotice — por una solicitud tuya\no directamente con tu DNI — aparecerá aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _card(Map<String, dynamic> c) {
    final empresa = c['empresa'] as Map<String, dynamic>?;
    final venta = c['venta'] as Map<String, dynamic>?;
    final solicitud = c['solicitudOrigen'] as Map<String, dynamic>?;
    final estado = c['estado'] as String? ?? '';
    final total = _n(c['total']);
    final adelanto = _n(c['adelantoMonto']);
    final saldo = total - adelanto;
    final items = (c['_count'] as Map<String, dynamic>?)?['detalles'] ?? 0;
    final fecha = (c['fechaEmision'] as String? ?? '').split('T').first;
    final logo = empresa?['logo'] as String?;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context
          .push('/mis-cotizaciones/${c['id']}')
          .then((_) => _load()),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: logo != null
                      ? CachedNetworkImage(
                          imageUrl: logo,
                          width: 30,
                          height: 30,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _logoFallback(),
                        )
                      : _logoFallback(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        empresa?['nombre'] as String? ?? 'Tienda',
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${c['codigo'] ?? ''} · $fecha · $items item${items == 1 ? '' : 's'}',
                        style: TextStyle(
                            fontSize: 10.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                _estadoChip(estado, adelanto),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Origen: respuesta a una solicitud suya, o directa de la
                // tienda (le cotizaron con su DNI).
                Expanded(
                  child: Text(
                    solicitud != null
                        ? 'Responde a tu solicitud ${solicitud['codigo']}'
                        : 'Cotización directa de la tienda',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (estado == 'CONVERTIDA' && venta != null)
                  Text(
                    'Comprado · S/ ${_n(venta['total']).toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue2),
                  )
                else if (adelanto > 0 && saldo > 0.005)
                  Text(
                    'Pagado S/ ${adelanto.toStringAsFixed(2)} · Saldo S/ ${saldo.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade700),
                  )
                else
                  Text(
                    'S/ ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w800),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoFallback() => Container(
        width: 30,
        height: 30,
        color: Colors.grey.shade100,
        child: Icon(Icons.storefront, size: 16, color: Colors.grey.shade400),
      );

  Widget _estadoChip(String estado, double adelanto) {
    String label;
    Color color;
    switch (estado) {
      case 'PENDIENTE':
        label = 'Por revisar';
        color = Colors.orange.shade700;
        break;
      case 'APROBADA':
        label = adelanto > 0 ? 'Separada' : 'Aceptada';
        color = Colors.green.shade700;
        break;
      case 'RECHAZADA':
        label = 'Rechazada';
        color = Colors.red.shade600;
        break;
      case 'VENCIDA':
        label = 'Vencida';
        color = Colors.grey.shade600;
        break;
      case 'CONVERTIDA':
        label = 'Comprada';
        color = AppColors.blue2;
        break;
      default:
        label = estado;
        color = Colors.grey.shade600;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
