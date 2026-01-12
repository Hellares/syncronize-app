import 'package:flutter/material.dart';
import '../bloc/usuario_list/usuario_list_cubit.dart';

/// Bottom sheet para filtrar usuarios
class UsuarioFilterSheet extends StatelessWidget {
  final UsuarioListCubit cubit;

  const UsuarioFilterSheet({
    super.key,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtros',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ListTile(
            title: const Text('Todos'),
            onTap: () {
              cubit.filterByActive(null);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Activos'),
            onTap: () {
              cubit.filterByActive(true);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Inactivos'),
            onTap: () {
              cubit.filterByActive(false);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          if (cubit.hasActiveFilters)
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('Limpiar filtros'),
              onTap: () {
                cubit.resetFilters();
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}
