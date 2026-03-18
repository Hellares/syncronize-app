import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';

class UbicacionSelector extends StatelessWidget {
  final double? lat;
  final double? lng;
  final String? label;
  final ValueChanged<({double? lat, double? lng, String? label})> onChanged;

  const UbicacionSelector({
    super.key,
    this.lat,
    this.lng,
    this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSelector(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.white,
        child: Row(
          children: [
            Icon(Icons.location_on, size: 14, color: AppColors.blue1),
            const SizedBox(width: 6),
            Text(
              label ?? 'Mi ubicación',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.blue1,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showSelector(BuildContext context) {
    final dio = locator<DioClient>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return FutureBuilder<List<dynamic>>(
          future: dio.get(ApiConstants.misDirecciones).then((r) => r.data as List).catchError((_) => <dynamic>[]),
          builder: (context, snapshot) {
            final direcciones = snapshot.data ?? [];

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Buscar productos cerca de',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),

                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.my_location, color: Colors.blue),
                    title: const Text('Mi ubicación actual', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Usar GPS del dispositivo', style: TextStyle(fontSize: 12)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final pos = await LocationService.getCurrentLocation();
                      onChanged((lat: pos?.latitude, lng: pos?.longitude, label: 'Mi ubicación'));
                    },
                  ),

                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else if (direcciones.isNotEmpty) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: Text('Mis direcciones',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                    ),
                    ...direcciones.map((d) {
                      final coords = d['coordenadas'] as Map<String, dynamic>?;
                      final esPred = d['esPredeterminada'] == true;
                      final etiqueta = d['etiqueta'] as String?;
                      final tipo = d['tipo'] as String? ?? '';

                      return ListTile(
                        dense: true,
                        leading: Icon(
                          esPred ? Icons.star : Icons.location_on,
                          color: esPred ? Colors.amber : Colors.grey,
                          size: 20,
                        ),
                        title: Text(
                          etiqueta ?? _tipoLabel(tipo),
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          d['direccion'] ?? '',
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: coords != null
                            ? Icon(Icons.check_circle, size: 16, color: Colors.green[400])
                            : null,
                        onTap: coords != null
                            ? () {
                                Navigator.pop(ctx);
                                final dLat = (coords['lat'] as num?)?.toDouble();
                                final dLng = ((coords['lng'] ?? coords['lon']) as num?)?.toDouble();
                                onChanged((lat: dLat, lng: dLng, label: etiqueta ?? _tipoLabel(tipo)));
                              }
                            : null,
                        enabled: coords != null,
                      );
                    }),
                  ],

                  const Divider(),
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.public, color: Colors.grey[400]),
                    title: const Text('Sin filtro de ubicación', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Mostrar todos los productos', style: TextStyle(fontSize: 12)),
                    onTap: () {
                      Navigator.pop(ctx);
                      onChanged((lat: null, lng: null, label: null));
                    },
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _tipoLabel(String tipo) {
    switch (tipo) {
      case 'ENVIO': return 'Envío';
      case 'FISCAL': return 'Fiscal';
      case 'TRABAJO': return 'Trabajo';
      default: return 'Dirección';
    }
  }
}
