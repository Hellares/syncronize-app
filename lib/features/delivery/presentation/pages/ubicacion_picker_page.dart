import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/smart_appbar.dart';

/// Resultado del picker: el punto exacto + la dirección aproximada de ese
/// punto (reverse geocoding de Nominatim, best-effort) para autollenar la
/// caja de dirección.
class UbicacionElegida {
  final LatLng punto;
  final String? direccion;

  /// Distrito/zona del punto (para autollenar y para el match de zonas
  /// de los repartidores freelance).
  final String? zona;

  const UbicacionElegida({required this.punto, this.direccion, this.zona});
}

/// Selector de ubicación EXACTA estilo Rappi/Uber: mueves el mapa bajo el
/// pin fijo del centro y confirmas. OpenStreetMap vía flutter_map — gratis,
/// sin API key. Devuelve la ubicación elegida (o null si canceló).
class UbicacionPickerPage extends StatefulWidget {
  /// Centro inicial; si es null intenta la última posición conocida del
  /// dispositivo y cae a Chiclayo como default.
  final LatLng? inicial;

  const UbicacionPickerPage({super.key, this.inicial});

  static Future<UbicacionElegida?> show(BuildContext context,
      {LatLng? inicial}) {
    return Navigator.of(context).push<UbicacionElegida>(
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
  final _busquedaCtrl = TextEditingController();
  LatLng _centro = _fallback;
  bool _listo = false;
  bool _buscando = false;
  List<({String nombre, double lat, double lon})> _resultados = const [];

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

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  /// Geocoding con Nominatim (OpenStreetMap) — gratis, sin API key. Se
  /// busca al ENVIAR (no por tecla: su política pide máx 1 req/s).
  Future<void> _buscarDireccion(String q) async {
    final query = q.trim();
    if (query.isEmpty) return;
    setState(() => _buscando = true);
    try {
      final uri =
          Uri.parse('https://nominatim.openstreetmap.org/search').replace(
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': '5',
          'countrycodes': 'pe',
        },
      );
      final r = await http.get(
        uri,
        headers: {'User-Agent': 'SyncronizeApp/1.0 (delivery picker)'},
      ).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final lista = (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
        final resultados = <({String nombre, double lat, double lon})>[];
        for (final e in lista) {
          final lat = double.tryParse(e['lat']?.toString() ?? '');
          final lon = double.tryParse(e['lon']?.toString() ?? '');
          final nombre = e['display_name']?.toString() ?? '';
          if (lat != null && lon != null && nombre.isNotEmpty) {
            resultados.add((nombre: nombre, lat: lat, lon: lon));
          }
        }
        if (mounted) setState(() => _resultados = resultados);
        if (resultados.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Sin resultados — prueba con calle y ciudad',
                style: TextStyle(fontSize: 12)),
          ));
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo buscar — revisa tu conexión',
              style: TextStyle(fontSize: 12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  void _irAResultado(({String nombre, double lat, double lon}) r) {
    FocusScope.of(context).unfocus();
    setState(() {
      _resultados = const [];
      // Si confirma cerca de aquí y el reverse falla, usamos este nombre.
      _ultimaDireccionBuscada = r.nombre;
    });
    _mapController.move(LatLng(r.lat, r.lon), 17);
  }

  String? _ultimaDireccionBuscada;
  bool _confirmando = false;

  /// Reverse geocoding del punto final (Nominatim, best-effort): la
  /// dirección corta se autollena en la caja del sheet.
  Future<void> _confirmar() async {
    final punto = _mapController.camera.center;
    setState(() => _confirmando = true);
    String? direccion;
    String? zona;
    try {
      final uri =
          Uri.parse('https://nominatim.openstreetmap.org/reverse').replace(
        queryParameters: {
          'lat': punto.latitude.toString(),
          'lon': punto.longitude.toString(),
          'format': 'json',
          'zoom': '18',
          'addressdetails': '1',
        },
      );
      final r = await http.get(
        uri,
        headers: {'User-Agent': 'SyncronizeApp/1.0 (delivery picker)'},
      ).timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        final nombre = body['display_name']?.toString();
        if (nombre != null && nombre.isNotEmpty) {
          // display_name es larguísimo (hasta el país): las 3 primeras
          // partes bastan como dirección editable.
          direccion = nombre.split(',').take(3).map((s) => s.trim()).join(', ');
        }
        // Zona/distrito: Nominatim lo reporta con nombres distintos según
        // el lugar — se toma el primero disponible de mayor precisión.
        final addr = body['address'];
        if (addr is Map<String, dynamic>) {
          for (final clave in [
            'suburb',
            'city_district',
            'district',
            'village',
            'town',
            'city',
          ]) {
            final v = addr[clave]?.toString();
            if (v != null && v.isNotEmpty) {
              zona = v;
              break;
            }
          }
        }
      }
    } catch (_) {}
    direccion ??= _ultimaDireccionBuscada;
    if (!mounted) return;
    setState(() => _confirmando = false);
    Navigator.pop(
      context,
      UbicacionElegida(punto: punto, direccion: direccion, zona: zona),
    );
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
                // Buscador de direcciones (Nominatim/OSM): escribe y ENTER.
                Positioned(
                  left: 12,
                  right: 12,
                  top: 10,
                  child: Column(
                    children: [
                      Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(10),
                        child: TextField(
                          controller: _busquedaCtrl,
                          textInputAction: TextInputAction.search,
                          onSubmitted: _buscarDireccion,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Buscar dirección… ej. Av. Balta 1234, Chiclayo',
                            hintStyle: const TextStyle(fontSize: 12),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _buscando
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.arrow_forward,
                                        size: 18),
                                    onPressed: () =>
                                        _buscarDireccion(_busquedaCtrl.text),
                                  ),
                          ),
                        ),
                      ),
                      if (_resultados.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          constraints: const BoxConstraints(maxHeight: 220),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 6),
                            ],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _resultados.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final r = _resultados[i];
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.place_outlined,
                                    size: 18, color: AppColors.blue1),
                                title: Text(
                                  r.nombre,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => _irAResultado(r),
                              );
                            },
                          ),
                        ),
                    ],
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
                          onPressed: _confirmando ? null : _confirmar,
                          icon: _confirmando
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check),
                          label: Text(_confirmando
                              ? 'Obteniendo dirección…'
                              : 'Confirmar ubicación'),
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
