import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';

class MapLocationPicker extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapLocationPicker({super.key, this.initialLat, this.initialLng});

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  late LatLng _selectedPosition;
  LatLng? _userPosition;
  bool _isLoading = true;

  // Búsqueda
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _selectedPosition = LatLng(
      widget.initialLat ?? -12.0464,
      widget.initialLng ?? -77.0428,
    );
    _loadUserLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadUserLocation() async {
    // Solicitar permiso explícitamente al abrir el mapa
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    final position = await LocationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (position != null) {
          _userPosition = LatLng(position.latitude, position.longitude);
          if (widget.initialLat == null) {
            _selectedPosition = _userPosition!;
          }
        }
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 3) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchAddress(query.trim());
    });
  }

  Future<void> _searchAddress(String query) async {
    setState(() => _isSearching = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json'
        '&addressdetails=1'
        '&limit=5'
        '&countrycodes=pe',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'SyncronizeApp/1.0',
      });

      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _searchResults = data.map((e) => Map<String, dynamic>.from(e)).toList();
          _showResults = _searchResults.isNotEmpty;
          _isSearching = false;
        });
      } else {
        if (mounted) setState(() => _isSearching = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final lat = double.tryParse(result['lat'].toString());
    final lng = double.tryParse(result['lon'].toString());
    if (lat != null && lng != null) {
      setState(() {
        _selectedPosition = LatLng(lat, lng);
        _showResults = false;
        _searchController.text = result['display_name'] ?? '';
      });
      _mapController.move(_selectedPosition, 17);
    }
  }

  Future<void> _centerOnUser() async {
    if (_userPosition != null) {
      setState(() => _selectedPosition = _userPosition!);
      _mapController.move(_userPosition!, 16);
      return;
    }

    // Intentar obtener ubicación si no la teníamos
    final position = await LocationService.getCurrentLocation();
    if (position != null && mounted) {
      setState(() {
        _userPosition = LatLng(position.latitude, position.longitude);
        _selectedPosition = _userPosition!;
      });
      _mapController.move(_userPosition!, 16);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener tu ubicación. Verifica que el GPS esté activado.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _centerOnSelected() {
    _mapController.move(_selectedPosition, 16);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar ubicación',
            style: TextStyle(fontSize: 16, color: Colors.white)),
        backgroundColor: AppColors.blue1,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'lat': _selectedPosition.latitude,
                'lng': _selectedPosition.longitude,
              });
            },
            child: const Text('Confirmar',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Mapa
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedPosition,
                    initialZoom: 15,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _selectedPosition = point;
                        _showResults = false;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.syncronize.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedPosition,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                        ),
                        if (_userPosition != null)
                          Marker(
                            point: _userPosition!,
                            width: 20,
                            height: 20,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // Barra de búsqueda
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Buscar dirección...',
                            hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 16, height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchResults = [];
                                            _showResults = false;
                                          });
                                        },
                                      )
                                    : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),

                      // Resultados
                      if (_showResults)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          constraints: const BoxConstraints(maxHeight: 220),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, index) {
                              final result = _searchResults[index];
                              return ListTile(
                                dense: true,
                                leading: Icon(Icons.location_on, size: 18, color: Colors.grey[500]),
                                title: Text(
                                  result['display_name'] ?? '',
                                  style: const TextStyle(fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => _selectSearchResult(result),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                // Info de coordenadas
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 80,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Toca el mapa para mover el pin',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedPosition.latitude.toStringAsFixed(6)}, ${_selectedPosition.longitude.toStringAsFixed(6)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),

                // Botones
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    children: [
                      if (_userPosition != null)
                        FloatingActionButton.small(
                          heroTag: 'user_loc',
                          onPressed: _centerOnUser,
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.my_location, color: Colors.blue, size: 20),
                        ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'pin_loc',
                        onPressed: _centerOnSelected,
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.pin_drop, color: Colors.red, size: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
