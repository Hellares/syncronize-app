import 'package:cached_network_image/cached_network_image.dart';
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
import '../widgets/pagar_yape_sheet.dart';

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
      // Contenido scrolleable + barra de ACCIONES FIJA abajo (no scrollea).
      child: Column(
        children: [
          Expanded(
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
                    const SizedBox(height: 10),

                    // === TIMELINE DE ESTADO ===
                    _buildTimelineSection(pedido),
                    const SizedBox(height: 10),

                    // === INFO DEL PEDIDO ===
                    _buildInfoSection(pedido),
                    const SizedBox(height: 10),

                    // === ITEMS ===
                    _buildItemsSection(pedido),
                    const SizedBox(height: 5),

                    // === TOTALES ===
                    _buildTotalsSection(pedido),
                    const SizedBox(height: 10),

                    // === MOTIVO DE RECHAZO ===
                    if (pedido.estado ==
                            EstadoPedidoMarketplace.pagoRechazado &&
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
                  ],
                ),
              ),
            ),
          ),

          // === ACCIONES (fijas al fondo) ===
          _buildBottomActionsBar(pedido),
        ],
      ),
    );
  }

  /// Barra fija inferior con las acciones del pedido. Fuera del scroll para
  /// que "Confirmar Recepción" (y pagar/cancelar) estén siempre a la vista.
  /// Se oculta cuando el pedido no tiene acciones disponibles.
  Widget _buildBottomActionsBar(PedidoMarketplace pedido) {
    final hayAcciones = pedido.puedeSubirComprobante ||
        pedido.puedeCancelar ||
        pedido.puedeConfirmarRecepcion;
    if (!hayAcciones) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      // Bottom bar custom → SafeArea(top:false) manual.
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: _buildActions(pedido),
        ),
      ),
    );
  }

  Widget _buildHeader(PedidoMarketplace pedido) {
    return GradientContainer(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          if (pedido.empresa.logo != null && pedido.empresa.logo!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: pedido.empresa.logo!,
                width: 30,
                height: 30,
                fit: BoxFit.cover,
                placeholder: (_, __) => _buildEmpresaPlaceholder(30),
                errorWidget: (_, __, ___) => _buildEmpresaPlaceholder(30),
              ),
            )
          else
            _buildEmpresaPlaceholder(30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  pedido.empresa.nombre,
                  fontWeight: FontWeight.w600,
                  size: 11,
                ),
                const SizedBox(height: 2),
                AppText(
                  pedido.codigo,
                  size: 10,
                  color: AppColors.blue1,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: pedido.estadoColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: AppText(
              pedido.estadoLabel,
              size: 10,
              fontWeight: FontWeight.w600,
              color: pedido.estadoColor,
            ),
          ),
        ],
      ),
    );
  }

  // === TIMELINE DE ESTADO ===
  // Tracking por pasos (estilo marketplace): completados, actual y
  // pendientes según el estado del pedido. CANCELADO corta el flujo con
  // un paso terminal rojo.

  /// Índice del último paso COMPLETADO (−1 = ninguno).
  int _pasoCompletado(PedidoMarketplace p) {
    switch (p.estado) {
      case EstadoPedidoMarketplace.pendientePago:
      case EstadoPedidoMarketplace.pagoEnviado:
      case EstadoPedidoMarketplace.pagoRechazado:
        return 0; // Solo "Pedido realizado".
      case EstadoPedidoMarketplace.pagoValidado:
        return 1;
      case EstadoPedidoMarketplace.enPreparacion:
        return 2;
      case EstadoPedidoMarketplace.enviado:
        return 3;
      case EstadoPedidoMarketplace.entregado:
        return 4;
      case EstadoPedidoMarketplace.cancelado:
        return 0;
    }
  }

  Widget _buildTimelineSection(PedidoMarketplace pedido) {
    final cancelado = pedido.estado == EstadoPedidoMarketplace.cancelado;
    final rechazado = pedido.estado == EstadoPedidoMarketplace.pagoRechazado;
    final pagoEnviado = pedido.estado == EstadoPedidoMarketplace.pagoEnviado;
    final completado = _pasoCompletado(pedido);

    // Fecha por hito: preparación no se persiste → usa la misma del pago
    // validado (la tienda pasa a preparar apenas valida). Solo se muestra
    // cuando el paso ya se alcanzó (ver gate abajo).
    final fechaPreparacion = pedido.pagoValidadoEn;

    // (título, ícono, subtítulo cuando es el paso ACTIVO, fecha del hito)
    final pasos = <(String, IconData, String, DateTime?)>[
      ('Pedido realizado', Icons.shopping_bag_outlined, '', pedido.creadoEn),
      (
        pedido.esContraentrega ? 'Pedido confirmado' : 'Pago validado',
        Icons.verified_outlined,
        rechazado
            ? 'Pago rechazado — revisa el motivo abajo'
            : pagoEnviado
                ? 'Comprobante en revisión por la tienda'
                : pedido.esContraentrega
                    ? 'Pagarás al recibir tu pedido'
                    : 'Esperando tu pago',
        pedido.pagoValidadoEn,
      ),
      ('En preparación', Icons.inventory_2_outlined,
          'La tienda está preparando tu pedido', fechaPreparacion),
      ('Enviado', Icons.local_shipping_outlined,
          'Tu pedido está en camino', pedido.enviadoEn),
      ('Entregado', Icons.home_outlined, '¡Pedido completado!',
          pedido.entregadoEn),
    ];

    return GradientContainer(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSubtitle('Seguimiento', fontSize: 11),
          const SizedBox(height: 12),
          for (var i = 0; i < pasos.length; i++)
            _buildPasoTimeline(
              titulo: pasos[i].$1,
              icono: pasos[i].$2,
              // Subtítulo solo en el paso siguiente al completado (el activo).
              subtitulo: i == completado + 1 ? pasos[i].$3 : null,
              // Fecha solo en pasos ya alcanzados (un paso pendiente no
              // puede mostrar fecha aunque herede la del pago validado).
              fecha: i <= completado && pasos[i].$4 != null
                  ? _formatDate(pasos[i].$4!)
                  : null,
              hecho: i <= completado,
              activo: i == completado + 1 && !cancelado,
              error: (rechazado && i == 1),
              esUltimo: i == pasos.length - 1 && !cancelado,
              cortado: cancelado && i > 0,
            ),
          // Paso terminal de cancelación.
          if (cancelado)
            _buildPasoTimeline(
              titulo: 'Pedido cancelado',
              icono: Icons.cancel_outlined,
              subtitulo: pedido.motivoRechazo,
              fecha: pedido.actualizadoEn != null
                  ? _formatDate(pedido.actualizadoEn!)
                  : null,
              hecho: true,
              activo: false,
              error: true,
              esUltimo: true,
              cortado: false,
            ),
        ],
      ),
    );
  }

  Widget _buildPasoTimeline({
    required String titulo,
    required IconData icono,
    String? subtitulo,
    String? fecha,
    required bool hecho,
    required bool activo,
    required bool error,
    required bool esUltimo,
    required bool cortado,
  }) {
    final color = error
        ? AppColors.red
        : hecho
            ? AppColors.green
            : activo
                ? AppColors.blue1
                : Colors.grey.shade400;
    // Pasos que ya no ocurrirán (pedido cancelado) se atenúan.
    final opacidad = cortado ? 0.35 : 1.0;

    return Opacity(
      opacity: opacidad,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Columna izquierda: nodo + línea conectora.
            SizedBox(
              width: 26,
              child: Column(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hecho || error
                          ? color.withValues(alpha: error ? 0.12 : 1)
                          : Colors.white,
                      border: Border.all(
                        color: color,
                        width: activo ? 2 : 1.2,
                      ),
                    ),
                    child: Icon(
                      error
                          ? Icons.close
                          : hecho
                              ? Icons.check
                              : icono,
                      size: 12,
                      color: error
                          ? color
                          : hecho
                              ? Colors.white
                              : color,
                    ),
                  ),
                  if (!esUltimo)
                    Expanded(
                      child: Container(
                        width: 1.5,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: hecho
                            ? AppColors.green.withValues(alpha: 0.5)
                            : Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Contenido del paso.
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: esUltimo ? 0 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppText(
                            titulo,
                            size: 11,
                            fontWeight:
                                hecho || activo ? FontWeight.w600 : FontWeight.w400,
                            color: error
                                ? AppColors.red
                                : hecho || activo
                                    ? AppColors.textPrimary
                                    : Colors.grey.shade500,
                          ),
                        ),
                        if (fecha != null)
                          AppText(fecha, size: 10, color: AppColors.textSecondary),
                      ],
                    ),
                    if (subtitulo != null && subtitulo.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      AppText(
                        subtitulo,
                        size: 11,
                        color: error ? AppColors.red : AppColors.textSecondary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(PedidoMarketplace pedido) {
    return GradientContainer(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSubtitle('Informacion del Pedido', fontSize: 11),
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
            child: AppText(label, size: 10, color: AppColors.textSecondary),
          ),
          Expanded(
            child: AppText(value, size: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(PedidoMarketplace pedido) {
    return GradientContainer(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSubtitle(
            'Productos (${pedido.detalles.length})',
            fontSize: 11,
          ),
          const SizedBox(height: 8),
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
                ? CachedNetworkImage(
                    imageUrl: detalle.imagenUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _buildProductoPlaceholder(),
                    errorWidget: (_, __, ___) => _buildProductoPlaceholder(),
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
                  size: 10,
                  fontWeight: FontWeight.w400,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                AppText(
                  'Cant: ${detalle.cantidad} x S/ ${detalle.precioUnitario.toStringAsFixed(2)}',
                  size: 10,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          // Subtotal
          AppText(
            'S/ ${detalle.subtotal.toStringAsFixed(2)}',
            size: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.blue1,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsSection(PedidoMarketplace pedido) {
    return GradientContainer(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText('Subtotal', size: 11, color: AppColors.textSecondary),
              AppText(
                'S/ ${pedido.subtotal.toStringAsFixed(2)}',
                size: 11,
              ),
            ],
          ),
          const Divider(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppSubtitle('Total', fontSize: 12),
              AppSubtitle(
                'S/ ${pedido.total.toStringAsFixed(2)}',
                fontSize: 14,
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
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
                size: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.red,
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppText(
            pedido.motivoRechazo!,
            size: 10,
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildComprobanteSection(PedidoMarketplace pedido) {
    return GradientContainer(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSubtitle('Comprobante de Pago', fontSize: 11),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: pedido.comprobantePagoUrl!,
              width: double.infinity,
              height: 250,
              fit: BoxFit.contain,
              placeholder: (_, __) => Container(
                height: 100,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.greyLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, __, ___) => Container(
                height: 100,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.greyLight.withValues(alpha: 0.3),
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

  Future<void> _pagarConYape(PedidoMarketplace pedido) async {
    final pagado = await PagarYapeSheet.show(
      context,
      cobroPath: '/marketplace/mis-pedidos/${pedido.id}/cobro-yape',
      pollPath: '/marketplace/mis-pedidos/${pedido.id}',
      esPagado: (d) {
        final estado = d['estado'] as String?;
        const pendientes = ['PENDIENTE_PAGO', 'PAGO_ENVIADO', 'PAGO_RECHAZADO'];
        return estado != null && !pendientes.contains(estado);
      },
    );
    if (!mounted) return;
    if (pagado == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Pago confirmado! Tu pedido está en proceso.'),
          backgroundColor: Colors.green,
        ),
      );
      _loadDetalle();
    }
  }

  Widget _buildActions(PedidoMarketplace pedido) {
    return BlocBuilder<PedidoActionCubit, PedidoActionState>(
      builder: (context, actionState) {
        final isActionLoading = actionState is PedidoActionLoading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pagar con Yape automático (api-yape): QR + monto exacto +
            // confirmación automática. El botón SOLO aparece si la empresa
            // tiene el cobro automático disponible (gate del backend,
            // mismo criterio que Venta Rápida) — sin api-yape el comprador
            // ve únicamente el flujo manual de subir la captura.
            if (pedido.puedeSubirComprobante &&
                pedido.yapeAutomaticoDisponible) ...[
              CustomButton(
                text: 'Pagar con Yape',
                onPressed: isActionLoading ? null : () => _pagarConYape(pedido),
                height: 48,
                borderRadius: 14,
                backgroundColor: const Color(0xFF742284),
                icon: const Icon(Icons.qr_code_2_rounded, color: AppColors.white, size: 20),
              ),
              const SizedBox(height: 12),
            ],

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
                borderColor: AppColors.green,
                textColor: AppColors.green
                ,
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
        color: AppColors.blue1.withValues(alpha: 0.1),
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
        color: AppColors.greyLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_outlined, size: 24, color: AppColors.grey),
    );
  }

  String _formatDate(DateTime date) {
    // El backend manda UTC → mostrar en hora local del dispositivo.
    final d = date.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year;
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
