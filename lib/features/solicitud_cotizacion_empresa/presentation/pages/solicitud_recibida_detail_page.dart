import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../domain/entities/solicitud_empresa.dart';
import '../bloc/solicitud_empresa_action_cubit.dart';

class SolicitudRecibidaDetailPage extends StatelessWidget {
  final String solicitudId;
  const SolicitudRecibidaDetailPage({super.key, required this.solicitudId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<SolicitudEmpresaActionCubit>()..loadDetalle(solicitudId),
      child: _DetailView(solicitudId: solicitudId),
    );
  }
}

class _DetailView extends StatelessWidget {
  final String solicitudId;
  const _DetailView({required this.solicitudId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SolicitudEmpresaActionCubit, SolicitudEmpresaActionState>(
      listener: (context, state) {
        if (state is SolicitudEmpresaActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.green),
          );
          context.read<SolicitudEmpresaActionCubit>().loadDetalle(solicitudId);
        }
        if (state is SolicitudEmpresaActionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        final sol = state is SolicitudEmpresaDetailLoaded ? state.solicitud : null;
        final isLoading = state is SolicitudEmpresaActionLoading;

        return Scaffold(
          appBar: SmartAppBar(
            title: sol?.codigo ?? 'Solicitud',
            backgroundColor: AppColors.blue1, foregroundColor: Colors.white,
          ),
          body: GradientBackground(
            child: isLoading && sol == null
                ? const Center(child: CircularProgressIndicator())
                : sol == null
                    ? const Center(child: Text('Error al cargar'))
                    : _buildContent(context, sol),
          ),
          bottomNavigationBar: sol != null ? _buildActions(context, sol, isLoading) : null,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, SolicitudRecibida sol) {
    final estado = sol.estado;
    final items = sol.items;
    final creadoEn = sol.creadoEn;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        GradientContainer(
          borderColor: AppColors.blueborder,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.request_quote, color: AppColors.blue1, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: AppSubtitle(sol.codigo ?? '', fontSize: 15)),
                    _buildEstadoChip(estado),
                  ],
                ),
                if (creadoEn != null) ...[
                  const SizedBox(height: 8),
                  Text(DateFormatter.formatDateTime(creadoEn),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Solicitante
        GradientContainer(
          borderColor: AppColors.blueborder,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSubtitle('SOLICITANTE', fontSize: 11, color: AppColors.blue1),
                const SizedBox(height: 8),
                _infoRow(Icons.person_outline, sol.nombreSolicitante ?? ''),
                if (sol.emailSolicitante != null) _infoRow(Icons.email_outlined, sol.emailSolicitante!),
                if (sol.telefonoSolicitante != null) _infoRow(Icons.phone_outlined, sol.telefonoSolicitante!),
                if (sol.solicitante?.dni != null) _infoRow(Icons.badge_outlined, 'DNI: ${sol.solicitante!.dni}'),
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
                AppSubtitle('ITEMS SOLICITADOS (${items.length})', fontSize: 11, color: AppColors.blue1),
                const SizedBox(height: 8),
                ...items.map((item) => _buildItemRow(item)),
              ],
            ),
          ),
        ),

        // Observaciones
        if (sol.observaciones != null) ...[
          const SizedBox(height: 12),
          GradientContainer(
            borderColor: AppColors.blueborder,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSubtitle('OBSERVACIONES DEL CLIENTE', fontSize: 11, color: AppColors.blue1),
                  const SizedBox(height: 8),
                  Text(sol.observaciones!, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                ],
              ),
            ),
          ),
        ],

        // Respuesta vendedor
        if (sol.respuestaVendedor != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: estado == 'RECHAZADA' ? Colors.red.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: estado == 'RECHAZADA' ? Colors.red.shade200 : Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(estado == 'RECHAZADA' ? 'Motivo del rechazo:' : 'Respuesta:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: estado == 'RECHAZADA' ? Colors.red : Colors.blue)),
                const SizedBox(height: 4),
                Text(sol.respuestaVendedor!, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildItemRow(SolicitudItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (item.imagenUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(item.imagenUrl!, width: 40, height: 40, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(width: 40, height: 40, color: Colors.grey.shade200,
                  child: const Icon(Icons.image, size: 16, color: Colors.grey))),
            ),
            const SizedBox(width: 10),
          ] else ...[
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: item.esManual ? Colors.orange.shade50 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(item.esManual ? Icons.edit : Icons.inventory_2, size: 18,
                color: item.esManual ? Colors.orange : Colors.grey),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: AppSubtitle(item.descripcion, fontSize: 12)),
                    if (item.esManual)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4)),
                        child: Text('Manual', style: TextStyle(fontSize: 9, color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
                Text('Cantidad: ${item.cantidad}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                if (item.notasItem != null && item.notasItem!.isNotEmpty)
                  Text('Nota: ${item.notasItem}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildActions(BuildContext context, SolicitudRecibida sol, bool isLoading) {
    if (!sol.permiteAcciones) return null;

    final cubit = context.read<SolicitudEmpresaActionCubit>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))]),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : () => _showRechazoDialog(context, cubit),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Rechazar'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : () {
                context.push('/empresa/cotizaciones/nueva', extra: {
                  'solicitudId': solicitudId,
                  'items': sol.items.map((i) => {
                    'descripcion': i.descripcion,
                    'cantidad': i.cantidad,
                    'esManual': i.esManual,
                    if (i.imagenUrl != null) 'imagenUrl': i.imagenUrl,
                    if (i.notasItem != null) 'notasItem': i.notasItem,
                  }).toList(),
                  'nombreCliente': sol.nombreSolicitante,
                });
              },
              icon: const Icon(Icons.receipt_long, size: 18),
              label: const Text('Crear Cotizacion'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue1, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ),
        ],
      ),
    );
  }

  void _showRechazoDialog(BuildContext context, SolicitudEmpresaActionCubit cubit) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar solicitud', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Motivo del rechazo', border: OutlineInputBorder()), maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              cubit.rechazar(solicitudId, controller.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildEstadoChip(String estado) {
    Color color;
    String label;
    switch (estado) {
      case 'PENDIENTE': color = Colors.orange; label = 'Pendiente'; break;
      case 'EN_REVISION': color = Colors.blue; label = 'En revision'; break;
      case 'COTIZADA': color = Colors.green; label = 'Cotizada'; break;
      case 'RECHAZADA': color = Colors.red; label = 'Rechazada'; break;
      case 'CANCELADA': color = Colors.grey; label = 'Cancelada'; break;
      default: color = Colors.grey; label = estado;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
