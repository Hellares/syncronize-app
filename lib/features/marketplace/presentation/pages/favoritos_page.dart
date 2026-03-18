import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../widgets/producto_marketplace_card.dart';

class FavoritosPage extends StatefulWidget {
  const FavoritosPage({super.key});

  @override
  State<FavoritosPage> createState() => _FavoritosPageState();
}

class _FavoritosPageState extends State<FavoritosPage> {
  final _dio = locator<DioClient>();

  List<dynamic> _productos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoritos();
  }

  Future<void> _loadFavoritos() async {
    setState(() => _isLoading = true);
    try {
      final response = await _dio.get(
        '${ApiConstants.marketplaceUsuario}/favoritos',
        queryParameters: {'limit': '50'},
      );
      setState(() {
        _productos = response.data['data'] as List;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar.withBackButton(
        title: 'Mis Favoritos',
        onBack: () => context.pop(),
      ),
      body: GradientBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _productos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border, size: 56, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No tienes favoritos aún',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Text('Toca el corazón en un producto para guardarlo',
                            style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadFavoritos,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.58,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _productos.length,
                      itemBuilder: (_, index) {
                        return ProductoMarketplaceCard(
                          producto: _productos[index],
                          onTap: () async {
                            await context.push('/producto-detalle/${_productos[index]['id']}');
                            _loadFavoritos();
                          },
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
