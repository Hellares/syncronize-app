import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Dirección aproximada de un punto. Ambos campos son best-effort: si
/// Nominatim no responde o no reconoce el lugar, quedan en `null` y la caja
/// se llena a mano.
class DireccionAproximada {
  final String? direccion;
  final String? zona;

  const DireccionAproximada({this.direccion, this.zona});

  static const DireccionAproximada vacia = DireccionAproximada();
}

/// Reverse geocoding contra Nominatim (OSM).
///
/// Lo usan el picker al confirmar el pin y el sheet de delivery cuando el
/// punto llega ya resuelto — por ejemplo una ubicación compartida por
/// WhatsApp, donde el usuario nunca pasa por el mapa y sin esto la caja de
/// dirección quedaría vacía.
///
/// Nunca lanza: un fallo de red no debe tumbar el flujo de delivery.
Future<DireccionAproximada> reverseGeocode(LatLng punto) async {
  try {
    final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse').replace(
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
    if (r.statusCode != 200) return DireccionAproximada.vacia;

    final body = jsonDecode(r.body) as Map<String, dynamic>;

    String? direccion;
    final nombre = body['display_name']?.toString();
    if (nombre != null && nombre.isNotEmpty) {
      // display_name es larguísimo (llega hasta el país): las 3 primeras
      // partes bastan como dirección editable.
      direccion = nombre.split(',').take(3).map((s) => s.trim()).join(', ');
    }

    // Zona/distrito: Nominatim lo reporta con nombres distintos según el
    // lugar — se toma el primero disponible.
    //
    // ⚠️ El orden va de DISTRITO hacia abajo, con `suburb` (el barrio) al
    // final a propósito. Este campo alimenta el match de zonas de los
    // repartidores, que declaran distritos o provincias: quedarse con el
    // barrio dejaba pedidos que no veía nadie (caso real: distrito
    // "MIRAMAR" contra repartidores con zona "TRUJILLO"). El barrio igual
    // no se pierde — va dentro del texto de la dirección.
    String? zona;
    final addr = body['address'];
    if (addr is Map<String, dynamic>) {
      for (final clave in [
        'city_district',
        'district',
        'town',
        'city',
        'village',
        'suburb',
      ]) {
        final v = addr[clave]?.toString();
        if (v != null && v.isNotEmpty) {
          zona = v;
          break;
        }
      }
    }

    return DireccionAproximada(direccion: direccion, zona: zona);
  } catch (_) {
    return DireccionAproximada.vacia;
  }
}
