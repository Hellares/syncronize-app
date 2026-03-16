import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_cubit.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_state.dart';
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
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return RefreshIndicator(
      onRefresh: _loadVenta,
      color: AppColors.blue1,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderSection(v, dateFormat),
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
          if (v.observaciones != null) ...[
            const SizedBox(height: 12),
            _buildNotasSection(v),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(Venta v, DateFormat dateFormat) {
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
                Icons.calendar_today, 'Fecha', dateFormat.format(v.fechaVenta)),
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
              final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
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
                            dateFormat.format(pago.fechaPago),
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
    MetodoPago metodoPago = MetodoPago.efectivo;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Registrar Pago',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saldo pendiente: ${_venta!.moneda} ${_venta!.saldoPendiente.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<MetodoPago>(
                value: metodoPago,
                decoration: const InputDecoration(
                  labelText: 'Metodo de pago',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: MetodoPago.values
                    .where((m) => m != MetodoPago.credito)
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.label, style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => metodoPago = v);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: montoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: refCtrl,
                decoration: const InputDecoration(
                  labelText: 'Referencia (opcional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final monto = double.tryParse(montoCtrl.text);
                if (monto == null || monto <= 0) return;
                Navigator.pop(ctx);
                context.read<VentaFormCubit>().procesarPago(
                  _venta!.id,
                  {
                    'metodoPago': metodoPago.apiValue,
                    'monto': monto,
                    if (refCtrl.text.isNotEmpty) 'referencia': refCtrl.text,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Registrar'),
            ),
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
              context.read<VentaFormCubit>().anularVenta(_venta!.id);
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
}
