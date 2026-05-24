import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import 'package:syncronize/features/impresoras/domain/services/impresoras_manager.dart';
import '../../domain/entities/caja.dart';
import '../../domain/entities/movimiento_caja.dart';
import '../../domain/entities/resumen_caja.dart';
import '../bloc/caja_activa_cubit.dart';
import '../bloc/caja_activa_state.dart';
import '../bloc/caja_movimientos_cubit.dart';
import '../bloc/caja_movimientos_state.dart';
import '../bloc/cerrar_caja_cubit.dart';
import '../bloc/cerrar_caja_state.dart';
import '../services/caja_ticket_data.dart';
import '../services/cierre_caja_esc_pos_generator.dart';

class CerrarCajaPage extends StatefulWidget {
  final String cajaId;

  /// `true` cuando el usuario actual es el dueño de la caja (flujo
  /// cajero estándar). `false` cuando un admin está cerrando la caja
  /// de otro cajero desde el monitor — en ese caso evitamos tocar el
  /// CajaActivaCubit del admin (que mira su propia caja, distinta o
  /// inexistente).
  final bool esCajaPropia;

  const CerrarCajaPage({
    super.key,
    required this.cajaId,
    this.esCajaPropia = true,
  });

  @override
  State<CerrarCajaPage> createState() => _CerrarCajaPageState();
}

class _CerrarCajaPageState extends State<CerrarCajaPage> {
  final _observacionesController = TextEditingController();
  final Map<MetodoPago, TextEditingController> _conteoControllers = {};
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers for each payment method
    for (final metodo in MetodoPago.values) {
      _conteoControllers[metodo] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    for (final controller in _conteoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Auto-impresion del resumen de cierre tras cerrar caja con exito.
  /// Silenciosa si no hay impresora principal configurada; nunca rompe
  /// el flujo de cierre (errores se notifican por snackbar). Si recibe
  /// `resumenPreCierre`, le pasa el desglose por categoría +
  /// anulaciones al ticket (datos que no están en `caja.cierre`).
  Future<void> _imprimirResumenCierre(Caja caja,
      {ResumenCaja? resumenPreCierre}) async {
    if (caja.cierre == null) return;
    try {
      // Resolvemos identidad efectiva sede > empresa (mismo patron que
      // ticket de venta) ANTES del primer await del manager para no
      // cruzar gaps con el context.
      final ticketData = await resolverCajaTicketData(context, caja);

      final manager = locator<ImpresorasManager>();
      final principal = await manager.getPrincipal();
      if (principal == null) return;

      final bytes = await CierreCajaEscPosGenerator.generate(
        caja: caja,
        cierre: caja.cierre!,
        empresaNombre: ticketData.empresaNombre,
        empresaRazonSocial: ticketData.razonSocial,
        empresaRuc: ticketData.ruc,
        empresaDireccion: ticketData.direccion,
        empresaTelefono: ticketData.telefono,
        sedeNombre: caja.sedeNombre,
        logoEmpresa: ticketData.logoBytes,
        paperWidth: principal.anchoPapel.mm,
        egresoAnulacionVenta: resumenPreCierre?.egresoAnulacionVenta ?? 0,
        cantidadAnulaciones: resumenPreCierre?.cantidadAnulaciones ?? 0,
        egresosPorCategoria:
            resumenPreCierre?.egresosPorCategoria ?? const [],
      );

      final ok = await manager.imprimirEnPrincipal(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Resumen de cierre impreso en ${principal.nombre}'
              : 'No se pudo imprimir el resumen automaticamente'),
          backgroundColor: ok ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (_) {
      // Silencioso: la impresion no debe romper el flujo de cierre.
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_PE',
      symbol: 'S/ ',
      decimalDigits: 2,
    );

    return BlocListener<CerrarCajaCubit, CerrarCajaState>(
      listener: (context, state) {
        if (state is CerrarCajaSuccess) {
          // Auto-impresión del resumen (no await — el listener no puede
          // ser async; la impresión corre en background y avisa por
          // snackbar si falla). Leemos el resumen pre-cierre desde el
          // cubit de movimientos para incluir el desglose por categoría
          // y la nota de anulaciones (no vienen en `caja.cierre`).
          final movState = context.read<CajaMovimientosCubit>().state;
          final resumenPreCierre =
              movState is CajaMovimientosLoaded ? movState.resumen : null;
          _imprimirResumenCierre(state.caja,
              resumenPreCierre: resumenPreCierre);

          // Si es la caja del usuario actual, invalidar el
          // CajaActivaCubit para que el dashboard vuelva a "sin caja".
          // Si la cerraba un admin sobre caja ajena, su cubit no se
          // toca.
          if (widget.esCajaPropia) {
            context.read<CajaActivaCubit>().loadCajaActiva();
          }

          SnackBarHelper.showSuccess(context, 'Caja cerrada exitosamente');
          Navigator.of(context).pop(true);
        }
        if (state is CerrarCajaError) {
          setState(() => _isClosing = false);
          SnackBarHelper.showError(context, state.message);
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          // Altura mayor para acomodar el subtítulo (código + estado).
          preferredSize: const Size.fromHeight(52),
          child: BlocBuilder<CajaActivaCubit, CajaActivaState>(
            builder: (context, state) {
              final caja = state is CajaActivaAbierta ? state.caja : null;
              return SmartAppBar(
                title: caja?.codigo ?? 'Cerrar Caja',
                subtitle: caja != null
                    ? 'Cerrando · ${caja.estado.label}'
                    : null,
                customHeight: 52,
                backgroundColor: AppColors.blue1,
                foregroundColor: AppColors.white,
              );
            },
          ),
        ),
        body: GradientContainer(
          child: BlocBuilder<CajaMovimientosCubit, CajaMovimientosState>(
            builder: (context, movState) {
              if (movState is CajaMovimientosLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (movState is CajaMovimientosLoaded &&
                  movState.resumen != null) {
                return _buildCierreForm(
                  context,
                  movState.resumen!,
                  movState.movimientos,
                  currencyFormat,
                );
              }

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No se pudo cargar el resumen',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Reintentar',
                      onPressed: () {
                        context
                            .read<CajaMovimientosCubit>()
                            .loadMovimientos(widget.cajaId);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCierreForm(
    BuildContext context,
    ResumenCaja resumen,
    List<MovimientoCaja> movimientos,
    NumberFormat currencyFormat,
  ) {
    // Monto de apertura tomado del CajaActivaCubit. Si por alguna
    // razón el cubit no tiene la caja cargada (estado intermedio),
    // dejamos `null` y ocultamos la fila.
    final cajaState = context.read<CajaActivaCubit>().state;
    final montoApertura =
        cajaState is CajaActivaAbierta ? cajaState.caja.montoApertura : null;

    // Total ingresos categoría VENTA (no anulados). Diferencia con
    // `resumen.totalIngresos` que incluye TODO ingreso (manuales,
    // adelantos, reversiones, etc.). Sirve al cajero para ver cuánto
    // se facturó realmente durante el turno.
    final totalIngresosVentas = movimientos
        .where((m) =>
            !m.anulado &&
            m.tipo == TipoMovimientoCaja.ingreso &&
            m.categoria == CategoriaMovimientoCaja.venta)
        .fold<double>(0, (sum, m) => sum + m.monto);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary header
          GradientContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSubtitle(
                  'Resumen del Sistema',
                  fontSize: 16,
                  color: AppColors.blue3,
                ),
                const SizedBox(height: 12),
                if (montoApertura != null) ...[
                  _buildSummaryRow(
                    'Monto de Apertura',
                    currencyFormat.format(montoApertura),
                    AppColors.blue2,
                  ),
                  const SizedBox(height: 6),
                ],
                _buildSummaryRow(
                  'Total Ingresos Ventas',
                  currencyFormat.format(totalIngresosVentas),
                  AppColors.green,
                ),
                if (resumen.egresoAnulacionVenta > 0) ...[
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      '(− ${currencyFormat.format(resumen.egresoAnulacionVenta)} anulados)',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                _buildSummaryRow(
                  'Total Egresos',
                  currencyFormat.format(resumen.totalEgresos),
                  AppColors.red,
                ),
                ...resumen.egresosPorCategoria.map((e) => Padding(
                      padding: const EdgeInsets.only(left: 16, top: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '· ${e.label}'
                            '${e.cantidad > 0 ? " (${e.cantidad})" : ""}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            currencyFormat.format(e.total),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.red.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    )),
                if (resumen.egresoAnulacionVenta > 0) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 12, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Anulación de Venta'
                                  '${resumen.cantidadAnulaciones > 0 ? " (${resumen.cantidadAnulaciones})" : ""}'
                                  ' — ya descontado',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currencyFormat.format(resumen.egresoAnulacionVenta),
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 16),
                _buildSummaryRow(
                  'Saldo Total',
                  currencyFormat.format(resumen.saldo),
                  AppColors.blue3,
                  isBold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Conteo por metodo de pago
          const AppSubtitle(
            'Conteo Fisico por Metodo de Pago',
            fontSize: 16,
            color: AppColors.blue3,
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingresa el monto fisico contado para cada metodo de pago',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          ...MetodoPago.values.map((metodo) {
            final detalle = resumen.detalles
                .where((d) => d.metodoPago == metodo)
                .toList();
            final esperado =
                detalle.isNotEmpty ? detalle.first.saldo : 0.0;

            // Only show payment methods that have expected amounts or are EFECTIVO
            if (esperado == 0 && metodo != MetodoPago.efectivo) {
              return const SizedBox.shrink();
            }

            return _buildConteoCard(
              metodo,
              esperado,
              currencyFormat,
            );
          }),

          const SizedBox(height: 16),

          // Aviso: el conteo declarado se depositara automaticamente a la
          // Caja Central (Tesoreria) de la sede al cerrar. Calculado en
          // vivo desde los _conteoControllers (re-render por setState al
          // onChanged de cada CustomText).
          _buildAvisoTesoreria(currencyFormat),

          // Observaciones
          CustomText(
            borderColor: AppColors.blue1,
            label: 'Observaciones (opcional)',
            hintText: 'Notas sobre el cierre de caja...',
            controller: _observacionesController,
            maxLines: 3,
            height: null,
            prefixIcon: const Icon(Icons.note_rounded),
          ),
          const SizedBox(height: 24),

          // Cerrar button
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Cerrar Caja',
              backgroundColor: AppColors.red,
              height: 48,
              isLoading: _isClosing,
              onPressed: _isClosing
                  ? null
                  : () => _confirmarCierre(context, resumen, currencyFormat),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAvisoTesoreria(NumberFormat currencyFormat) {
    double totalDeposito = 0;
    for (final c in _conteoControllers.values) {
      totalDeposito +=
          double.tryParse(c.text.replaceAll(',', '.')) ?? 0;
    }
    if (totalDeposito <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.blue1.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.blue1.withValues(alpha: 0.20)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.account_balance_rounded,
              color: AppColors.blue1,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Se depositará en Tesorería',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue1,
                    ),
                  ),
                  Text(
                    'El conteo declarado se transfiere automáticamente a la Caja Central de la sede al cerrar.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary.withValues(alpha: 0.90),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              currencyFormat.format(totalDeposito),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.blue1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConteoCard(
    MetodoPago metodo,
    double esperado,
    NumberFormat currencyFormat,
  ) {
    final controller = _conteoControllers[metodo]!;
    final conteoValue =
        double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
    final diferencia = conteoValue - esperado;
    final hasDiferencia = controller.text.isNotEmpty && diferencia != 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GradientContainer(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(metodo.icon, size: 20, color: AppColors.blue3),
                const SizedBox(width: 8),
                AppSubtitle(
                  metodo.label,
                  fontSize: 14,
                  color: AppColors.blue3,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Esperado',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        currencyFormat.format(esperado),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue3,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CustomText(
                    borderColor: AppColors.blue1,
                    label: 'Conteo Fisico',
                    controller: controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    prefixText: 'S/ ',
                    height: 38,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            if (hasDiferencia) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: diferencia > 0
                      ? AppColors.green.withValues(alpha: 0.1)
                      : AppColors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      diferencia > 0
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 14,
                      color: diferencia > 0 ? AppColors.green : AppColors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Diferencia: ${currencyFormat.format(diferencia.abs())}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            diferencia > 0 ? AppColors.green : AppColors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Pre-check: detecta diferencias entre conteo físico ingresado y
  /// saldo esperado por método. Si hay diferencias (positivas, negativas
  /// o métodos sin contar con esperado≠0), muestra un dialog reforzado
  /// para que el cajero/admin no cierre por error. Si todo cuadra,
  /// muestra el dialog de confirmación simple.
  void _confirmarCierre(
    BuildContext context,
    ResumenCaja resumen,
    NumberFormat currencyFormat,
  ) {
    final discrepancias = <_Discrepancia>[];
    for (final metodo in MetodoPago.values) {
      final detalle = resumen.detalles
          .where((d) => d.metodoPago == metodo)
          .toList();
      final esperado = detalle.isNotEmpty ? detalle.first.saldo : 0.0;
      final text = _conteoControllers[metodo]!.text;
      // Salteamos métodos sin actividad ni conteo (no aportan ruido).
      if (esperado == 0 && text.isEmpty) continue;
      final conteo = text.isEmpty
          ? 0.0
          : (double.tryParse(text.replaceAll(',', '.')) ?? 0);
      final diferencia = conteo - esperado;
      if (diferencia != 0) {
        discrepancias.add(_Discrepancia(
          metodo: metodo,
          esperado: esperado,
          conteo: conteo,
          diferencia: diferencia,
          conteoVacio: text.isEmpty,
        ));
      }
    }

    if (discrepancias.isEmpty) {
      _mostrarDialogConfirmacionSimple(context);
    } else {
      _mostrarDialogDiferencias(context, discrepancias, currencyFormat);
    }
  }

  /// Dialog cuando el conteo físico cuadra con todo lo esperado.
  /// Mismo estilo visual que el de diferencias (GradientContainer +
  /// borde acentuado + sombra), pero en verde de éxito en vez de rojo.
  void _mostrarDialogConfirmacionSimple(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: GradientContainer(
          borderColor: AppColors.green.withValues(alpha: 0.4),
          borderWidth: 1,
          customShadows: [
            BoxShadow(
              color: AppColors.green.withValues(alpha: 0.18),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con ícono check + título
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.green,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Conteo conforme',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'El conteo físico coincide con el saldo esperado del '
                'sistema. Esta acción no se puede deshacer: se cerrará '
                'la caja y se registrarán los conteos.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              // Botones
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: TextButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.blue3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _cerrarCaja(context);
                      },
                      child: const Text(
                        'Cerrar Caja',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
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
  }

  /// Dialog reforzado cuando hay diferencias entre conteo y esperado.
  /// Listado en rojo con cada método, esperado y diferencia. El cajero
  /// puede cancelar y revisar conteos, o cerrar igual asumiendo la
  /// diferencia (queda registrada en el cierre).
  void _mostrarDialogDiferencias(
    BuildContext context,
    List<_Discrepancia> discrepancias,
    NumberFormat currencyFormat,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: GradientContainer(
          borderColor: AppColors.red.withValues(alpha: 0.4),
          borderWidth: 1,
          customShadows: [
            BoxShadow(
              color: AppColors.red.withValues(alpha: 0.18),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con ícono + título
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.red,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Hay diferencias en el conteo',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'El conteo físico no coincide con el saldo esperado del '
                'sistema. Si cierras la caja igual, las diferencias '
                'quedarán registradas en el cierre.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              // Lista de discrepancias
              ...discrepancias.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.red.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            d.metodo.icon,
                            size: 16,
                            color: AppColors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.metodo.label,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.red,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Esperado: ${currencyFormat.format(d.esperado)}'
                                  ' · Conteo: ${d.conteoVacio ? "—" : currencyFormat.format(d.conteo)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${d.diferencia >= 0 ? "+" : ""}${currencyFormat.format(d.diferencia)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 6),
              // Botones
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: TextButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Revisar conteos',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.blue3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _cerrarCaja(context);
                      },
                      child: const Text(
                        'Cerrar igual',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
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
  }

  void _cerrarCaja(BuildContext context) {
    setState(() => _isClosing = true);

    final conteos = <Map<String, dynamic>>[];
    for (final metodo in MetodoPago.values) {
      final text = _conteoControllers[metodo]!.text;
      if (text.isNotEmpty) {
        final conteoFisico =
            double.tryParse(text.replaceAll(',', '.')) ?? 0;
        conteos.add({
          'metodoPago': metodo.apiValue,
          'conteoFisico': conteoFisico,
        });
      }
    }

    context.read<CerrarCajaCubit>().cerrarCaja(
          cajaId: widget.cajaId,
          conteos: conteos,
          observaciones: _observacionesController.text.isNotEmpty
              ? _observacionesController.text
              : null,
        );
  }
}

/// Discrepancia entre conteo físico y saldo esperado para un método
/// de pago. Sirve como modelo del listado mostrado en el dialog de
/// advertencia previo al cierre. `conteoVacio` permite distinguir
/// "no contó nada" (mostrar "—") de "contó S/ 0".
class _Discrepancia {
  final MetodoPago metodo;
  final double esperado;
  final double conteo;
  final double diferencia;
  final bool conteoVacio;

  const _Discrepancia({
    required this.metodo,
    required this.esperado,
    required this.conteo,
    required this.diferencia,
    required this.conteoVacio,
  });
}
