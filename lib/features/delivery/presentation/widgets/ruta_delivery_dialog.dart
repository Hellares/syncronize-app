import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as ll;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/delivery_local.dart';

/// Muestra el recorrido del pedido: de la TIENDA al DESTINO.
///
/// La card del pool solo decía la dirección de entrega, y con eso el
/// repartidor no puede evaluar si el pedido le queda de camino o lo manda
/// al otro extremo de la ciudad. Acá ve los dos puntos, la distancia y
/// hacia dónde va antes de comprometerse.
///
/// ⚠️ Traza una LÍNEA RECTA, no la ruta por calles: dibujar el recorrido
/// real exige un servicio de routing que se cobra por consulta. Para navegar
/// de verdad está el botón, que abre Google Maps por deep link — eso no
/// factura. Por eso la distancia se rotula "en línea recta": la real por
/// calle siempre es mayor y no hay que hacerla pasar por exacta.
Future<void> showRutaDeliveryDialog({
  required BuildContext context,
  required DeliveryLocal delivery,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _RutaDialog(delivery: delivery),
  );
}

class _RutaDialog extends StatefulWidget {
  final DeliveryLocal delivery;

  const _RutaDialog({required this.delivery});

  @override
  State<_RutaDialog> createState() => _RutaDialogState();
}

class _RutaDialogState extends State<_RutaDialog> {
  gmaps.GoogleMapController? _mapa;

  gmaps.LatLng get _origen =>
      gmaps.LatLng(widget.delivery.origenLat!, widget.delivery.origenLon!);
  gmaps.LatLng get _destino =>
      gmaps.LatLng(widget.delivery.destinoLat!, widget.delivery.destinoLon!);

  /// Distancia en línea recta. `latlong2` ya está en el proyecto y evita
  /// escribir la haversine a mano.
  double get _kilometros =>
      const ll.Distance().as(
        ll.LengthUnit.Meter,
        ll.LatLng(widget.delivery.origenLat!, widget.delivery.origenLon!),
        ll.LatLng(widget.delivery.destinoLat!, widget.delivery.destinoLon!),
      ) /
      1000;

  @override
  void dispose() {
    _mapa?.dispose();
    super.dispose();
  }

  /// Encuadra los dos puntos. Va tras el primer frame porque el mapa
  /// necesita estar medido para aceptar un `LatLngBounds`.
  Future<void> _encuadrar() async {
    final mapa = _mapa;
    if (mapa == null) return;
    final bounds = gmaps.LatLngBounds(
      southwest: gmaps.LatLng(
        _origen.latitude < _destino.latitude
            ? _origen.latitude
            : _destino.latitude,
        _origen.longitude < _destino.longitude
            ? _origen.longitude
            : _destino.longitude,
      ),
      northeast: gmaps.LatLng(
        _origen.latitude > _destino.latitude
            ? _origen.latitude
            : _destino.latitude,
        _origen.longitude > _destino.longitude
            ? _origen.longitude
            : _destino.longitude,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    // 60 px de margen para que los pines no queden pegados al borde.
    await mapa.animateCamera(gmaps.CameraUpdate.newLatLngBounds(bounds, 60));
  }

  Future<void> _navegar() async {
    final uri = Uri.parse(widget.delivery.urlNavegacion);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.delivery;
    final alto = MediaQuery.of(context).size.height;

    return Dialog(
      insetPadding: const EdgeInsets.all(14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: Row(
              children: [
                Icon(Icons.route_outlined, size: 18, color: AppColors.blue1),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Recorrido · ${_kilometros.toStringAsFixed(1)} km en línea recta',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          ClipRRect(
            child: SizedBox(
              height: alto * 0.42,
              child: gmaps.GoogleMap(
                initialCameraPosition: gmaps.CameraPosition(
                  target: _origen,
                  zoom: 13,
                ),
                onMapCreated: (c) {
                  _mapa = c;
                  _encuadrar();
                },
                markers: {
                  gmaps.Marker(
                    markerId: const gmaps.MarkerId('origen'),
                    position: _origen,
                    infoWindow: gmaps.InfoWindow(
                      title: d.origenNombre ?? 'Tienda',
                      snippet: d.origenDireccion,
                    ),
                    icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                      gmaps.BitmapDescriptor.hueAzure,
                    ),
                  ),
                  gmaps.Marker(
                    markerId: const gmaps.MarkerId('destino'),
                    position: _destino,
                    infoWindow: gmaps.InfoWindow(
                      title: 'Entrega',
                      snippet: d.direccion,
                    ),
                  ),
                },
                polylines: {
                  gmaps.Polyline(
                    polylineId: const gmaps.PolylineId('recta'),
                    points: [_origen, _destino],
                    color: AppColors.blue1,
                    width: 3,
                    // Punteada, para que no se lea como la ruta real.
                    patterns: [
                      gmaps.PatternItem.dash(18),
                      gmaps.PatternItem.gap(10),
                    ],
                  ),
                },
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                liteModeEnabled: false,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              children: [
                _punto(
                  icono: Icons.store_mall_directory_outlined,
                  color: Colors.blue.shade700,
                  titulo: d.origenNombre ?? 'Tienda',
                  detalle: d.origenDireccion ?? 'Punto de partida',
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 8, top: 2, bottom: 2),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(Icons.more_vert, size: 14, color: Colors.grey),
                  ),
                ),
                _punto(
                  icono: Icons.location_on_outlined,
                  color: Colors.red.shade700,
                  titulo: d.direccion,
                  detalle: [d.referencia, d.distrito]
                      .where((s) => s != null && s.trim().isNotEmpty)
                      .join(' · '),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.blue1,
                      textStyle: const TextStyle(fontSize: 12.5),
                    ),
                    onPressed: _navegar,
                    icon: const Icon(Icons.navigation_outlined, size: 17),
                    label: const Text('Navegar con Google Maps'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _punto({
    required IconData icono,
    required Color color,
    required String titulo,
    required String detalle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 17, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
              if (detalle.isNotEmpty)
                Text(
                  detalle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
