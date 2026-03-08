import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/avatar_circle.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/widgets/chip_simple.dart';
import '../../domain/entities/cliente.dart';

class ClienteListTile extends StatelessWidget {
  final Cliente cliente;
  final VoidCallback? onTap;

  const ClienteListTile({
    super.key,
    required this.cliente,
    this.onTap,
  });

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
          text: cliente.iniciales,
          fontSize: 10,
          colors: cliente.isActive
              ? [AppColors.blue1, AppColors.blue1.withValues(alpha: 0.8)]
              : [Colors.grey[400]!, Colors.grey[600]!],
          shadowColor: cliente.isActive ? AppColors.blue1 : Colors.grey,
        ),
        title: AppSubtitle(cliente.nombreCompleto, fontSize: 12),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.badge, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'DNI: ${cliente.dni ?? 'Sin DNI'}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.phone, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  cliente.telefono ?? 'Sin teléfono',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                if (cliente.email != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.email, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      cliente.email!,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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
                ChipSimple(
                  label: cliente.isActive ? 'Activo' : 'Inactivo',
                  color: cliente.isActive ? Colors.green : Colors.grey,
                ),
                if (cliente.yaExistiaEnSistema)
                  ChipSimple(label: 'Existente', color: Colors.orange),
                if (cliente.distrito != null && cliente.distrito!.isNotEmpty)
                  ChipSimple(label: cliente.distrito!, color: AppColors.blue),
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
