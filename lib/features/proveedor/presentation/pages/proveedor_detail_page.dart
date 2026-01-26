import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/proveedor.dart';

class ProveedorDetailPage extends StatelessWidget {
  final String empresaId;
  final Proveedor proveedor;

  const ProveedorDetailPage({
    super.key,
    required this.empresaId,
    required this.proveedor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(proveedor.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.push(
                '/empresa/$empresaId/proveedores/${proveedor.id}/editar',
                extra: proveedor,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con calificación
            Container(
              color: Colors.blue.shade50,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      proveedor.iniciales,
                      style: TextStyle(
                        fontSize: 32,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    proveedor.codigo,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  if (proveedor.calificacion != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${proveedor.calificacion}/5',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            _buildSection(
              'Información General',
              [
                _buildInfoTile('Nombre Comercial', proveedor.nombreComercial),
                _buildInfoTile(
                  'Documento',
                  '${proveedor.tipoDocumento.toString().split('.').last} - ${proveedor.numeroDocumento}',
                ),
                _buildInfoTile('Email', proveedor.email),
                _buildInfoTile('Teléfono', proveedor.telefono),
                _buildInfoTile('Sitio Web', proveedor.sitioWeb),
              ],
            ),
            _buildSection(
              'Dirección',
              [
                _buildInfoTile('Dirección', proveedor.direccion),
                _buildInfoTile('Ciudad', proveedor.ciudad),
                _buildInfoTile('Provincia', proveedor.provincia),
                _buildInfoTile('País', proveedor.pais),
              ],
            ),
            _buildSection(
              'Términos Comerciales',
              [
                _buildInfoTile('Términos de Pago', proveedor.terminosPagoTexto),
                if (proveedor.limiteCredito != null)
                  _buildInfoTile(
                    'Límite de Crédito',
                    'S/ ${proveedor.limiteCredito!.toStringAsFixed(2)}',
                  ),
                if (proveedor.descuentoPreferencial != null)
                  _buildInfoTile(
                    'Descuento Preferencial',
                    '${proveedor.descuentoPreferencial}%',
                  ),
              ],
            ),
            if (proveedor.contactos != null && proveedor.contactos!.isNotEmpty)
              _buildSection(
                'Contactos (${proveedor.contactos!.length})',
                proveedor.contactos!
                    .map((c) => ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(c.nombre),
                          subtitle: Text(c.cargo ?? 'Sin cargo'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (c.telefono != null) Text(c.telefono!),
                              if (c.email != null)
                                Text(
                                  c.email!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            if (proveedor.bancos != null && proveedor.bancos!.isNotEmpty)
              _buildSection(
                'Cuentas Bancarias (${proveedor.bancos!.length})',
                proveedor.bancos!
                    .map((b) => ListTile(
                          leading: const Icon(Icons.account_balance),
                          title: Text(b.nombreBanco),
                          subtitle: Text(
                            '${b.tipoCuentaTexto} - ${b.numeroCuentaOculto}',
                          ),
                          trailing: Text(
                            b.moneda,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ))
                    .toList(),
              ),
            if (proveedor.notas != null && proveedor.notas!.isNotEmpty)
              _buildSection(
                'Notas',
                [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(proveedor.notas!),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  Widget _buildInfoTile(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return ListTile(
      dense: true,
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
