import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/repositories/venta_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/widgets/autorizacion_dialog.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/producto_sede_selector/producto_sede_search_cubit.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_cubit.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_state.dart';
import '../../../producto/presentation/bloc/producto_list/producto_list_cubit.dart';
import '../../domain/entities/venta.dart';
import '../../domain/usecases/get_venta_usecase.dart';
import '../bloc/venta_form/venta_form_cubit.dart';
import '../bloc/venta_form/venta_form_state.dart';
import '../widgets/venta_estado_chip.dart';

class VentaDetailPage extends StatefulWidget {
  final String ventaId;

  const VentaDetailPage({super.key, required this.ventaId});

  @override
  State<VentaDetailPage> createState() => _VentaDetailPageState();
}

class _VentaDetailPageState extends State<VentaDetailPage> {
  Venta? _venta;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVenta();
  }

  Future<void> _loadVenta() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await locator<GetVentaUseCase>()(ventaId: widget.ventaId);

    if (result is Success<Venta>) {
      setState(() {
        _venta = result.data;
        _loading = false;
      });
    } else if (result is Error<Venta>) {
      setState(() {
        _error = result.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<VentaFormCubit>(),
      child: BlocListener<VentaFormCubit, VentaFormState>(
        listener: (context, state) {
          if (state is VentaConfirmada) {
            // Confirming a sale deducts stock — invalidate product caches
            try {
              context.read<ProductoListCubit>().invalidateCache();
            } catch (_) {}
            try {
              context.read<ProductoSedeSearchCubit>().clearCache();
            } catch (_) {}
            setState(() => _venta = state.venta);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Venta confirmada')),
            );
            _loadVenta();
          }
          if (state is VentaPagoRegistrado) {
            setState(() => _venta = state.venta);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pago registrado')),
            );
            _loadVenta();
          }
          if (state is VentaAnulada) {
            // Annulling a sale reverses stock — invalidate product caches
            try {
              context.read<ProductoListCubit>().invalidateCache();
            } catch (_) {}
            try {
              context.read<ProductoSedeSearchCubit>().clearCache();
            } catch (_) {}
            setState(() => _venta = state.venta);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Venta anulada')),
            );
            _loadVenta();
          }
          if (state is VentaFormError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: GradientBackground(
          child: Builder(
            builder: (context) => Scaffold(
              backgroundColor: Colors.transparent,
              appBar: SmartAppBar(
                title: _venta?.codigo ?? 'Venta',
                backgroundColor: AppColors.blue1,
                foregroundColor: Colors.white,
                actions: [
                  if (_venta != null)
                    PopupMenuButton<String>(
                      onSelected: (value) =>
                          _handleMenuAction(context, value),
                      itemBuilder: (_) => [
                        if (_venta!.puedeConfirmar)
                          const PopupMenuItem(
                            value: 'confirmar',
                            child: ListTile(
                              leading:
                                  Icon(Icons.check_circle, color: Colors.green),
                              title: Text('Confirmar'),
                              dense: true,
                            ),
                          ),
                        if (_venta!.puedePagar)
                          const PopupMenuItem(
                            value: 'pago',
                            child: ListTile(
                              leading: Icon(Icons.payment),
                              title: Text('Registrar Pago'),
                              dense: true,
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'ticket',
                          child: ListTile(
                            leading: Icon(Icons.receipt_long),
                            title: Text('Generar Ticket'),
                            dense: true,
                          ),
                        ),
                        if (_venta!.puedeAnular)
                          const PopupMenuItem(
                            value: 'devolucion',
                            child: ListTile(
                              leading: Icon(Icons.assignment_return),
                              title: Text('Registrar Devolucion'),
                              dense: true,
                            ),
                          ),
                        if (_venta!.puedeAnular) ...[
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'anular',
                            child: ListTile(
                              leading: Icon(Icons.cancel, color: Colors.red),
                              title: Text('Anular',
                                  style: TextStyle(color: Colors.red)),
                              dense: true,
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
              body: _buildBody(),
              bottomNavigationBar: _buildBottomActions(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadVenta,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blue1,
                  side: const BorderSide(color: AppColors.blue1),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final v = _venta!;
    // Usar DateFormatter para formato consistente

    return RefreshIndicator(
      onRefresh: _loadVenta,
      color: AppColors.blue1,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderSection(v),
          const SizedBox(height: 12),
          _buildClienteSection(v),
          const SizedBox(height: 12),
          _buildItemsSection(v),
          const SizedBox(height: 12),
          _buildTotalesSection(v),
          const SizedBox(height: 12),
          _buildPagoSection(v),
          if (v.pagos != null && v.pagos!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildPagosHistorialSection(v),
          ],
          if (v.cuotas != null && v.cuotas!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildCuotasSection(),
          ],
          if (v.observaciones != null) ...[
            const SizedBox(height: 12),
            _buildNotasSection(v),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(Venta v) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.bluechip,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.point_of_sale,
                      color: AppColors.blue1, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppSubtitle(v.codigo, fontSize: 15),
                ),
                VentaEstadoChip(estado: v.estado),
              ],
            ),
            const SizedBox(height: 14),
            _buildDetailRow(
                Icons.calendar_today, 'Fecha', DateFormatter.formatDateTime(v.fechaVenta)),
            _buildDetailRow(
                Icons.monetization_on_outlined, 'Moneda', v.moneda),
            if (v.sedeNombre != null)
              _buildDetailRow(Icons.store_outlined, 'Sede', v.sedeNombre!),
            if (v.vendedorNombre != null)
              _buildDetailRow(
                  Icons.person_outline, 'Vendedor', v.vendedorNombre!),
            if (v.cotizacionCodigo != null)
              _buildDetailRow(
                  Icons.link, 'Cotizacion', v.cotizacionCodigo!),
            // Comprobante
            const SizedBox(height: 6),
            if (v.codigoComprobante != null)
              _buildDetailRow(
                  Icons.receipt_long, 'Comprobante',
                  '${v.tipoComprobante} ${v.codigoComprobante}')
            else
              Row(
                children: [
                  Icon(Icons.receipt_long, size: 14, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text('TICKET', style: TextStyle(fontSize: 11, color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showGenerarComprobanteDialog(context, v),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.blue1,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Generar Comprobante', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClienteSection(Venta v) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.person_outline, 'CLIENTE'),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.person, 'Nombre', v.nombreCliente),
            if (v.documentoCliente != null)
              _buildDetailRow(
                  Icons.badge_outlined, 'Documento', v.documentoCliente!),
            if (v.emailCliente != null)
              _buildDetailRow(
                  Icons.email_outlined, 'Email', v.emailCliente!),
            if (v.telefonoCliente != null)
              _buildDetailRow(
                  Icons.phone_outlined, 'Telefono', v.telefonoCliente!),
            if (v.direccionCliente != null)
              _buildDetailRow(Icons.location_on_outlined, 'Direccion',
                  v.direccionCliente!),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection(Venta v) {
    final detalles = v.detalles ?? [];

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
                Icons.shopping_cart_outlined, 'ITEMS (${detalles.length})'),
            const SizedBox(height: 12),
            ...detalles.asMap().entries.map((entry) {
              final index = entry.key;
              final d = entry.value;
              return Column(
                children: [
                  if (index > 0)
                    Divider(
                        height: 16,
                        color: AppColors.blueborder.withValues(alpha: 0.4)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.bluechip,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blue1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.descripcion,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${d.cantidad} x ${v.moneda} ${d.precioUnitario.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppSubtitle(
                        '${v.moneda} ${d.total.toStringAsFixed(2)}',
                        fontSize: 12,
                        color: AppColors.blue1,
                      ),
                    ],
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalesSection(Venta v) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTotalRow(
                'Subtotal', '${v.moneda} ${v.subtotal.toStringAsFixed(2)}'),
            if (v.descuento > 0) ...[
              const SizedBox(height: 4),
              _buildTotalRow(
                  'Descuento',
                  '-${v.moneda} ${v.descuento.toStringAsFixed(2)}',
                  color: Colors.red),
            ],
            const SizedBox(height: 4),
            _buildTotalRow(_getNombreImpuesto(),
                '${v.moneda} ${v.impuestos.toStringAsFixed(2)}'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(
                  height: 1,
                  color: AppColors.blueborder.withValues(alpha: 0.5)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AppSubtitle('TOTAL', fontSize: 14),
                AppSubtitle(
                  '${v.moneda} ${v.total.toStringAsFixed(2)}',
                  fontSize: 16,
                  color: AppColors.blue1,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagoSection(Venta v) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.payment, 'PAGO'),
            const SizedBox(height: 12),
            if (v.metodoPago != null)
              _buildDetailRow(
                  Icons.credit_card, 'Metodo', v.metodoPago!.label),
            if (v.montoRecibido != null)
              _buildDetailRow(Icons.attach_money, 'Recibido',
                  '${v.moneda} ${v.montoRecibido!.toStringAsFixed(2)}'),
            if (v.montoCambio != null && v.montoCambio! > 0)
              _buildDetailRow(Icons.change_circle_outlined, 'Cambio',
                  '${v.moneda} ${v.montoCambio!.toStringAsFixed(2)}'),
            if (v.esCredito) ...[
              _buildDetailRow(Icons.schedule, 'Tipo', 'Venta a Credito'),
              if (v.plazoCredito != null)
                _buildDetailRow(
                    Icons.timer, 'Plazo', '${v.plazoCredito} dias'),
            ],
            _buildDetailRow(Icons.account_balance_wallet, 'Pagado',
                '${v.moneda} ${v.totalPagado.toStringAsFixed(2)}'),
            if (v.saldoPendiente > 0)
              _buildDetailRow(Icons.warning_amber, 'Pendiente',
                  '${v.moneda} ${v.saldoPendiente.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildPagosHistorialSection(Venta v) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.history, 'HISTORIAL DE PAGOS'),
            const SizedBox(height: 12),
            ...v.pagos!.map((pago) {
              // Usar DateFormatter para formato consistente
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pago.metodoPago.label,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            DateFormatter.formatDateTime(pago.fechaPago),
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey.shade600),
                          ),
                          if (pago.referencia != null)
                            Text(
                              'Ref: ${pago.referencia}',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade500),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${v.moneda} ${pago.monto.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCuotasSection() {
    final cuotas = _venta!.cuotas!;
    final cuotasPagadas = cuotas.where((c) => c.estado == 'PAGADA').length;

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month, size: 16, color: AppColors.blue1),
                const SizedBox(width: 6),
                AppSubtitle('Cuotas ($cuotasPagadas/${cuotas.length} pagadas)', fontSize: 14),
              ],
            ),
            const Divider(height: 16),
            // Resumen de mora si hay
            Builder(builder: (_) {
              final totalMora = cuotas.fold<double>(0, (sum, c) => sum + c.montoMora);
              final totalSaldoConMora = cuotas.where((c) => c.saldoPendiente > 0).fold<double>(0, (sum, c) => sum + c.saldoPendiente + c.montoMora);
              if (totalMora > 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Mora acumulada: S/ ${totalMora.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.red.shade700)),
                              Text('Deuda total con mora: S/ ${totalSaldoConMora.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 10, color: Colors.red.shade600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            ...cuotas.map((cuota) {
              Color estadoColor;
              IconData estadoIcon;
              switch (cuota.estado) {
                case 'PAGADA':
                  estadoColor = Colors.green;
                  estadoIcon = Icons.check_circle;
                  break;
                case 'PAGADA_PARCIAL':
                  estadoColor = Colors.blue;
                  estadoIcon = Icons.timelapse;
                  break;
                case 'VENCIDA':
                  estadoColor = Colors.red;
                  estadoIcon = Icons.error;
                  break;
                default:
                  estadoColor = Colors.orange;
                  estadoIcon = Icons.schedule;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(estadoIcon, size: 18, color: estadoColor),
                    const SizedBox(width: 8),
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: estadoColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text('${cuota.numero}',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: estadoColor)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('S/ ${cuota.monto.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(
                            'Vence: ${DateFormatter.formatDate(cuota.fechaVencimiento)}'
                            '${cuota.montoPagado > 0 ? ' | Pagado: S/ ${cuota.montoPagado.toStringAsFixed(2)}' : ''}',
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          ),
                          if (cuota.tieneMora)
                            Text(
                              'Mora: S/ ${cuota.montoMora.toStringAsFixed(2)} (${cuota.diasVencido} días) → Total: S/ ${cuota.totalConMora.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.red),
                            ),
                          if (!cuota.tieneMora && cuota.estado == 'VENCIDA' && cuota.saldoPendiente > 0)
                            Text(
                              'Vencida hace ${DateTime.now().difference(cuota.fechaVencimiento).inDays} días — mora pendiente de cálculo',
                              style: TextStyle(fontSize: 10, color: Colors.red.shade300, fontStyle: FontStyle.italic),
                            ),
                          if (cuota.estado == 'PENDIENTE' || cuota.estado == 'PAGADA_PARCIAL') ...[
                            Builder(builder: (_) {
                              final diasParaVencer = cuota.fechaVencimiento.difference(DateTime.now()).inDays;
                              if (diasParaVencer <= 3 && diasParaVencer >= 0) {
                                return Text(
                                  'Vence en $diasParaVencer día${diasParaVencer != 1 ? 's' : ''} — pague a tiempo para evitar mora',
                                  style: TextStyle(fontSize: 10, color: Colors.orange.shade700, fontStyle: FontStyle.italic),
                                );
                              }
                              return const SizedBox.shrink();
                            }),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: estadoColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        cuota.estado == 'PAGADA_PARCIAL' ? 'Parcial' : cuota.estado == 'PAGADA' ? 'Pagada' : cuota.estado == 'VENCIDA' ? 'Vencida' : 'Pendiente',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: estadoColor),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNotasSection(Venta v) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.notes, 'OBSERVACIONES'),
            const SizedBox(height: 8),
            Text(
              v.observaciones!,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildBottomActions(BuildContext context) {
    if (_venta == null) return null;

    final v = _venta!;
    final actions = <Widget>[];

    if (v.puedeConfirmar) {
      actions.add(Expanded(
        child: ElevatedButton.icon(
          onPressed: () => _showConfirmDialog(context),
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Confirmar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.blue1,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ));
    } else if (v.puedePagar) {
      actions.add(Expanded(
        child: ElevatedButton.icon(
          onPressed: () => _showPagoDialog(context),
          icon: const Icon(Icons.payment, size: 18),
          label: const Text('Registrar Pago'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ));
    }

    if (actions.isEmpty) return null;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(children: actions),
    );
  }

  // ─── Helpers ───

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.blue1),
        const SizedBox(width: 8),
        AppSubtitle(title, fontSize: 12),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getNombreImpuesto() {
    final configState = context.read<ConfiguracionEmpresaCubit>().state;
    if (configState is ConfiguracionEmpresaLoaded) {
      return configState.configuracion.nombreImpuesto;
    }
    return 'IGV';
  }

  // ─── Actions ───

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'confirmar':
        _showConfirmDialog(context);
        break;
      case 'pago':
        _showPagoDialog(context);
        break;
      case 'ticket':
        context.push('/empresa/ventas/${widget.ventaId}/ticket');
        break;
      case 'devolucion':
        context.push('/empresa/devoluciones/desde-venta/${widget.ventaId}');
        break;
      case 'anular':
        _showAnularDialog(context);
        break;
    }
  }

  void _showGenerarComprobanteDialog(BuildContext context, Venta v) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generar Comprobante', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Venta: ${v.codigo}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Text('Total: S/ ${v.total.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            const Text('Selecciona el tipo de comprobante:', style: TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () { Navigator.pop(ctx); _generarComprobante(v.id, 'BOLETA'); },
            icon: const Icon(Icons.receipt, size: 16),
            label: const Text('Boleta'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue1, foregroundColor: Colors.white),
          ),
          ElevatedButton.icon(
            onPressed: () { Navigator.pop(ctx); _generarComprobante(v.id, 'FACTURA'); },
            icon: const Icon(Icons.description, size: 16),
            label: const Text('Factura'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Future<void> _generarComprobante(String ventaId, String tipo) async {
    setState(() => _loading = true);
    final repo = locator<VentaRepository>();
    final result = await repo.generarComprobante(ventaId: ventaId, tipoComprobante: tipo);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result is Success<Venta>) {
      setState(() => _venta = result.data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$tipo generada: ${result.data.codigoComprobante ?? ''}'), backgroundColor: Colors.green),
      );
    } else if (result is Error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as Error).message), backgroundColor: Colors.red),
      );
    }
  }

  void _showConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar venta',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: const Text(
          'Al confirmar, se descontara el stock de los productos. ¿Desea continuar?',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<VentaFormCubit>().confirmarVenta(_venta!.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue1,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _showPagoDialog(BuildContext context) {
    final montoCtrl = TextEditingController(
      text: _venta!.saldoPendiente.toStringAsFixed(2),
    );
    final refCtrl = TextEditingController();
    String metodoActual = 'EFECTIVO';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            margin: const EdgeInsets.only(top: 60),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      children: [
                        Icon(Icons.payment, size: 20, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        const AppSubtitle('Registrar Pago', fontSize: 16),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Saldo pendiente
                    GradientContainer(
                      borderColor: Colors.orange.shade300,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Saldo pendiente',
                                style: TextStyle(fontSize: 13, color: Colors.orange[700])),
                            AppSubtitle(
                              '${_venta!.moneda} ${_venta!.saldoPendiente.toStringAsFixed(2)}',
                              fontSize: 16,
                              color: Colors.orange[700],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Método de pago chips
                    const AppSubtitle('Metodo de Pago', fontSize: 13),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _pagoChip('EFECTIVO', '💵', 'Efectivo', metodoActual, (v) => setSheetState(() => metodoActual = v)),
                        _pagoChip('TARJETA', '💳', 'Tarjeta', metodoActual, (v) => setSheetState(() => metodoActual = v)),
                        _pagoChip('YAPE', '📱', 'Yape', metodoActual, (v) => setSheetState(() => metodoActual = v)),
                        _pagoChip('PLIN', '📱', 'Plin', metodoActual, (v) => setSheetState(() => metodoActual = v)),
                        _pagoChip('TRANSFERENCIA', '🏦', 'Transfer.', metodoActual, (v) => setSheetState(() => metodoActual = v)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Monto
                    TextFormField(
                      controller: montoCtrl,
                      decoration: InputDecoration(
                        labelText: 'Monto',
                        prefixText: 'S/ ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),

                    // Referencia (solo si no es efectivo)
                    if (metodoActual != 'EFECTIVO')
                      TextFormField(
                        controller: refCtrl,
                        decoration: InputDecoration(
                          labelText: 'Referencia / N° operacion',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          isDense: true,
                        ),
                      ),
                    if (metodoActual != 'EFECTIVO') const SizedBox(height: 16),
                    if (metodoActual == 'EFECTIVO') const SizedBox(height: 4),

                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final monto = double.tryParse(montoCtrl.text);
                              if (monto == null || monto <= 0) return;
                              Navigator.pop(ctx);
                              context.read<VentaFormCubit>().procesarPago(
                                _venta!.id,
                                {
                                  'metodoPago': metodoActual,
                                  'monto': monto,
                                  if (refCtrl.text.isNotEmpty) 'referencia': refCtrl.text,
                                },
                              );
                            },
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Registrar Pago'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _pagoChip(String value, String icon, String label, String selected, ValueChanged<String> onTap) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue1 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.blue1 : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  void _showAnularDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Anular venta',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: const Text(
          'Se reversara el stock y la venta quedara anulada. Esta accion no se puede deshacer. ¿Desea continuar?',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _requestAutorizacionAnular(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Anular'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestAutorizacionAnular(BuildContext ctx) async {
    final result = await showAutorizacionDialog(
      ctx,
      operacion: 'ANULAR_VENTA',
      titulo: 'Autorizacion para anular',
      descripcion: 'Un administrador debe autorizar la anulacion de esta venta',
    );

    if (!mounted || result == null) return;

    context.read<VentaFormCubit>().anularVenta(
      _venta!.id,
      autorizadoPorId: result.autorizadoPorId,
      motivo: result.autorizadoPorNombre.isNotEmpty
          ? 'Anulacion de venta - Autorizado por ${result.autorizadoPorNombre}'
          : 'Anulacion de venta',
    );
  }
}
