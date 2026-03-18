import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';

class FavoritoButton extends StatefulWidget {
  final String productoId;
  final bool initialFavorito;
  final double size;

  const FavoritoButton({
    super.key,
    required this.productoId,
    this.initialFavorito = false,
    this.size = 22,
  });

  /// IDs de productos favoritos del usuario (cargados una vez)
  static Set<String> _favoritosIds = {};
  static bool _loaded = false;

  static Future<void> loadFavoritos() async {
    try {
      final dio = locator<DioClient>();
      final response = await dio.get('${ApiConstants.marketplaceUsuario}/favoritos/ids');
      _favoritosIds = Set<String>.from(response.data as List);
      _loaded = true;
    } catch (_) {
      // No autenticado o error - ignorar
    }
  }

  static bool isFavorito(String productoId) => _favoritosIds.contains(productoId);
  static bool get isLoaded => _loaded;

  @override
  State<FavoritoButton> createState() => _FavoritoButtonState();
}

class _FavoritoButtonState extends State<FavoritoButton> {
  late bool _esFavorito;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _esFavorito = widget.initialFavorito || FavoritoButton.isFavorito(widget.productoId);
  }

  Future<void> _toggle() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _esFavorito = !_esFavorito;
    });

    try {
      final dio = locator<DioClient>();
      final response = await dio.post(
        '${ApiConstants.marketplaceUsuario}/favoritos/${widget.productoId}',
      );
      final result = response.data['favorito'] as bool;
      if (result) {
        FavoritoButton._favoritosIds.add(widget.productoId);
      } else {
        FavoritoButton._favoritosIds.remove(widget.productoId);
      }
      if (mounted) setState(() => _esFavorito = result);
    } catch (_) {
      if (mounted) setState(() => _esFavorito = !_esFavorito);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          _esFavorito ? Icons.favorite : Icons.favorite_border,
          key: ValueKey(_esFavorito),
          size: widget.size,
          color: _esFavorito ? Colors.red : Colors.grey[400],
        ),
      ),
    );
  }
}
