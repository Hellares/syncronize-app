import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/avatar_circle.dart';
import '../../../../core/widgets/chip_simple.dart';
import '../../domain/entities/usuario.dart';

/// Widget que muestra un usuario en la lista
class UsuarioListTile extends StatelessWidget {
  final Usuario usuario;
  final VoidCallback? onTap;

  const UsuarioListTile({
    super.key,
    required this.usuario,
    this.onTap,
  });

  /// Verifica si el usuario es un cliente
  bool get _esCliente =>
      usuario.rolEnEmpresa == 'CLIENTE' ||
      usuario.rolEnEmpresa == 'CLIENTE_EMPRESA';

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      margin: const EdgeInsets.only(bottom: 12),
      borderColor: AppColors.blueborder,
      shadowStyle: ShadowStyle.glow,
      child: ListTile(
        dense: true,
        leading: AvatarCircle(
          size: 40,
          text: _esCliente ? null : usuario.iniciales,
          fontSize: 10,
          colors: _esCliente
              ? [Colors.orange[400]!, Colors.orange[600]!]
              : usuario.isActive
                  ? [AppColors.blue1, AppColors.blue1.withValues(alpha: 0.8)]
                  : [Colors.grey[400]!, Colors.grey[600]!],
          shadowColor: _esCliente
              ? Colors.orange
              : usuario.isActive
                  ? AppColors.blue1
                  : Colors.grey,
          customChild: _esCliente
              ? const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                )
              : null,
        ),
        title: AppSubtitle(usuario.nombreCompleto, fontSize: 12,),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height:2),
            AppSubtitle(usuario.rolFormateado),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.phone,
                  size: 12,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  usuario.telefono ?? '-',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                if (usuario.email != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.email,
                    size: 12,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      usuario.email!,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (_esCliente)
                ChipSimple(label: 'Cliente', color: AppColors.blue,)
                else ...[
                  ChipSimple(
                    label:usuario.estadoFormateado,
                    color:usuario.isActive ? Colors.green : Colors.grey,
                  ),
                  if (usuario.tieneSedes)
                    ChipSimple(
                      label: '${usuario.sedesActivas} ${usuario.sedesActivas == 1 ? 'sede' : 'sedes'}',
                      color: AppColors.blue,
                    ),
                  if (usuario.puedeAbrirCaja)
                    ChipSimple(label:'Abre caja',color: Colors.orange),
                  if (usuario.puedeCerrarCaja)
                    ChipSimple(label:'Cierra caja',color: Colors.purple),
                  if (usuario.requiereCambioPassword)
                    ChipSimple(label:'Cambiar contraseña',color: Colors.red),
                ],
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }

}
