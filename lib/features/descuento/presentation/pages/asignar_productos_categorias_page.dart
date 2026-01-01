import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../bloc/asignar_productos/asignar_productos_cubit.dart';
import '../bloc/asignar_productos/asignar_productos_state.dart';

class AsignarProductosCategoriasPage extends StatefulWidget {
  final String politicaId;
  final String politicaNombre;

  const AsignarProductosCategoriasPage({
    super.key,
    required this.politicaId,
    required this.politicaNombre,
  });

  @override
  State<AsignarProductosCategoriasPage> createState() =>
      _AsignarProductosCategoriasPageState();
}

class _AsignarProductosCategoriasPageState
    extends State<AsignarProductosCategoriasPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _selectedProductos = {};
  final Set<String> _selectedCategorias = {};

  // Mock data - TODO: Load from API
  final List<Map<String, dynamic>> _allProductos = [];
  final List<Map<String, dynamic>> _allCategorias = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // TODO: Load productos and categorias from empresa
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _asignarProductos() {
    if (_selectedProductos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un producto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final productos = _selectedProductos
        .map((id) => {'productoId': id})
        .toList();

    context.read<AsignarProductosCubit>().asignarProductos(
          politicaId: widget.politicaId,
          productos: productos,
        );

    setState(() => _selectedProductos.clear());
  }

  void _asignarCategorias() {
    if (_selectedCategorias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos una categoría'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final categorias = _selectedCategorias
        .map((id) => {'categoriaId': id})
        .toList();

    context.read<AsignarProductosCubit>().asignarCategorias(
          politicaId: widget.politicaId,
          categorias: categorias,
        );

    setState(() => _selectedCategorias.clear());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<AsignarProductosCubit>(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: SmartAppBar(
          showLogo: false,
          title: 'Asignar Productos/Categorías',
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.blue1,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.blue1,
              tabs: const [
                Tab(text: 'PRODUCTOS'),
                Tab(text: 'CATEGORÍAS'),
              ],
            ),
          ),
        ),
        body: GradientBackground(
          style: GradientStyle.professional,
          child: SafeArea(
            child: BlocConsumer<AsignarProductosCubit, AsignarProductosState>(
              listener: (context, state) {
                if (state is AsignarProductosSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (state is AsignarProductosError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProductosTab(),
                    _buildCategoriasTab(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductosTab() {
    return Column(
      children: [
        _buildHeader('Selecciona los productos a asignar'),
        Expanded(
          child: _allProductos.isEmpty
              ? _buildEmptyState('productos', Icons.inventory_2)
              : _buildProductosList(),
        ),
        if (_selectedProductos.isNotEmpty)
          _buildAssignButton(
            'Asignar Productos (${_selectedProductos.length})',
            _asignarProductos,
          ),
      ],
    );
  }

  Widget _buildCategoriasTab() {
    return Column(
      children: [
        _buildHeader('Selecciona las categorías a asignar'),
        Expanded(
          child: _allCategorias.isEmpty
              ? _buildEmptyState('categorías', Icons.category)
              : _buildCategoriasList(),
        ),
        if (_selectedCategorias.isNotEmpty)
          _buildAssignButton(
            'Asignar Categorías (${_selectedCategorias.length})',
            _asignarCategorias,
          ),
      ],
    );
  }

  Widget _buildHeader(String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Política: ${widget.politicaNombre}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String tipo, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay $tipo disponibles',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega $tipo a tu empresa primero',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildProductosList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _allProductos.length,
      itemBuilder: (context, index) {
        final producto = _allProductos[index];
        final productoId = producto['id'] as String;
        final isSelected = _selectedProductos.contains(productoId);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedProductos.add(productoId);
                } else {
                  _selectedProductos.remove(productoId);
                }
              });
            },
            title: Text(
              producto['nombre'] ?? 'Sin nombre',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (producto['codigo'] != null)
                  Text('Código: ${producto['codigo']}'),
                if (producto['precio'] != null)
                  Text('Precio: S/. ${producto['precio']}'),
              ],
            ),
            secondary: CircleAvatar(
              backgroundColor: AppColors.blue1.withValues(alpha: 0.1),
              child: const Icon(Icons.inventory_2, color: AppColors.blue1),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoriasList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _allCategorias.length,
      itemBuilder: (context, index) {
        final categoria = _allCategorias[index];
        final categoriaId = categoria['id'] as String;
        final isSelected = _selectedCategorias.contains(categoriaId);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedCategorias.add(categoriaId);
                } else {
                  _selectedCategorias.remove(categoriaId);
                }
              });
            },
            title: Text(
              categoria['nombre'] ?? 'Sin nombre',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              categoria['descripcion'] ?? 'Sin descripción',
            ),
            secondary: CircleAvatar(
              backgroundColor: AppColors.blue1.withValues(alpha: 0.1),
              child: const Icon(Icons.category, color: AppColors.blue1),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssignButton(String label, VoidCallback onPressed) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
