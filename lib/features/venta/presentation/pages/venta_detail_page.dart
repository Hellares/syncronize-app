import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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
import '../../data/datasources/venta_remote_datasource.dart';
import '../../domain/entities/reversion_total.dart';
import '../../domain/entities/venta.dart';
import '../../domain/usecases/get_venta_usecase.dart';
import '../../domain/usecases/reversion_total_usecase.dart';
import '../bloc/venta_form/venta_form_cubit.dart';
import '../bloc/venta_form/venta_form_state.dart';
import '../widgets/flujo_documentos_widget.dart';
import '../widgets/venta_estado_chip.dart';
import '../../../facturacion/domain/entities/crear_nota_item.dart';
import '../../../facturacion/domain/entities/tipo_nota.dart';
import '../../../facturacion/presentation/widgets/crear_nota_dialog.dart';
import '../../../facturacion/presentation/widgets/anular_comprobante_dialog.dart';

class VentaDetailPage extends StatefulWidget {
  final String ventaId;

  const VentaDetailPage({super.key, required this.ventaId});

  @override
  State<VentaDetailPage> createState() => _VentaDetailPageState();
}

class _VentaDetailPageState extends State<VentaDetailPage> {
  Venta? _venta;
  ReversionTotal? _reversion;
  bool _loading = true;
  String? _error;
  bool _procesandoReversion = false;

  /// Último intento de pago: si el backend rechaza por Ley 28194 (efectivo
  /// sobre el umbral de bancarización), se reintenta con el flag de
  /// confirmación tras avisar al cajero.
  Map<String, dynamic>? _ultimoPagoData;

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
      // Cargar reversión existente en segundo plano (no bloquea la pantalla).
      _loadReversion();
    } else if (result is Error<Venta>) {
      setState(() {
        _error = result.message;
        _loading = false;
      });
    }
  }

  Future<void> _loadReversion() async {
    final result = await locator<ObtenerReversionTotalUseCase>()(
      ventaId: widget.ventaId,
    );
    if (!mounted) return;
    if (result is Success<ReversionTotal?>) {
      setState(() => _reversion = result.data);
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
            _ultimoPagoData = null;
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
            // Pago en efectivo sobre el umbral de bancarización: el backend
            // exige confirmación expresa — se pregunta y se reintenta con
            // el flag en vez de dejar el pago bloqueado.
            final pagoPendiente = _ultimoPagoData;
            if (state.message.contains('Ley 28194') && pagoPendiente != null) {
              _ultimoPagoData = null;
              final cubit = context.read<VentaFormCubit>();
              final ventaId = _venta!.id;
              showDialog<bool>(
                context: context,
                builder: (dctx) => AlertDialog(
                  title: const Text('Pago en efectivo — Ley 28194',
                      style: TextStyle(fontSize: 15)),
                  content: Text(
                    '${state.message}\n\n¿Confirmar el pago en efectivo de todas formas?',
                    style: const TextStyle(fontSize: 12),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dctx, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Confirmar pago'),
                    ),
                  ],
                ),
              ).then((ok) {
                if (ok == true && mounted) {
                  cubit.procesarPago(ventaId, {
                    ...pagoPendiente,
                    'aceptaRiesgoBancarizacion': true,
                  });
                }
              });
              return;
            }
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        children: [
          _buildHeaderSection(v),
          const SizedBox(height: 12),
          _buildClienteSection(v),
          const SizedBox(height: 12),
          _buildItemsSection(v),
          const SizedBox(height: 12),
          _buildPagoSection(v),
          if (v.cuotas != null && v.cuotas!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildCuotasSection(),
          ],
          if (v.observaciones != null) ...[
            const SizedBox(height: 12),
            _buildNotasSection(v),
          ],
          const SizedBox(height: 12),
          FlujoDocumentosWidget(ventaId: v.id),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(Venta v) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.bluechip,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.point_of_sale,
                      color: AppColors.blue1, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppSubtitle(v.codigo, fontSize: 11),
                ),
                VentaEstadoChip(estado: v.estado),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
                Icons.calendar_today, 'Fecha', DateFormatter.formatDateTime(v.fechaVenta)),
            // _buildDetailRow(
            //     Icons.monetization_on_outlined, 'Moneda', v.moneda),
            if (v.sedeNombre != null)
              _buildDetailRow(Icons.store_outlined, 'Sede', v.sedeNombre!),
            if (v.vendedorNombre != null)
              _buildDetailRow(
                  Icons.person_outline, 'Vendedor', v.vendedorNombre!),
            if (v.cotizacionCodigo != null)
              _buildDetailRow(
                  Icons.link, 'Cotizacion', v.cotizacionCodigo!),
            // Banner de venta revertida (reversión total post-anulación)
            if (_reversion != null) ...[
              const SizedBox(height: 8),
              _buildReversionBanner(_reversion!),
            ],
            // Comprobante
            const SizedBox(height: 6),
            if (v.codigoComprobante != null) ...[
              _buildDetailRow(
                  Icons.receipt_long, 'Comprobante',
                  '${v.tipoComprobante} ${v.codigoComprobante}'),
              if (v.comprobanteAnulado == true)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                  child: const Text('ANULADO', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w700)),
                ),
              const SizedBox(height: 4),
              _buildSunatStatusRow(v),
              if (v.comprobanteSunatPdfUrl != null || v.comprobanteEnlaceProveedor != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (v.comprobanteSunatPdfUrl != null)
                      GestureDetector(
                        onTap: () => _abrirUrl(v.comprobanteSunatPdfUrl!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.picture_as_pdf, size: 11, color: Colors.blue.shade700),
                              const SizedBox(width: 4),
                              Text('Ver PDF SUNAT', style: TextStyle(fontSize: 9, color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    if (v.comprobanteEnlaceProveedor != null) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _abrirUrl(v.comprobanteEnlaceProveedor!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.open_in_new, size: 11, color: Colors.grey.shade700),
                              const SizedBox(width: 4),
                              Text('Ver comprobante', style: TextStyle(fontSize: 9, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              if (v.comprobanteSunatStatus == 'ACEPTADO' && v.comprobanteAnulado != true) ...[
                const SizedBox(height: 8),
                _buildComprobanteActions(context, v),
              ],
              // Acción "Devolución Total" cuando el comprobante ya está anulado.
              // Se renderiza fuera de _buildComprobanteActions porque ese bloque
              // se oculta al estar anulado.
              if (v.comprobanteAnulado == true && _reversion == null) ...[
                Builder(
                  builder: (_) {
                    final w = _buildReversionTotalAction(v);
                    return w ?? const SizedBox.shrink();
                  },
                ),
              ],
              // Notas de crédito/débito relacionadas
              if (v.notasRelacionadas != null && v.notasRelacionadas!.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...v.notasRelacionadas!.map((nota) => _buildNotaCard(nota, v.sedeId)),
              ],
            ] else ...[
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
              const SizedBox(height: 8),
              _actionChip(
                icon: Icons.local_shipping,
                label: 'Guía Remisión',
                color: Colors.indigo,
                onTap: () => context.push('/empresa/guias-remision/desde-venta/${v.id}'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClienteSection(Venta v) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.person_outline, 'CLIENTE'),
            const SizedBox(height: 8),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            Icons.shopping_cart_outlined, 'ITEMS (${detalles.length})'),
        const SizedBox(height: 5),
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
              // ── Header ──
              Container(
                color: AppColors.bluechip,
                padding: const EdgeInsets.symmetric(
                    vertical: 6, horizontal: 8),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 26,
                      child: Center(child: _Th('#')),
                    ),
                    Expanded(flex: 5, child: _Th('PRODUCTO')),
                    Expanded(
                        flex: 2, child: Center(child: _Th('CANT.'))),
                    Expanded(
                        flex: 3,
                        child: Align(
                            alignment: Alignment.centerRight,
                            child: _Th('P. UNIT.'))),
                    Expanded(
                        flex: 3,
                        child: Align(
                            alignment: Alignment.centerRight,
                            child: _Th('TOTAL'))),
                  ],
                ),
              ),
              // ── Body con zebra striping ──
              for (var i = 0; i < detalles.length; i++)
                Container(
                  color: i.isEven ? Colors.white : Colors.grey.shade50,
                  padding: const EdgeInsets.symmetric(
                      vertical: 4, horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 26,
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  detalles[i].descripcion,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                // Nivel/precio aplicado al vender (snapshot).
                                // Las líneas de combo expandido (origenComboId)
                                // no muestran nivel: su precio es regular +
                                // descuento prorrateado, no un nivel real.
                                if (detalles[i].nivelAplicadoSnapshot != null &&
                                    detalles[i].origenComboId == null) ...[
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.blue1
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      detalles[i].nivelAplicadoSnapshot!,
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.blue1,
                                      ),
                                    ),
                                  ),
                                ],
                                // Línea que cobra una orden de servicio: el
                                // precio es el SALDO. Mostrar el contexto
                                // (costo total y adelanto previo) para que
                                // el monto no parezca el costo del servicio.
                                if (detalles[i].esOrdenServicio) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Servicio S/ ${(detalles[i].ordenCostoTotal ?? 0).toStringAsFixed(2)}'
                                    '${(detalles[i].ordenAdelanto ?? 0) > 0 ? ' · Adelanto${detalles[i].ordenMetodoPagoAdelanto != null ? " ${detalles[i].ordenMetodoPagoAdelanto}" : ""} -S/ ${detalles[i].ordenAdelanto!.toStringAsFixed(2)}' : ''}',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text(
                                _fmtCantidad(detalles[i].cantidad),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                detalles[i].precioUnitario.toStringAsFixed(2),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                detalles[i].total.toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.blue1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Sub-líneas de devoluciones/cambios asociados
                      // a este VentaDetalle (si los hay).
                      ..._buildDevolucionLines(v, detalles[i].id),
                    ],
                  ),
                ),
              // ── Footer: subtotal / descuento / IGV / TOTAL ──
              // Cierra la tabla como factura: alineado a la derecha,
              // con borde superior fuerte para separarlo del body.
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.blueborder.withValues(alpha: 0.5),
                      width: 0.6,
                    ),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: Column(
                  children: [
                    _buildFooterRow(
                      'Subtotal',
                      '${v.moneda} ${v.subtotal.toStringAsFixed(2)}',
                    ),
                    if (v.descuento > 0)
                      _buildFooterRow(
                        'Descuento',
                        '-${v.moneda} ${v.descuento.toStringAsFixed(2)}',
                        color: Colors.red.shade600,
                      ),
                    _buildFooterRow(
                      _getNombreImpuesto(),
                      '${v.moneda} ${v.impuestos.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
              // Total destacado — barra propia con fondo bluechip
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bluechip,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.blueborder.withValues(alpha: 0.5),
                      width: 0.6,
                    ),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.blue1,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${v.moneda} ${v.total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.blue1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Fila del footer de la tabla de items (subtotal, descuento, IGV).
  /// Alineada a la derecha con label + monto en ancho fijo.
  Widget _buildFooterRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color ?? Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Cantidad sin decimales innecesarios (1, 2, 3 → "1", "2", "3";
  /// 1.5 → "1.5"). Mantiene la tabla legible para enteros.
  static String _fmtCantidad(num n) {
    final d = n.toDouble();
    if (d.truncateToDouble() == d) return d.toStringAsFixed(0);
    return d.toStringAsFixed(2);
  }

  Widget _buildPagoSection(Venta v) {
    // Pagos de ESTA venta (hoy). Los pagos "Adelanto OS-X" se excluyen del
    // historial: ya se muestran en PAGOS PREVIOS con su contexto, y la
    // lógica de vuelto (montoCambio es de HOY) no les aplica — un adelanto
    // EFECTIVO mostraría el vuelto restado de un dinero que no lo generó.
    final pagosHoy = (v.pagos ?? [])
        .where((p) => !(p.referencia?.startsWith('Adelanto ') ?? false))
        .toList();
    final tieneHistorial = pagosHoy.isNotEmpty;
    // Adelantos previos de órdenes de servicio cobradas en esta venta.
    // NO son PagoVenta (entraron a caja con su propio movimiento
    // ADELANTO_SERVICIO cuando se recibieron), pero sin mostrarlos aquí
    // se pierde la traza de cómo se completó el costo del servicio:
    // costo total = adelantos previos + total de esta venta.
    final adelantosServicio = (v.detalles ?? [])
        .where((d) => d.esOrdenServicio && (d.ordenAdelanto ?? 0) > 0)
        .toList();
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.payment, 'PAGO'),
            const SizedBox(height: 8),
            // Resumen
            if (v.metodoPagoDisplay != null)
              _buildDetailRow(
                  Icons.credit_card, 'Metodo', v.metodoPagoDisplay!),
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
            // Pagos previos de órdenes de servicio: el adelanto entró a
            // caja antes de esta venta; aquí se muestra para cerrar la
            // trazabilidad (adelanto + total venta = costo del servicio).
            if (adelantosServicio.isNotEmpty) ...[
              const SizedBox(height: 10),
              Divider(
                  height: 1,
                  color: AppColors.blueborder.withValues(alpha: 0.5)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.home_repair_service_outlined,
                      size: 14, color: AppColors.blue1),
                  const SizedBox(width: 6),
                  Text(
                    'PAGOS PREVIOS (SERVICIO)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blue1,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...adelantosServicio.map((d) {
                final costo = d.ordenCostoTotal ?? 0;
                final adelanto = d.ordenAdelanto ?? 0;
                final metodo = d.ordenMetodoPagoAdelanto;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Adelanto ${d.ordenCodigo ?? 'orden de servicio'}'
                                  '${metodo != null ? ' · $metodo' : ''}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Pagado antes del cobro (registrado en caja al recibirse)',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${v.moneda} ${adelanto.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                      if (costo > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2, left: 8),
                          child: Text(
                            'Costo servicio S/ ${costo.toStringAsFixed(2)} = '
                            'adelanto S/ ${adelanto.toStringAsFixed(2)} + '
                            'cobrado hoy S/ ${(d.total - adelanto).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.blue1,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
            // Historial inline (solo si hay pagos registrados). Va dentro
            // del MISMO card que el resumen — separado por un divisor +
            // subtítulo, no por otra tarjeta aparte.
            if (tieneHistorial) ...[
              const SizedBox(height: 10),
              Divider(
                  height: 1,
                  color: AppColors.blueborder.withValues(alpha: 0.5)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.history, size: 14, color: AppColors.blue1),
                  const SizedBox(width: 6),
                  Text(
                    'HISTORIAL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blue1,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${pagosHoy.length})',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...pagosHoy.map((pago) {
                final tieneVuelto = pago.metodoPago == MetodoPago.efectivo &&
                    v.montoCambio != null &&
                    v.montoCambio! > 0;
                final montoNeto = tieneVuelto
                    ? pago.monto - v.montoCambio!
                    : pago.monto;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pago.metodoPago.label,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  DateFormatter.formatDateTime(pago.fechaPago),
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600),
                                ),
                                if (pago.referencia != null)
                                  Text(
                                    'Ref: ${pago.referencia}',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '${v.moneda} ${montoNeto.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                      if (tieneVuelto)
                        Padding(
                          padding: const EdgeInsets.only(top: 2, left: 8),
                          child: Text(
                            'Recibido S/ ${pago.monto.toStringAsFixed(2)} · Vuelto S/ ${v.montoCambio!.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
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
        AppSubtitle(title, fontSize: 11),
      ],
    );
  }

  /// Genera las sub-líneas que aparecen indentadas debajo del Row de
  /// un item cuando ese item tiene devoluciones PROCESADAS asociadas.
  /// Diseño tipo árbol con conector └─▶ (mismo lenguaje visual que el
  /// FlujoDocumentosWidget) para indicar jerarquía.
  List<Widget> _buildDevolucionLines(Venta v, String ventaDetalleId) {
    final items = (v.devoluciones ?? const <VentaDevolucionItemInfo>[])
        .where((d) => d.ventaDetalleId == ventaDetalleId)
        .toList();
    if (items.isEmpty) return const [];

    return List.generate(items.length, (idx) {
      final d = items[idx];
      final isLast = idx == items.length - 1;
      final isCambio = d.accion == 'CAMBIO_PRODUCTO';
      final icon = isCambio ? Icons.swap_horiz : Icons.assignment_return;
      final color = isCambio ? Colors.indigo : Colors.orange.shade800;

      final reemplazoNombre =
          d.varianteReemplazoNombre ?? d.productoReemplazoNombre;
      final fecha = d.procesadoEn != null
          ? DateFormatter.formatDate(d.procesadoEn!)
          : null;

      // Diferencia de precio: positiva = cliente pagó más (verde),
      // negativa = devolvimos diferencia (rojo). Solo si != 0.
      final dif = d.diferenciaPrecio ?? 0;
      final mostrarDif = isCambio && dif.abs() > 0.001;

      return Padding(
        padding: const EdgeInsets.only(left: 26),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Conector └─▶ pintado a la misma escala que el árbol del
              // flujo de documentos. Si no es el último, extiende la
              // línea vertical hacia abajo para "continuar el tronco".
              SizedBox(
                width: 22,
                child: CustomPaint(
                  size: const Size(22, 32),
                  painter: _ConnectorPainter(
                    color: color.withValues(alpha: 0.55),
                    isLast: isLast,
                  ),
                ),
              ),
              // Contenido del nodo
              Expanded(
                child: InkWell(
                  onTap: () => context
                      .push('/empresa/devoluciones/${d.devolucionId}'),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Línea 1: ícono + acción + reemplazo + dif precio
                        Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.13),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child:
                                  Icon(icon, size: 12, color: color),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: color,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  children: [
                                    TextSpan(
                                        text:
                                            '${d.accionLabel}: ${d.cantidad}'),
                                    if (isCambio && reemplazoNombre != null)
                                      TextSpan(
                                        text: ' → $reemplazoNombre',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: color,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (mostrarDif)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: dif > 0
                                      ? Colors.green.shade50
                                      : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: dif > 0
                                        ? Colors.green.shade300
                                        : Colors.red.shade300,
                                  ),
                                ),
                                child: Text(
                                  '${dif > 0 ? '+' : '−'} S/ ${dif.abs().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: dif > 0
                                        ? Colors.green.shade800
                                        : Colors.red.shade800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Línea 2: chips compactos
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: [
                            _DevolucionChip(label: d.motivoLabel, color: color),
                            _DevolucionChip(
                              label: 'Estado: ${d.estadoProductoLabel}',
                              color: color,
                            ),
                            _DevolucionChip(
                              label: d.tipoReembolso == 'CAMBIO_PRODUCTO'
                                  ? 'Cambio'
                                  : 'Reembolso efectivo',
                              color: color,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Línea 3: código + fecha (cliqueable)
                        Row(
                          children: [
                            Text(
                              '${d.devolucionCodigo}${fecha != null ? " • $fecha" : ""}',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                size: 12, color: Colors.grey.shade500),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildNotaCard(NotaRelacionada nota, String sedeId) {
    final isCredito = nota.tipoComprobante == 'NOTA_CREDITO';
    final color = isCredito ? Colors.orange : Colors.purple;

    // Cuando está anulada, el chip de estado pasa a "ANULADO" rojo (sobreescribe sunatStatus
    // porque ese sigue siendo ACEPTADO oficialmente — la anulación es flag aparte).
    final statusLabel = nota.anulado ? 'ANULADO' : (nota.sunatStatus ?? 'PENDIENTE');
    final statusColor = nota.anulado
        ? Colors.red.shade700
        : (nota.sunatStatus == 'ACEPTADO'
            ? Colors.green
            : nota.sunatStatus == 'RECHAZADO'
                ? Colors.red
                : Colors.amber.shade700);

    // Anular vía CDB: ACEPTADA, no anulada, dentro de plazo 7 días, serie F* (FC*/FD*).
    final esSerieF = nota.codigoGenerado.startsWith('F');
    final dias = nota.fechaEmision != null
        ? DateTime.now().difference(nota.fechaEmision!.toLocal()).inDays
        : 999;
    final puedeAnular = nota.sunatStatus == 'ACEPTADO' &&
        !nota.anulado &&
        esSerieF &&
        dias <= 7;
    final esSerieBPendiente = nota.sunatStatus == 'ACEPTADO' &&
        !nota.anulado &&
        !esSerieF;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        // Cuando está anulada, fondo gris atenuado para señalizar visualmente.
        color: nota.anulado
            ? Colors.grey.shade100
            : color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: nota.anulado
              ? Colors.red.shade200
              : color.withValues(alpha: 0.2),
          width: nota.anulado ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                nota.anulado
                    ? Icons.cancel_outlined
                    : (isCredito
                        ? Icons.remove_circle_outline
                        : Icons.add_circle_outline),
                size: 14,
                color: nota.anulado ? Colors.red.shade700 : color,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${nota.tipoLabel} ${nota.codigoGenerado}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: nota.anulado ? Colors.grey.shade600 : color,
                    decoration: nota.anulado ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: nota.anulado
                      ? Border.all(color: Colors.red.shade400, width: 0.8)
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (nota.anulado) ...[
                      Icon(Icons.cancel,
                          size: 8, color: statusColor),
                      const SizedBox(width: 2),
                    ],
                    Text(
                      statusLabel,
                      style: TextStyle(
                          fontSize: 8,
                          color: statusColor,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Banner explicativo cuando está anulada
          if (nota.anulado) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 11, color: Colors.red.shade700),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Documento anulado oficialmente ante SUNAT.',
                      style: TextStyle(
                          fontSize: 9, color: Colors.red.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Total: S/ ${nota.total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade700,
                  decoration: nota.anulado ? TextDecoration.lineThrough : null,
                ),
              ),
              if (nota.sunatHash != null) ...[
                const Spacer(),
                Text('Hash: ${nota.sunatHash!.substring(0, nota.sunatHash!.length.clamp(0, 15))}...',
                    style: TextStyle(fontSize: 8, color: Colors.grey.shade500)),
              ],
            ],
          ),
          if (nota.motivoNota != null) ...[
            const SizedBox(height: 2),
            Text('Motivo: ${nota.motivoNota}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
          ],
          if (nota.enlaceProveedor != null || nota.sunatPdfUrl != null || puedeAnular || esSerieBPendiente) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (nota.sunatPdfUrl != null)
                  GestureDetector(
                    onTap: () => _abrirUrl(nota.sunatPdfUrl!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.picture_as_pdf, size: 11, color: Colors.blue.shade700),
                          const SizedBox(width: 4),
                          Text('Ver PDF', style: TextStyle(fontSize: 9, color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                if (nota.enlaceProveedor != null)
                  GestureDetector(
                    onTap: () => _abrirUrl(nota.enlaceProveedor!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_new, size: 11, color: Colors.grey.shade700),
                          const SizedBox(width: 4),
                          Text('Ver comprobante', style: TextStyle(fontSize: 9, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                if (puedeAnular)
                  GestureDetector(
                    onTap: () => _anularNota(context, nota, sedeId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cancel_outlined, size: 11, color: Colors.red.shade700),
                          const SizedBox(width: 4),
                          Text('Anular',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                if (esSerieBPendiente)
                  Tooltip(
                    message:
                        'Notas con serie BC/BD se anulan vía Resumen Diario. Próximamente.',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline, size: 11, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text('Anular (próx.)',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _abrirUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildComprobanteActions(BuildContext context, Venta v) {
    // Notas activas = ACEPTADAS y no anuladas
    final notasActivas = (v.notasRelacionadas ?? const [])
        .where((n) => (n.sunatStatus == 'ACEPTADO') && !n.anulado)
        .toList();
    final ncs = notasActivas.where((n) => n.tipoComprobante == 'NOTA_CREDITO').toList();
    final nds = notasActivas.where((n) => n.tipoComprobante == 'NOTA_DEBITO').toList();
    final totalNCs = ncs.fold<double>(0, (s, n) => s + n.total);

    // Saldo restante para emitir más NCs (no se puede exceder el total).
    final saldoRestante = v.total - totalNCs;
    final puedeEmitirNC = saldoRestante > 0.01;

    // Anular vía CDB/RC requiere que NO haya NCs aceptadas asociadas (regla SUNAT).
    final puedeAnular = ncs.isEmpty;

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        if (puedeEmitirNC)
          _actionChip(
            icon: Icons.note_add_outlined,
            label: 'Nota Crédito',
            color: Colors.orange,
            badge: ncs.isNotEmpty ? '${ncs.length}' : null,
            onTap: () => _abrirDialogNota(context, v, TipoNota.notaCredito),
          ),
        // ND siempre disponible — múltiples válidas (intereses por períodos, etc.)
        _actionChip(
          icon: Icons.add_circle_outline,
          label: 'Nota Débito',
          color: Colors.purple,
          badge: nds.isNotEmpty ? '${nds.length}' : null,
          onTap: () => _abrirDialogNota(context, v, TipoNota.notaDebito),
        ),
        if (puedeAnular)
          _actionChip(
            icon: Icons.cancel_outlined,
            label: 'Anular',
            color: Colors.red,
            onTap: () => _abrirDialogAnulacion(context, v),
          ),
        _actionChip(
          icon: Icons.local_shipping,
          label: 'Guía Remisión',
          color: Colors.indigo,
          onTap: () => context.push('/empresa/guias-remision/desde-venta/${v.id}'),
        ),
      ],
    );
  }

  /// Renderiza el chip "Devolución Total" cuando el comprobante (y todas sus
  /// notas) ya fueron anulados ante SUNAT y aún no se procesó la reversión.
  /// Va en su propia sección porque [_buildComprobanteActions] está oculto
  /// cuando el comprobante ya está anulado.
  Widget? _buildReversionTotalAction(Venta v) {
    if (v.comprobanteAnulado != true) return null;
    if (_reversion != null) return null;
    final notas = v.notasRelacionadas ?? const [];
    final todasNotasAnuladas =
        notas.every((n) => n.anulado || n.sunatStatus != 'ACEPTADO');
    if (!todasNotasAnuladas) {
      // Mostrar hint de qué falta para habilitar la reversión total.
      final pendientes = notas
          .where((n) => !n.anulado && n.sunatStatus == 'ACEPTADO')
          .map((n) => n.codigoGenerado)
          .toList();
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                size: 14, color: Colors.amber.shade800),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Para procesar la Devolución Total falta anular: ${pendientes.join(", ")}',
                style: TextStyle(
                    fontSize: 11, color: Colors.amber.shade900),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _actionChip(
        icon: Icons.replay_circle_filled_outlined,
        label: 'Devolución Total',
        color: Colors.deepOrange,
        onTap: () => _confirmarReversionTotal(context, v),
      ),
    );
  }

  Widget _buildReversionBanner(ReversionTotal r) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red.shade300, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cancel_outlined, color: Colors.red.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VENTA REVERTIDA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.red.shade800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Comprobante anulado, stock devuelto y caja reversada${r.procesadoEn != null ? ' el ${DateFormatter.formatDateTime(r.procesadoEn!)}' : ''}.',
                  style: TextStyle(
                      fontSize: 10, color: Colors.red.shade900),
                ),
                const SizedBox(height: 2),
                Text('Devolución: ${r.codigo}',
                    style: TextStyle(
                        fontSize: 9,
                        color: Colors.red.shade700,
                        fontFamily: 'monospace')),
                if (r.pendienteRegistroCaja) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '⚠ Egreso de caja pendiente de registro manual',
                      style: TextStyle(
                          fontSize: 9, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarReversionTotal(BuildContext context, Venta v) async {
    if (_procesandoReversion) return;

    // Capturar refs sincrónicas ANTES de cualquier await — el linter no detecta
    // los `if (!mounted)` posteriores y marca warnings espurios sino.
    final messenger = ScaffoldMessenger.of(context);
    final productoListCubit = _tryRead<ProductoListCubit>(context);
    final productoSedeSearchCubit = _tryRead<ProductoSedeSearchCubit>(context);

    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Devolución Total — confirmar',
            style: TextStyle(fontSize: 15)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Esta acción es IRREVERSIBLE y ejecutará:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const _BulletItem('Devolver el stock de todos los items al inventario'),
              const _BulletItem('Registrar EGRESO en tu caja por cada método de pago'),
              const _BulletItem('Cancelar cuotas pendientes (si era venta a crédito)'),
              const _BulletItem('Notificar al cajero original'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Text(
                  'Necesitas tu caja abierta. Si no, solo administradores pueden procesar (queda pendiente de cuadre).',
                  style: TextStyle(fontSize: 10, color: Colors.amber.shade900),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Procesar reversión',
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _procesandoReversion = true);
    final result = await locator<CrearReversionTotalUseCase>()(ventaId: v.id);
    if (!mounted) return;

    setState(() => _procesandoReversion = false);

    if (result is Success<ReversionTotal>) {
      productoListCubit?.invalidateCache();
      productoSedeSearchCubit?.clearCache();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Reversión total ${result.data.codigo} procesada'),
          backgroundColor: Colors.green,
        ),
      );
      _loadVenta();
    } else if (result is Error<ReversionTotal>) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  T? _tryRead<T>(BuildContext ctx) {
    try {
      return ctx.read<T>();
    } catch (_) {
      return null;
    }
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
            if (badge != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _abrirDialogNota(BuildContext context, Venta v, TipoNota tipo) async {
    if (v.comprobanteId == null) return;
    final itemsOrigen = (v.detalles ?? const [])
        .map((d) => CrearNotaItem(
              descripcion: d.descripcion,
              cantidad: d.cantidad,
              valorUnitario: d.precioUnitario,
              precioUnitario: d.precioUnitario,
              tipoAfectacion: d.tipoAfectacion,
              igv: d.igv,
              icbper: d.icbper,
              subtotal: d.subtotal,
              total: d.total,
            ))
        .toList();

    final result = await CrearNotaDialog.show(
      context,
      comprobanteOrigenId: v.comprobanteId!,
      sedeId: v.sedeId,
      tipoNota: tipo,
      comprobanteCodigo: '${v.tipoComprobante ?? ''} ${v.codigoComprobante ?? ''}'.trim(),
      comprobanteTotal: v.total,
      moneda: v.moneda,
      itemsOrigen: itemsOrigen,
    );

    if (result != null && mounted) {
      _loadVenta();
    }
  }

  /// Anula una NC/ND ya emitida. Reusa el AnularComprobanteDialog (CDB para
  /// serie F*, RC bloqueado para serie B* hasta que Syncrofact exponga endpoint).
  Future<void> _anularNota(
    BuildContext context,
    NotaRelacionada nota,
    String sedeId,
  ) async {
    final fechaEmision = nota.fechaEmision ?? DateTime.now();
    final result = await AnularComprobanteDialog.show(
      context,
      comprobanteId: nota.id,
      comprobanteCodigo: nota.codigoGenerado,
      tipoComprobante: nota.tipoComprobante,
      fechaEmision: fechaEmision,
      sedeId: sedeId,
      total: nota.total,
    );
    if (result != null && mounted) {
      _loadVenta();
    }
  }

  Future<void> _abrirDialogAnulacion(BuildContext context, Venta v) async {
    if (v.comprobanteId == null) return;

    // Soportado:
    //  - FACTURA / NC-FC* / ND-FD* → Comunicación de Baja (RA), 7 días.
    //  - BOLETA                    → Resumen Diario (RC), 3 días.
    // No soportado aún: NC con serie BC*, ND con serie BD* (notas sobre boleta).
    final tipo = v.tipoComprobante ?? '';
    final codigo = v.codigoComprobante ?? '';
    final esNotaSobreBoleta =
        (tipo == 'NOTA_CREDITO' || tipo == 'NOTA_DEBITO') &&
        codigo.startsWith('B');
    if (esNotaSobreBoleta) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Notas con serie BC/BD aún no se pueden anular desde el app. Próximamente.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await AnularComprobanteDialog.show(
      context,
      comprobanteId: v.comprobanteId!,
      comprobanteCodigo: codigo,
      tipoComprobante: tipo,
      fechaEmision: v.fechaVenta,
      sedeId: v.sedeId,
      total: v.total,
      moneda: v.moneda,
    );

    if (result != null && mounted) {
      _loadVenta();
    }
  }

  Widget _buildSunatStatusRow(Venta v) {
    final status = v.comprobanteSunatStatus ?? 'PENDIENTE';
    Color chipColor;
    String label;
    switch (status) {
      case 'ACEPTADO':
        chipColor = Colors.green;
        label = 'SUNAT: Aceptado';
        break;
      case 'RECHAZADO':
        chipColor = Colors.red;
        label = 'SUNAT: Rechazado';
        break;
      case 'ERROR_COMUNICACION':
        chipColor = Colors.orange;
        label = 'SUNAT: Error conexión';
        break;
      case 'PROCESANDO':
        chipColor = Colors.blue;
        label = 'SUNAT: Procesando';
        break;
      default:
        chipColor = Colors.amber.shade700;
        label = 'SUNAT: Pendiente';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: chipColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(label, style: TextStyle(fontSize: 10, color: chipColor, fontWeight: FontWeight.w600)),
            ),
            const Spacer(),
            if (status == 'PENDIENTE' || status == 'ERROR_COMUNICACION')
              GestureDetector(
                onTap: () => _reenviarASunat(v.comprobanteId!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text('Reintentar', style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
        if (status == 'RECHAZADO' && v.comprobanteErrorProveedor != null) ...[
          const SizedBox(height: 4),
          Text(v.comprobanteErrorProveedor!, style: TextStyle(fontSize: 10, color: Colors.red.shade600)),
        ],
        if (v.comprobanteSunatHash != null) ...[
          const SizedBox(height: 4),
          _buildDetailRow(Icons.tag, 'Hash', v.comprobanteSunatHash!),
        ],
      ],
    );
  }

  Future<void> _reenviarASunat(String comprobanteId) async {
    setState(() => _loading = true);
    try {
      final datasource = locator<VentaRemoteDataSource>();
      await datasource.reenviarASunat(comprobanteId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comprobante reenviado a SUNAT')),
        );
        // Recargar venta
        _loadVenta();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
        _showAnularVentaDialog(context);
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
                              // Ley 28194 (paridad backend): en ventas sobre
                              // el umbral, los pagos digitales exigen N° de
                              // operación — validar acá evita un 400 seguro.
                              final umbralLey =
                                  _venta!.moneda == 'USD' ? 500 : 2000;
                              if (metodoActual != 'EFECTIVO' &&
                                  _venta!.total >= umbralLey &&
                                  refCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Esta venta supera el umbral de bancarización: ingresa el N° de operación'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              Navigator.pop(ctx);
                              final data = <String, dynamic>{
                                'metodoPago': metodoActual,
                                'monto': monto,
                                if (refCtrl.text.isNotEmpty) 'referencia': refCtrl.text,
                              };
                              _ultimoPagoData = data;
                              context.read<VentaFormCubit>().procesarPago(
                                _venta!.id,
                                data,
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

  void _showAnularVentaDialog(BuildContext context) {
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

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3, right: 4),
            child: Icon(Icons.fiber_manual_record, size: 6),
          ),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

/// Header de columna para la tabla de items: uppercase compacto,
/// tipografía bold y gris. Mismo estilo que el detalle de cotización.
class _Th extends StatelessWidget {
  final String text;
  const _Th(this.text);

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

/// Dibuja el conector └─▶ para sub-líneas indentadas debajo de un
/// item. Mismo lenguaje visual que el FlujoDocumentosWidget para
/// mantener coherencia. `isLast=true` no extiende la vertical hacia
/// abajo (no hay más hijos).
class _ConnectorPainter extends CustomPainter {
  final Color color;
  final bool isLast;

  _ConnectorPainter({required this.color, required this.isLast});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Vertical desde arriba al centro.
    canvas.drawLine(
      const Offset(6, 0),
      Offset(6, size.height / 2),
      paint,
    );

    // Horizontal desde la vertical hasta la punta de la flecha.
    canvas.drawLine(
      Offset(6, size.height / 2),
      Offset(size.width - 4, size.height / 2),
      paint,
    );

    // Punta de flecha ▶ rellena.
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final arrowPath = Path()
      ..moveTo(size.width - 4, size.height / 2 - 3)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width - 4, size.height / 2 + 3)
      ..close();
    canvas.drawPath(arrowPath, arrowPaint);

    // Si no es el último, continuar la vertical hacia abajo para
    // conectar con el siguiente hijo.
    if (!isLast) {
      canvas.drawLine(
        Offset(6, size.height / 2),
        Offset(6, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter oldDelegate) =>
      color != oldDelegate.color || isLast != oldDelegate.isLast;
}

/// Chip pequeño para mostrar motivo / estado / tipo en la sub-línea de
/// devolución. Color heredado del row (orange/indigo).
class _DevolucionChip extends StatelessWidget {
  final String label;
  final Color color;
  const _DevolucionChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
