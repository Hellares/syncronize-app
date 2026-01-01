import 'package:flutter/material.dart';

/// Sección de categorías del Marketplace
class MarketplaceCategoriesSection extends StatelessWidget {
  const MarketplaceCategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categorías',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Ver todas las categorías
                },
                child: const Text('Ver todas'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _CategoryCard(
                icon: Icons.phone_android,
                label: 'Electrónica',
                color: Colors.blue,
                onTap: () {},
              ),
              _CategoryCard(
                icon: Icons.checkroom,
                label: 'Ropa',
                color: Colors.purple,
                onTap: () {},
              ),
              _CategoryCard(
                icon: Icons.home,
                label: 'Hogar',
                color: Colors.orange,
                onTap: () {},
              ),
              _CategoryCard(
                icon: Icons.sports_soccer,
                label: 'Deportes',
                color: Colors.green,
                onTap: () {},
              ),
              _CategoryCard(
                icon: Icons.book,
                label: 'Libros',
                color: Colors.brown,
                onTap: () {},
              ),
              _CategoryCard(
                icon: Icons.toys,
                label: 'Juguetes',
                color: Colors.pink,
                onTap: () {},
              ),
              _CategoryCard(
                icon: Icons.restaurant,
                label: 'Alimentos',
                color: Colors.red,
                onTap: () {},
              ),
              _CategoryCard(
                icon: Icons.more_horiz,
                label: 'Más',
                color: Colors.grey,
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Card de categoría
class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 90,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}