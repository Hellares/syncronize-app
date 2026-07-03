import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/solicitud_cotizacion.dart';
import '../../domain/usecases/get_solicitud_detalle_usecase.dart';
import '../../domain/usecases/cancelar_solicitud_usecase.dart';

class SolicitudDetailPage extends StatefulWidget {
  final String solicitudId;

  const SolicitudDetailPage({super.key, required this.solicitudId});

  @override
  State<SolicitudDetailPage> createState() => _SolicitudDetailPageState();
}

class _SolicitudDetailPageState extends State<SolicitudDetailPage> {
  final _getDetalleUseCase = locator<GetSolicitudDetalleUseCase>();
  final _cancelarUseCase = locator<CancelarSolicitudUseCase>();

  SolicitudCotizacion? _solicitud;
  bool _isLoading = true;
  bool _isCancelling = false;
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

    final result =
        await _getDetalleUseCase(solicitudId: widget.solicitudId);

    if (!mounted) return;

    if (result is Success<SolicitudCotizacion>) {
      setState(() {
        _solicitud = result.data;
        _isLoading = false;
      });
    } else if (result is Error<SolicitudCotizacion>) {
      setState(() {
        _error = result.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelarSolicitud() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const AppSubtitle('Cancelar solicitud', fontSize: 14),
        content: const Text(
          'Esta seguro de cancelar esta solicitud de cotizacion?',
          style: TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'No',
              style: TextStyle(fontSize: 11, color: AppColors.blueGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Si, cancelar',
              style: TextStyle(fontSize: 11, color: AppColors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);

    final result =
        await _cancelarUseCase(solicitudId: widget.solicitudId);

    if (!mounted) return;

    setState(() => _isCancelling = false);

    if (result is Success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud cancelada'),
          backgroundColor: AppColors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else if (result is Error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((result).message),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      style: GradientStyle.minimal,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(title: 'Detalle de Solicitud'),
        body: _buildBody(),
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
            Icon(Icons.error_outline, size: 40, color: AppColors.red),
            const SizedBox(height: 12),
            AppText(_error!, size: 12, color: AppColors.red),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadDetalle,
              child: Text(
                'Reintentar',
                style: TextStyle(fontSize: 11, color: AppColors.blue2),
              ),
            ),
          ],
        ),
      );
    }

    final solicitud = _solicitud!;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(solicitud),
                const SizedBox(height: 16),
                _buildEmpresaInfo(solicitud),
                const SizedBox(height: 16),
                _buildItemsSection(solicitud),
                if (solicitud.observaciones != null &&
                    solicitud.observaciones!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildObservaciones(solicitud),
                ],
                if (solicitud.estado ==
                    EstadoSolicitudCotizacion.cotizada) ...[
                  const SizedBox(height: 16),
                  _buildCotizadaSection(solicitud),
                ],
                if (solicitud.estado ==
                    EstadoSolicitudCotizacion.rechazada) ...[
                  const SizedBox(height: 16),
                  _buildRechazadaSection(solicitud),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        if (solicitud.estado.puedeCancelar) _buildCancelButton(),
      ],
    );
  }

  Widget _buildHeader(SolicitudCotizacion solicitud) {
    return GradientContainer(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSubtitle(solicitud.codigo, fontSize: 14),
                const SizedBox(height: 4),
                Text(
                  solicitud.nombreSolicitante,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.blueGrey,
                  ),
                ),
                if (solicitud.creadoEn != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(solicitud.creadoEn!),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.grey,
                    ),
                  ),
                ],
                if (solicitud.fechaVencimiento != null) ...[
                  const SizedBox(height: 6),
                  _buildFechaVencimientoRow(solicitud.fechaVencimiento!),
                ],
              ],
            ),
          ),
          _buildEstadoChip(solicitud.estado),
        ],
      ),
    );
  }

  Widget _buildEmpresaInfo(SolicitudCotizacion solicitud) {
    if (solicitud.empresa == null) return const SizedBox.shrink();

    return GradientContainer(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.blue3.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: solicitud.empresa!.logo != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: solicitud.empresa!.logo!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const SizedBox.shrink(),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.store,
                        color: AppColors.blue3,
                        size: 20,
                      ),
                    ),
                  )
                : const Icon(Icons.store, color: AppColors.blue3, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSubtitle(solicitud.empresa!.nombre, fontSize: 12),
                const SizedBox(height: 2),
                Text(
                  solicitud.empresa!.subdominio,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(SolicitudCotizacion solicitud) {
    final items = solicitud.items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSubtitle(
          'Items (${items.length})',
          fontSize: 12,
        ),
        const SizedBox(height: 8),
        // Tabla tipo Excel (mismo patrón que el detalle de la empresa):
        // header bluechip + zebra striping + thumbnail por fila.
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.blueborder.withValues(alpha: 0.5),
              width: 0.6,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                color: AppColors.bluechip,
                padding:
                    const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                child: const Row(
                  children: [
                    SizedBox(width: 26, child: Center(child: _ThItem('#'))),
                    Expanded(child: _ThItem('PRODUCTO')),
                    SizedBox(
                        width: 52, child: Center(child: _ThItem('CANT.'))),
                  ],
                ),
              ),
              for (var i = 0; i < items.length; i++)
                _ItemTablaRow(index: i, item: items[i]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildObservaciones(SolicitudCotizacion solicitud) {
    return GradientContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes, size: 16, color: AppColors.blue3),
              const SizedBox(width: 6),
              const AppSubtitle('Observaciones', fontSize: 11),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            solicitud.observaciones!,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCotizadaSection(SolicitudCotizacion solicitud) {
    return GradientContainer(
      padding: const EdgeInsets.all(12),
      borderColor: AppColors.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, size: 18, color: AppColors.green),
              const SizedBox(width: 6),
              AppSubtitle(
                'Cotizacion recibida',
                fontSize: 12,
                color: AppColors.green,
              ),
            ],
          ),
          if (solicitud.respuestaVendedor != null) ...[
            const SizedBox(height: 8),
            Text(
              'Respuesta del vendedor:',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.blueGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              solicitud.respuestaVendedor!,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.black87,
                height: 1.4,
              ),
            ),
          ],
          if (solicitud.cotizacionId != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Ver Cotizacion',
                borderColor: AppColors.green,
                textColor: AppColors.green,
                fontSize: 11,
                onPressed: () async {
                  // Ver la cotización formal (precios, aceptar/rechazar,
                  // separar con adelanto Yape).
                  await context.push(
                    '/mis-solicitudes-cotizacion/${widget.solicitudId}/cotizacion',
                  );
                  _loadDetalle();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRechazadaSection(SolicitudCotizacion solicitud) {
    return GradientContainer(
      padding: const EdgeInsets.all(12),
      borderColor: AppColors.red,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cancel, size: 18, color: AppColors.red),
              const SizedBox(width: 6),
              AppSubtitle(
                'Solicitud rechazada',
                fontSize: 11,
                color: AppColors.red,
              ),
            ],
          ),
          if (solicitud.respuestaVendedor != null) ...[
            const SizedBox(height: 8),
            Text(
              'Motivo:',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.blueGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              solicitud.respuestaVendedor!,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.black87,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: 'Cancelar Solicitud',
            isLoading: _isCancelling,
            loadingText: 'Cancelando...',
            backgroundColor: Colors.white,
            borderColor: AppColors.red,
            textColor: AppColors.red,
            fontSize: 11,
            onPressed: _isCancelling ? null : _cancelarSolicitud,
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoChip(EstadoSolicitudCotizacion estado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: estado.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: estado.color,
        ),
      ),
    );
  }

  Widget _buildFechaVencimientoRow(DateTime fechaVencimiento) {
    final now = DateTime.now();
    final diferencia = fechaVencimiento.difference(now);
    final diasRestantes = diferencia.inDays;

    final Color color;
    final String texto;

    if (diasRestantes < 0) {
      color = AppColors.red;
      texto = 'Vencida hace ${diasRestantes.abs()} dia${diasRestantes.abs() == 1 ? '' : 's'}';
    } else if (diasRestantes == 0) {
      color = AppColors.orange;
      texto = 'Vence hoy';
    } else if (diasRestantes <= 3) {
      color = AppColors.orange;
      texto = 'Vence en $diasRestantes dia${diasRestantes == 1 ? '' : 's'}';
    } else {
      color = AppColors.green;
      texto = 'Vence en $diasRestantes dias';
    }

    return Row(
      children: [
        Icon(Icons.timer_outlined, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          '${_formatDate(fechaVencimiento)} - $texto',
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Header de columna de la tabla de items (uppercase compacto, mismo estilo
/// que las tablas de cotización).
class _ThItem extends StatelessWidget {
  final String text;
  const _ThItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade800,
        letterSpacing: 0.3,
      ),
    );
  }
}

/// Fila de la tabla de items con zebra striping + thumbnail 18px. La nota
/// y el badge "Manual" van como sub-línea bajo la descripción.
class _ItemTablaRow extends StatelessWidget {
  final int index;
  final SolicitudItem item;

  const _ItemTablaRow({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: index.isEven ? Colors.white : Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 26,
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 9,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),
          // Thumbnail 18px (o ícono si no hay imagen)
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: item.imagenUrl != null
                ? CachedNetworkImage(
                    imageUrl: item.imagenUrl!,
                    width: 18,
                    height: 18,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        width: 18, height: 18, color: Colors.grey.shade100),
                    errorWidget: (_, __, ___) => Container(
                      width: 18,
                      height: 18,
                      color: Colors.grey.shade100,
                      child: Icon(Icons.image,
                          size: 10, color: Colors.grey.shade400),
                    ),
                  )
                : Container(
                    width: 18,
                    height: 18,
                    color: item.esManual
                        ? Colors.orange.shade50
                        : Colors.grey.shade100,
                    child: Icon(
                      item.esManual
                          ? Icons.edit_note
                          : Icons.inventory_2_outlined,
                      size: 11,
                      color: item.esManual
                          ? Colors.orange
                          : Colors.grey.shade400,
                    ),
                  ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.descripcion,
                        style: const TextStyle(
                          fontSize: 10,
                          height: 1.1,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.esManual) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'Manual',
                          style: TextStyle(
                            fontSize: 8,
                            height: 1.1,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (item.notasItem != null && item.notasItem!.isNotEmpty)
                  Text(
                    'Nota: ${item.notasItem}',
                    style: TextStyle(
                      fontSize: 8,
                      height: 1.1,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 52,
            child: Center(
              child: Text(
                '${item.cantidad}',
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
