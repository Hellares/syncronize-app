import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../domain/entities/empresa_context.dart';

class SedesSection extends StatelessWidget {
  final EmpresaContext empresaContext;

  const SedesSection({
    super.key,
    required this.empresaContext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppSubtitle('Sedes', fontSize: 14),
            if (empresaContext.permissions.canManageSedes)
              TextButton(
                onPressed: () => context.push('/empresa/sedes'),
                child: const Text('Ver todas'),
              ),
          ],
        ),
        // const SizedBox(height: 16),
        ...empresaContext.sedes.take(3).map((sede) => Card(
              child: ListTile(
                leading: Icon(
                  sede.esPrincipal ? Icons.star : Icons.store,
                  color: sede.esPrincipal ? Colors.amber : Colors.grey,
                  size: 16,
                ),
                title: Text(sede.nombre, style: TextStyle(fontSize: 12),),
                subtitle: Text(sede.direccion ?? 'Sin dirección', style: TextStyle(fontSize: 10),),
                trailing: sede.hasUserRole
                    ? Chip(
                        label: Text(
                          _formatRole(sede.userRole!),
                          style: const TextStyle(fontSize: 10),
                        ),
                      )
                    : null,
              ),
            )),
      ],
    );
  }

  String _formatRole(String role) {
    final roleMap = {
      'SUPER_ADMIN': 'Super Admin',
      'EMPRESA_ADMIN': 'Administrador',
      'SEDE_ADMIN': 'Admin de Sede',
      'CAJERO': 'Cajero',
      'VENDEDOR': 'Vendedor',
      'TECNICO': 'Técnico',
      'CONTADOR': 'Contador',
      'LECTURA': 'Solo Lectura',
    };
    return roleMap[role] ?? role;
  }
}
