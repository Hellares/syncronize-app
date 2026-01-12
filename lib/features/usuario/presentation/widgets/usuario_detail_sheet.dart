import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_button.dart';

import '../../domain/entities/usuario.dart';
import '../bloc/usuario_list/usuario_list_cubit.dart';
import '../widgets/asignar_rol_dialog.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';

/// Bottom sheet que muestra el detalle de un usuario
class UsuarioDetailSheet extends StatelessWidget {
  final Usuario usuario;
  final ScrollController scrollController;
  final UsuarioListCubit cubit;

  const UsuarioDetailSheet({
    super.key,
    required this.usuario,
    required this.scrollController,
    required this.cubit,
  });

  /// Verifica si el usuario es un cliente
  bool get _esCliente =>
      usuario.rolEnEmpresa == 'CLIENTE' ||
      usuario.rolEnEmpresa == 'CLIENTE_EMPRESA';

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
                        usuario.iniciales,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            usuario.nombreCompleto,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            usuario.rolFormateado,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.badge, 'DNI', usuario.dni),
                _buildInfoRow(Icons.phone, 'Teléfono', usuario.telefono ?? '-'),
                _buildInfoRow(Icons.email, 'Email', usuario.email ?? '-'),
                _buildInfoRow(Icons.info, 'Estado', usuario.estadoFormateado),
                const SizedBox(height: 16),
                if (usuario.sedes.isNotEmpty) ...[
                  const Text(
                    'Sedes Asignadas',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...usuario.sedes.map(
                    (sede) => GradientContainer(
                      borderColor: AppColors.blueborder,
                      gradient: AppGradients.blueWhiteBlue(),
                      child: ListTile(
                        dense: true,
                        title: Text(
                          sede.sedeNombre,
                          style: TextStyle(fontSize: 12),
                        ),
                        subtitle: Text(
                          sede.rolFormateado,
                          style: TextStyle(fontSize: 10),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (sede.puedeAbrirCaja)
                              const Icon(Icons.lock_open, size: 16),
                            if (sede.puedeCerrarCaja)
                              const Icon(Icons.lock, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Botones de acción
          const Divider(),
          const SizedBox(height: 12),
          if (_esCliente)
            // Botón para convertir cliente a empleado
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showConvertirAEmpleadoDialog(context),
                icon: const Icon(Icons.badge),
                label: const Text('Convertir a Empleado'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            )
          else
            // Botones para empleados
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    backgroundColor: AppColors.blue1,
                    fontSize: 10,
                    icon: Icon(Icons.person_off),
                    text: 'Desactivar',
                    onPressed: usuario.isActive
                        ? () => _showDesactivarDialog(context)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: CustomButton(
                    borderColor: AppColors.white,
                    backgroundColor: AppColors.white,
                    textColor: AppColors.blue1,
                    fontSize: 10,
                    text: 'Asignar Rol/Permisos',
                    onPressed: () => _showAsignarRolDialog(context),
                    icon: const Icon(Icons.security),
                  ),
                ),
              ],
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
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showAsignarRolDialog(
    BuildContext context, {
    bool esConversion = false,
  }) {
    // Obtener las sedes disponibles desde el contexto de la empresa
    final empresaState = context.read<EmpresaContextCubit>().state;
    final List<SedeOption> sedesDisponibles = [];

    if (empresaState is EmpresaContextLoaded) {
      // Convertir List<Sede> a List<SedeOption>
      sedesDisponibles.addAll(
        empresaState.context.sedes
            .where((sede) => sede.isActive) // Solo sedes activas
            .map(
              (sede) => SedeOption(
                id: sede.id,
                nombre: sede.nombre,
                direccion: sede.direccion,
              ),
            )
            .toList(),
      );
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AsignarRolDialog(
        usuario: usuario,
        esConversion: esConversion,
        sedesDisponibles: sedesDisponibles,
        onGuardar: (data) async {
          print('📝 onGuardar ejecutado');
          print('esConversion: $esConversion');
          print('data: $data');
          print('usuario.id: ${usuario.id}');

          // NO cerrar el dialog aquí - el dialog se cerrará solo cuando termine
          // El dialog muestra su propio loading indicator

          bool success;

          if (esConversion) {
            print('🔄 Entrando a conversión...');
            // Convertir cliente a empleado (actualizar su rol)
            success = await cubit.convertirClienteAEmpleado(
              usuarioId: usuario.id,
              datosEmpleado: data,
            );
            print('Resultado conversión: $success');
          } else {
            print('🔄 Entrando a actualización...');
            // Actualizar empleado existente
            success = await cubit.updateUsuario(
              usuarioId: usuario.id,
              data: data,
            );
            print('Resultado actualización: $success');
          }

          if (success) {
            // Verificar que el widget sigue montado antes de usar context
            if (!context.mounted) return;

            // Cerrar el sheet de detalle
            Navigator.pop(context);

            // Mostrar mensaje de éxito
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  esConversion
                      ? '${usuario.nombreCompleto} ahora es empleado de la empresa'
                      : 'Usuario actualizado exitosamente',
                ),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'Ver',
                  textColor: Colors.white,
                  onPressed: () {
                    // TODO: Navegar al detalle del usuario actualizado
                  },
                ),
              ),
            );
          } else {
            // Si falló, lanzar excepción para que el dialog la muestre
            throw Exception(
              esConversion
                  ? 'Error al convertir cliente a empleado'
                  : 'Error al actualizar usuario',
            );
          }
        },
      ),
    );
  }

  void _showConvertirAEmpleadoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // ajusta el valor
        ),
        backgroundColor: AppColors.white,
        title: Row(
          children: const [
            Icon(Icons.badge, color: Colors.green, size: 16),
            SizedBox(width: 8),
            Text('Convertir a Empleado', style: TextStyle(fontSize: 12)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${usuario.nombreCompleto} será convertido a empleado de la empresa.',
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Deberá asignar un rol y permisos específicos.',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Datos del cliente:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoChip(Icons.badge, 'DNI: ${usuario.dni}'),
            if (usuario.telefono != null)
              _buildInfoChip(Icons.phone, usuario.telefono!),
            if (usuario.email != null)
              _buildInfoChip(Icons.email, usuario.email!),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  borderColor: AppColors.white,
                  backgroundColor: AppColors.white,
                  textColor: AppColors.blue1,
                  text: 'Cancelar',
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: CustomButton(
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                  text: 'Continuar',
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    // Abrir el dialog de asignar rol en modo conversión
                    _showAsignarRolDialog(context, esConversion: true);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _showDesactivarDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Desactivar Usuario'),
        content: Text(
          '¿Está seguro que desea desactivar a ${usuario.nombreCompleto}?\n\nEsta acción se puede revertir posteriormente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Mostrar loading
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Desactivando usuario...'),
                  duration: Duration(seconds: 1),
                ),
              );

              // Desactivar el usuario
              final success = await cubit.deleteUsuario(usuarioId: usuario.id);

              // Verificar que el widget sigue montado antes de usar context
              if (!context.mounted) return;

              if (success) {
                // Cerrar el sheet de detalle
                Navigator.pop(context);

                // Mostrar mensaje de éxito
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${usuario.nombreCompleto} ha sido desactivado',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error al desactivar usuario'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }
}
