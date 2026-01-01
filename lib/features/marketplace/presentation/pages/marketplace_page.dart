import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import '../../../../core/utils/auth_helper.dart';
import '../widgets/marketplace_app_bar.dart';
import '../widgets/marketplace_categories_section.dart';
import '../widgets/marketplace_featured_products_section.dart';
import '../widgets/marketplace_sorteos_section.dart';
import '../widgets/marketplace_search_bar.dart';
import '../widgets/marketplace_companies_section.dart';
import '../widgets/marketplace_drawer.dart';

/// Página principal del Marketplace
/// Muestra productos de todas las empresas disponibles
class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final ScrollController _scrollController = ScrollController();
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 100 && !_showSearchBar) {
      setState(() => _showSearchBar = true);
    } else if (_scrollController.offset <= 100 && _showSearchBar) {
      setState(() => _showSearchBar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: const MarketplaceDrawer(),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar personalizado
          MarketplaceAppBar(showSearchBar: _showSearchBar),

          // Contenido principal
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barra de búsqueda principal
                const MarketplaceSearchBar(),

                // Categorías
                const MarketplaceCategoriesSection(),

                // Productos destacados
                const MarketplaceFeaturedProductsSection(),

                // Sorteos
                const MarketplaceSorteosSection(),

                // Empresas destacadas
                const MarketplaceCompaniesSection(),

                // Espacio inferior
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () => _showCreateCompanyDialog(context),
      //   icon: const Icon(Icons.add_business),
      //   label: const Text('Crear Empresa'),
      //   backgroundColor: Colors.blue,
      // ),
    );
  }

  // void _showCreateCompanyDialog(BuildContext context) {
  //   // Usar AuthHelper para verificar autenticación
  //   AuthHelper.requireAuth(
  //     context,
  //     returnTo: '/create-empresa',
  //     title: 'Inicia Sesión',
  //     message: 'Necesitas iniciar sesión para crear tu empresa',
  //     onAuthenticated: () {
  //       // Si está autenticado, mostrar diálogo de confirmación
  //       showDialog(
  //         context: context,
  //         builder: (context) => AlertDialog(
  //           title: const Text('Crear tu Empresa'),
  //           content: const Text(
  //             '¿Deseas crear tu propia empresa para vender en el marketplace?',
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.pop(context),
  //               child: const Text('Cancelar'),
  //             ),
  //             FilledButton(
  //               onPressed: () {
  //                 Navigator.of(context).pop();
  //                 if (context.mounted) {
  //                   context.goNamed('create-empresa');
  //                 }
  //               },
  //               child: const Text('Continuar'),
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }
}