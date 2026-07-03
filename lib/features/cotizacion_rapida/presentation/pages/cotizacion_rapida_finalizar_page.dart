import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cliente_unificado_selector.dart';
import '../../../../core/widgets/currency/currency_textfield.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_switch.dart';
import '../../../../core/widgets/date/custom_date.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../../caja/presentation/bloc/caja_activa_cubit.dart';
import '../../../caja/presentation/bloc/caja_activa_state.dart';
import '../bloc/cotizacion_rapida_cubit.dart';

class CotizacionRapidaFinalizarPage extends StatelessWidget {
  const CotizacionRapidaFinalizarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: locator<CotizacionRapidaCubit>()),
        // CajaActivaCubit es @injectable — instancia por página.
        // Necesario para el bloque "Reserva de stock" que registra el
        // pago adelantado en la caja abierta del cajero.
        BlocProvider(
          create: (_) => locator<CajaActivaCubit>()..loadCajaActiva(),
        ),
      ],
      child: const _FinalizarView(),
    );
  }
}

class _FinalizarView extends StatefulWidget {
  const _FinalizarView();

  @override
  State<_FinalizarView> createState() => _FinalizarViewState();
}

class _FinalizarViewState extends State<_FinalizarView> {
  final _nombreCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  final _condCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();

  static final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    final state = context.read<CotizacionRapidaCubit>().state;
    _nombreCtrl.text = state.nombreCotizacion;
    _obsCtrl.text = state.observaciones;
    _condCtrl.text = state.condiciones;
    if (state.fechaVencimiento != null) {
      _fechaCtrl.text = _dateFmt.format(state.fechaVencimiento!);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _obsCtrl.dispose();
    _condCtrl.dispose();
    _fechaCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarCliente() async {
    final cubit = context.read<CotizacionRapidaCubit>();
    final empresaId = cubit.state.empresaId;
    if (empresaId == null) return;
    final result = await ClienteUnificadoSelector.show(
      context: context,
      empresaId: empresaId,
    );
    if (result == null || !mounted) return;

    if (result.isPersona) {
      cubit.aplicarClienteResuelto(
        clienteId: result.clienteId,
        clienteEmpresaId: null,
        tipoDocCliente: 'DNI',
        numeroDocCliente: result.dni ?? '',
        nombreResuelto: result.nombreCompleto ?? '',
      );
    } else {
      cubit.aplicarClienteResuelto(
        clienteId: null,
        clienteEmpresaId: result.clienteEmpresaId,
        tipoDocCliente: 'RUC',
        numeroDocCliente: result.ruc ?? '',
        nombreResuelto: result.razonSocial ?? '',
      );
    }
  }

  Future<void> _crear() async {
    final cubit = context.read<CotizacionRapidaCubit>();

    // Aviso NO bloqueante: cotizar no exige stock (es promesa de precio,
    // no de mercadería — cotizar mercadería por llegar es válido), pero el
    // vendedor debe decidir consciente si algún item supera el disponible.
    final sinStock = cubit.state.items.where((i) {
      final esManual =
          i.productoId == null && i.varianteId == null && i.servicioId == null;
      if (esManual || i.servicioId != null) return false;
      return i.cantidad > (i.stockDisponible ?? 0);
    }).toList();
    if (sinStock.isNotEmpty) {
      final continuar = await showDialog<bool>(
        context: context,
        builder: (ctx) => StyledDialog(
          accentColor: Colors.orange.shade800,
          icon: Icons.inventory_2_outlined,
          titulo: 'Stock insuficiente',
          content: [
            Text(
              sinStock.length == 1
                  ? '1 item supera el stock disponible:'
                  : '${sinStock.length} items superan el stock disponible:',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 6),
            ...sinStock.take(5).map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '• ${i.descripcion}: pides ${i.cantidad.toStringAsFixed(i.cantidad % 1 == 0 ? 0 : 2)}, hay ${i.stockDisponible ?? 0}',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                )),
            if (sinStock.length > 5)
              Text('… y ${sinStock.length - 5} más',
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            Text(
              'Puedes cotizar igual (ej. mercadería por llegar) — el stock '
              'se exigirá recién al convertir en venta.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
          actions: [
            Expanded(
              child: CustomButton(
                text: 'Revisar',
                isOutlined: true,
                borderColor: Colors.grey.shade400,
                textColor: Colors.grey.shade700,
                enableShadows: false,
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            ),
            Expanded(
              child: CustomButton(
                text: 'Cotizar igual',
                backgroundColor: Colors.orange.shade800,
                textColor: Colors.white,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ),
          ],
        ),
      );
      if (continuar != true || !mounted) return;
    }

    cubit.setNombreCotizacion(_nombreCtrl.text);
    cubit.setObservaciones(_obsCtrl.text);
    cubit.setCondiciones(_condCtrl.text);
    cubit.crearCotizacion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Finalizar cotización',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        leftIcon: Icons.arrow_back_rounded,
        onLeftTap: () => context.pop(),
      ),
      // Botón fijo al final. El bottomNavigationBar respeta la barra
      // del sistema (gestos / botones nav) automáticamente en todos
      // los devices — más robusto que un Padding+SafeArea manual
      // (que en algunos celulares con gesture bar gruesa quedaba
      // tapado).
      bottomNavigationBar:
          BlocBuilder<CotizacionRapidaCubit, CotizacionRapidaState>(
        buildWhen: (a, b) =>
            a.total != b.total || a.procesando != b.procesando,
        builder: (context, state) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: CustomButton(
                text:
                    'CREAR COTIZACIÓN  —  S/ ${state.total.toStringAsFixed(2)}',
                backgroundColor: AppColors.blue1,
                textColor: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                isLoading: state.procesando,
                enabled: !state.procesando,
                onPressed: state.procesando ? null : _crear,
              ),
            ),
          );
        },
      ),
      body: BlocConsumer<CotizacionRapidaCubit, CotizacionRapidaState>(
        listener: (context, state) {
          if (state.error != null) {
            SnackBarHelper.showError(context, state.error!);
            context.read<CotizacionRapidaCubit>().clearError();
          }
          if (state.cotizacionCompletadaId != null) {
            final id = state.cotizacionCompletadaId!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Cotización creada'),
                backgroundColor: Colors.green.shade600,
              ),
            );
            context.read<CotizacionRapidaCubit>().resetCompletada();
            // Stack post-creación: dashboard → cotizaciones → detalle.
            context.go('/empresa/dashboard');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              context.push('/empresa/cotizaciones');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                context.push('/empresa/cotizaciones/$id');
              });
            });
          }
        },
        builder: (context, state) {
          final tieneCliente = state.nombreClienteResuelto.isNotEmpty;
          final esGenerico = state.clienteGenerico;

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Resumen
                        _SectionCard(
                          title: 'Resumen',
                          child: Column(
                            children: [
                              // Detalle de items — tabla tipo Excel (mismo
                              // patrón de cobrar cotización): header bluechip
                              // + zebra striping, con el descuento por línea.
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.blueborder
                                        .withValues(alpha: 0.5),
                                    width: 0.6,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  children: [
                                    Container(
                                      color: AppColors.bluechip,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5, horizontal: 8),
                                      child: const Row(
                                        children: [
                                          SizedBox(
                                              width: 20,
                                              child: Center(
                                                  child: _ThDetalle('#'))),
                                          Expanded(
                                              flex: 6,
                                              child:
                                                  _ThDetalle('PRODUCTO')),
                                          Expanded(
                                              flex: 2,
                                              child: Center(
                                                  child:
                                                      _ThDetalle('CANT.'))),
                                          Expanded(
                                              flex: 3,
                                              child: Align(
                                                  alignment: Alignment
                                                      .centerRight,
                                                  child: _ThDetalle(
                                                      'P. UNIT.'))),
                                          Expanded(
                                              flex: 3,
                                              child: Align(
                                                  alignment: Alignment
                                                      .centerRight,
                                                  child:
                                                      _ThDetalle('DESC.'))),
                                          Expanded(
                                              flex: 3,
                                              child: Align(
                                                  alignment: Alignment
                                                      .centerRight,
                                                  child:
                                                      _ThDetalle('TOTAL'))),
                                        ],
                                      ),
                                    ),
                                    for (var i = 0;
                                        i < state.items.length;
                                        i++)
                                      _DetalleTablaRow(
                                          index: i, item: state.items[i]),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              _ResumenRow(
                                label: 'Items',
                                value: '${state.cantidadItems}',
                              ),
                              _ResumenRow(
                                label: 'Subtotal',
                                value:
                                    'S/ ${state.subtotal.toStringAsFixed(2)}',
                              ),
                              _ResumenRow(
                                label:
                                    'IGV (${state.impuestoPorcentaje.toStringAsFixed(0)}%)',
                                value: 'S/ ${state.igv.toStringAsFixed(2)}',
                              ),
                              const Divider(height: 16),
                              _ResumenRow(
                                label: 'Total',
                                value:
                                    'S/ ${state.total.toStringAsFixed(2)}',
                                bold: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Cliente
                        _SectionCard(
                          title: 'Cliente',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (tieneCliente) ...[
                                Row(
                                  children: [
                                    Icon(Icons.person_outline,
                                        size: 18,
                                        color: AppColors.blue1),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        state.nombreClienteResuelto,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (state.numeroDocCliente.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 24, top: 2),
                                    child: Text(
                                      '${state.tipoDocCliente}: ${state.numeroDocCliente}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                              ] else if (esGenerico)
                                Row(
                                  children: [
                                    Icon(Icons.people_outline,
                                        size: 18,
                                        color: Colors.grey.shade600),
                                    const SizedBox(width: 6),
                                    Text(
                                      'CLIENTES VARIOS',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  'Sin cliente',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomButton(
                                      text: 'Buscar cliente',
                                      height: 30,
                                      icon: const Icon(Icons.search,
                                          size: 16,
                                          color: AppColors.blue1),
                                      borderColor: AppColors.blue1,
                                      textColor: AppColors.blue1,
                                      onPressed: _seleccionarCliente,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: CustomButton(
                                      text: 'Genérico',
                                      height: 30,
                                      icon: Icon(Icons.people_outline,
                                          size: 16,
                                          color: Colors.grey.shade700),
                                      borderColor: Colors.grey.shade400,
                                      textColor: Colors.grey.shade700,
                                      onPressed: () => context
                                          .read<CotizacionRapidaCubit>()
                                          .setClienteGenerico(),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Vigencia
                        _SectionCard(
                          title: 'Vigencia',
                          child: CustomDate(
                            controller: _fechaCtrl,
                            label: 'Vence el',
                            hintText: 'dd/MM/yyyy',
                            borderColor: AppColors.blue1,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365)),
                            initialDate:
                                state.fechaVencimiento ?? DateTime.now(),
                            onDateSelected: (d) {
                              context
                                  .read<CotizacionRapidaCubit>()
                                  .setFechaVencimiento(d);
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Reserva de stock + pago adelantado.
                        // Solo aplica en modo PARA_VENTA.
                        const _ReservaStockSection(),
                        const SizedBox(height: 12),
                        // Detalles — todos en mayúsculas (TextCase.upper)
                        _SectionCard(
                          title: 'Detalles',
                          child: Column(
                            children: [
                              CustomText(
                                controller: _nombreCtrl,
                                label: 'Título (opcional)',
                                hintText: 'EJ. PC GAMER PROFESIONAL',
                                borderColor: AppColors.blue1,
                                textCase: TextCase.upper,
                                fieldType: FieldType.text,
                                maxLength: 120,
                              ),
                              const SizedBox(height: 8),
                              CustomText(
                                controller: _obsCtrl,
                                label: 'Observaciones (opcional)',
                                borderColor: AppColors.blue1,
                                textCase: TextCase.upper,
                                fieldType: FieldType.text,
                                minLines: 2,
                                maxLines: 4,
                              ),
                              const SizedBox(height: 8),
                              CustomText(
                                controller: _condCtrl,
                                label: 'Condiciones (opcional)',
                                hintText:
                                    'EJ. VALIDEZ 7 DÍAS. ENTREGA 48H.',
                                borderColor: AppColors.blue1,
                                textCase: TextCase.upper,
                                fieldType: FieldType.text,
                                minLines: 2,
                                maxLines: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _ResumenRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _ResumenRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 12 : 10,
      fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
      color: bold ? AppColors.blue1 : Colors.black87,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

/// Bloque "Reserva de stock + adelanto" en la página de finalizar.
///
/// - Solo activable en modo PARA_VENTA (los items manuales no reservan).
/// - El campo de adelanto solo se habilita si la reserva está activa
///   y hay una caja abierta. Auto-vincula la caja activa al cubit.
class _ReservaStockSection extends StatefulWidget {
  const _ReservaStockSection();

  @override
  State<_ReservaStockSection> createState() => _ReservaStockSectionState();
}

class _ReservaStockSectionState extends State<_ReservaStockSection> {
  final _adelantoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final monto = context.read<CotizacionRapidaCubit>().state.adelantoMonto;
    if (monto > 0) {
      _adelantoCtrl.text = monto.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _adelantoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CotizacionRapidaCubit, CotizacionRapidaState>(
      buildWhen: (a, b) =>
          a.tipoCotizacion != b.tipoCotizacion ||
          a.reservarStock != b.reservarStock ||
          a.adelantoMonto != b.adelantoMonto,
      builder: (context, state) {
        final esParaVenta =
            state.tipoCotizacion == TipoCotizacionRapida.paraVenta;
        return _SectionCard(
          title: 'Reserva de stock',
          child: BlocBuilder<CajaActivaCubit, CajaActivaState>(
            builder: (context, cajaState) {
              final cajaAbierta = cajaState is CajaActivaAbierta;
              final cajaId = cajaAbierta ? cajaState.caja.id : null;

              // Auto-vincular la caja activa al cubit si cambió.
              if (cajaId != state.cajaIdAdelanto) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!context.mounted) return;
                  context
                      .read<CotizacionRapidaCubit>()
                      .setCajaIdAdelanto(cajaId);
                });
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Switch principal
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Apartar productos para este cliente',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: esParaVenta
                                    ? AppColors.blue1
                                    : AppColors.blue1.withValues(alpha: 0.4),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              esParaVenta
                                  ? 'El stock queda reservado hasta convertir, anular o expirar la cotización.'
                                  : 'Solo disponible en cotización PARA VENTA.',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      CustomSwitch(
                        value: state.reservarStock && esParaVenta,
                        onChanged: esParaVenta
                            ? (v) => context
                                .read<CotizacionRapidaCubit>()
                                .setReservarStock(v)
                            : null,
                      ),
                    ],
                  ),
                  // Campo de adelanto solo si la reserva está activa
                  if (state.reservarStock && esParaVenta) ...[
                    const SizedBox(height: 12),
                    if (!cajaAbierta)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 16, color: Colors.orange[700]),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'No hay caja abierta. Abrí caja primero si vas a registrar un pago adelantado.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      CurrencyTextField(
                        controller: _adelantoCtrl,
                        label: 'Pago adelantado (opcional)',
                        hintText: '0.00',
                        borderColor: AppColors.blue1,
                        onChanged: (monto) {
                          context
                              .read<CotizacionRapidaCubit>()
                              .setAdelantoMonto(monto);
                        },
                      ),
                    if (cajaAbierta && state.adelantoMonto > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Se registrará como ingreso en caja "${(cajaState).caja.codigo}". Si se anula la cotización, se devuelve automáticamente.',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// Header de columna de la tabla de items del resumen (mismo estilo que la
/// tabla de cobrar cotización: uppercase compacto sobre fondo bluechip).
class _ThDetalle extends StatelessWidget {
  final String text;
  const _ThDetalle(this.text);

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

/// Fila de la tabla de items del resumen con zebra striping: nombre,
/// cantidad, precio unitario, descuento de la línea y total.
class _DetalleTablaRow extends StatelessWidget {
  final int index;
  final dynamic item; // VentaDetalleInput

  const _DetalleTablaRow({required this.index, required this.item});

  static String _fmtCantidad(double n) {
    if (n.truncateToDouble() == n) return n.toStringAsFixed(0);
    return n.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final double descuentoManual = (item.descuento as num).toDouble();
    final double cantidad = (item.cantidad as num).toDouble();
    final double precio = (item.precioUnitario as num).toDouble();
    final double? precioBase = (item.precioBase as num?)?.toDouble();
    // Rebaja del nivel por mayor / VIP: viene "escondida" en el precio
    // unitario (precioBase → precioUnitario). La columna DESC. muestra el
    // ahorro TOTAL de la línea: nivel + descuento manual.
    final bool tieneNivel = item.nivelAplicado != null &&
        precioBase != null &&
        precioBase > precio;
    final double descuentoNivel =
        tieneNivel ? (precioBase - precio) * cantidad : 0;
    final double descuentoTotal = descuentoManual + descuentoNivel;
    return Container(
      color: index.isEven ? Colors.white : Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 22,
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
          Expanded(
            // Debe coincidir con el flex del header PRODUCTO para que
            // CANT./P.UNIT./DESC./TOTAL queden alineadas con sus cabeceras.
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.descripcion as String,
                  style: const TextStyle(
                    fontSize: 9,
                    height: 1.1,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (tieneNivel)
                  Text(
                    '${item.nivelAplicado}',
                    style: TextStyle(
                      fontSize: 8,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                // Precio de OFERTA pública: informativo (no cuenta como
                // descuento de la cotización — es el precio vigente). Se
                // muestra el precio normal para ver el ahorro de la oferta.
                if (item.enOferta == true)
                  Text(
                    (item.precioAntesOferta as num?) != null &&
                            (item.precioAntesOferta as num) > precio
                        ? 'En oferta — antes S/ ${(item.precioAntesOferta as num).toStringAsFixed(2)}'
                        : 'En oferta',
                    style: TextStyle(
                      fontSize: 8,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade800,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                _fmtCantidad(cantidad),
                style: const TextStyle(fontSize: 9, height: 1.1),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Precio regular tachado cuando hay nivel/VIP aplicado.
                if (tieneNivel)
                  Text(
                    precioBase.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 8,
                      height: 1.1,
                      color: Colors.grey.shade400,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Colors.grey.shade400,
                    ),
                  ),
                Text(
                  precio.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 9,
                    height: 1.1,
                    fontWeight:
                        tieneNivel ? FontWeight.w600 : FontWeight.w400,
                    color: tieneNivel ? Colors.green.shade700 : null,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                descuentoTotal > 0.005
                    ? '−${descuentoTotal.toStringAsFixed(2)}'
                    : '—',
                style: TextStyle(
                  fontSize: 9,
                  height: 1.1,
                  fontWeight: descuentoTotal > 0.005
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: descuentoTotal > 0.005
                      ? Colors.red.shade600
                      : Colors.grey.shade400,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                (item.total as num).toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 9,
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
