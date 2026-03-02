import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/info_chip.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/orden_compra.dart';
import '../../domain/usecases/get_orden_compra_usecase.dart';
import '../../domain/usecases/cambiar_estado_oc_usecase.dart';
import '../../domain/usecases/duplicar_orden_compra_usecase.dart';
import '../../domain/usecases/eliminar_orden_compra_usecase.dart';

class OrdenCompraDetailPage extends StatefulWidget {
  final String empresaId;
  final OrdenCompra orden;

  const OrdenCompraDetailPage({
    super.key,
    required this.empresaId,
    required this.orden,
  });

  @override
  State<OrdenCompraDetailPage> createState() => _OrdenCompraDetailPageState();
}

class _OrdenCompraDetailPageState extends State<OrdenCompraDetailPage> {
  late OrdenCompra _orden;
  bool _isLoadingDetail = true;

  @override
  void initState() {
    super.initState();
    _orden = widget.orden;
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final result = await locator<GetOrdenCompraUseCase>()(
      empresaId: widget.empresaId,
      id: widget.orden.id,
    );

    if (!mounted) return;

    if (result is Success<OrdenCompra>) {
      setState(() {
        _orden = result.data;
        _isLoadingDetail = false;
      });
    } else {
      setState(() => _isLoadingDetail = false);
    }
  }

  IconData _estadoIcon() {
    switch (_orden.estado) {
      case EstadoOrdenCompra.BORRADOR:
        return Icons.edit_note;
      case EstadoOrdenCompra.PENDIENTE:
        return Icons.hourglass_top;
      case EstadoOrdenCompra.APROBADA:
        return Icons.verified;
      case EstadoOrdenCompra.PARCIAL:
        return Icons.incomplete_circle;
      case EstadoOrdenCompra.COMPLETADA:
        return Icons.check_circle;
      case EstadoOrdenCompra.CANCELADA:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_orden.codigo),
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_orden.puedeEditar)
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () async {
                final result = await context.push(
                  '/empresa/compras/ordenes/${_orden.id}/editar',
                  extra: _orden,
                );
                if (result == true && context.mounted) {
                  context.pop(true);
                }
              },
            ),
          PopupMenuButton<String>(
            onSelected: (action) => _handleAction(context, action),
            itemBuilder: (context) => [
              if (_orden.esBorrador)
                const PopupMenuItem(
                  value: 'enviar',
                  child: ListTile(
                    leading: Icon(Icons.send, color: AppColors.blue1),
                    title: Text('Enviar a aprobacion'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              if (_orden.estado == EstadoOrdenCompra.PENDIENTE)
                const PopupMenuItem(
                  value: 'aprobar',
                  child: ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.green),
                    title: Text('Aprobar'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              if (_orden.estado == EstadoOrdenCompra.APROBADA ||
                  _orden.estado == EstadoOrdenCompra.PARCIAL)
                const PopupMenuItem(
                  value: 'recibir',
                  child: ListTile(
                    leading: Icon(Icons.local_shipping, color: Colors.blue),
                    title: Text('Crear recepcion'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuItem(
                value: 'duplicar',
                child: ListTile(
                  leading: Icon(Icons.copy, color: Colors.blueGrey),
                  title: Text('Duplicar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (_orden.esBorrador ||
                  _orden.estado == EstadoOrdenCompra.PENDIENTE)
                const PopupMenuItem(
                  value: 'cancelar',
                  child: ListTile(
                    leading: Icon(Icons.cancel, color: Colors.red),
                    title: Text('Cancelar'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              if (_orden.esBorrador)
                const PopupMenuItem(
                  value: 'eliminar',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Eliminar'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDetail,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildProveedorCard(),
                    const SizedBox(height: 12),
                    _buildInfoCard(),
                    const SizedBox(height: 12),
                    _buildMontosCard(),
                    const SizedBox(height: 12),
                    _buildDetallesSection(),
                    if (_orden.observaciones != null &&
                        _orden.observaciones!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildNotasCard(
                        'Observaciones',
                        _orden.observaciones!,
                        Icons.notes,
                      ),
                    ],
                    if (_orden.condiciones != null &&
                        _orden.condiciones!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildNotasCard(
                        'Condiciones',
                        _orden.condiciones!,
                        Icons.gavel,
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.blue1,
            AppColors.blue1.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            children: [
              // Estado chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_estadoIcon(), size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      _orden.estadoTexto,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Total
              Text(
                '${_orden.moneda} ${_orden.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              // Info chips row
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  _buildHeaderChip(
                    Icons.calendar_today,
                    DateFormatter.formatDate(_orden.fechaEmision),
                  ),
                  if (_orden.sedeNombre.isNotEmpty)
                    _buildHeaderChip(Icons.store, _orden.sedeNombre),
                  if (_orden.moneda != 'PEN')
                    _buildHeaderChip(Icons.currency_exchange, _orden.moneda),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProveedorCard() {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      shadowStyle: ShadowStyle.colorful,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.business, size: 18, color: AppColors.blue1),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText('PROVEEDOR',
                        size: 10, color: AppColors.blueGrey),
                    const SizedBox(height: 2),
                    Text(
                      _orden.nombreProveedor,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blue3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_orden.documentoProveedor != null ||
              _orden.emailProveedor != null ||
              _orden.telefonoProveedor != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (_orden.documentoProveedor != null &&
                    _orden.documentoProveedor!.isNotEmpty)
                  _buildMiniInfo(
                      Icons.badge_outlined, _orden.documentoProveedor!),
                if (_orden.emailProveedor != null &&
                    _orden.emailProveedor!.isNotEmpty)
                  _buildMiniInfo(
                      Icons.email_outlined, _orden.emailProveedor!),
                if (_orden.telefonoProveedor != null &&
                    _orden.telefonoProveedor!.isNotEmpty)
                  _buildMiniInfo(
                      Icons.phone_outlined, _orden.telefonoProveedor!),
              ],
            ),
            if (_orden.direccionProveedor != null &&
                _orden.direccionProveedor!.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildMiniInfo(
                  Icons.location_on_outlined, _orden.direccionProveedor!),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.blueGrey),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppColors.blueGrey),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      shadowStyle: ShadowStyle.colorful,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.info_outline, 'INFORMACION'),
          const SizedBox(height: 12),
          _buildInfoRow('Fecha Emision',
              DateFormatter.formatDate(_orden.fechaEmision)),
          if (_orden.fechaEntregaEsperada != null)
            _buildInfoRow('Entrega Esperada',
                DateFormatter.formatDate(_orden.fechaEntregaEsperada!)),
          if (_orden.terminosPago != null && _orden.terminosPago!.isNotEmpty)
            _buildInfoRow('Terminos de Pago', _orden.terminosPago!),
          if (_orden.diasCredito != null)
            _buildInfoRow('Dias de Credito', '${_orden.diasCredito} dias'),
          _buildInfoRow('Moneda', _orden.moneda),
          if (_orden.sedeNombre.isNotEmpty)
            _buildInfoRow('Sede', _orden.sedeNombre),
          if (_orden.fechaAprobacion != null)
            _buildInfoRow('Fecha Aprobacion',
                DateFormatter.formatDate(_orden.fechaAprobacion!)),
        ],
      ),
    );
  }

  Widget _buildMontosCard() {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      shadowStyle: ShadowStyle.colorful,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.receipt_long, 'RESUMEN DE MONTOS'),
          const SizedBox(height: 12),
          _buildMontoRow('Subtotal',
              '${_orden.moneda} ${_orden.subtotal.toStringAsFixed(2)}'),
          if (_orden.descuento > 0)
            _buildMontoRow(
              'Descuento',
              '- ${_orden.moneda} ${_orden.descuento.toStringAsFixed(2)}',
              valueColor: Colors.red.shade600,
            ),
          _buildMontoRow('Impuestos (IGV)',
              '${_orden.moneda} ${_orden.impuestos.toStringAsFixed(2)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue3,
                ),
              ),
              Text(
                '${_orden.moneda} ${_orden.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetallesSection() {
    if (_isLoadingDetail) {
      return GradientContainer(
        gradient: AppGradients.blueWhiteBlue(),
        borderColor: AppColors.blueborder,
        shadowStyle: ShadowStyle.colorful,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.inventory_2_outlined, 'PRODUCTOS'),
            const SizedBox(height: 24),
            const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    final detalles = _orden.detalles;
    if (detalles == null || detalles.isEmpty) {
      return GradientContainer(
        gradient: AppGradients.blueWhiteBlue(),
        borderColor: AppColors.blueborder,
        shadowStyle: ShadowStyle.colorful,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.inventory_2_outlined, 'PRODUCTOS'),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text(
                    'Sin productos',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 16, color: AppColors.blue1),
              const SizedBox(width: 6),
              AppSubtitle('PRODUCTOS (${detalles.length})',
                  fontSize: 11, color: AppColors.blue3),
            ],
          ),
        ),
        ...detalles.asMap().entries.map((entry) {
          final d = entry.value;
          return _buildProductoItem(d);
        }),
      ],
    );
  }

  Widget _buildProductoItem(OrdenCompraDetalle d) {
    final porcentaje = d.porcentajeRecibido;
    final estaCompleto = d.cantidadRecibida >= d.cantidad;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: estaCompleto
              ? AppColors.greenBorder
              : AppColors.blueborder.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre y total
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.bluechip,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.category_outlined,
                      size: 16, color: AppColors.blue1),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.nombreProducto,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${d.cantidad} x ${_orden.moneda} ${d.precioUnitario.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_orden.moneda} ${d.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blue1,
                  ),
                ),
              ],
            ),
            // Barra de progreso de recepcion
            if (d.cantidadRecibida > 0 || d.cantidadPendiente > 0) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (porcentaje / 100).clamp(0.0, 1.0),
                            minHeight: 5,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              estaCompleto ? AppColors.green : AppColors.blue1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  InfoChip(
                    text: '${d.cantidadRecibida}/${d.cantidad}',
                    icon: estaCompleto ? Icons.check_circle : Icons.pending,
                    textColor:
                        estaCompleto ? AppColors.green : AppColors.blue1,
                    backgroundColor: estaCompleto
                        ? AppColors.greenContainer
                        : AppColors.bluechip,
                    borderRadius: 4,
                    fontSize: 10,
                  ),
                ],
              ),
              if (d.cantidadPendiente > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Pendiente: ${d.cantidadPendiente} unidades',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
            // Descuento si aplica
            if (d.descuento > 0) ...[
              const SizedBox(height: 6),
              InfoChip(
                text:
                    'Desc: ${_orden.moneda} ${d.descuento.toStringAsFixed(2)}',
                icon: Icons.discount_outlined,
                textColor: Colors.red.shade600,
                backgroundColor: Colors.red.shade50,
                borderRadius: 4,
                fontSize: 10,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotasCard(String title, String content, IconData icon) {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      shadowStyle: ShadowStyle.none,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(icon, title.toUpperCase()),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(fontSize: 13, color: AppColors.blueGrey, height: 1.4),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.blue1),
        const SizedBox(width: 6),
        AppSubtitle(title, fontSize: 11, color: AppColors.blue3),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Text(
            value,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMontoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // --- Acciones ---

  void _handleAction(BuildContext context, String action) async {
    switch (action) {
      case 'enviar':
        final result = await locator<CambiarEstadoOcUseCase>()(
          empresaId: widget.empresaId,
          id: _orden.id,
          estado: 'PENDIENTE',
        );
        if (result is Success<OrdenCompra> && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Orden enviada a aprobacion'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(true);
        } else if (result is Error<OrdenCompra> && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
        break;
      case 'aprobar':
        final result = await locator<CambiarEstadoOcUseCase>()(
          empresaId: widget.empresaId,
          id: _orden.id,
          estado: 'APROBADA',
        );
        if (result is Success<OrdenCompra> && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Orden aprobada'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(true);
        } else if (result is Error<OrdenCompra> && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
        break;
      case 'recibir':
        context.push(
          '/empresa/compras/recepciones/nueva-desde-oc',
          extra: _orden,
        );
        break;
      case 'duplicar':
        final result = await locator<DuplicarOrdenCompraUseCase>()(
          empresaId: widget.empresaId,
          id: _orden.id,
        );
        if (result is Success<OrdenCompra> && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Orden duplicada: ${result.data.codigo}'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(true);
        } else if (result is Error<OrdenCompra> && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
        break;
      case 'cancelar':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cancelar orden'),
            content: const Text(
                'Esta seguro de cancelar esta orden de compra?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Si, cancelar'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          final result = await locator<CambiarEstadoOcUseCase>()(
            empresaId: widget.empresaId,
            id: _orden.id,
            estado: 'CANCELADA',
          );
          if (result is Success<OrdenCompra> && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Orden cancelada'),
                backgroundColor: Colors.orange,
              ),
            );
            context.pop(true);
          } else if (result is Error<OrdenCompra> && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;
      case 'eliminar':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Eliminar orden'),
            content: const Text(
                'Esta seguro de eliminar esta orden de compra? Esta accion no se puede deshacer.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Si, eliminar'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          final result = await locator<EliminarOrdenCompraUseCase>()(
            empresaId: widget.empresaId,
            id: _orden.id,
          );
          if (result is Success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Orden eliminada'),
                backgroundColor: Colors.green,
              ),
            );
            context.pop(true);
          } else if (result is Error<void> && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;
    }
  }
}
