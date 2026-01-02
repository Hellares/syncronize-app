import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: usuario.isActive ? Colors.blue : Colors.grey,
          child: Text(
            usuario.iniciales,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(
          usuario.nombreCompleto,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(usuario.rolFormateado),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.phone,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  usuario.telefono ?? '-',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (usuario.email != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.email,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      usuario.email!,
                      style: TextStyle(
                        fontSize: 12,
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
                _buildBadge(
                  usuario.estadoFormateado,
                  usuario.isActive ? Colors.green : Colors.grey,
                ),
                if (usuario.tieneSedes)
                  _buildBadge(
                    '${usuario.sedesActivas} ${usuario.sedesActivas == 1 ? 'sede' : 'sedes'}',
                    Colors.blue,
                  ),
                if (usuario.puedeAbrirCaja)
                  _buildBadge('Abre caja', Colors.orange),
                if (usuario.puedeCerrarCaja)
                  _buildBadge('Cierra caja', Colors.purple),
                if (usuario.requiereCambioPassword)
                  _buildBadge('Cambiar contraseña', Colors.red),
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

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.withOpacity(0.9),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
