import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:printing/printing.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
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
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_filter_chip.dart';
import '../../../../core/widgets/custom_navigation_menu.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../../auth/presentation/widgets/custom_text.dart'
    show CustomText, FieldType;
import '../../../../core/widgets/producto_sede_selector/producto_sede_search_cubit.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_cubit.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_state.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import 'package:syncronize/features/impresoras/domain/services/impresoras_manager.dart';
import '../../../cuentas_por_cobrar/domain/usecases/registrar_abono_cuenta_cobrar_usecase.dart';
import '../../../cuentas_por_cobrar/presentation/widgets/abono_cliente_sheet.dart';
import '../../../servicio/presentation/widgets/bluetooth_printer_sheet.dart';
import '../services/recibo_cuota_esc_pos_generator.dart';
import '../../../sorteo/presentation/services/rotulo_envio_pdf_generator.dart';
import '../../../producto/presentation/bloc/producto_list/producto_list_cubit.dart';
import '../../data/datasources/venta_remote_datasource.dart';
import '../../domain/entities/cuota_venta.dart';
import '../../domain/entities/pago_venta.dart';
import '../../domain/entities/reversion_total.dart';
import '../../domain/entities/venta.dart';
import '../../domain/usecases/get_venta_usecase.dart';
import '../../domain/usecases/reversion_total_usecase.dart';
import '../bloc/venta_form/venta_form_cubit.dart';
import '../bloc/venta_form/venta_form_state.dart';
import '../widgets/flujo_documentos_widget.dart';
import '../widgets/venta_envio_sheet.dart';
import '../../../delivery/domain/entities/delivery_local.dart';
import '../../../delivery/domain/repositories/delivery_repository.dart';
import '../../../delivery/presentation/widgets/solicitar_delivery_sheet.dart';
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

  /// Foto de `cuotaId -> montoPagado` tomada JUSTO ANTES de enviar un pago.
  /// El backend reparte el monto entre las cuotas pendientes en orden (un
  /// pago puede cerrar varias), así que la única forma exacta de saber a
  /// qué cuotas se aplicó es diffear contra la venta que devuelve.
  Map<String, double>? _cuotasAntesPago;

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

  // ── Venta con envío (rótulo de agencia) ─────────────────────────────

  /// Sheet editable (prellenado en cascada: envío de ESTA venta > último
  /// envío del cliente > snapshot del cliente) → upsert del envío (marca
  /// conEnvio) → imprime el rótulo si el usuario tocó "Guardar e imprimir".
  Future<void> _gestionarEnvio() async {
    final venta = _venta;
    if (venta == null) return;

    // La agencia/destino del cliente suele repetirse entre ventas: si esta
    // venta aún no tiene envío, prellenar con el último del cliente para
    // que el cajero solo corrobore e imprima (best-effort, no bloquea).
    VentaEnvioData? ultimoEnvio;
    if (venta.envio == null && venta.clienteId != null) {
      final r = await locator<VentaRepository>()
          .ultimoEnvioCliente(venta.clienteId!);
      if (r is Success<VentaEnvioData?>) ultimoEnvio = r.data;
    }
    if (!mounted) return;

    final datos = await showVentaEnvioSheet(
      context: context,
      venta: venta,
      ultimoEnvioCliente: ultimoEnvio,
    );
    if (datos == null || !mounted) return;

    final res = await locator<VentaRepository>()
        .upsertEnvio(ventaId: venta.id, data: datos.toJson());
    if (!mounted) return;
    if (res is Error<void>) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.message, style: const TextStyle(fontSize: 12)),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    await _loadVenta();
    if (!mounted) return;

    if (datos.imprimir) await _imprimirRotuloVenta(datos);
  }

  Future<void> _imprimirRotuloVenta(VentaEnvioFormData datos) async {
    final venta = _venta;
    if (venta == null) return;
    final ctxState = context.read<EmpresaContextCubit>().state;
    final empresa =
        ctxState is EmpresaContextLoaded ? ctxState.context.empresa : null;

    // Logo como marca de agua (best-effort).
    Uint8List? logoBytes;
    final logoUrl = empresa?.logo;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      try {
        final r = await http
            .get(Uri.parse(logoUrl))
            .timeout(const Duration(seconds: 5));
        if (r.statusCode == 200) logoBytes = r.bodyBytes;
      } catch (_) {}
    }

    // Remitente = NOMBRE COMERCIAL (la marca que ve el cliente), no la
    // razón social. Config efectiva sede > empresa; fallback al nombre
    // legal si no hay configuración (best-effort, no bloquea el rótulo).
    String? nombreComercial;
    try {
      final config = await locator<VentaRemoteDataSource>()
          .getConfiguracionSunat(sedeId: venta.sedeId);
      nombreComercial = config['nombreComercial'] as String?;
    } catch (_) {}

    final bytes = await RotuloEnvioPdfGenerator.generate(
      rotulos: [
        DatosRotulo(
          nombre: datos.destinatarioNombre,
          dni: datos.destinatarioDni,
          celular: datos.destinatarioCelular,
          agenciaNombre: datos.agenciaNombre,
          destinoDepartamento: datos.destinoDepartamento,
          destinoProvincia: datos.destinoProvincia,
          agenciaDireccion: datos.agenciaDireccion,
        ),
      ],
      remitenteNombre: nombreComercial ?? empresa?.nombre ?? '',
      remitenteTelefono: empresa?.telefono,
      logoBytes: logoBytes,
    );
    final impreso = await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'rotulo_envio_${venta.codigo}.pdf',
    );
    if (impreso) {
      await locator<VentaRepository>().marcarRotuloEnvioImpreso(venta.id);
      if (mounted) await _loadVenta();
    }
  }

  // ── Delivery local (repartidor propio) ──────────────────────────────

  /// Publica el delivery de una venta PAGADA al 100%: dirección + tarifa
  /// (vacía = la default de la sede) → el backend lo pone en el pool y
  /// notifica a los repartidores por push. El repartidor cobra SOLO la
  /// tarifa al entregar — el producto ya está pagado.
  Future<void> _solicitarDeliveryLocal() async {
    final venta = _venta;
    if (venta == null) return;
    final ctxState = context.read<EmpresaContextCubit>().state;
    final empresaId =
        ctxState is EmpresaContextLoaded ? ctxState.context.empresa.id : '';
    if (empresaId.isEmpty) return;

    final datos = await showSolicitarDeliverySheet(
      context: context,
      ventaCodigo: venta.codigo,
      // Geocoder propio: búsqueda local + direcciones recientes del cliente.
      empresaId: empresaId,
      telefonoCliente: venta.telefonoCliente,
    );
    if (datos == null || !mounted) return;

    final res = await locator<DeliveryRepository>().solicitar({
      'empresaId': empresaId,
      'ventaId': venta.id,
      ...datos.toJson(),
    });
    if (!mounted) return;
    if (res is Success<DeliveryLocal>) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          '🛵 Delivery publicado (tarifa S/ '
          '${res.data.costoDelivery.toStringAsFixed(2)}) — los repartidores '
          'fueron notificados.',
          style: const TextStyle(fontSize: 12),
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ));
    } else if (res is Error<DeliveryLocal>) {
      // 409 = ya tiene delivery; 400 = venta no pagada. El backend manda
      // el mensaje exacto — mostrarlo siempre (nada de fallos silenciosos).
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.message, style: const TextStyle(fontSize: 12)),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  /// Edita la dirección del delivery (equivocada o el cliente pidió otro
  /// punto): reusa el sheet en modo edición con los datos actuales; al
  /// guardar, el backend avisa al repartidor si ya tomó el pedido.
  Future<void> _editarDireccionDelivery(VentaDeliveryData d) async {
    final venta = _venta;
    if (venta == null || d.id == null) return;
    final ctxState = context.read<EmpresaContextCubit>().state;
    final empresaId =
        ctxState is EmpresaContextLoaded ? ctxState.context.empresa.id : '';
    if (empresaId.isEmpty) return;

    final datos = await showSolicitarDeliverySheet(
      context: context,
      ventaCodigo: venta.codigo,
      empresaId: empresaId,
      telefonoCliente: venta.telefonoCliente,
      esEdicion: true,
      initDireccion: d.direccion,
      initReferencia: d.referencia,
      initDistrito: d.distrito,
      initDestino:
          (d.lat != null && d.lon != null) ? LatLng(d.lat!, d.lon!) : null,
    );
    if (datos == null || !mounted) return;

    final res = await locator<DeliveryRepository>().actualizarDireccion(
      d.id!,
      {'empresaId': empresaId, ...datos.toJson()},
    );
    if (!mounted) return;
    if (res is Success<DeliveryLocal>) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('📍 Dirección de entrega actualizada',
            style: TextStyle(fontSize: 12)),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ));
      _loadVenta(); // refresca la sección con la dirección nueva
    } else if (res is Error<DeliveryLocal>) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.message, style: const TextStyle(fontSize: 12)),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
      ));
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
            // Datos del pago ANTES de limpiarlos: el recibo los necesita.
            final pagoImpreso = _ultimoPagoData;
            final antes = _cuotasAntesPago;
            _ultimoPagoData = null;
            _cuotasAntesPago = null;
            setState(() => _venta = state.venta);

            final aplicaciones =
                _cuotasAplicadas(antes, state.venta.cuotas ?? const []);
            if (aplicaciones.isNotEmpty && pagoImpreso != null) {
              // Cobranza de crédito: el cliente se lleva su constancia.
              _ofrecerReciboCuota(state.venta, aplicaciones, pagoImpreso);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pago registrado')),
              );
            }
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
                  // Rótulo de envío: disponible SIEMPRE (una venta por
                  // teléfono puede marcarse con envío después de
                  // cobrada). Color según estado: tenue = sin envío,
                  // blanco = con envío, verde = rótulo ya impreso.
                  if (_venta != null)
                    IconButton(
                      tooltip: _venta!.envio?.rotuloImpreso == true
                          ? 'Rótulo impreso — reimprimir'
                          : _venta!.conEnvio
                              ? 'Rótulo de envío'
                              : 'Marcar como venta con envío',
                      icon: Icon(
                        Icons.local_shipping_outlined,
                        size: 21,
                        color: _venta!.envio?.rotuloImpreso == true
                            ? Colors.greenAccent
                            : _venta!.conEnvio
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.45),
                      ),
                      onPressed: _gestionarEnvio,
                    ),
                  // Delivery local (repartidor propio/freelance): al costado
                  // del envío por agencia. Encendido SOLO con la venta
                  // pagada al 100% — el repartidor jamás cobra el producto.
                  if (_venta != null)
                    IconButton(
                      tooltip: _venta!.estado == EstadoVenta.pagadaCompleta
                          ? 'Solicitar delivery local'
                          : 'Delivery local (requiere venta pagada al 100%)',
                      icon: Icon(
                        Icons.delivery_dining,
                        size: 22,
                        color: _venta!.estado == EstadoVenta.pagadaCompleta
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.45),
                      ),
                      onPressed: () {
                        if (_venta!.estado != EstadoVenta.pagadaCompleta) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text(
                              'El delivery local requiere la venta pagada al 100%',
                              style: TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.orange.shade800,
                            behavior: SnackBarBehavior.floating,
                          ));
                          return;
                        }
                        _solicitarDeliveryLocal();
                      },
                    ),
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
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        children: [
          _buildHeaderSection(v),
          const SizedBox(height: 12),
          _buildItemsSection(v),
          const SizedBox(height: 12),
          _buildPagoSection(v),
          if (v.envio != null) ...[
            const SizedBox(height: 12),
            _buildEnvioSection(v.envio!),
          ],
          if (v.delivery != null) ...[
            const SizedBox(height: 12),
            _buildDeliverySection(v.delivery!),
          ],
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
      borderRadius: BorderRadius.circular(6),
      gradient: AppGradients.sinfondo,
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.bluechip,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.point_of_sale,
                      color: AppColors.blue1, size: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppSubtitle(v.codigo, fontSize: 11, font: AppFont.amazonEmberMedium,),
                ),
                VentaEstadoChip(estado: v.estado),
                // Menú de acciones del comprobante (NC/ND/Anular/Guía).
                // Se ubica junto al chip de estado para mantener limpia la
                // tarjeta: en el cuerpo solo quedan los chips de SUNAT.
                Builder(
                  builder: (context) {
                    final items = _buildComprobanteMenuItems(context, v);
                    if (items.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: CustomNavigationMenu(
                        items: items,
                        triggerIcon: Icons.more_vert,
                        triggerIconSize: 18,
                        triggerIconColor: AppColors.blue1,
                        tooltip: 'Acciones del comprobante',
                        menuWidth: 200,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 5),
            // Fecha y Sede en una sola fila, a extremos opuestos del header:
            // fecha a la izquierda, sede a la derecha.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: _buildDetailRowCompact(Icons.calendar_today,
                      DateFormatter.formatDateTime(v.fechaVenta)),
                ),
                if (v.sedeNombre != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: _buildDetailRowCompact(
                        Icons.store_outlined, v.sedeNombre!,
                        alignEnd: true),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
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
            const SizedBox(height: 2),
            if (v.codigoComprobante != null) ...[
              _buildDetailRow(
                Icons.receipt_long,
                'Comprobante',
                '${v.tipoComprobante} ${v.codigoComprobante}',
                // Cuando está anulado: texto tachado en rojo + chip ANULADO,
                // para dejar claro de un vistazo que la boleta/factura se anuló.
                valueColor: v.comprobanteAnulado == true ? Colors.red : null,
                strikethrough: v.comprobanteAnulado == true,
                trailing: v.comprobanteAnulado == true
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('ANULADO',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.w700)),
                      )
                    : null,
              ),
              const SizedBox(height: 4),
              // Estado SUNAT + accesos (Ver PDF SUNAT / Ver comprobante) van
              // juntos en una sola fila dentro de _buildSunatStatusRow.
              _buildSunatStatusRow(v),
              // Acciones del comprobante (NC/ND/Anular/Guía) ahora viven en
              // el menú ⋮ junto al chip de estado (ver _buildHeaderSection).
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
            // ── CLIENTE (fusionado en la misma card que el header) ──
            const SizedBox(height: 10),
            Divider(
                height: 1, color: AppColors.blueborder.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            _buildSectionHeader(Icons.person_outline, 'CLIENTE'),
            // const SizedBox(height: 8),
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

  /// Datos del envío por agencia — para revisar destinatario/agencia/destino
  /// después de registrarlo, igual que la sección de delivery.
  Widget _buildEnvioSection(VentaEnvioData e) {
    final destino = [e.destinoDepartamento, e.destinoProvincia]
        .where((s) => s != null && s.trim().isNotEmpty)
        .join(' / ');
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.local_shipping_outlined, 'ENVÍO'),
            _buildDetailRow(Icons.flag_outlined, 'Rótulo',
                e.rotuloImpreso ? 'Impreso' : 'Pendiente de imprimir'),
            if (e.destinatarioNombre.trim().isNotEmpty)
              _buildDetailRow(
                  Icons.person_outline, 'Destinatario', e.destinatarioNombre),
            if (e.destinatarioDni != null &&
                e.destinatarioDni!.trim().isNotEmpty)
              _buildDetailRow(
                  Icons.badge_outlined, 'DNI', e.destinatarioDni!),
            if (e.destinatarioCelular != null &&
                e.destinatarioCelular!.trim().isNotEmpty)
              _buildDetailRow(
                  Icons.phone_outlined, 'Celular', e.destinatarioCelular!),
            if (e.agenciaNombre != null && e.agenciaNombre!.trim().isNotEmpty)
              _buildDetailRow(
                  Icons.storefront_outlined, 'Agencia', e.agenciaNombre!),
            if (e.agenciaDireccion != null &&
                e.agenciaDireccion!.trim().isNotEmpty)
              _buildDetailRow(Icons.location_on_outlined, 'Sede agencia',
                  e.agenciaDireccion!),
            if (destino.isNotEmpty)
              _buildDetailRow(Icons.map_outlined, 'Destino', destino),
          ],
        ),
      ),
    );
  }

  /// Datos del delivery publicado — para revisar la dirección/tarifa
  /// después de solicitarlo (antes solo se veían al momento de publicar).
  Widget _buildDeliverySection(VentaDeliveryData d) {
    final estados = {
      'SOLICITADO': d.esInterno
          ? 'Por salir (interno)'
          : 'Publicado — esperando repartidor',
      'TOMADO': 'Tomado por repartidor',
      'EN_CAMINO': 'En camino',
      'ENTREGADO': 'Entregado',
      'CANCELADO': 'Cancelado',
    };
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildSectionHeader(
                        Icons.delivery_dining, 'DELIVERY')),
                // Compartir la ubicación por WhatsApp (instancia de la
                // empresa) a cualquier celular — sin salir del app.
                if (d.id != null)
                  GestureDetector(
                    onTap: () => _compartirUbicacionDelivery(d),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.share_location,
                              size: 15, color: Colors.teal.shade700),
                          const SizedBox(width: 3),
                          Text('Compartir',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.teal.shade700)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                // Corregir dirección (equivocada o el cliente pidió otra).
                // El backend avisa al repartidor si ya tomó el pedido.
                if (d.editable)
                  GestureDetector(
                    onTap: () => _editarDireccionDelivery(d),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_location_alt_outlined,
                              size: 15, color: AppColors.blue1),
                          const SizedBox(width: 3),
                          Text('Editar dirección',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.blue1)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            _buildDetailRow(Icons.flag_outlined, 'Estado',
                estados[d.estado] ?? d.estado),
            _buildDetailRow(
                Icons.location_on_outlined, 'Direccion', d.direccion),
            if (d.referencia != null && d.referencia!.trim().isNotEmpty)
              _buildDetailRow(
                  Icons.push_pin_outlined, 'Referencia', d.referencia!),
            if (d.distrito != null && d.distrito!.trim().isNotEmpty)
              _buildDetailRow(Icons.map_outlined, 'Distrito', d.distrito!),
            if (d.destinatarioNombre != null &&
                d.destinatarioNombre!.trim().isNotEmpty)
              _buildDetailRow(Icons.person_outline, 'Recibe',
                  d.destinatarioNombre!),
            if (d.destinatarioCelular != null &&
                d.destinatarioCelular!.trim().isNotEmpty)
              _buildDetailRow(Icons.phone_outlined, 'Celular',
                  d.destinatarioCelular!),
            _buildDetailRow(
                Icons.payments_outlined,
                d.esInterno ? 'Tarifa delivery' : 'Tarifa repartidor',
                'S/ ${d.costoDelivery.toStringAsFixed(2)}'),
            if (d.esInterno)
              _buildDetailRow(
                  Icons.badge_outlined,
                  'Interno',
                  (d.encargadoInterno?.trim().isNotEmpty ?? false)
                      ? 'Lo lleva ${d.encargadoInterno}'
                      : 'Lo lleva un empleado de la empresa'),
            // Interno: el staff avanza los estados (sin pool, sin PIN).
            if (d.esInterno && d.id != null &&
                (d.estado == 'SOLICITADO' || d.estado == 'EN_CAMINO')) ...[
              const SizedBox(height: 8),
              CustomButton(
                height: 30,
                borderWidth: 0.6,
                enableShadows: false,
                text: d.estado == 'SOLICITADO'
                    ? 'Marcar EN CAMINO (salió el empleado)'
                    : 'Marcar ENTREGADO',
                borderColor: d.estado == 'SOLICITADO'
                    ? Colors.teal
                    : Colors.green.shade700,
                textColor: d.estado == 'SOLICITADO'
                    ? Colors.teal.shade700
                    : Colors.green.shade700,
                icon: Icon(
                    d.estado == 'SOLICITADO'
                        ? Icons.two_wheeler_outlined
                        : Icons.check_circle_outline,
                    size: 14,
                    color: d.estado == 'SOLICITADO'
                        ? Colors.teal.shade700
                        : Colors.green.shade700),
                onPressed: () => _avanzarDeliveryInterno(d),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Comparte la ubicación de entrega por WhatsApp a cualquier celular —
  /// sale del WhatsApp de la empresa, sin salir del app. Pin nativo
  /// (tocable) + texto con dirección/referencia/link de Maps.
  Future<void> _compartirUbicacionDelivery(VentaDeliveryData d) async {
    final ctxState = context.read<EmpresaContextCubit>().state;
    final empresaId =
        ctxState is EmpresaContextLoaded ? ctxState.context.empresa.id : '';
    if (empresaId.isEmpty || d.id == null) return;

    final celularCtrl = TextEditingController();
    final enviar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StyledDialog(
        accentColor: Colors.teal,
        icon: Icons.share_location,
        titulo: 'Compartir ubicación',
        content: [
          Text(
            'Se envía por el WhatsApp de la empresa: pin de ubicación + '
            'dirección y referencia. Ideal para el empleado que reparte o '
            'un familiar del cliente.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          CustomText(
            controller: celularCtrl,
            label: 'Celular destino',
            hintText: 'Ej: 999888777',
            borderColor: Colors.teal,
            fieldType: FieldType.number,
            maxLength: 9,
          ),
        ],
        actions: [
          Expanded(
            child: CustomButton(
              text: 'Cancelar',
              borderColor: Colors.grey.shade400,
              textColor: Colors.grey.shade700,
              onPressed: () => Navigator.pop(ctx, false),
            ),
          ),
          Expanded(
            child: CustomButton(
              text: 'Enviar',
              backgroundColor: Colors.teal,
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ),
        ],
      ),
    );
    // No dispose inmediato tras el dialog (gotcha TextController).
    final celular = celularCtrl.text.trim();
    if (enviar != true || !mounted) return;
    if (celular.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Ingresa un celular válido de 9 dígitos',
            style: TextStyle(fontSize: 12)),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final res = await locator<DeliveryRepository>()
        .compartirUbicacion(d.id!, empresaId, celular);
    if (!mounted) return;
    if (res is Success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('📍 Ubicación enviada por WhatsApp al $celular',
            style: const TextStyle(fontSize: 12)),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ));
    } else if (res is Error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.message, style: const TextStyle(fontSize: 12)),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  /// Delivery interno: el staff avanza SOLICITADO → EN_CAMINO → ENTREGADO
  /// (sin PIN — lo lleva personal de confianza). El cliente recibe su
  /// WhatsApp en cada paso igual que con repartidor.
  Future<void> _avanzarDeliveryInterno(VentaDeliveryData d) async {
    final ctxState = context.read<EmpresaContextCubit>().state;
    final empresaId =
        ctxState is EmpresaContextLoaded ? ctxState.context.empresa.id : '';
    if (empresaId.isEmpty || d.id == null) return;

    final repo = locator<DeliveryRepository>();
    final res = d.estado == 'SOLICITADO'
        ? await repo.enCaminoInterno(d.id!, empresaId)
        : await repo.entregadoInterno(d.id!, empresaId);
    if (!mounted) return;
    if (res is Success<DeliveryLocal>) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          d.estado == 'SOLICITADO'
              ? '🛵 En camino — el cliente fue avisado por WhatsApp'
              : '✅ Entregado — ¡delivery completado!',
          style: const TextStyle(fontSize: 12),
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ));
      _loadVenta();
    } else if (res is Error<DeliveryLocal>) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.message, style: const TextStyle(fontSize: 12)),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Widget _buildItemsSection(Venta v) {
    final detalles = v.detalles ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            Icons.shopping_cart_outlined, 'ITEMS (${detalles.length})'),
        // const SizedBox(height: 3),
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
                    vertical: 4, horizontal: 8),
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
                                // Componente vendido como parte de un combo
                                // expandido — mismo dato con el que el ticket
                                // y el PDF agrupan (** COMBO: X **).
                                if (detalles[i].origenComboId != null) ...[
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.inventory_2_outlined,
                                          size: 8,
                                          color: Colors.deepPurple.shade700,
                                        ),
                                        const SizedBox(width: 3),
                                        Flexible(
                                          child: Text(
                                            'COMBO: ${(detalles[i].origenComboNombre ?? 'Combo').toUpperCase()}',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  Colors.deepPurple.shade700,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
                  children: _buildFooterTotales(v),
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
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blue1,
                        letterSpacing: 0.5,
                      ),
                    ),
                    // Text(
                    //   '${v.moneda} ${v.total.toStringAsFixed(2)}',
                    //   style: TextStyle(
                    //     fontSize: 11,
                    //     fontWeight: FontWeight.w700,
                    //     color: AppColors.blue1,
                    //   ),
                    // ),
                    Text(
                      'S/${v.total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue1
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Totales del footer, uniformizados con el ticket/PDF/factura (espejo
  /// SUNAT): desglose por operación cuando hay comprobante electrónico, y
  /// Subtotal simple cuando no. Op. Gratuitas solo si hay regalos convertidos;
  /// Descuento muestra el FISCAL (las líneas al 100% ya son gratuitas).
  List<Widget> _buildFooterTotales(Venta v) {
    final tieneDesglose = v.comprobanteGravada != null;
    final moneda = v.moneda;

    if (!tieneDesglose) {
      return [
        _buildFooterRow('Subtotal', '$moneda ${v.subtotal.toStringAsFixed(2)}'),
        if (v.descuento > 0)
          _buildFooterRow(
            'Descuento',
            '-$moneda ${v.descuento.toStringAsFixed(2)}',
            color: Colors.red.shade600,
          ),
        _buildFooterRow(
          _getNombreImpuesto(),
          '$moneda ${v.impuestos.toStringAsFixed(2)}',
        ),
      ];
    }

    final gratuitas = v.comprobanteGratuitas ?? 0;
    final icbper = v.comprobanteIcbper ?? 0;
    final descuentoConvertido = (v.detalles ?? []).fold<double>(
      0,
      (s, d) => s + ((d.subtotal == 0 && d.descuento > 0) ? d.descuento : 0),
    );
    final descuentoFiscal =
        (v.descuento - descuentoConvertido).clamp(0, double.infinity);

    return [
      _buildFooterRow(
        'Op. Gravada',
        // '$moneda ${(v.comprobanteGravada ?? 0).toStringAsFixed(2)}',
        'S/ ${(v.comprobanteGravada ?? 0).toStringAsFixed(2)}',
      ),
      _buildFooterRow(
        'Op. Exonerada',
        // '$moneda ${(v.comprobanteExonerada ?? 0).toStringAsFixed(2)}',
        'S/ ${(v.comprobanteExonerada ?? 0).toStringAsFixed(2)}',
      ),
      _buildFooterRow(
        'Op. Inafecta',
        // '$moneda ${(v.comprobanteInafecta ?? 0).toStringAsFixed(2)}',
        'S/ ${(v.comprobanteInafecta ?? 0).toStringAsFixed(2)}',
      ),
      if (gratuitas > 0)
        _buildFooterRow(
          'Op. Gratuitas',
          // '$moneda ${gratuitas.toStringAsFixed(2)}',
          'S/ ${gratuitas.toStringAsFixed(2)}',
          color: Colors.deepPurple.shade600,
        ),
      if (descuentoFiscal > 0)
        _buildFooterRow(
          'Descuento',
          // '-$moneda ${descuentoFiscal.toStringAsFixed(2)}',
          '-S /${descuentoFiscal.toStringAsFixed(2)}',
          color: Colors.red.shade600,
        ),
      _buildFooterRow(
        _getNombreImpuesto(),
        // '$moneda ${(v.comprobanteIgv ?? v.impuestos).toStringAsFixed(2)}',
        'S/ ${(v.comprobanteIgv ?? v.impuestos).toStringAsFixed(2)}',
      ),
      if (icbper > 0)
        // _buildFooterRow('ICBPER', '$moneda ${icbper.toStringAsFixed(2)}'),
        _buildFooterRow('ICBPER', 'S/ ${icbper.toStringAsFixed(2)}'),
    ];
  }

  /// Fila del footer de la tabla de items (subtotal, descuento, IGV).
  /// Alineada a la derecha con label + monto en ancho fijo.
  Widget _buildFooterRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
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
            width: 90,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color ?? Colors.grey.shade700,
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
    // Adelantos de COTIZACIÓN: el cliente los pagó ONLINE (Yape/Plin desde
    // el marketplace) antes de esta venta — el dinero entró a Tesorería en
    // su momento. Se muestran como pagos previos con su contexto (quedan
    // fuera del historial de hoy, igual que los adelantos de OS).
    final adelantosCotizacion = (v.pagos ?? [])
        .where((p) => p.referencia?.startsWith('Adelanto cotización') ?? false)
        .toList();
    // Adelantos previos de órdenes de servicio cobradas en esta venta.
    // NO son PagoVenta (entraron a caja con su propio movimiento
    // ADELANTO_SERVICIO cuando se recibieron), pero sin mostrarlos aquí
    // se pierde la traza de cómo se completó el costo del servicio:
    // costo total = adelantos previos + total de esta venta.
    final adelantosServicio = (v.detalles ?? [])
        .where((d) => d.esOrdenServicio && (d.ordenAdelanto ?? 0) > 0)
        .toList();
    return GradientContainer(
      gradient: AppGradients.sinfondo,
      borderColor: AppColors.blueborder,
      borderRadius: BorderRadius.all(Radius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.payment, 'PAGO'),
            const SizedBox(height: 5),
            // Resumen
            if (v.metodoPagoDisplay != null)
              _buildDetailRow(
                  Icons.credit_card, 'Metodo', v.metodoPagoDisplay!),
            if (v.montoRecibido != null)
              _buildDetailRow(Icons.attach_money, 'Recibido',
                  // '${v.moneda} ${v.montoRecibido!.toStringAsFixed(2)}'),
                  'S/ ${v.montoRecibido!.toStringAsFixed(2)}'),
            if (v.montoCambio != null && v.montoCambio! > 0)
              _buildDetailRow(Icons.change_circle_outlined, 'Cambio',
                  // '${v.moneda} ${v.montoCambio!.toStringAsFixed(2)}'),
                  'S/ ${v.montoCambio!.toStringAsFixed(2)}'),
            if (v.esCredito) ...[
              _buildDetailRow(Icons.schedule, 'Tipo', 'Venta a Credito'),
              if (v.plazoCredito != null)
                _buildDetailRow(
                    Icons.timer, 'Plazo', '${v.plazoCredito} dias'),
            ],
            _buildDetailRow(Icons.account_balance_wallet, 'Pagado',
                // '${v.moneda} ${v.totalPagado.toStringAsFixed(2)}'),
                'S/ ${v.totalPagado.toStringAsFixed(2)}'),
            if (v.saldoPendiente > 0)
              _buildDetailRow(Icons.warning_amber, 'Pendiente',
                  // '${v.moneda} ${v.saldoPendiente.toStringAsFixed(2)}'),
                  'S/ ${v.saldoPendiente.toStringAsFixed(2)}'),
            // Pagos previos de COTIZACIÓN: el cliente pagó online (Yape/
            // Plin) desde su cotización del marketplace; el dinero ya está
            // en Tesorería desde esa fecha.
            if (adelantosCotizacion.isNotEmpty) ...[
              const SizedBox(height: 7),
              Divider(
                  height: 1,
                  color: AppColors.blueborder.withValues(alpha: 0.5)),
              const SizedBox(height: 7),
              Row(
                children: [
                  Icon(Icons.phone_android, size: 14, color: AppColors.blue1),
                  const SizedBox(width: 6),
                  Text(
                    'PAGOS PREVIOS (COTIZACIÓN)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue1,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ...adelantosCotizacion.map((pago) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${pago.metodoPago.label} (online) · ${pago.referencia}',
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Pagado por el cliente desde su cotización — '
                              '${DateFormatter.formatDateTime(pago.fechaPago)} · en Tesorería',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${v.moneda} ${pago.monto.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.green),
                      ),
                    ],
                  ),
                );
              }),
            ],
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
              const SizedBox(height: 7),
              Divider(
                  height: 1,
                  color: AppColors.blueborder.withValues(alpha: 0.5)),
              const SizedBox(height: 7),
              Row(
                children: [
                  Icon(Icons.history, size: 14, color: AppColors.blue1),
                  const SizedBox(width: 6),
                  // Text(
                  //   'HISTORIAL',
                  //   style: TextStyle(
                  //     fontSize: 10,
                  //     fontWeight: FontWeight.w800,
                  //     color: AppColors.blue1,
                  //     letterSpacing: 0.5,
                  //   ),
                  // ),
                  AppSubtitle('HISTORIAL', font: AppFont.amazonEmberMedium, fontSize: 10,),
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
                  padding: const EdgeInsets.only(bottom: 3),
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
                                      fontSize: 10,
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
                            // '${v.moneda} ${montoNeto.toStringAsFixed(2)}',
                            'S/ ${montoNeto.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 11, color: AppColors.greendark),
                          ),
                          // Reimprimir el recibo de este cobro: la impresión
                          // automática pudo no salir (sin impresora
                          // configurada) o el cliente pedir otra copia.
                          if (v.esCredito && !pago.anulado)
                            GestureDetector(
                              onTap: () => _reimprimirReciboPago(v, pago),
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(Icons.print_outlined,
                                    size: 18, color: AppColors.blue1),
                              ),
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

  /// Reimprime el recibo de un cobro ya registrado (la impresión automática
  /// no salió por falta de impresora, o el cliente pide otra copia).
  ///
  /// La imputación exacta a cuotas NO se persiste cuando un abono cubre
  /// varias (el backend solo guarda la PRIMERA en `cuotaVentaId` más el
  /// desglose principal/interés/mora), así que el recibo se arma con lo que
  /// sí está guardado y se rotula REIMPRESION: el monto y el método son
  /// exactos, el estado de la deuda es el de hoy.
  Future<void> _reimprimirReciboPago(Venta v, PagoVenta pago) async {
    final cuotas = v.cuotas ?? const [];
    final cuota = pago.cuotaVentaId == null
        ? null
        : cuotas.where((c) => c.id == pago.cuotaVentaId).firstOrNull;

    final aplicaciones = cuota == null
        ? const <CuotaAplicada>[]
        : [
            CuotaAplicada(
              numero: cuota.numero,
              montoAplicado: pago.monto,
              saldoRestante: cuota.saldoPendiente,
              fechaVencimiento: cuota.fechaVencimiento,
            ),
          ];

    await _imprimirReciboCuota(
      venta: v,
      aplicaciones: aplicaciones,
      montoPagado: pago.monto,
      metodoPago: pago.metodoPago.label.toUpperCase(),
      referencia: pago.referencia,
      fecha: pago.fechaPago,
      esReimpresion: true,
      montoInteres: pago.montoInteres,
      montoMora: pago.montoMora,
    );
  }

  /// Cobro de una venta a CRÉDITO por el circuito de CxC: el sheet de abono
  /// permite elegir la fuente del ingreso (Tesorería / Caja / Banco), valida
  /// contra el saldo CON mora y el backend imputa en cascada mora → interés
  /// → principal. El pago directo (`procesarPago`) asienta siempre en la caja
  /// del cajero, que es incorrecto para una transferencia o un cobro que
  /// entra a bóveda.
  Future<void> _abonarCredito() async {
    final v = _venta;
    if (v == null) return;

    final cuotas = v.cuotas ?? const [];
    // Sin cuotas el saldo sale de la venta (crédito sin cronograma).
    final saldo = cuotas.isNotEmpty
        ? cuotas.fold<double>(0, (s, c) => s + c.saldoPendiente)
        : v.saldoPendiente;
    final mora = cuotas.fold<double>(0, (s, c) => s + c.montoMora);

    // Foto para saber después a qué cuotas se aplicó (el recibo lo necesita).
    final antes = {for (final c in cuotas) c.id: c.montoPagado};

    final ok = await AbonoClienteSheet.mostrar(
      context,
      codigoVenta: v.codigo,
      nombreCliente: v.nombreCliente,
      saldoPendiente: saldo,
      totalMora: mora,
      onRegistrar: ({
        required metodoPago,
        required monto,
        referencia,
        fuente,
        bancoId,
      }) async {
        final res = await locator<RegistrarAbonoCuentaCobrarUseCase>()(
          v.id,
          metodoPago: metodoPago,
          monto: monto,
          referencia: referencia,
          fuente: fuente,
          bancoId: bancoId,
        );
        return res is Error<void> ? res.message : null;
      },
    );

    if (ok != true || !mounted) return;

    // El endpoint de abono no devuelve la venta: hay que releerla para
    // saber cómo quedaron las cuotas y poder emitir el recibo.
    await _loadVenta();
    if (!mounted) return;

    final actualizada = _venta;
    if (actualizada == null) return;
    final aplicaciones =
        _cuotasAplicadas(antes, actualizada.cuotas ?? const []);
    if (aplicaciones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abono registrado'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }
    final aplicado =
        aplicaciones.fold<double>(0, (s, a) => s + a.montoAplicado);
    _ofrecerReciboCuota(actualizada, aplicaciones, {
      'monto': aplicado,
      'metodoPago': _metodoUltimoPago(actualizada),
    });
  }

  /// Método del último pago registrado — el sheet de abono no lo devuelve y
  /// el recibo necesita mostrarlo. Se toma el más reciente por fecha porque
  /// el orden de `pagos` no está garantizado.
  String _metodoUltimoPago(Venta v) {
    final pagos = [...(v.pagos ?? const <PagoVenta>[])];
    if (pagos.isEmpty) return 'EFECTIVO';
    pagos.sort((a, b) => a.fechaPago.compareTo(b.fechaPago));
    return pagos.last.metodoPago.label.toUpperCase();
  }

  /// Diff de cuotas antes/después del pago: devuelve a cuáles se les aplicó
  /// plata y cuánto. Vacío si la venta no tenía cuotas (pago normal, sin
  /// crédito) — ahí no hay recibo de cobranza que emitir.
  List<CuotaAplicada> _cuotasAplicadas(
    Map<String, double>? antes,
    List<CuotaVenta> despues,
  ) {
    if (antes == null || antes.isEmpty || despues.isEmpty) return const [];
    final out = <CuotaAplicada>[];
    for (final c in despues) {
      final pagadoAntes = antes[c.id];
      if (pagadoAntes == null) continue; // cuota nueva: no debería pasar
      final aplicado = c.montoPagado - pagadoAntes;
      if (aplicado <= 0.005) continue;
      out.add(CuotaAplicada(
        numero: c.numero,
        montoAplicado: aplicado,
        saldoRestante: c.saldoPendiente,
        fechaVencimiento: c.fechaVencimiento,
      ));
    }
    out.sort((a, b) => a.numero.compareTo(b.numero));
    return out;
  }

  /// Tras cobrar una cuota: si la impresora principal tiene la
  /// auto-impresión activada el recibo sale solo (cobranza diaria = cero
  /// fricción); si no, se ofrece el botón. El pago YA está registrado, así
  /// que nada de esto puede romperlo.
  Future<void> _ofrecerReciboCuota(
    Venta venta,
    List<CuotaAplicada> aplicaciones,
    Map<String, dynamic> pago,
  ) async {
    final monto = (pago['monto'] as num?)?.toDouble() ?? 0;
    final metodo = pago['metodoPago']?.toString() ?? 'EFECTIVO';
    final referencia = pago['referencia']?.toString();

    final impreso = await _imprimirReciboCuota(
      venta: venta,
      aplicaciones: aplicaciones,
      montoPagado: monto,
      metodoPago: metodo,
      referencia: referencia,
      soloSiAutoImprimir: true,
    );
    if (!mounted) return;

    if (impreso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pago registrado - recibo impreso'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Pago registrado'),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'IMPRIMIR RECIBO',
          onPressed: () => _imprimirReciboCuota(
            venta: venta,
            aplicaciones: aplicaciones,
            montoPagado: monto,
            metodoPago: metodo,
            referencia: referencia,
          ),
        ),
      ),
    );
  }

  /// Imprime el recibo de cobranza: intenta la impresora principal y, si no
  /// hay o falla, abre el selector Bluetooth. Con [soloSiAutoImprimir] es un
  /// intento silencioso (sin sheet ni mensajes) para la vía automática.
  /// Devuelve si llegó a imprimirse.
  Future<bool> _imprimirReciboCuota({
    required Venta venta,
    required List<CuotaAplicada> aplicaciones,
    required double montoPagado,
    required String metodoPago,
    String? referencia,
    bool soloSiAutoImprimir = false,
    DateTime? fecha,
    bool esReimpresion = false,
    double montoInteres = 0,
    double montoMora = 0,
  }) async {
    try {
      // Fallbacks de empresa leídos ANTES del primer await (evita usar el
      // context tras un gap async).
      final empresaState = context.read<EmpresaContextCubit>().state;
      String empresaNombre = '';
      String? razonSocial;
      String? ruc;
      String? direccion;
      String? telefono;
      if (empresaState is EmpresaContextLoaded) {
        final e = empresaState.context.empresa;
        empresaNombre = e.nombre;
        razonSocial = e.razonSocial;
        ruc = e.ruc;
        direccion = e.direccionFiscal;
        telefono = e.telefono;
      }

      // Identidad EFECTIVA (sede > empresa), igual que el ticket de venta:
      // la sede puede tener su propio nombre comercial, RUC, razón social y
      // dirección fiscal, y esos deben ganar en la cabecera. Sin esto el
      // recibo salía con la dirección de la empresa aunque el cobro fuera
      // en otra sede.
      try {
        final config = await locator<VentaRemoteDataSource>()
            .getConfiguracionSunat(
                sedeId: venta.comprobanteSedeId ?? venta.sedeId);
        empresaNombre =
            (config['nombreComercial'] as String?)?.trim().isNotEmpty == true
                ? config['nombreComercial'] as String
                : empresaNombre;
        razonSocial = (config['razonSocial'] as String?) ?? razonSocial;
        ruc = (config['ruc'] as String?) ?? ruc;
        direccion = (config['direccionFiscal'] as String?) ?? direccion;
        telefono = (config['telefono'] as String?) ?? telefono;
      } catch (_) {
        // Sin config de facturación (o sin red): el recibo igual sale con
        // los datos de la empresa — es un documento interno.
      }

      final manager = locator<ImpresorasManager>();
      final principal = await manager.getPrincipal();
      // Vía automática: solo si hay principal y el usuario activó el
      // auto-print en su configuración. Si no, se sale sin hacer ruido y el
      // caller ofrece el botón.
      if (soloSiAutoImprimir &&
          (principal == null || !principal.autoImprimirVentaRapida)) {
        return false;
      }

      final bytes = await ReciboCuotaEscPosGenerator.generate(
        venta: venta,
        aplicaciones: aplicaciones,
        montoPagado: montoPagado,
        metodoPago: metodoPago,
        referencia: referencia,
        empresaNombre: empresaNombre,
        empresaRazonSocial: razonSocial,
        empresaRuc: ruc,
        empresaDireccion: direccion,
        empresaTelefono: telefono,
        sedeNombre: venta.sedeNombre,
        // Alias primero (igual que el ticket de venta): en el mostrador se
        // usa el apodo del cajero, no su nombre completo.
        cobradoPor: venta.cajeroAlias ?? venta.cajeroNombre,
        // El ancho importa: con 80 por defecto en una térmica de 58mm las
        // columnas se aplastan a la derecha.
        paperWidth: principal?.anchoPapel.mm ?? 80,
        fecha: fecha,
        esReimpresion: esReimpresion,
        montoInteres: montoInteres,
        montoMora: montoMora,
      );

      if (principal != null) {
        final ok = await manager.imprimirEnPrincipal(bytes);
        if (ok) {
          // En modo automático el caller ya avisa; no duplicar el mensaje.
          if (mounted && !soloSiAutoImprimir) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Recibo impreso en ${principal.nombre}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return true;
        }
      }
      // El intento automático no insiste con el selector: devuelve false y
      // el caller ofrece el botón.
      if (soloSiAutoImprimir) return false;

      // Sin impresora principal configurada (o falló): que elija una.
      if (!mounted) return false;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BluetoothPrinterSheet(ticketBytes: bytes),
      );
      return true;
    } catch (e) {
      if (!mounted || soloSiAutoImprimir) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo generar el recibo: $e'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }
  }

  Widget _buildCuotasSection() {
    final cuotas = _venta!.cuotas!;
    final cuotasPagadas = cuotas.where((c) => c.estado == 'PAGADA').length;

    return GradientContainer(
      borderColor: AppColors.blueborder,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month, size: 16, color: AppColors.blue1),
                const SizedBox(width: 6),
                AppSubtitle('Cuotas ($cuotasPagadas/${cuotas.length} pagadas)', fontSize: 10, font: AppFont.amazonEmberMedium,),
              ],
            ),
            const Divider(height: 12),
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
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    Icon(estadoIcon, size: 16, color: estadoColor),
                    const SizedBox(width: 8),
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: estadoColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
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
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                          Text(
                            'Vence: ${DateFormatter.formatDate(cuota.fechaVencimiento)}'
                            '${cuota.montoPagado > 0 ? ' | Pagado: S/ ${cuota.montoPagado.toStringAsFixed(2)}' : ''}',
                            style: TextStyle(
                              fontSize: 10,
                              // Naranja cuando la cuota está pagada parcialmente.
                              color: cuota.estado == 'PAGADA_PARCIAL'
                                  ? Colors.orange.shade700
                                  : Colors.grey[600],
                              fontWeight: cuota.estado == 'PAGADA_PARCIAL'
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
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
          // Las ventas a crédito cobran por el circuito de CxC: ahí se
          // elige a dónde ENTRA la plata (Tesorería/Caja/Banco). El pago
          // directo siempre asienta en la caja del cajero, que solo es
          // correcto para el saldo de una venta al contado.
          onPressed: () =>
              v.esCredito ? _abonarCredito() : _showPagoDialog(context),
          icon: const Icon(Icons.payment, size: 18),
          label: Text(v.esCredito ? 'Registrar Abono' : 'Registrar Pago'),
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
        AppSubtitle(title, fontSize: 9),
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

  /// Acciones del comprobante (NC/ND/Anular/Guía) que alimentan el menú ⋮
  /// ubicado junto al chip de estado. Devuelve lista vacía si el comprobante
  /// no está ACEPTADO o ya fue anulado — en ese caso no se muestra el menú.
  List<NavigationMenuItem> _buildComprobanteMenuItems(
      BuildContext context, Venta v) {
    if (v.codigoComprobante == null) return const [];
    if (v.comprobanteSunatStatus != 'ACEPTADO' ||
        v.comprobanteAnulado == true) {
      return const [];
    }

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

    return [
      if (puedeEmitirNC)
        NavigationMenuItem(
          id: 'nota_credito',
          label: 'Nota Crédito${ncs.isNotEmpty ? ' (${ncs.length})' : ''}',
          icon: Icons.note_add_outlined,
          iconColor: Colors.orange,
          onTap: () => _abrirDialogNota(context, v, TipoNota.notaCredito),
        ),
      // ND siempre disponible — múltiples válidas (intereses por períodos, etc.)
      NavigationMenuItem(
        id: 'nota_debito',
        label: 'Nota Débito${nds.isNotEmpty ? ' (${nds.length})' : ''}',
        icon: Icons.add_circle_outline,
        iconColor: Colors.purple,
        onTap: () => _abrirDialogNota(context, v, TipoNota.notaDebito),
      ),
      if (puedeAnular)
        NavigationMenuItem(
          id: 'anular',
          label: 'Anular',
          icon: Icons.cancel_outlined,
          iconColor: Colors.red,
          onTap: () => _abrirDialogAnulacion(context, v),
        ),
      NavigationMenuItem(
        id: 'guia_remision',
        label: 'Guía Remisión',
        icon: Icons.local_shipping,
        iconColor: Colors.indigo,
        onTap: () => context.push('/empresa/guias-remision/desde-venta/${v.id}'),
      ),
    ];
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
        // Chip de estado SUNAT + accesos (Ver PDF SUNAT / Ver comprobante)
        // en una sola fila. Wrap para que baje de línea en pantallas chicas.
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: chipColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(label, style: TextStyle(fontSize: 9, color: chipColor, fontWeight: FontWeight.w500)),
            ),
            if (v.comprobanteSunatPdfUrl != null)
              _sunatLinkChip(
                icon: Icons.picture_as_pdf,
                label: 'Ver PDF SUNAT',
                color: Colors.blue,
                onTap: () => _abrirUrl(v.comprobanteSunatPdfUrl!),
              ),
            if (v.comprobanteEnlaceProveedor != null)
              _sunatLinkChip(
                icon: Icons.open_in_new,
                label: 'Ver comprobante',
                color: Colors.grey,
                onTap: () => _abrirUrl(v.comprobanteEnlaceProveedor!),
              ),
            if (status == 'PENDIENTE' || status == 'ERROR_COMUNICACION')
              _sunatLinkChip(
                icon: Icons.refresh,
                label: 'Reintentar',
                color: Colors.blue,
                onTap: () => _reenviarASunat(v.comprobanteId!),
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

  /// Chip-enlace compacto usado en la fila de estado SUNAT
  /// (Ver PDF SUNAT, Ver comprobante, Reintentar).
  Widget _sunatLinkChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final shade700 = color is MaterialColor ? color.shade700 : color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(4),
          // b
          //order: Border.all(color: color.withValues(alpha: 0.30), width: 0.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: shade700),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    color: shade700,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
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

  /// Versión compacta (ícono + valor, sin label) para colocar varios datos
  /// en una misma fila. El ícono ya comunica el campo (calendario, sede…).
  Widget _buildDetailRowCompact(IconData icon, String value,
      {bool alignEnd = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            value,
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.blue1
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {Widget? trailing, Color? valueColor, bool strikethrough = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: valueColor,
                decoration:
                    strikethrough ? TextDecoration.lineThrough : null,
                decorationColor: valueColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
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
    final docCtrl = TextEditingController(text: v.documentoCliente ?? '');
    String tipo = 'BOLETA';
    String? errorDoc;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          void generar() {
            final doc = docCtrl.text.trim();
            // Validación local: FACTURA exige RUC (11 dígitos); BOLETA
            // acepta DNI (8) o RUC (11). El backend re-valida igual.
            if (tipo == 'FACTURA' && !(doc.length == 11 && int.tryParse(doc) != null)) {
              setDialogState(() => errorDoc = 'Factura requiere RUC de 11 dígitos');
              return;
            }
            if (tipo == 'BOLETA' &&
                !((doc.length == 8 || doc.length == 9 || doc.length == 11) &&
                    int.tryParse(doc) != null)) {
              setDialogState(() =>
                  errorDoc = 'Boleta requiere DNI (8), CE (9) o RUC (11 dígitos)');
              return;
            }
            Navigator.pop(ctx);
            _generarComprobante(
              v.id,
              tipo,
              documentoCliente: doc,
              tipoDocumentoCliente:
                  doc.length == 11 ? '6' : (doc.length == 9 ? '4' : '1'),
            );
          }

          return StyledDialog(
            accentColor: AppColors.blue1,
            backgroundColor: Colors.white,
            icon: Icons.receipt_long,
            titulo: 'Generar Comprobante',
            content: [
              Text('Venta ${v.codigo} · Total S/ ${v.total.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  CustomFilterChip(
                    label: 'Boleta',
                    icon: Icons.receipt,
                    selected: tipo == 'BOLETA',
                    onSelected: () => setDialogState(() {
                      tipo = 'BOLETA';
                      errorDoc = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  CustomFilterChip(
                    label: 'Factura',
                    icon: Icons.description,
                    selected: tipo == 'FACTURA',
                    onSelected: () => setDialogState(() {
                      tipo = 'FACTURA';
                      errorDoc = null;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Documento del cliente: las ventas ONLINE del marketplace
              // llegan sin DNI/RUC — se captura aquí y el backend lo
              // persiste en la venta al emitir.
              CustomText(
                controller: docCtrl,
                label: tipo == 'FACTURA' ? 'RUC del cliente' : 'DNI o RUC del cliente',
                hintText: tipo == 'FACTURA' ? '20XXXXXXXXX' : 'XXXXXXXX',
                borderColor: AppColors.blue1,
                fieldType: FieldType.number,
              ),
              if (errorDoc != null) ...[
                const SizedBox(height: 4),
                Text(errorDoc!,
                    style: TextStyle(fontSize: 10.5, color: Colors.red.shade700)),
              ],
            ],
            actions: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancelar',
                      style: TextStyle(color: Colors.grey.shade600)),
                ),
              ),
              Expanded(
                child: CustomButton(
                  text: 'Generar',
                  icon: const Icon(Icons.receipt_long,
                      size: 14, color: Colors.white),
                  backgroundColor: AppColors.blue1,
                  textColor: Colors.white,
                  onPressed: generar,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _generarComprobante(
    String ventaId,
    String tipo, {
    String? documentoCliente,
    String? tipoDocumentoCliente,
  }) async {
    setState(() => _loading = true);
    final repo = locator<VentaRepository>();
    final result = await repo.generarComprobante(
      ventaId: ventaId,
      tipoComprobante: tipo,
      documentoCliente: documentoCliente,
      tipoDocumentoCliente: tipoDocumentoCliente,
    );
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
                              _cuotasAntesPago = {
                                for (final c in (_venta!.cuotas ?? []))
                                  c.id: c.montoPagado,
                              };
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
        fontSize: 9,
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
