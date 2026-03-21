import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
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
      appBar: SmartAppBar(
        title: proveedor.nombre,
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.push(
                '/empresa/proveedores/${proveedor.id}/editar',
                extra: proveedor,
              );
            },
          ),
        ],
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Header card
              _buildHeaderCard(),
              const SizedBox(height: 12),

              // Info general
              _buildSection(
                'Informacion General',
                Icons.business,
                children: [
                  _buildInfoRow('Nombre Comercial', proveedor.nombreComercial),
                  _buildInfoRow('Documento', '${proveedor.tipoDocumento.toString().split('.').last} - ${proveedor.numeroDocumento}'),
                  _buildInfoRow('Email', proveedor.email),
                  _buildInfoRow('Telefono', proveedor.telefono),
                  _buildInfoRow('Tel. Alternativo', proveedor.telefonoAlternativo),
                  _buildInfoRow('Sitio Web', proveedor.sitioWeb),
                ],
              ),
              const SizedBox(height: 12),

              // Dirección
              _buildSection(
                'Direccion',
                Icons.location_on,
                children: [
                  _buildInfoRow('Direccion', proveedor.direccion),
                  _buildInfoRow('Ciudad', proveedor.ciudad),
                  _buildInfoRow('Provincia', proveedor.provincia),
                  _buildInfoRow('Pais', proveedor.pais),
                ],
              ),
              const SizedBox(height: 12),

              // Términos comerciales
              _buildSection(
                'Terminos Comerciales',
                Icons.handshake,
                children: [
                  _buildInfoRow('Terminos de Pago', proveedor.terminosPagoTexto),
                  if (proveedor.limiteCredito != null)
                    _buildInfoRow('Limite de Credito', 'S/ ${proveedor.limiteCredito!.toStringAsFixed(2)}'),
                  if (proveedor.descuentoPreferencial != null)
                    _buildInfoRow('Descuento Preferencial', '${proveedor.descuentoPreferencial}%'),
                  if (proveedor.diasCredito != null)
                    _buildInfoRow('Dias de Credito', '${proveedor.diasCredito} dias'),
                ],
              ),
              const SizedBox(height: 12),

              // Contacto principal
              if (proveedor.contactoPrincipal != null && proveedor.contactoPrincipal!.isNotEmpty)
                ...[
                  _buildSection(
                    'Contacto Principal',
                    Icons.person,
                    children: [
                      _buildInfoRow('Nombre', proveedor.contactoPrincipal),
                      _buildInfoRow('Cargo', proveedor.cargoContacto),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

              // Cuentas bancarias
              _buildBancosSection(context),
              const SizedBox(height: 12),

              // Notas
              if (proveedor.notas != null && proveedor.notas!.isNotEmpty)
                _buildSection(
                  'Notas',
                  Icons.note,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        proveedor.notas!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.blue1.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  proveedor.iniciales,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blue1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSubtitle(proveedor.nombre, fontSize: 14),
                  const SizedBox(height: 2),
                  Text(
                    proveedor.codigo,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  if (proveedor.numeroDocumento.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: proveedor.numeroDocumento));
                      },
                      child: Row(
                        children: [
                          Text(
                            proveedor.numeroDocumento,
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.copy, size: 12, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (proveedor.calificacion != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.amber[700]),
                    const SizedBox(width: 4),
                    Text(
                      '${proveedor.calificacion}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.amber[800]),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, {required List<Widget> children}) {
    // Filtrar widgets vacíos
    final validChildren = children.where((w) {
      if (w is SizedBox) return w.height != 0;
      return true;
    }).toList();
    if (validChildren.isEmpty) return const SizedBox.shrink();

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.blue1),
                const SizedBox(width: 6),
                AppSubtitle(title, fontSize: 13, color: AppColors.blue1),
              ],
            ),
            const SizedBox(height: 10),
            ...validChildren,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox(height: 0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBancosSection(BuildContext context) {
    final bancos = proveedor.bancos ?? [];

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance, size: 16, color: AppColors.blue1),
                const SizedBox(width: 6),
                AppSubtitle('Cuentas Bancarias (${bancos.length})', fontSize: 13, color: AppColors.blue1),
              ],
            ),
            if (bancos.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...bancos.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.blue1.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.account_balance, size: 16, color: AppColors.blue1),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.nombreBanco, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text('${b.tipoCuentaTexto} - ${b.numeroCuentaOculto}',
                              style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(b.moneda,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.green[700])),
                    ),
                  ],
                ),
              )),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await context.push(
                    '/empresa/proveedores/${proveedor.id}/bancos',
                    extra: {'nombre': proveedor.nombre},
                  );
                },
                icon: const Icon(Icons.account_balance, size: 14),
                label: const Text('Gestionar cuentas', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blue1,
                  side: const BorderSide(color: AppColors.blue1),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
