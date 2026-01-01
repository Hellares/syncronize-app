import 'package:flutter/material.dart';

/// Barra de búsqueda del Marketplace
class MarketplaceSearchBar extends StatelessWidget {
  const MarketplaceSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Buscar productos, empresas...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: IconButton(
              icon: const Icon(Icons.tune, color: Colors.blue),
              onPressed: () => _showFilters(context),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              // TODO: Implementar búsqueda
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Buscando: $value')),
              );
            }
          },
        ),
      ),
    );
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtros',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _FilterOption(
              icon: Icons.category,
              title: 'Categoría',
              onTap: () {
                // TODO: Mostrar categorías
              },
            ),
            _FilterOption(
              icon: Icons.attach_money,
              title: 'Rango de precio',
              onTap: () {
                // TODO: Mostrar selector de precio
              },
            ),
            _FilterOption(
              icon: Icons.business,
              title: 'Empresa',
              onTap: () {
                // TODO: Mostrar empresas
              },
            ),
            _FilterOption(
              icon: Icons.location_on,
              title: 'Ubicación',
              onTap: () {
                // TODO: Mostrar ubicaciones
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Aplicar filtros
                },
                child: const Text('Aplicar Filtros'),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

/// Widget para cada opción de filtro
class _FilterOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _FilterOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}