import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../services/reverse_geocoder.dart';

/// Resultado del picker: el punto exacto + la dirección aproximada de ese
/// punto (reverse geocoding de Nominatim, best-effort) para autollenar la
/// caja de dirección.
class UbicacionElegida {
  final LatLng punto;
  final String? direccion;

  /// Distrito/zona del punto (para autollenar y para el match de zonas
  /// de los repartidores freelance).
  final String? zona;

  /// Referencia guardada (solo cuando se eligió una dirección frecuente).
  final String? referencia;

  const UbicacionElegida({
    required this.punto,
    this.direccion,
    this.zona,
    this.referencia,
  });
}

/// Resultado de búsqueda: frecuente (geocoder propio), Nominatim/OSM o
/// Google (fallback por botón, server-side).
typedef _ResultadoBusqueda = ({
  String nombre,
  double lat,
  double lon,
  bool frecuente,
  bool google,
  String? distrito,
  String? referencia,
});

/// Selector de ubicación EXACTA estilo Rappi/Uber: mueves el mapa bajo el
/// pin fijo del centro y confirmas. OpenStreetMap vía flutter_map — gratis,
/// sin API key. Devuelve la ubicación elegida (o null si canceló).
///
/// Geocoder PROPIO (Fase 1): la búsqueda consulta PRIMERO las direcciones
/// confirmadas de la empresa (los lugares reales de la zona) y muestra las
/// recientes del cliente por su celular — Nominatim queda como complemento.
class UbicacionPickerPage extends StatefulWidget {
  /// Centro inicial; si es null intenta la última posición conocida del
  /// dispositivo y cae a Chiclayo como default.
  final LatLng? inicial;

  /// Habilitan el geocoder propio (búsqueda local + recientes del cliente).
  final String? empresaId;
  final String? telefonoCliente;

  const UbicacionPickerPage({
    super.key,
    this.inicial,
    this.empresaId,
    this.telefonoCliente,
  });

  static Future<UbicacionElegida?> show(
    BuildContext context, {
    LatLng? inicial,
    String? empresaId,
    String? telefonoCliente,
  }) {
    return Navigator.of(context).push<UbicacionElegida>(
      MaterialPageRoute(
        builder: (_) => UbicacionPickerPage(
          inicial: inicial,
          empresaId: empresaId,
          telefonoCliente: telefonoCliente,
        ),
      ),
    );
  }

  @override
  State<UbicacionPickerPage> createState() => _UbicacionPickerPageState();
}

class _UbicacionPickerPageState extends State<UbicacionPickerPage> {
  static const _fallback = LatLng(-6.7714, -79.8409); // Chiclayo

  gmaps.GoogleMapController? _gmap;
  final _busquedaCtrl = TextEditingController();
  LatLng _centro = _fallback;

  /// Centro actual de la cámara (el pin fijo apunta aquí).
  LatLng _centroActual = _fallback;
  bool _listo = false;
  bool _buscando = false;
  List<_ResultadoBusqueda> _resultados = const [];

  /// Última búsqueda enviada: habilita el botón "Buscar con Google".
  String? _ultimaBusqueda;

  /// Direcciones recientes del cliente (geocoder propio, por celular).
  List<_ResultadoBusqueda> _recientes = const [];

  /// Frecuente elegida: al confirmar se usa SU texto/zona/referencia (mejor
  /// que el reverse de Nominatim — es lo que un humano ya confirmó antes).
  _ResultadoBusqueda? _seleccionFrecuente;

  @override
  void initState() {
    super.initState();
    if (widget.inicial != null) {
      _centro = widget.inicial!;
      _listo = true;
    } else {
      _resolverCentro();
    }
    _cargarRecientes();
  }

  /// Recientes del cliente por celular (best-effort, silencioso).
  Future<void> _cargarRecientes() async {
    final empresaId = widget.empresaId;
    final telefono = widget.telefonoCliente?.trim();
    if (empresaId == null || telefono == null || telefono.isEmpty) return;
    try {
      final r = await locator<DioClient>().get(
        '/delivery-local/direcciones/buscar',
        queryParameters: {'empresaId': empresaId, 'telefono': telefono},
      );
      final lista = ((r.data as Map)['delCliente'] as List? ?? const [])
          .whereType<Map>()
          .map(_mapFrecuente)
          .toList();
      if (mounted && lista.isNotEmpty) setState(() => _recientes = lista);
    } catch (_) {}
  }

  _ResultadoBusqueda _mapFrecuente(Map d) => (
        nombre: d['texto']?.toString() ?? '',
        lat: ((d['lat'] ?? 0) as num).toDouble(),
        lon: ((d['lon'] ?? 0) as num).toDouble(),
        frecuente: true,
        google: false,
        distrito: d['distrito']?.toString(),
        referencia: d['referencia']?.toString(),
      );

  /// Fase 2: geocodificación Google vía NUESTRO backend (key por IP, jamás
  /// en el APK). Se dispara por BOTÓN — 1 llamada por búsqueda exacta.
  Future<void> _buscarGoogle() async {
    final query = _ultimaBusqueda ?? _busquedaCtrl.text.trim();
    if (query.isEmpty) return;
    setState(() => _buscando = true);
    try {
      final r = await locator<DioClient>().get(
        '/delivery-local/direcciones/geocode',
        queryParameters: {'q': query},
      );
      final lista = ((r.data as Map)['resultados'] as List? ?? const [])
          .whereType<Map>()
          .map((d) => (
                nombre: d['nombre']?.toString() ?? '',
                lat: ((d['lat'] ?? 0) as num).toDouble(),
                lon: ((d['lon'] ?? 0) as num).toDouble(),
                frecuente: false,
                google: true,
                distrito: null,
                referencia: null,
              ))
          .where((e) => e.nombre.isNotEmpty)
          .toList();
      if (!mounted) return;
      if (lista.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Google tampoco encontró esa dirección',
              style: TextStyle(fontSize: 12)),
        ));
      } else {
        // Google al tope (reemplaza lo anterior: el usuario pidió este
        // fallback explícitamente).
        setState(() => _resultados = lista);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo buscar con Google',
              style: TextStyle(fontSize: 12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  /// Búsqueda en el geocoder PROPIO (direcciones confirmadas de la empresa).
  Future<List<_ResultadoBusqueda>> _buscarFrecuentes(String q) async {
    final empresaId = widget.empresaId;
    if (empresaId == null) return const [];
    try {
      final r = await locator<DioClient>().get(
        '/delivery-local/direcciones/buscar',
        queryParameters: {'empresaId': empresaId, 'q': q},
      );
      return ((r.data as Map)['coincidencias'] as List? ?? const [])
          .whereType<Map>()
          .map(_mapFrecuente)
          .where((e) => e.nombre.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  /// Busca al ENVIAR (no por tecla): PRIMERO el geocoder propio (direcciones
  /// confirmadas de la zona) y en paralelo Nominatim/OSM como complemento.
  Future<void> _buscarDireccion(String q) async {
    final query = q.trim();
    if (query.isEmpty) return;
    setState(() {
      _buscando = true;
      _ultimaBusqueda = query;
    });
    try {
      final resultados = await Future.wait([
        _buscarFrecuentes(query),
        _buscarNominatim(query),
      ]);
      final combinados = [...resultados[0], ...resultados[1]];
      if (mounted) setState(() => _resultados = combinados);
      if (combinados.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sin resultados locales — prueba "Buscar con Google"',
              style: TextStyle(fontSize: 12)),
        ));
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

  /// Geocoding con Nominatim (OpenStreetMap) — gratis, sin API key.
  Future<List<_ResultadoBusqueda>> _buscarNominatim(String query) async {
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
      if (r.statusCode != 200) return const [];
      final lista = (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
      final resultados = <_ResultadoBusqueda>[];
      for (final e in lista) {
        final lat = double.tryParse(e['lat']?.toString() ?? '');
        final lon = double.tryParse(e['lon']?.toString() ?? '');
        final nombre = e['display_name']?.toString() ?? '';
        if (lat != null && lon != null && nombre.isNotEmpty) {
          resultados.add((
            nombre: nombre,
            lat: lat,
            lon: lon,
            frecuente: false,
            google: false,
            distrito: null,
            referencia: null,
          ));
        }
      }
      return resultados;
    } catch (_) {
      return const [];
    }
  }

  void _irAResultado(_ResultadoBusqueda r) {
    FocusScope.of(context).unfocus();
    setState(() {
      _resultados = const [];
      _ultimaBusqueda = null;
      // Frecuente: al confirmar mandan su texto/zona/referencia guardados.
      _seleccionFrecuente = r.frecuente ? r : null;
      // Si confirma cerca de aquí y el reverse falla, usamos este nombre.
      _ultimaDireccionBuscada = r.nombre;
    });
    _centroActual = LatLng(r.lat, r.lon);
    _gmap?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(gmaps.LatLng(r.lat, r.lon), 17),
    );
  }

  String? _ultimaDireccionBuscada;
  bool _confirmando = false;

  /// Reverse geocoding del punto final (Nominatim, best-effort): la
  /// dirección corta se autollena en la caja del sheet.
  ///
  /// Si se eligió una dirección FRECUENTE, se devuelven su texto/zona/
  /// referencia guardados directamente (mejor que el reverse: es lo que un
  /// humano ya confirmó antes) — sin llamada externa.
  Future<void> _confirmar() async {
    final punto = _centroActual;
    final frecuente = _seleccionFrecuente;
    if (frecuente != null) {
      Navigator.pop(
        context,
        UbicacionElegida(
          punto: punto,
          direccion: frecuente.nombre,
          zona: frecuente.distrito,
          referencia: frecuente.referencia,
        ),
      );
      return;
    }
    setState(() => _confirmando = true);
    final aproximada = await reverseGeocode(punto);
    final zona = aproximada.zona;
    final direccion = aproximada.direccion ?? _ultimaDireccionBuscada;
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
                // Google Maps SDK: el mapa móvil no factura (gratis
                // ilimitado); la key vive en el AndroidManifest.
                gmaps.GoogleMap(
                  initialCameraPosition: gmaps.CameraPosition(
                    target:
                        gmaps.LatLng(_centro.latitude, _centro.longitude),
                    zoom: 16,
                  ),
                  onMapCreated: (c) => _gmap = c,
                  onCameraMove: (pos) => _centroActual = LatLng(
                      pos.target.latitude, pos.target.longitude),
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
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
                      if (_resultados.isNotEmpty || _ultimaBusqueda != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          constraints: const BoxConstraints(maxHeight: 260),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 6),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
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
                                      leading: Icon(
                                        r.frecuente
                                            ? Icons.star
                                            : r.google
                                                ? Icons.travel_explore
                                                : Icons.place_outlined,
                                        size: 18,
                                        color: r.frecuente
                                            ? Colors.amber.shade700
                                            : r.google
                                                ? Colors.blue.shade700
                                                : AppColors.blue1,
                                      ),
                                      title: Text(
                                        r.nombre,
                                        style: const TextStyle(fontSize: 12),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: r.frecuente
                                          ? Text(
                                              [
                                                if (r.distrito != null &&
                                                    r.distrito!.isNotEmpty)
                                                  r.distrito!,
                                                'usada antes',
                                              ].join(' · '),
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors
                                                      .amber.shade800),
                                            )
                                          : null,
                                      onTap: () => _irAResultado(r),
                                    );
                                  },
                                ),
                              ),
                              // Fallback Google por BOTÓN: 1 llamada por
                              // búsqueda, vía backend (key nunca en el APK).
                              if (_ultimaBusqueda != null) ...[
                                if (_resultados.isNotEmpty)
                                  const Divider(height: 1),
                                ListTile(
                                  dense: true,
                                  leading: Icon(Icons.travel_explore,
                                      size: 18, color: Colors.blue.shade700),
                                  title: Text(
                                    'Buscar con Google Maps',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade700),
                                  ),
                                  onTap: _buscando ? null : _buscarGoogle,
                                ),
                              ],
                            ],
                          ),
                        ),
                      // Direcciones recientes del CLIENTE (por su celular):
                      // atajo de un tap, sin escribir nada.
                      if (_resultados.isEmpty && _recientes.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 6),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 8, 12, 0),
                                child: Text(
                                  'Direcciones del cliente',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade600),
                                ),
                              ),
                              ..._recientes.map((r) => ListTile(
                                    dense: true,
                                    leading: Icon(Icons.history,
                                        size: 18,
                                        color: Colors.teal.shade700),
                                    title: Text(
                                      r.nombre,
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: (r.distrito != null &&
                                            r.distrito!.isNotEmpty)
                                        ? Text(r.distrito!,
                                            style: TextStyle(
                                                fontSize: 10,
                                                color:
                                                    Colors.grey.shade500))
                                        : null,
                                    onTap: () => _irAResultado(r),
                                  )),
                            ],
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
