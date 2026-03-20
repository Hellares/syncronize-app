import 'package:flutter/material.dart';
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
                    child: Image.network(
                      solicitud.empresa!.logo!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSubtitle(
          'Items (${solicitud.items.length})',
          fontSize: 12,
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: solicitud.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = solicitud.items[index];
            return _buildDetailItemCard(item);
          },
        ),
      ],
    );
  }

  Widget _buildDetailItemCard(SolicitudItem item) {
    return GradientContainer(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: item.imagenUrl != null
                ? Image.network(
                    item.imagenUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: AppColors.greyLight,
                      child: const Icon(Icons.image, size: 20),
                    ),
                  )
                : Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: item.esManual
                          ? AppColors.orange.withValues(alpha: 0.1)
                          : AppColors.blue3.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      item.esManual
                          ? Icons.edit_note
                          : Icons.inventory_2_outlined,
                      size: 22,
                      color:
                          item.esManual ? AppColors.orange : AppColors.blue3,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.descripcion,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.esManual)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Manual',
                          style: TextStyle(
                            fontSize: 8,
                            color: AppColors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Cantidad: ${item.cantidad}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.blueGrey,
                  ),
                ),
                if (item.notasItem != null &&
                    item.notasItem!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Nota: ${item.notasItem}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.blueGrey,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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
                isOutlined: true,
                borderColor: AppColors.green,
                textColor: AppColors.green,
                fontSize: 10,
                height: 34,
                onPressed: () {
                  // TODO: Navegar al detalle de la cotizacion
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Cotizacion ID: ${solicitud.cotizacionId}'),
                    ),
                  );
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
                fontSize: 12,
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
            height: 40,
            isOutlined: true,
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
