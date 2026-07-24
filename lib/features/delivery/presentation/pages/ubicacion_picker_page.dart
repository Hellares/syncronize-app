import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/smart_appbar.dart';

/// Selector de ubicación EXACTA estilo Rappi/Uber: mueves el mapa bajo el
/// pin fijo del centro y confirmas. OpenStreetMap vía flutter_map — gratis,
/// sin API key. Devuelve el LatLng elegido (o null si canceló).
class UbicacionPickerPage extends StatefulWidget {
  /// Centro inicial; si es null intenta la última posición conocida del
  /// dispositivo y cae a Chiclayo como default.
  final LatLng? inicial;

  const UbicacionPickerPage({super.key, this.inicial});

  static Future<LatLng?> show(BuildContext context, {LatLng? inicial}) {
    return Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => UbicacionPickerPage(inicial: inicial),
      ),
    );
  }

  @override
  State<UbicacionPickerPage> createState() => _UbicacionPickerPageState();
}

class _UbicacionPickerPageState extends State<UbicacionPickerPage> {
  static const _fallback = LatLng(-6.7714, -79.8409); // Chiclayo

  final _mapController = MapController();
  LatLng _centro = _fallback;
  bool _listo = false;

  @override
  void initState() {
    super.initState();
    if (widget.inicial != null) {
      _centro = widget.inicial!;
      _listo = true;
    } else {
      _resolverCentro();
    }
  }

  /// Best-effort: última posición conocida SIN pedir permisos nuevos.
  Future<void> _resolverCentro() async {
    try {
      final permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.whileInUse ||
          permiso == LocationPermission.always) {
        final p = await Geolocator.getLastKnownPosition();
        if (p != null) _centro = LatLng(p.latitude, p.longitude);
      }
    } catch (_) {}
    if (mounted) setState(() => _listo = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Fijar ubicación de entrega',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
      ),
      body: !_listo
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _centro,
                    initialZoom: 16,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'pe.syncronize.app',
                    ),
                  ],
                ),
                // Pin FIJO al centro: la punta apunta exactamente al centro
                // del mapa (offset de media altura del ícono).
                const IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 42),
                      child: Icon(
                        Icons.location_pin,
                        size: 46,
                        color: Colors.red,
                        shadows: [
                          Shadow(color: Colors.black38, blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 20,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 6),
                          ],
                        ),
                        child: const Text(
                          'Mueve el mapa hasta que el pin quede sobre el '
                          'punto exacto de entrega',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blue1,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => Navigator.pop(
                            context,
                            _mapController.camera.center,
                          ),
                          icon: const Icon(Icons.check),
                          label: const Text('Confirmar ubicación'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
