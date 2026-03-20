import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../bloc/pedido_empresa_action_cubit.dart';

class PedidoMarketplaceDetailEmpresaPage extends StatelessWidget {
  final String pedidoId;
  const PedidoMarketplaceDetailEmpresaPage({super.key, required this.pedidoId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<PedidoEmpresaActionCubit>()..loadDetalle(pedidoId),
      child: _DetailView(pedidoId: pedidoId),
    );
  }
}

class _DetailView extends StatelessWidget {
  final String pedidoId;
  const _DetailView({required this.pedidoId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PedidoEmpresaActionCubit, PedidoEmpresaActionState>(
      listener: (context, state) {
        if (state is PedidoEmpresaActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.green),
          );
          context.read<PedidoEmpresaActionCubit>().loadDetalle(pedidoId);
        }
        if (state is PedidoEmpresaActionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        final pedido = state is PedidoEmpresaDetailLoaded ? state.pedido : null;
        final isLoading = state is PedidoEmpresaActionLoading;

        return Scaffold(
          appBar: SmartAppBar(
            title: pedido?['codigo'] ?? 'Pedido',
            backgroundColor: AppColors.blue1,
            foregroundColor: Colors.white,
          ),
          body: GradientBackground(
            child: isLoading && pedido == null
                ? const Center(child: CircularProgressIndicator())
                : pedido == null
                    ? const Center(child: Text('Error al cargar'))
                    : _buildContent(context, pedido),
          ),
          bottomNavigationBar: pedido != null ? _buildActions(context, pedido, isLoading) : null,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> p) {
    final estado = p['estado'] as String? ?? '';
    final detalles = p['detalles'] as List<dynamic>? ?? [];
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final creadoEn = p['creadoEn'] != null ? DateTime.tryParse(p['creadoEn'].toString()) : null;
    final comprobante = p['comprobantePagoUrl'] as String?;

    return RefreshIndicator(
      onRefresh: () => context.read<PedidoEmpresaActionCubit>().loadDetalle(pedidoId),
      color: AppColors.blue1,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Estado
          GradientContainer(
            borderColor: AppColors.blueborder,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: AppColors.blue1, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: AppSubtitle(p['codigo'] ?? '', fontSize: 15)),
                  _buildEstadoChip(estado),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Comprador + Dirección
          GradientContainer(
            borderColor: AppColors.blueborder,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSubtitle('COMPRADOR', fontSize: 11, color: AppColors.blue1),
                  const SizedBox(height: 8),
                  _infoRow(Icons.person_outline, 'Nombre', p['nombreComprador'] ?? ''),
                  if (p['emailComprador'] != null) _infoRow(Icons.email_outlined, 'Email', p['emailComprador']),
                  if (p['telefonoComprador'] != null) _infoRow(Icons.phone_outlined, 'Teléfono', p['telefonoComprador']),
                  if (creadoEn != null) _infoRow(Icons.calendar_today, 'Fecha', dateFormat.format(creadoEn)),
                  if (p['direccionEnvio'] != null) ...[
                    const Divider(height: 16),
                    const AppSubtitle('DIRECCIÓN DE ENVÍO', fontSize: 11, color: AppColors.blue1),
                    const SizedBox(height: 8),
                    _infoRow(Icons.location_on_outlined, 'Dirección', p['direccionEnvio']),
                    if (p['referenciaEnvio'] != null) _infoRow(Icons.near_me, 'Referencia', p['referenciaEnvio']),
                    if (p['distritoEnvio'] != null || p['provinciaEnvio'] != null || p['departamentoEnvio'] != null)
                      _infoRow(Icons.map_outlined, 'Ubicación',
                        [p['distritoEnvio'], p['provinciaEnvio'], p['departamentoEnvio']]
                          .where((e) => e != null && e.toString().isNotEmpty).join(', ')),
                    if (p['coordenadasEnvio'] != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final coords = p['coordenadasEnvio'] as Map<String, dynamic>?;
                            if (coords == null) return;
                            final lat = coords['lat'];
                            final lng = coords['lng'] ?? coords['lon'];
                            if (lat != null && lng != null) {
                              launchUrl(Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'), mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.directions, size: 18),
                          label: const Text('Ver en mapa / Cómo llegar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green.shade700,
                            side: BorderSide(color: Colors.green.shade400),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Items
          GradientContainer(
            borderColor: AppColors.blueborder,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSubtitle('ITEMS (${detalles.length})', fontSize: 11, color: AppColors.blue1),
                  const SizedBox(height: 8),
                  ...detalles.map((d) {
                    final det = d as Map<String, dynamic>;
                    final cantidad = det['cantidad'] as int? ?? 1;
                    final precio = double.tryParse(det['precioUnitario']?.toString() ?? '') ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          if (det['imagenUrl'] != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(det['imagenUrl'], width: 40, height: 40, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox(width: 40, height: 40)),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(child: AppSubtitle(det['descripcion'] ?? '', fontSize: 12)),
                          Text('$cantidad x S/${precio.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const AppSubtitle('Total', fontSize: 14),
                      AppSubtitle('S/ ${double.tryParse(p['total']?.toString() ?? '')?.toStringAsFixed(2) ?? '0.00'}',
                        fontSize: 16, color: AppColors.blue1),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Comprobante
          if (comprobante != null)
            GradientContainer(
              borderColor: AppColors.blueborder,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppSubtitle('COMPROBANTE DE PAGO', fontSize: 11, color: AppColors.blue1),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.payment, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text('Método: ${p['metodoPago'] ?? 'No especificado'}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(comprobante, width: double.infinity, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(height: 100, color: Colors.grey.shade200,
                          child: const Center(child: Text('Error al cargar imagen')))),
                    ),
                  ],
                ),
              ),
            ),

          if (p['motivoRechazo'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Motivo rechazo: ${p['motivoRechazo']}', style: const TextStyle(fontSize: 12, color: Colors.red))),
                ],
              ),
            ),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget? _buildActions(BuildContext context, Map<String, dynamic> p, bool isLoading) {
    final estado = p['estado'] as String? ?? '';
    final actions = <Widget>[];
    final cubit = context.read<PedidoEmpresaActionCubit>();

    if (estado == 'PAGO_ENVIADO') {
      actions.add(Expanded(
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : () => _showRechazoDialog(context, cubit),
          icon: const Icon(Icons.close, size: 18),
          label: const Text('Rechazar'),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
      ));
      actions.add(const SizedBox(width: 12));
      actions.add(Expanded(
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : () => cubit.aprobarPago(pedidoId),
          icon: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check, size: 18),
          label: const Text('Aprobar Pago'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
      ));
    } else if (estado == 'PAGO_VALIDADO') {
      actions.add(Expanded(
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : () => cubit.cambiarEstado(pedidoId, 'EN_PREPARACION'),
          icon: const Icon(Icons.inventory, size: 18),
          label: const Text('En Preparación'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue1, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
      ));
    } else if (estado == 'EN_PREPARACION') {
      actions.add(Expanded(
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : () => _showEnvioDialog(context, cubit),
          icon: const Icon(Icons.local_shipping, size: 18),
          label: const Text('Marcar Enviado'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
      ));
    }

    if (actions.isEmpty) return null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))]),
      child: Row(children: actions),
    );
  }

  void _showRechazoDialog(BuildContext context, PedidoEmpresaActionCubit cubit) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar pago', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Motivo del rechazo', border: OutlineInputBorder()), maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              cubit.rechazarPago(pedidoId, controller.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  void _showEnvioDialog(BuildContext context, PedidoEmpresaActionCubit cubit) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar como enviado', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Código de seguimiento (opcional)', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              cubit.cambiarEstado(pedidoId, 'ENVIADO', codigoSeguimiento: controller.text.trim().isEmpty ? null : controller.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            child: const Text('Confirmar Envío'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          SizedBox(width: 70, child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildEstadoChip(String estado) {
    Color color;
    String label;
    switch (estado) {
      case 'PENDIENTE_PAGO': color = Colors.grey; label = 'Pendiente pago'; break;
      case 'PAGO_ENVIADO': color = Colors.orange; label = 'Pago enviado'; break;
      case 'PAGO_VALIDADO': color = Colors.blue; label = 'Pago validado'; break;
      case 'EN_PREPARACION': color = Colors.indigo; label = 'En preparación'; break;
      case 'ENVIADO': color = Colors.teal; label = 'Enviado'; break;
      case 'ENTREGADO': color = Colors.green; label = 'Entregado'; break;
      case 'CANCELADO': case 'PAGO_RECHAZADO': color = Colors.red; label = estado == 'CANCELADO' ? 'Cancelado' : 'Pago rechazado'; break;
      default: color = Colors.grey; label = estado;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
