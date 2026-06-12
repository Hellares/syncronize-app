import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/resource.dart';
import 'package:syncronize/core/widgets/editar_datos_contacto_dialog.dart';

import '../../domain/entities/cliente.dart';
import '../../domain/repositories/cliente_repository.dart';

/// Bottom sheet que muestra el detalle de un cliente
class ClienteDetailSheet extends StatelessWidget {
  final Cliente cliente;
  final ScrollController scrollController;

  /// Necesario para PUT /clientes/:id al editar datos.
  final String empresaId;

  /// Notifica a la página (reload de la lista) tras guardar cambios.
  final VoidCallback? onUpdated;

  const ClienteDetailSheet({
    super.key,
    required this.cliente,
    required this.scrollController,
    required this.empresaId,
    this.onUpdated,
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
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 18, color: AppColors.blue1),
                      tooltip: 'Editar datos',
                      onPressed: () => _showEditarDatosDialog(context),
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

  /// Edita los datos de contacto con el dialog compartido. PUT
  /// /clientes/:id actualiza la Persona compartida — el push
  /// CLIENTE_CAMBIADO propaga el cambio a los catálogos locales de
  /// todas las empresas vinculadas.
  Future<void> _showEditarDatosDialog(BuildContext context) async {
    final data = await showEditarDatosContactoDialog(
      context,
      telefono: cliente.telefono,
      email: cliente.email,
      direccion: cliente.direccion,
    );
    if (data == null || !context.mounted) return;

    final result = await locator<ClienteRepository>().updateCliente(
      empresaId: empresaId,
      clienteId: cliente.id,
      data: data,
    );
    final ok = result is Success<Cliente>;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Datos actualizados' : 'No se pudo actualizar'),
        backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
      ),
    );
    if (ok) {
      onUpdated?.call();
      Navigator.pop(context);
    }
  }

  /// Ancho fijo de la columna de labels — mismo estilo que
  /// UsuarioDetailSheet: todos los valores alineados verticalmente.
  static const double _labelWidth = 90;

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: _labelWidth,
            child: AppSubtitle(
              label,
              font: AppFont.amazonEmberMedium,
              fontSize: 11,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: AppSubtitle(value, fontSize: 11, font: AppFont.amazonEmberMedium),
          ),
        ],
      ),
    );
  }
}
