import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/pedido_marketplace.dart';
import '../../domain/usecases/get_pedido_detalle_usecase.dart';
import '../bloc/pedido_action_cubit.dart';
import '../widgets/comprobante_upload_widget.dart';

class PedidoDetailPage extends StatefulWidget {
  final String pedidoId;

  const PedidoDetailPage({super.key, required this.pedidoId});

  @override
  State<PedidoDetailPage> createState() => _PedidoDetailPageState();
}

class _PedidoDetailPageState extends State<PedidoDetailPage> {
  PedidoMarketplace? _pedido;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetalle();
  }

  Future<void> _loadDetalle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await locator<GetPedidoDetalleUseCase>()(widget.pedidoId);

    if (!mounted) return;

    if (result is Success<PedidoMarketplace>) {
      setState(() {
        _pedido = result.data;
        _isLoading = false;
      });
    } else if (result is Error<PedidoMarketplace>) {
      setState(() {
        _error = result.message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<PedidoActionCubit>(),
      child: GradientBackground(
        style: GradientStyle.minimal,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const SmartAppBar(title: 'Detalle del Pedido'),
          body: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.red),
            const SizedBox(height: 12),
            AppText(_error!, size: 14, color: AppColors.textSecondary, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _loadDetalle,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final pedido = _pedido!;

    return BlocListener<PedidoActionCubit, PedidoActionState>(
      listener: (context, state) {
        if (state is PedidoActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.green,
            ),
          );
          _loadDetalle(); // Recargar detalle despues de accion
        } else if (state is PedidoActionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.red,
            ),
          );
        }
      },
      child: RefreshIndicator(
        onRefresh: _loadDetalle,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === CABECERA: Empresa + Estado ===
              _buildHeader(pedido),
              const SizedBox(height: 16),

              // === INFO DEL PEDIDO ===
              _buildInfoSection(pedido),
              const SizedBox(height: 16),

              // === ITEMS ===
              _buildItemsSection(pedido),
              const SizedBox(height: 16),

              // === TOTALES ===
              _buildTotalsSection(pedido),
              const SizedBox(height: 16),

              // === MOTIVO DE RECHAZO ===
              if (pedido.estado == EstadoPedidoMarketplace.pagoRechazado &&
                  pedido.motivoRechazo != null) ...[
                _buildRechazoSection(pedido),
                const SizedBox(height: 16),
              ],

              // === COMPROBANTE EXISTENTE ===
              if (pedido.comprobantePagoUrl != null &&
                  pedido.comprobantePagoUrl!.isNotEmpty) ...[
                _buildComprobanteSection(pedido),
                const SizedBox(height: 16),
              ],

              // === ACCIONES ===
              _buildActions(pedido),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(PedidoMarketplace pedido) {
    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (pedido.empresa.logo != null && pedido.empresa.logo!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                pedido.empresa.logo!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildEmpresaPlaceholder(48),
              ),
            )
          else
            _buildEmpresaPlaceholder(48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  pedido.empresa.nombre,
                  fontWeight: FontWeight.w600,
                  size: 15,
                ),
                const SizedBox(height: 2),
                AppText(
                  pedido.codigo,
                  size: 13,
                  color: AppColors.blue1,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: pedido.estadoColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: AppText(
              pedido.estadoLabel,
              size: 11,
              fontWeight: FontWeight.w600,
              color: pedido.estadoColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(PedidoMarketplace pedido) {
    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSubtitle('Informacion del Pedido', fontSize: 14),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.person_outline, 'Comprador', pedido.nombreComprador),
          _buildInfoRow(Icons.email_outlined, 'Email', pedido.emailComprador),
          if (pedido.telefonoComprador != null)
            _buildInfoRow(Icons.phone_outlined, 'Telefono', pedido.telefonoComprador!),
          _buildInfoRow(Icons.location_on_outlined, 'Direccion', pedido.direccionEnvio),
          _buildInfoRow(Icons.payment_outlined, 'Metodo de pago', pedido.metodoPago),
          _buildInfoRow(Icons.calendar_today_outlined, 'Fecha', _formatDate(pedido.creadoEn)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.blue1),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: AppText(label, size: 12, color: AppColors.textSecondary),
          ),
          Expanded(
            child: AppText(value, size: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(PedidoMarketplace pedido) {
    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSubtitle(
            'Productos (${pedido.detalles.length})',
            fontSize: 14,
          ),
          const SizedBox(height: 12),
          ...pedido.detalles.map((detalle) => _buildDetalleItem(detalle)),
        ],
      ),
    );
  }

  Widget _buildDetalleItem(PedidoDetalle detalle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del producto
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: detalle.imagenUrl != null && detalle.imagenUrl!.isNotEmpty
                ? Image.network(
                    detalle.imagenUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildProductoPlaceholder(),
                  )
                : _buildProductoPlaceholder(),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  detalle.descripcion,
                  size: 13,
                  fontWeight: FontWeight.w500,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                AppText(
                  'Cant: ${detalle.cantidad} x S/ ${detalle.precioUnitario.toStringAsFixed(2)}',
                  size: 11,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          // Subtotal
          AppText(
            'S/ ${detalle.subtotal.toStringAsFixed(2)}',
            size: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.blue1,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsSection(PedidoMarketplace pedido) {
    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText('Subtotal', size: 13, color: AppColors.textSecondary),
              AppText(
                'S/ ${pedido.subtotal.toStringAsFixed(2)}',
                size: 13,
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppSubtitle('Total', fontSize: 16),
              AppSubtitle(
                'S/ ${pedido.total.toStringAsFixed(2)}',
                fontSize: 18,
                color: AppColors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRechazoSection(PedidoMarketplace pedido) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.red),
              SizedBox(width: 8),
              AppText(
                'Motivo de rechazo',
                size: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.red,
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppText(
            pedido.motivoRechazo!,
            size: 13,
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildComprobanteSection(PedidoMarketplace pedido) {
    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSubtitle('Comprobante de Pago', fontSize: 14),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              pedido.comprobantePagoUrl!,
              width: double.infinity,
              height: 250,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                height: 100,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.greyLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_outlined, size: 32, color: AppColors.grey),
                    SizedBox(height: 8),
                    AppText('No se pudo cargar la imagen', size: 12, color: AppColors.grey),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(PedidoMarketplace pedido) {
    return BlocBuilder<PedidoActionCubit, PedidoActionState>(
      builder: (context, actionState) {
        final isActionLoading = actionState is PedidoActionLoading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Subir comprobante
            if (pedido.puedeSubirComprobante) ...[
              ComprobanteUploadWidget(
                pedidoId: pedido.id,
                isLoading: isActionLoading,
              ),
              const SizedBox(height: 12),
            ],

            // Cancelar pedido
            if (pedido.puedeCancelar) ...[
              CustomButton(
                text: 'Cancelar Pedido',
                onPressed: isActionLoading
                    ? null
                    : () => _showConfirmDialog(
                          context,
                          title: 'Cancelar pedido',
                          message: 'Esta seguro de cancelar este pedido? Esta accion no se puede deshacer.',
                          onConfirm: () {
                            context
                                .read<PedidoActionCubit>()
                                .cancelarPedido(pedido.id);
                          },
                        ),
                isLoading: isActionLoading,
                height: 48,
                borderRadius: 14,
                backgroundColor: AppColors.red,
                icon: const Icon(Icons.cancel_outlined, color: AppColors.white, size: 20),
              ),
              const SizedBox(height: 12),
            ],

            // Confirmar recepcion
            if (pedido.puedeConfirmarRecepcion) ...[
              CustomButton(
                text: 'Confirmar Recepcion',
                onPressed: isActionLoading
                    ? null
                    : () => _showConfirmDialog(
                          context,
                          title: 'Confirmar recepcion',
                          message: 'Confirma que recibio el pedido correctamente?',
                          onConfirm: () {
                            context
                                .read<PedidoActionCubit>()
                                .confirmarRecepcion(pedido.id);
                          },
                        ),
                isLoading: isActionLoading,
                height: 48,
                borderRadius: 14,
                icon: const Icon(Icons.check_circle_outline, color: AppColors.white, size: 20),
              ),
            ],
          ],
        );
      },
    );
  }

  void _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: AppSubtitle(title, fontSize: 16),
        content: AppText(message, size: 14),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            child: const Text('Si, confirmar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpresaPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.blue1.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.store, size: size * 0.5, color: AppColors.blue1),
    );
  }

  Widget _buildProductoPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.greyLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_outlined, size: 24, color: AppColors.grey),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
