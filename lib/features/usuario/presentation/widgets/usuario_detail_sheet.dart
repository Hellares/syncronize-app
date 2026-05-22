import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_button.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';

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
  bool get _esCliente => usuario.rolEnEmpresa == 'CLIENTE';

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
                // Alias para ticket — solo aplica a roles que aparecen en
                // tickets (cajero/vendedor/técnico). Mostrar siempre que NO
                // sea cliente para que el admin descubra la funcionalidad.
                if (!_esCliente)
                  InkWell(
                    onTap: () => _showEditarAliasDialog(context),
                    child: _buildInfoRow(
                      Icons.badge_outlined,
                      'Alias ticket',
                      usuario.aliasTicket?.isNotEmpty == true
                          ? '${usuario.aliasTicket}  ✎'
                          : 'Sin alias  ✎',
                    ),
                  ),
                if (usuario.direccion != null && usuario.direccion!.isNotEmpty)
                  _buildInfoRow(Icons.home, 'Dirección', usuario.direccion!),
                if (usuario.distrito != null && usuario.distrito!.isNotEmpty)
                  _buildInfoRow(Icons.place, 'Distrito', usuario.distrito!),
                if (usuario.provincia != null && usuario.provincia!.isNotEmpty)
                  _buildInfoRow(Icons.location_city, 'Provincia', usuario.provincia!),
                if (usuario.departamento != null && usuario.departamento!.isNotEmpty)
                  _buildInfoRow(Icons.map, 'Departamento', usuario.departamento!),
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

          // Botones de acción. SafeArea(top: false) garantiza que en
          // celulares con gesture bar gruesa los botones no queden
          // tapados por la barra del sistema. Va acá adentro (no
          // afuera del Container) para que el sheet siga llegando al
          // borde inferior visualmente.
          SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                else ...[
                  // Botón ver dashboard del vendedor
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push(
                            '/empresa/dashboard-vendedor?vendedorId=${usuario.id}');
                      },
                      icon: const Icon(Icons.trending_up, size: 16),
                      label: const Text('Ver Dashboard de Ventas'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green.shade700,
                        side: BorderSide(color: Colors.green.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Botones para empleados
                  Row(
                    children: [
                      Expanded(
                        child: usuario.isActive
                            ? CustomButton(
                                backgroundColor: AppColors.blue1,
                                fontSize: 10,
                                icon: const Icon(Icons.person_off),
                                text: 'Desactivar',
                                onPressed: () =>
                                    _showDesactivarDialog(context),
                              )
                            : CustomButton(
                                backgroundColor: Colors.green.shade700,
                                fontSize: 10,
                                icon: const Icon(Icons.person_add_alt_1),
                                text: 'Reactivar',
                                onPressed: () =>
                                    _showReactivarDialog(context),
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

  /// Dialog de confirmación para reactivar un usuario que estaba
  /// inactivo. Tras éxito, el cubit recarga la lista respetando el
  /// filtro actual (si filtro es "inactivos" el usuario sigue visible
  /// pero ya como activo; si filtro es "activos" reaparece).
  void _showReactivarDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reactivar Usuario'),
        content: Text(
          '¿Está seguro que desea reactivar a ${usuario.nombreCompleto}?\n\nEl usuario podrá iniciar sesión nuevamente y acceder a la empresa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reactivando usuario...'),
                  duration: Duration(seconds: 1),
                ),
              );

              final success =
                  await cubit.reactivarUsuario(usuarioId: usuario.id);

              if (!context.mounted) return;

              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${usuario.nombreCompleto} ha sido reactivado',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error al reactivar usuario'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reactivar'),
          ),
        ],
      ),
    );
  }

  /// Dialog para asignar/cambiar/limpiar el alias del usuario que se
  /// imprime en tickets. Reusa `cubit.updateUsuario` con un body parcial
  /// `{aliasTicket: ...}` — el endpoint PATCH /usuarios/:id ya lo acepta.
  Future<void> _showEditarAliasDialog(BuildContext context) async {
    final controller = TextEditingController(text: usuario.aliasTicket ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String?>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: AppGradients.blueWhiteBlue(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con icono + título
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.blue1.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.badge_outlined,
                          size: 16, color: AppColors.blue1),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Alias para ticket',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 38),
                  child: Text(
                    usuario.nombreCompleto,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Mensaje explicativo
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.35),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 12, color: Colors.amber.shade800),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Lo verá el cliente en el ticket en lugar del '
                          'nombre completo. Dejalo vacío para mostrar el '
                          'nombre real.',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade800,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Input
                CustomText(
                  controller: controller,
                  label: 'Alias',
                  hintText: 'JP, Caja 1, Juana...',
                  borderColor: AppColors.blue1,
                  maxLength: 30,
                  textCase: TextCase.normal,
                  prefixIcon: Icon(Icons.short_text,
                      size: 16, color: AppColors.blue1),
                  validator: (v) {
                    final trimmed = (v ?? '').trim();
                    if (trimmed.length > 30) return 'Máximo 30 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // CustomButton internamente usa `SizedBox(double.infinity)`,
                    // así que requiere un ancho acotado cuando vive dentro de
                    // un Row.
                    SizedBox(
                      width: 130,
                      child: CustomButton(
                        text: 'Guardar',
                        backgroundColor: AppColors.blue1,
                        fontSize: 12,
                        icon: const Icon(Icons.check, size: 14),
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(dialogCtx, controller.text.trim());
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == null) return; // cancelado
    // String vacío = limpiar alias (backend lo guarda como null).
    final ok = await cubit.updateUsuario(
      usuarioId: usuario.id,
      data: {'aliasTicket': result},
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? (result.isEmpty
                ? 'Alias eliminado'
                : 'Alias guardado: $result')
            : 'No se pudo guardar el alias'),
        backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
      ),
    );
    if (ok && context.mounted) {
      // Cerrar el sheet para que al reabrir muestre el nuevo valor.
      Navigator.pop(context);
    }
  }
}
