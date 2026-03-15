import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';

import '../../domain/entities/cliente.dart';

/// Bottom sheet que muestra el detalle de un cliente
class ClienteDetailSheet extends StatelessWidget {
  final Cliente cliente;
  final ScrollController scrollController;

  const ClienteDetailSheet({
    super.key,
    required this.cliente,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        gradient: AppGradients.blueWhiteBlue(),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      child: Text(
                        cliente.iniciales,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cliente.nombreCompleto,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Cliente',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.badge, 'DNI', cliente.dni ?? '-'),
                _buildInfoRow(Icons.phone, 'Teléfono', cliente.telefono ?? '-'),
                _buildInfoRow(Icons.email, 'Email', cliente.email ?? '-'),
                if (cliente.direccion != null && cliente.direccion!.isNotEmpty)
                  _buildInfoRow(Icons.home, 'Dirección', cliente.direccion!),
                if (cliente.distrito != null && cliente.distrito!.isNotEmpty)
                  _buildInfoRow(Icons.place, 'Distrito', cliente.distrito!),
                if (cliente.provincia != null && cliente.provincia!.isNotEmpty)
                  _buildInfoRow(
                      Icons.location_city, 'Provincia', cliente.provincia!),
                if (cliente.departamento != null &&
                    cliente.departamento!.isNotEmpty)
                  _buildInfoRow(
                      Icons.map, 'Departamento', cliente.departamento!),
                _buildInfoRow(Icons.info, 'Estado',
                    cliente.isActive ? 'Activo' : 'Inactivo'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push(
                        '/empresa/citas/historial-cliente',
                        extra: {
                          'clienteId': cliente.id,
                          'clienteNombre': cliente.nombreCompleto,
                        },
                      );
                    },
                    icon: const Icon(Icons.calendar_month, size: 16),
                    label: const Text('Ver historial de citas', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.blue1,
                      side: const BorderSide(color: AppColors.blue1, width: 0.8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                if (cliente.registradoPorNombre != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Registro',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GradientContainer(
                    borderColor: AppColors.blueborder,
                    gradient: AppGradients.blueWhiteBlue(),
                    child: ListTile(
                      dense: true,
                      leading:
                          Icon(Icons.person, size: 20, color: Colors.grey[600]),
                      title: Text(
                        'Registrado por ${cliente.registradoPorNombre}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
