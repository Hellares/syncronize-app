import 'package:geolocator/geolocator.dart';

class LocationService {
  static Position? _lastPosition;

  static Position? get lastPosition => _lastPosition;

  /// Obtener ubicación actual del usuario
  static Future<Position?> getCurrentLocation() async {
    try {
      // Verificar si el servicio está habilitado
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return _lastPosition;

      // Verificar permisos
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return _lastPosition;
      }
      if (permission == LocationPermission.deniedForever) return _lastPosition;

      // Obtener posición
      _lastPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return _lastPosition;
    } catch (e) {
      return _lastPosition;
    }
  }

  /// Formatear distancia para mostrar
  static String formatDistance(double? km) {
    if (km == null) return '';
    if (km < 1) return '${(km * 1000).round()} m';
    if (km < 10) return '${km.toStringAsFixed(1)} km';
    return '${km.round()} km';
  }
}
