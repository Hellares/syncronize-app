import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/currency/currency_formatter.dart';
import '../../../../core/widgets/currency/currency_textfield.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/numpad/numpad_controller.dart';
import '../../../../core/widgets/numpad/pos_numpad.dart';
import '../../../../core/widgets/pagos_section_widget.dart'
    show
        aplicaBancarizacion,
        bancosFrecuentes,
        bancosPeru,
        requiereBancoPago,
        umbralBancarizacionPen;
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../../producto/presentation/bloc/producto_list/producto_list_cubit.dart';
import '../bloc/venta_rapida_cubit.dart';

/// Medio centavo: error máximo de redondeo a 2 decimales en PEN. Se usa para
/// no mostrar "falta 0.00" o "vuelto 0.00" cuando la diferencia es residual.
const double _kPenRoundingTolerance = 0.005;

class VentaRapidaCobroPage extends StatelessWidget {
  const VentaRapidaCobroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: locator<VentaRapidaCubit>(),
      child: const _CobroView(),
    );
  }
}

class _CobroView extends StatefulWidget {
  const _CobroView();

  @override
  State<_CobroView> createState() => _CobroViewState();
}

class _CobroViewState extends State<_CobroView> {
  final _efectivoCtrl = TextEditingController();
  final _efectivoFocus = FocusNode();
  // Segundo input principal: Yape (es el más usado en Perú).
  final _yapeCtrl = TextEditingController();
  final _yapeFocus = FocusNode();
  // Referencia por defecto "000" — el cajero verifica visualmente el Yape o
  // por notificación; solo edita si la operatoria requiere registrar el N° real.
  final _yapeRefCtrl = TextEditingController(text: '000');
  final _yapeRefFocus = FocusNode();
  final _docCtrl = TextEditingController();
  final _docFocus = FocusNode();

  /// Filas de pago "otros" (TARJETA / PLIN / TRANSFERENCIA) renderizadas
  /// con el mismo patrón visual que efectivo/yape: input de monto + referencia.
  /// Se mantienen en estado local del widget; al cobrar se vuelcan al cubit.
  final List<_OtroPago> _otrosPagos = [];

  /// Numpad activo: vinculado al input que tiene foco. Siempre presente.
  NumpadController? _numpadCtrl;
  String _numpadTitulo = '';

  /// Modo del numpad según el contexto del input enfocado:
  ///  - `monto` → muestra chips de quick amounts y permite acción "Exacto".
  ///  - `documento` → oculta chips y deshabilita "Exacto" (DNI/RUC/N° op
  ///    no son montos).
  _ModoNumpad _modoNumpad = _ModoNumpad.monto;

  @override
  void initState() {
    super.initState();
    _efectivoCtrl.addListener(_onAnyChange);
    _yapeCtrl.addListener(_onAnyChange);
    // El doc cambia el state del cubit en cada keystroke (afecta clienteId,
    // clienteGenerico, botón Buscar). Como el numpad escribe directo al
    // controller (sin pasar por TextField.onChanged), el sync se hace acá.
    _docCtrl.addListener(_onDocChange);

    _efectivoFocus.addListener(() => _onInputFocus(
          focus: _efectivoFocus,
          ctrl: _efectivoCtrl,
          titulo: 'Pago efectivo',
          modo: _ModoNumpad.monto,
        ));
    _yapeFocus.addListener(() => _onInputFocus(
          focus: _yapeFocus,
          ctrl: _yapeCtrl,
          titulo: 'Pago Yape',
          modo: _ModoNumpad.monto,
        ));
    _yapeRefFocus.addListener(() => _onInputFocus(
          focus: _yapeRefFocus,
          ctrl: _yapeRefCtrl,
          titulo: 'N° de operación Yape',
          modo: _ModoNumpad.documento,
        ));
    _docFocus.addListener(() => _onInputFocus(
          focus: _docFocus,
          ctrl: _docCtrl,
          titulo: 'Documento del cliente',
          modo: _ModoNumpad.documento,
        ));

    // Numpad inicializado por default vinculado al efectivo. Queda visible
    // siempre, listo para tipear; cambia su controller al input que el
    // cajero enfoque después.
    _numpadCtrl = NumpadController(textController: _efectivoCtrl);
    _numpadTitulo = 'Pago efectivo';
    _modoNumpad = _ModoNumpad.monto;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Si entramos a cobro y el cubit tiene un cliente resuelto previo
      // (típico al re-entrar tras hacer pop), pero el TextField local
      // arranca vacío, sincronizamos el state al input visible (vacío).
      // Esto limpia clienteId/clienteEmpresaId/nombreClienteResuelto.
      final cubit = context.read<VentaRapidaCubit>();
      if (_docCtrl.text.isEmpty &&
          cubit.state.numeroDocCliente.isNotEmpty) {
        cubit.setNumeroDocCliente('');
      }
      // Foco automático al efectivo para que el cajero pueda tipear sin
      // tap previo.
      _efectivoFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _numpadCtrl?.dispose();
    _efectivoCtrl.dispose();
    _efectivoFocus.dispose();
    _yapeCtrl.dispose();
    _yapeFocus.dispose();
    _yapeRefCtrl.dispose();
    _yapeRefFocus.dispose();
    _docCtrl.dispose();
    _docFocus.dispose();
    for (final p in _otrosPagos) {
      p.dispose();
    }
    super.dispose();
  }

  void _onAnyChange() => setState(() {});

  /// Tope de dígitos por contexto del input. El numpad lo usa para
  /// bloquear escritura más allá del tope (DNI=8, RUC=11, N° op=6).
  int? _maxDigitosPara(TextEditingController ctrl) {
    if (ctrl == _docCtrl) {
      final tipo = context.read<VentaRapidaCubit>().state.tipoDocCliente;
      if (tipo == 'DNI') return 8;
      if (tipo == 'RUC') return 11;
      return null;
    }
    if (ctrl == _yapeRefCtrl) return 6;
    if (_otrosPagos.any((p) => p.refCtrl == ctrl)) return 6;
    return null; // montos no tienen tope (limit por overflow del double).
  }

  /// Listener del `_docCtrl`: sincroniza el state del cubit con el texto
  /// del controller. Necesario porque el numpad escribe al controller
  /// directamente (no pasa por `TextField.onChanged`).
  void _onDocChange() {
    if (!mounted) return;
    final text = _docCtrl.text;
    final cubit = context.read<VentaRapidaCubit>();
    if (cubit.state.numeroDocCliente != text) {
      cubit.setNumeroDocCliente(text);
    }
    setState(() {});
  }

  /// Vincula el numpad al input que gana foco. El numpad sigue visible
  /// siempre; al perder foco mantiene el último controller. El `modo`
  /// determina si el numpad presenta chips de quick amounts y la acción
  /// "Exacto" (montos) o se reduce a entrada simple (documento/referencia).
  void _onInputFocus({
    required FocusNode focus,
    required TextEditingController ctrl,
    required String titulo,
    required _ModoNumpad modo,
  }) {
    if (!focus.hasFocus) return;
    final mismoCtrl = _numpadCtrl?.textController == ctrl;
    final mismoModo = _modoNumpad == modo;
    if (mismoCtrl && mismoModo) return;
    if (!mismoCtrl) {
      _numpadCtrl?.dispose();
      final esDoc = modo == _ModoNumpad.documento;
      setState(() {
        _numpadCtrl = NumpadController(
          textController: ctrl,
          // Documento: sin decimales (DNI, RUC, N° op son enteros).
          decimales: esDoc ? 0 : 2,
          // Documento: sin separadores de miles (44885296, no 44,885,296).
          formatearMiles: !esDoc,
          // Tope de dígitos según el contexto del input.
          maxDigitos: _maxDigitosPara(ctrl),
        );
        _numpadTitulo = titulo;
        _modoNumpad = modo;
      });
    } else {
      setState(() {
        _numpadTitulo = titulo;
        _modoNumpad = modo;
      });
    }
  }

  /// Total recibido considerando: efectivo + yape (inputs locales)
  /// + las filas locales de "otros" pagos. Lee el monto vía
  /// `CurrencyUtilsImproved.parseToDouble` porque el `CurrencyTextField`
  /// formatea el texto con separadores de miles (ej. "1,200.00").
  double _calcularTotalRecibido() {
    final efectivo = CurrencyUtilsImproved.parseToDouble(_efectivoCtrl.text);
    final yape = CurrencyUtilsImproved.parseToDouble(_yapeCtrl.text);
    final otros = _otrosPagos.fold<double>(
      0,
      (sum, p) => sum + CurrencyUtilsImproved.parseToDouble(p.montoCtrl.text),
    );
    return efectivo + yape + otros;
  }

  void _persistirPagos(BuildContext context) {
    final cubit = context.read<VentaRapidaCubit>();
    // Antes de cobrar, sincronizamos state.pagos con los inputs locales:
    // limpiamos todo y volvemos a agregar desde los TextFields.
    while (cubit.state.pagos.isNotEmpty) {
      cubit.eliminarPago(cubit.state.pagos.length - 1);
    }
    final efe = CurrencyUtilsImproved.parseToDouble(_efectivoCtrl.text);
    final yape = CurrencyUtilsImproved.parseToDouble(_yapeCtrl.text);
    if (efe > 0) cubit.agregarPago(metodo: 'EFECTIVO', monto: efe);
    if (yape > 0) {
      cubit.agregarPago(
        metodo: 'YAPE',
        monto: yape,
        referencia: _yapeRefCtrl.text.trim().isEmpty ? null : _yapeRefCtrl.text.trim(),
      );
    }
    for (final p in _otrosPagos) {
      final monto = CurrencyUtilsImproved.parseToDouble(p.montoCtrl.text);
      if (monto <= 0) continue;
      final ref = p.refCtrl.text.trim();
      cubit.agregarPago(
        metodo: p.metodo,
        monto: monto,
        // Solo enviamos banco si el método lo amerita (TARJETA/TRANSFERENCIA).
        banco: requiereBancoPago(p.metodo) ? p.banco : null,
        referencia: ref.isEmpty ? null : ref,
      );
    }
  }

  void _agregarOtraFila(String metodo) {
    final pago = _OtroPago(metodo: metodo, refInicial: '000');
    pago.montoCtrl.addListener(_onAnyChange);
    final tituloMonto =
        'Pago ${pago.metodo[0]}${pago.metodo.substring(1).toLowerCase()}';
    // Listeners de foco para vincular el numpad cuando se enfoque cada input.
    pago.montoFocus.addListener(() => _onInputFocus(
          focus: pago.montoFocus,
          ctrl: pago.montoCtrl,
          titulo: tituloMonto,
          modo: _ModoNumpad.monto,
        ));
    pago.refFocus.addListener(() => _onInputFocus(
          focus: pago.refFocus,
          ctrl: pago.refCtrl,
          titulo: 'N° de operación $metodo',
          modo: _ModoNumpad.documento,
        ));
    setState(() => _otrosPagos.add(pago));
    // Tras el primer frame, llevamos el foco al input de monto recién creado
    // para que el cajero pueda tipear de inmediato.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      pago.montoFocus.requestFocus();
    });
  }

  void _quitarOtraFila(int idx) {
    if (idx < 0 || idx >= _otrosPagos.length) return;
    final pago = _otrosPagos[idx];
    pago.montoCtrl.removeListener(_onAnyChange);
    pago.dispose();
    setState(() => _otrosPagos.removeAt(idx));
  }

  /// Flujo final de Cobrar: persiste los pagos en el state, detecta si
  /// la venta dispara la advertencia de Ley 28194 (≥ S/2,000 con
  /// efectivo cuya parte bancarizada no cubre el umbral), pide
  /// confirmación al cajero, y finalmente llama al cubit. La venta SE
  /// CONCRETA aunque se haya pagado en efectivo sobre el límite — el
  /// cliente asume el riesgo y queda registrado en `bancarizacionAdvertida`.
  Future<void> _confirmarYCobrar(BuildContext context) async {
    _persistirPagos(context);
    final cubit = context.read<VentaRapidaCubit>();
    final state = cubit.state;

    // Total efectivo + total bancarizado (no-EFECTIVO/CREDITO).
    final totalEfectivo = state.pagos
        .where((p) => p['metodo'] == 'EFECTIVO')
        .fold<double>(0, (s, p) => s + (p['monto'] as num).toDouble());
    final totalBancarizado = state.pagos
        .where((p) => p['metodo'] != 'EFECTIVO' && p['metodo'] != 'CREDITO')
        .fold<double>(0, (s, p) => s + (p['monto'] as num).toDouble());

    bool aceptaRiesgo = false;
    if (aplicaBancarizacion(totalVentaPen: state.total) &&
        totalEfectivo > 0 &&
        totalBancarizado < umbralBancarizacionPen) {
      final ok = await _confirmarRiesgoBancarizacion(
        totalVenta: state.total,
        efectivo: totalEfectivo,
        bancarizado: totalBancarizado,
      );
      if (!ok) return;
      aceptaRiesgo = true;
    }

    if (!context.mounted) return;
    cubit.cobrar(aceptaRiesgoBancarizacion: aceptaRiesgo);
  }

  /// Dialog Ley 28194: explica al cajero las consecuencias para el
  /// cliente y pide confirmación explícita. Mismo patrón que el POS
  /// avanzado para consistencia entre ambos flujos.
  Future<bool> _confirmarRiesgoBancarizacion({
    required double totalVenta,
    required double efectivo,
    required double bancarizado,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded,
            color: Colors.red[700], size: 36),
        title: const Text('Ley 28194 — bancarización'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta venta de S/ ${totalVenta.toStringAsFixed(2)} supera el límite '
              'de S/ ${umbralBancarizacionPen.toStringAsFixed(0)}, pero el pago en '
              'efectivo (S/ ${efectivo.toStringAsFixed(2)}) excede lo permitido por ley.',
              style: const TextStyle(fontSize: 10),
            ),
            const SizedBox(height: 8),
            Text(
              'Parte bancarizada actual: S/ ${bancarizado.toStringAsFixed(2)} '
              '(< S/ ${umbralBancarizacionPen.toStringAsFixed(0)}).',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Text(
                'Consecuencias para el cliente:\n'
                '• Pierde el derecho a deducir el IGV (crédito fiscal).\n'
                '• El gasto puede ser observado por SUNAT.\n'
                '• Posibles multas tributarias al cliente.',
                style: TextStyle(fontSize: 10, color: Colors.red[900]),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'La boleta o factura se emitirá igualmente. ¿El cliente '
              'confirma asumir este riesgo?',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cliente acepta riesgo',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Construye la barra inferior. Cuando el cajero está editando un
  /// input que requiere teclado del sistema (referencia, doc), oculta el
  /// numpad y muestra solo la barra Atrás/Cobrar para que no se
  /// superponga con el teclado nativo. En el resto del tiempo, el numpad
  /// completo es el centro de la operación con Atrás/Cobrar como acciones.
  Widget _buildBottomBar(
      BuildContext context, VentaRapidaState state, double faltante) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    // Banco obligatorio cuando: aplica bancarización (≥ S/2,000) Y hay
    // un pago no-EFECTIVO con método que requiere entidad financiera
    // (TARJETA / TRANSFERENCIA) sin banco seleccionado.
    final bancarizable = aplicaBancarizacion(totalVentaPen: state.total);
    final faltaBanco = bancarizable &&
        _otrosPagos.any((p) {
          final monto = CurrencyUtilsImproved.parseToDouble(p.montoCtrl.text);
          return monto > 0 &&
              requiereBancoPago(p.metodo) &&
              (p.banco == null || p.banco!.isEmpty);
        });
    final puedeCobrar = !state.procesando &&
        faltante <= 0 &&
        state.items.isNotEmpty &&
        !faltaBanco;
    final esModoMonto = _modoNumpad == _ModoNumpad.monto;

    final accionAtras = NumpadAction(
      label: 'Atrás',
      icon: Icons.arrow_back,
      color: Colors.red.shade400,
      enabled: !state.procesando,
      onTap: () => context.pop(),
    );

    final accionExacto = NumpadAction(
      label: 'Exacto',
      icon: Icons.flash_on,
      // En modo documento (DNI/RUC/N° op) Exacto no aplica.
      enabled: esModoMonto && faltante > 0 && _numpadCtrl != null,
      onTap: () {
        if (faltante <= 0) return;
        final actual = _numpadCtrl!.value;
        _numpadCtrl!.setValue(actual + faltante);
      },
    );

    final etiquetaCobrar = faltante > 0
        ? 'Falta S/ ${faltante.toStringAsFixed(2)}'
        : (faltaBanco ? 'Falta banco' : 'Cobrar');
    final accionCobrar = NumpadAction(
      label: etiquetaCobrar,
      icon: (faltante > 0 || faltaBanco) ? null : Icons.check_circle_outline,
      destacado: true,
      enabled: puedeCobrar,
      loading: state.procesando,
      onTap: () => _confirmarYCobrar(context),
    );

    return SafeArea(
      top: false,
      child: keyboardOpen
          ? _buildBarraMini(state, [accionAtras, accionCobrar])
          : (_numpadCtrl != null
              ? PosNumpad(
                  controller: _numpadCtrl!,
                  titulo: _numpadTitulo,
                  // En modo documento ocultamos los chips (no son montos
                  // sumables). Pasar null al numpad los oculta.
                  quickAmounts:
                      esModoMonto ? const [10, 20, 50, 100, 200] : null,
                  // DNI/RUC/N° op no llevan punto decimal.
                  permiteDecimal: esModoMonto,
                  mostrarDobleZero: esModoMonto,
                  acciones: [accionAtras, accionExacto, accionCobrar],
                )
              : const SizedBox.shrink()),
    );
  }

  /// Barra inferior compacta cuando el numpad está oculto (teclado del
  /// sistema activo en input de referencia/doc).
  Widget _buildBarraMini(VentaRapidaState state, List<NumpadAction> acciones) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Row(
        children: acciones
            .map((a) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ElevatedButton(
                      onPressed: (a.enabled && !a.loading) ? a.onTap : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: a.color ??
                            (a.destacado
                                ? Colors.green.shade500
                                : Colors.grey.shade200),
                        foregroundColor: a.destacado || a.color != null
                            ? Colors.white
                            : Colors.black87,
                        disabledBackgroundColor: Colors.grey.shade200,
                        disabledForegroundColor: Colors.grey.shade500,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: a.loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (a.icon != null) ...[
                                  Icon(a.icon, size: 16),
                                  const SizedBox(width: 4),
                                ],
                                Flexible(
                                  child: Text(
                                    a.label,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  /// El botón "Buscar" se habilita cuando el doc tiene la longitud correcta
  /// para el tipo seleccionado (DNI: 8, RUC: 11) y no es el placeholder
  /// genérico '00000000'.
  bool _validoParaBuscar(String tipoDoc, String doc) {
    final d = doc.trim();
    if (d == '00000000') return false;
    if (tipoDoc == 'DNI') return d.length == 8;
    if (tipoDoc == 'RUC') return d.length == 11;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VentaRapidaCubit, VentaRapidaState>(
      listener: (context, state) {
        if (state.preciosDesactualizados != null) {
          // El backend rechazó la venta porque el precio cambió. Mostrar
          // dialog con la lista de productos afectados (cantidad, precio
          // viejo vs nuevo) y dos opciones: aplicar los nuevos precios al
          // carrito o cancelar.
          _mostrarDialogPreciosDesactualizados(
            context, state.preciosDesactualizados!);
        }
        if (state.stockInsuficiente != null) {
          // El backend rechazó la venta porque otro cajero vendió ese
          // stock primero. Mostrar dialog con cantidades pedidas vs
          // disponibles + acción "Ajustar al disponible".
          _mostrarDialogStockInsuficiente(context, state.stockInsuficiente!);
        }
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          context.read<VentaRapidaCubit>().clearError();
        }
        if (state.ventaCompletadaId != null) {
          // Capturamos el id ANTES de resetear (resetCompletada lo limpia)
          // para navegar al preview del ticket con la opción de imprimir.
          final ventaId = state.ventaCompletadaId!;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Venta registrada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          context.read<VentaRapidaCubit>().resetCompletada();
          // Stack post-venta deseada: dashboard → productos → ticket.
          // Así el back desde ticket cae en productos (nueva venta),
          // y el back desde productos cae en dashboard (no sale de
          // la app). Los pushes se difieren entre frames para que
          // GoRouter complete cada transición antes de la siguiente.
          context.go('/empresa/dashboard');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            context.push('/empresa/venta-rapida');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              context.push('/empresa/ventas/$ventaId/ticket');
            });
          });
        }
        // Si el cubit limpió el doc (ej. al cambiar a FACTURA), reflejarlo
        // en el TextField local para evitar inconsistencia visual.
        if (state.numeroDocCliente.isEmpty && _docCtrl.text.isNotEmpty) {
          _docCtrl.clear();
        }
        // Si el cajero cambió de tipo de doc mientras el numpad apunta al
        // _docCtrl, ajustamos su tope (DNI=8, RUC=11) y truncamos si
        // ya tipeó de más.
        if (_numpadCtrl?.textController == _docCtrl) {
          final nuevo = _maxDigitosPara(_docCtrl);
          if (_numpadCtrl!.maxDigitos != nuevo) {
            _numpadCtrl!.maxDigitos = nuevo;
            _numpadCtrl!.truncarSiExcede();
          }
        }
      },
      builder: (context, state) {
        final tituloAppBar = state.tipoComprobante == 'TICKET'
            ? 'Nota de Venta'
            : state.tipoComprobante == 'BOLETA'
                ? 'Boleta de Venta'
                : 'Factura';

        final totalCobrar = state.total;
        final totalRecibido = _calcularTotalRecibido();
        final diferencia = totalRecibido - totalCobrar;
        // Tolerancia de medio centavo para no mostrar "falta 0.00" por redondeo.
        final faltante = diferencia < -_kPenRoundingTolerance ? -diferencia : 0.0;
        final vuelto = diferencia > _kPenRoundingTolerance ? diferencia : 0.0;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.blue1,
            foregroundColor: Colors.white,
            title: Text(tituloAppBar),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Total a cobrar  ',
                            style: TextStyle(fontSize: 14, color: Colors.black87)),
                        Text(
                          'S/ ${totalCobrar.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (totalCobrar >= 2000)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      border: Border.all(color: Colors.amber.shade300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 20, color: Colors.amber.shade800),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bancarización Ley 28194: ventas ≥ S/ 2,000 deben pagarse '
                            'por medio bancarizado (Yape, Plin, tarjeta, transferencia) '
                            'con N° de operación. Si el pago es solo en efectivo, el '
                            'cliente pierde derecho a sustento de gasto/IGV.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.amber.shade900,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),

                // Tipo doc + Genérico. Si es FACTURA, el tipo queda fijado
                // a RUC (SUNAT solo permite facturas contra RUC) y se oculta
                // el botón Genérico (CLIENTES VARIOS no aplica a factura).
                Row(
                  children: [
                    Expanded(
                      child: CustomDropdown<String>(
                        value: state.tipoDocCliente,
                        borderColor: AppColors.blue1,
                        enabled: state.tipoComprobante != 'FACTURA',
                        items: const [
                          DropdownItem<String>(value: 'DNI', label: 'DNI'),
                          DropdownItem<String>(value: 'RUC', label: 'RUC'),
                          DropdownItem<String>(value: 'CE', label: 'CE'),
                          DropdownItem<String>(value: 'PASAPORTE', label: 'Pasaporte'),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          context.read<VentaRapidaCubit>().setTipoDocCliente(v);
                          _docCtrl.clear();
                        },
                      ),
                    ),
                    if (state.tipoComprobante != 'FACTURA') ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 35,
                        child: OutlinedButton(
                          onPressed: () {
                            context.read<VentaRapidaCubit>().setClienteGenerico();
                            _docCtrl.text = '00000000';
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.green.shade500),
                            foregroundColor: Colors.green.shade600,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            state.clienteGenerico ? 'Genérico ✓' : 'Genérico',
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        controller: _docCtrl,
                        focusNode: _docFocus,
                        readOnly: true,
                        fieldType: FieldType.number,
                        hintText: state.tipoDocCliente,
                        borderColor: AppColors.blue1,
                        maxLength: state.tipoDocCliente == 'DNI'
                            ? 8
                            : (state.tipoDocCliente == 'RUC' ? 11 : null),
                      ),
                    ),
                    if (state.tipoDocCliente == 'DNI' ||
                        state.tipoDocCliente == 'RUC') ...[
                      const SizedBox(width: 8),
                      _BotonBuscarDocumento(
                        habilitado: _validoParaBuscar(state.tipoDocCliente, _docCtrl.text) &&
                            !state.buscandoCliente,
                        cargando: state.buscandoCliente,
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          final cubit = context.read<VentaRapidaCubit>();
                          if (state.tipoDocCliente == 'DNI') {
                            cubit.buscarClientePorDni(_docCtrl.text);
                          } else {
                            cubit.buscarClientePorRuc(_docCtrl.text);
                          }
                        },
                      ),
                    ],
                  ],
                ),
                if (state.tipoComprobante == 'FACTURA')
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      'RUC obligatorio para Factura',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                if (state.nombreClienteResuelto.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            size: 16, color: Colors.green.shade600),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            state.nombreClienteResuelto,
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                //const SizedBox(height: 14),

                Row(
                  children: [
                    // Indicador visual fijo (Venta Rápida es siempre Contado);
                    // antes era un Radio deshabilitado pero la API quedó
                    // deprecada en Flutter 3.32 a favor de RadioGroup.
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Icon(
                        Icons.radio_button_checked,
                        size: 20,
                        color: AppColors.blue1,
                      ),
                    ),
                    const Text('Contado', style: TextStyle(fontSize: 12)),
                    const Spacer(),
                  ],
                ),
                //const SizedBox(height: 14),

                _PagoRow(
                  label: 'Pago efectivo',
                  controller: _efectivoCtrl,
                  focusNode: _efectivoFocus,
                ),
                //const SizedBox(height: 5),
                _PagoRow(
                  label: 'Pago Yape',
                  controller: _yapeCtrl,
                  focusNode: _yapeFocus,
                  refController: _yapeRefCtrl,
                  refFocusNode: _yapeRefFocus,
                  showRef: CurrencyUtilsImproved.parseToDouble(_yapeCtrl.text) > 0,
                  trailing: IconButton(
                    icon: const CircleAvatar(
                      radius: 13,
                      backgroundColor: AppColors.blue1,
                      child: Icon(Icons.add, color: Colors.white, size: 12),
                    ),
                    onPressed: () => _agregarOtroPago(context),
                    tooltip: 'Agregar otro método',
                  ),
                ),
                ..._otrosPagos.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final pago = entry.value;
                  final monto = CurrencyUtilsImproved.parseToDouble(pago.montoCtrl.text);
                  // Banco visible cuando el método requiere entidad financiera
                  // (TARJETA / TRANSFERENCIA) y hay monto tipeado.
                  final mostrarBanco = requiereBancoPago(pago.metodo) && monto > 0;
                  return Padding(
                    key: ValueKey(pago.id),
                    padding: const EdgeInsets.only(top: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PagoRow(
                          label: 'Pago ${pago.metodo[0]}${pago.metodo.substring(1).toLowerCase()}',
                          controller: pago.montoCtrl,
                          focusNode: pago.montoFocus,
                          refController: pago.refCtrl,
                          refFocusNode: pago.refFocus,
                          showRef: monto > 0,
                          trailing: IconButton(
                            icon: Icon(Icons.close, color: Colors.red.shade400),
                            onPressed: () => _quitarOtraFila(idx),
                            tooltip: 'Quitar',
                          ),
                        ),
                        if (mostrarBanco)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: _BancoSelector(
                              metodo: pago.metodo,
                              valor: pago.banco,
                              onChanged: (v) {
                                setState(() => pago.banco = v);
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                }),

                Row(
                  children: [
                    const Expanded(
                      child: Text('Total recibido', style: TextStyle(fontSize: 14)),
                    ),
                    Container(
                      width: 120,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        //color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        totalRecibido.toStringAsFixed(2),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Builder(
                  builder: (_) {
                    final mostrarFalta = faltante > 0;
                    final color = mostrarFalta
                        ? Colors.orange.shade800
                        : (vuelto > 0 ? Colors.green.shade700 : Colors.black54);
                    final monto = mostrarFalta ? faltante : vuelto;
                    final etiqueta = mostrarFalta ? 'Falta' : 'Vuelto';
                    return Row(
                      children: [
                        Text(
                          monto.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          etiqueta,
                          style: TextStyle(fontSize: 14, color: color),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomBar(context, state, faltante),
        );
      },
    );
  }

  Future<void> _agregarOtroPago(BuildContext context) async {
    // Métodos alineados con Venta Avanzada (POS).
    // EFECTIVO y YAPE no van acá porque ya están como inputs principales.
    final metodos = ['TARJETA', 'PLIN', 'TRANSFERENCIA'];
    final metodoElegido = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: metodos
              .map((m) => ListTile(
                    title: Text(m),
                    onTap: () => Navigator.of(context).pop(m),
                  ))
              .toList(),
        ),
      ),
    );
    if (metodoElegido == null || !context.mounted) return;
    _agregarOtraFila(metodoElegido);
  }

  /// Muestra un dialog con la lista de productos cuyo precio cambió en el
  /// backend mientras el cajero tenía el carrito armado (admin actualizó el
  /// precio). El cajero puede elegir:
  ///  - "Actualizar precios": aplica los precios nuevos al carrito (los
  ///    items quedan recalculados con los niveles según la cantidad). El
  ///    cajero ve el nuevo total y decide si reintentar el cobro.
  ///  - "Cancelar": cierra el dialog sin tocar el carrito. Sirve si el
  ///    cajero ya cobró al cliente en efectivo con el precio viejo y
  ///    necesita resolver la diferencia manualmente antes.
  /// El dialog NO reintenta el cobro automáticamente — la decisión vuelve
  /// al cajero para evitar cargos no deseados.
  Future<void> _mostrarDialogPreciosDesactualizados(
    BuildContext context,
    List<Map<String, dynamic>> divergencias,
  ) async {
    final accion = await showDialog<_AccionPrecios>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.orange.shade700, size: 22),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Precios actualizados',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                divergencias.length == 1
                    ? '1 producto del carrito tiene un precio nuevo:'
                    : '${divergencias.length} productos del carrito tienen precios nuevos:',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: SingleChildScrollView(
                  child: Column(
                    children: divergencias.map((d) {
                      final desc = (d['descripcion'] as String?) ?? 'Item';
                      final viejo = (d['precioCliente'] as num?)?.toDouble() ?? 0;
                      final nuevo = (d['precioServer'] as num?)?.toDouble() ?? 0;
                      final cant = (d['cantidad'] as num?)?.toDouble() ?? 0;
                      final subio = nuevo > viejo;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.grey.shade200, width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              desc,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  '${cant.toStringAsFixed(cant.truncateToDouble() == cant ? 0 : 2)} u  ·  ',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600),
                                ),
                                Text(
                                  'S/ ${viejo.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  subio
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  size: 12,
                                  color: subio
                                      ? Colors.red.shade600
                                      : Colors.green.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'S/ ${nuevo.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: subio
                                        ? Colors.red.shade700
                                        : Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogCtx, _AccionPrecios.cancelar),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.pop(dialogCtx, _AccionPrecios.aplicar),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Actualizar precios'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue1,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    final cubit = context.read<VentaRapidaCubit>();
    if (accion == _AccionPrecios.aplicar) {
      // `aplicarPreciosNuevosDeBackend` ahora es async porque también
      // re-fetchea los niveles (Por Mayor, Por Cientos, etc.) por si el
      // admin los cambió. Se espera para que el snackbar se muestre con
      // el carrito ya actualizado.
      await cubit.aplicarPreciosNuevosDeBackend();
      // Refrescar el catálogo de productos para que cuando el cajero
      // vuelva a la grilla (o vacíe el carrito y re-agregue), los cards
      // muestren el precio nuevo en vez del cacheado. Sin esto, el
      // precio queda "desfasado" en el catálogo hasta el próximo
      // pull-to-refresh manual.
      if (!context.mounted) return;
      try {
        context.read<ProductoListCubit>().reload();
      } catch (_) {
        // El cubit puede no estar en el árbol según la ruta de navegación.
        // Si no está, el catálogo se refresca cuando el usuario vuelva.
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Carrito actualizado. Revisá el total y volvé a cobrar.'),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      cubit.descartarAvisoPreciosDesactualizados();
    }
  }

  /// Muestra un dialog cuando el backend rechaza el cobro con
  /// `STOCK_INSUFICIENTE` (otro cajero vendió ese stock antes, o hubo
  /// merma/transferencia mientras tanto). Lista los productos afectados
  /// con la cantidad pedida vs la disponible y ofrece dos acciones:
  ///  - "Ajustar al disponible": cambia la cantidad de cada item al
  ///    stock real (o lo elimina si el disponible es 0).
  ///  - "Cancelar": mantiene el carrito; útil si el cajero ya hizo el
  ///    cobro físico y necesita resolver la operación manualmente.
  Future<void> _mostrarDialogStockInsuficiente(
    BuildContext context,
    List<Map<String, dynamic>> divergencias,
  ) async {
    final accion = await showDialog<_AccionStock>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.inventory_2_outlined,
                color: Colors.red.shade700, size: 22),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Stock insuficiente',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                divergencias.length == 1
                    ? '1 producto sin stock suficiente:'
                    : '${divergencias.length} productos sin stock suficiente:',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: SingleChildScrollView(
                  child: Column(
                    children: divergencias.map((d) {
                      final desc = (d['descripcion'] as String?) ?? 'Item';
                      final pedida = (d['cantidadSolicitada'] as num?)
                              ?.toDouble() ??
                          0;
                      final disp =
                          (d['stockDisponible'] as num?)?.toInt() ?? 0;
                      final sinStock = disp <= 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: sinStock
                              ? Colors.red.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: sinStock
                                ? Colors.red.shade200
                                : Colors.orange.shade200,
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              desc,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  'Pediste ${pedida.toStringAsFixed(pedida.truncateToDouble() == pedida ? 0 : 2)}  ·  ',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700),
                                ),
                                Icon(Icons.arrow_forward,
                                    size: 12,
                                    color: sinStock
                                        ? Colors.red.shade700
                                        : Colors.orange.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  sinStock
                                      ? 'Sin stock'
                                      : 'Disponible: $disp',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: sinStock
                                        ? Colors.red.shade700
                                        : Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogCtx, _AccionStock.cancelar),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dialogCtx, _AccionStock.ajustar),
            icon: const Icon(Icons.tune, size: 16),
            label: const Text('Ajustar al disponible'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue1,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    final cubit = context.read<VentaRapidaCubit>();
    if (accion == _AccionStock.ajustar) {
      await cubit.ajustarCarritoAStockDisponible();
      if (!context.mounted) return;
      // También refrescar el catálogo para que las cards reflejen el
      // stock real (otra venta lo bajó).
      try {
        context.read<ProductoListCubit>().reload();
      } catch (_) {/* cubit puede no estar en el árbol */}
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Carrito ajustado al stock disponible. Revisá y volvé a cobrar.'),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      cubit.descartarAvisoStockInsuficiente();
    }
  }
}

/// Acción elegida en el dialog de precios desactualizados.
enum _AccionPrecios { aplicar, cancelar }

/// Acción elegida en el dialog de stock insuficiente.
enum _AccionStock { ajustar, cancelar }

class _BotonBuscarDocumento extends StatelessWidget {
  final bool habilitado;
  final bool cargando;
  final VoidCallback onPressed;

  const _BotonBuscarDocumento({
    required this.habilitado,
    required this.cargando,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35,
      child: ElevatedButton(
        onPressed: habilitado ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue1,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: cargando
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.search, size: 18),
      ),
    );
  }
}

/// Selector de entidad financiera para TARJETA / TRANSFERENCIA.
/// Combina chips de bancos frecuentes + dropdown completo. El cajero
/// elige con un tap los más usados; los demás vía dropdown.
class _BancoSelector extends StatelessWidget {
  final String metodo;
  final String? valor;
  final ValueChanged<String?> onChanged;

  const _BancoSelector({
    required this.metodo,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hint = metodo == 'TARJETA'
        ? 'Banco / tarjeta de la operación'
        : 'Banco origen / destino';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Chips frecuentes — selección con un tap.
        SizedBox(
          height: 30,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: bancosFrecuentes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final b = bancosFrecuentes[i];
              final seleccionado = valor == b;
              return InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () => onChanged(b),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: seleccionado
                        ? AppColors.blue1
                        : AppColors.blue1.withValues(alpha: 0.08),
                    border: Border.all(
                      color: seleccionado
                          ? AppColors.blue1
                          : AppColors.blue1.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    b,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: seleccionado ? Colors.white : AppColors.blue1,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        // Dropdown completo (todas las entidades).
        CustomDropdown<String>(
          value: valor,
          borderColor: AppColors.blue1,
          hintText: hint,
          items: bancosPeru
              .map((b) => DropdownItem<String>(value: b, label: b))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Modos del numpad según el contexto del input enfocado.
enum _ModoNumpad { monto, documento }

/// Modelo local de un pago "otro" (TARJETA / PLIN / TRANSFERENCIA).
/// Mantiene sus controllers y se vuelca al cubit al cobrar.
class _OtroPago {
  final String id;
  final String metodo;
  final TextEditingController montoCtrl;
  final TextEditingController refCtrl;
  final FocusNode montoFocus;
  final FocusNode refFocus;
  /// Banco seleccionado (solo aplica cuando el método requiere entidad
  /// financiera: TARJETA / TRANSFERENCIA). Se persiste en `PagoVenta.banco`.
  String? banco;

  _OtroPago({required this.metodo, required String refInicial})
      : id = '${DateTime.now().microsecondsSinceEpoch}-$metodo',
        montoCtrl = TextEditingController(),
        refCtrl = TextEditingController(text: refInicial),
        montoFocus = FocusNode(),
        refFocus = FocusNode();

  void dispose() {
    montoCtrl.dispose();
    refCtrl.dispose();
    montoFocus.dispose();
    refFocus.dispose();
  }
}

class _PagoRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Widget? trailing;
  final TextEditingController? refController;
  final bool showRef;
  final FocusNode? focusNode;
  final FocusNode? refFocusNode;

  const _PagoRow({
    required this.label,
    required this.controller,
    this.trailing,
    this.refController,
    this.showRef = false,
    this.focusNode,
    this.refFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    final mostrarRef = showRef && refController != null;
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        if (trailing != null)
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: trailing!,
          ),
        const SizedBox(width: 8),
        SizedBox(
          width: mostrarRef ? 110 : 130,
          child: CurrencyTextField(
            label: 'Monto',
            controller: controller,
            focusNode: focusNode,
            readOnly: true,
            borderColor: AppColors.blue1,
            enableRealTimeValidation: false,
            hintText: '0.00',
          ),
        ),
        if (mostrarRef) ...[
          const SizedBox(width: 6),
          SizedBox(
            width: 75,
            child: CustomText(
              label: 'Ref. Oper',
              controller: refController!,
              focusNode: refFocusNode,
              readOnly: true,
              fieldType: FieldType.number,
              hintText: 'N° op.',
              borderColor: AppColors.blue1,
              maxLength: 6,
            ),
          ),
        ],
      ],
    );
  }
}
