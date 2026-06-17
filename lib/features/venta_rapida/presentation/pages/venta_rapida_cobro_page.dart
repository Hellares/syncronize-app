import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/currency/currency_formatter.dart';
import '../../../../core/widgets/currency/currency_textfield.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../widgets/cobro_yape_sheet.dart';
import '../../../../core/widgets/numpad/numpad_controller.dart';
import '../../../../core/widgets/numpad/pos_numpad.dart';
import '../../../../core/widgets/pagos_section_widget.dart'
    show
        aplicaBancarizacion,
        bancosFrecuentes,
        bancosPeru,
        requiereBancoPago,
        umbralBancarizacionPen;
import '../../../../core/widgets/autorizacion_dialog.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/utils/cuota_calculator.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/cliente_unificado_selector.dart';
import '../../../../core/widgets/popup_item.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../../cliente/data/cache/cliente_catalogo_service.dart';
import '../../../cliente/domain/entities/cliente.dart';
import '../../../cliente/domain/repositories/cliente_repository.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_cubit.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_state.dart';
import '../../../producto/presentation/bloc/producto_list/producto_list_cubit.dart';
import '../../../venta/domain/entities/venta_detalle_input.dart';
import '../bloc/venta_rapida_cubit.dart';

/// Resultado del guard de venta bajo costo. `cancelar=true` aborta el
/// cobro; `autorizadoPorId` viaja al cubit cuando se autorizó manualmente
/// una venta con margen negativo.
class _VentaBajoCostoResult {
  final String? autorizadoPorId;
  final bool cancelar;
  const _VentaBajoCostoResult({this.autorizadoPorId, this.cancelar = false});
}

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

  /// Cliente persona resuelto SIN cuenta de app (usuarioId null en el
  /// catálogo, o aún no sincronizado = recién creado por RENIEC). Muestra
  /// el chip "Crear acceso al app".
  bool _clienteSinCuenta = false;
  String? _accesoCheckedParaId;

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

    // Auto-búsqueda al completar los dígitos (reemplaza al botón buscar):
    // local-first → backend/RENIEC → si no existe, el cubit emite
    // docSinResultado y el listener abre el sheet de registro.
    final st = cubit.state;
    final doc = text.trim();
    // Ya resuelto para este mismo documento → no repetir.
    if (st.nombreClienteResuelto.isNotEmpty && st.numeroDocCliente == doc) {
      return;
    }
    if (st.tipoDocCliente == 'DNI' && doc.length == 8 && doc != '00000000') {
      cubit.buscarClientePorDni(doc);
    } else if (st.tipoDocCliente == 'RUC' && doc.length == 11) {
      cubit.buscarClientePorRuc(doc);
    }
  }

  /// Pega el documento desde el portapapeles: extrae solo dígitos, recorta al
  /// largo del tipo (DNI 8 / RUC 11) y lo escribe en `_docCtrl`. El listener
  /// `_onDocChange` sincroniza el state y dispara la búsqueda automática.
  Future<void> _pegarDocumento(VentaRapidaState state) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final digitos = (data?.text ?? '').replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El portapapeles no tiene un número de documento'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final max = state.tipoDocCliente == 'DNI'
        ? 8
        : (state.tipoDocCliente == 'RUC' ? 11 : digitos.length);
    _docCtrl.text =
        digitos.length > max ? digitos.substring(0, max) : digitos;
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
  bool _creditoPermitido(BuildContext context) {
    final configState = context.read<ConfiguracionEmpresaCubit>().state;
    if (configState is ConfiguracionEmpresaLoaded) {
      return configState.configuracion.ventaCreditoHabilitada;
    }
    return false;
  }

  Future<void> _confirmarYCobrar(BuildContext context) async {
    _persistirPagos(context);
    final cubit = context.read<VentaRapidaCubit>();
    final state = cubit.state;

    // Pago 100% por Yape/Plin → validación con api-yape (monto único + espera).
    // Si api-yape no está disponible o la empresa no lo tiene, la hoja cae al
    // cobro MANUAL (con el comprobante del cliente): la venta nunca se bloquea.
    final soloYapePlin = !state.esCredito &&
        state.pagos.isNotEmpty &&
        state.pagos
            .every((p) => p['metodo'] == 'YAPE' || p['metodo'] == 'PLIN');
    if (soloYapePlin) {
      await _cobrarConValidacionYape(context);
      return;
    }

    // Guard venta bajo costo: si hay líneas con margen negativo que NO
    // están en liquidación, pedimos autorización gerencial. Las líneas
    // en liquidación pasan automáticamente con resumen informativo.
    final autorizacion = await _confirmarVentaBajoCosto(context, state.items);
    if (autorizacion.cancelar) return;

    // Total efectivo + total bancarizado (no-EFECTIVO/CREDITO).
    final totalEfectivo = state.pagos
        .where((p) => p['metodo'] == 'EFECTIVO')
        .fold<double>(0, (s, p) => s + (p['monto'] as num).toDouble());
    final totalBancarizado = state.pagos
        .where((p) => p['metodo'] != 'EFECTIVO' && p['metodo'] != 'CREDITO')
        .fold<double>(0, (s, p) => s + (p['monto'] as num).toDouble());

    bool aceptaRiesgo = false;
    if (!state.esCredito &&
        aplicaBancarizacion(totalVentaPen: state.totalACobrar) &&
        totalEfectivo > 0 &&
        totalBancarizado < umbralBancarizacionPen) {
      final ok = await _confirmarRiesgoBancarizacion(
        totalVenta: state.totalACobrar,
        efectivo: totalEfectivo,
        bancarizado: totalBancarizado,
      );
      if (!ok) return;
      aceptaRiesgo = true;
    }

    if (!context.mounted) return;
    cubit.cobrar(
      aceptaRiesgoBancarizacion: aceptaRiesgo,
      ventaBajoCostoAutorizadaPorId: autorizacion.autorizadoPorId,
    );
  }

  /// Flujo de cobro Yape/Plin con validación api-yape: crea la venta pendiente,
  /// muestra el monto único a pagar y espera la confirmación (automática por
  /// webhook o manual con el comprobante).
  Future<void> _cobrarConValidacionYape(BuildContext context) async {
    final cubit = context.read<VentaRapidaCubit>();
    final state = cubit.state;
    final metodo = state.pagos.first['metodo'] as String; // YAPE | PLIN
    final total = state.totalACobrar;

    final res = await cubit.iniciarCobroYape();
    if (res == null || !context.mounted) return;

    // QR precargado del comercio: el del método elegido, con fallback al otro
    // si solo hay uno cargado (decisión: un solo QR sirve para ambos).
    final qrYape = res['qrYapeUrl'] as String?;
    final qrPlin = res['qrPlinUrl'] as String?;
    final qrUrl = metodo == 'PLIN' ? (qrPlin ?? qrYape) : (qrYape ?? qrPlin);

    final paid = await CobroYapeSheet.mostrar(
      context,
      ventaId: res['ventaId'] as String,
      total: total,
      payAmount: res['payAmount'] as double?,
      habilitado: res['habilitado'] == true,
      metodo: metodo,
      qrUrl: qrUrl,
      cubit: cubit,
      realtime: cubit.realtimeSync,
    );
    if (paid && context.mounted) {
      // Diferimos un frame: la hoja (modal) todavía se está desmontando, y si
      // emitimos ventaCompletadaId ahora, la cadena de navegación al ticket
      // (go dashboard → push venta-rápida → push ticket) se corta a media.
      // Esperar al siguiente frame deja la pila limpia → muestra el ticket
      // igual que el flujo normal.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        cubit.marcarVentaCompletada(res['ventaId'] as String);
      });
    }
  }

  /// Detecta líneas con margen negativo y devuelve:
  /// - `cancelado` si el usuario abandona el flujo
  /// - `_VentaBajoCostoResult(autorizadoPorId)` si autorizó (o si solo
  ///   había líneas en liquidación y aceptó el resumen)
  /// - `_VentaBajoCostoResult.skip` si no hay líneas con margen negativo
  Future<_VentaBajoCostoResult> _confirmarVentaBajoCosto(
    BuildContext context,
    List<VentaDetalleInput> items,
  ) async {
    final lineasPerdida = items
        .where((d) {
          final m = d.margenUnitario;
          return m != null && m < 0 && (d.precioCostoSnapshot ?? 0) > 0;
        })
        .toList();

    if (lineasPerdida.isEmpty) return const _VentaBajoCostoResult();

    final requierenAutorizacion =
        lineasPerdida.where((d) => !d.enLiquidacion).toList();
    final perdidaTotal =
        lineasPerdida.fold<double>(0, (s, d) => s + d.perdidaLinea);

    if (requierenAutorizacion.isEmpty) {
      // Todas las lineas estan en liquidacion activa: la autorizacion
      // gerencial ya fue dada al activar la liquidacion del producto, y
      // la perdida quedara registrada en VentaDetalle.margenSnapshot +
      // motivoLiquidacionSnapshot para el reporte. No tiene sentido
      // pedir confirmacion al cajero en cada venta.
      return const _VentaBajoCostoResult();
    }

    // Hay líneas con margen negativo SIN liquidación → autorización gerencial.
    final detalle = requierenAutorizacion.map((d) {
      final m = d.margenUnitario!;
      return '• ${d.descripcion}  →  pérdida S/ ${(-m * d.cantidad).toStringAsFixed(2)}';
    }).join('\n');

    final confirmado = await ConfirmDialog.show(
      context: context,
      type: ConfirmDialogType.warning,
      title: 'Venta bajo costo',
      customContent: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${requierenAutorizacion.length} producto(s) se venden bajo costo y NO están en liquidación.',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepOrange.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.deepOrange.shade200),
            ),
            child: Text(detalle, style: const TextStyle(fontSize: 11)),
          ),
          const SizedBox(height: 8),
          Text(
            'Pérdida total: S/ ${perdidaTotal.toStringAsFixed(2)}',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Para continuar se requiere autorización de GERENTE o ADMIN.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      confirmText: 'Autorizar',
    );
    if (confirmado != true || !context.mounted) {
      return const _VentaBajoCostoResult(cancelar: true);
    }

    final auth = await showAutorizacionDialog(
      context,
      operacion: 'VENTA_BAJO_COSTO',
      titulo: 'Autorizar venta bajo costo',
      descripcion:
          'Un GERENTE o ADMINISTRADOR debe autorizar esta venta con pérdida total S/ ${perdidaTotal.toStringAsFixed(2)}.',
    );
    if (auth == null) return const _VentaBajoCostoResult(cancelar: true);
    return _VentaBajoCostoResult(autorizadoPorId: auth.autorizadoPorId);
  }

  /// Dialog Ley 28194: explica al cajero las consecuencias para el
  /// cliente y pide confirmación explícita. Mismo patrón que el POS
  /// avanzado para consistencia entre ambos flujos.
  Future<bool> _confirmarRiesgoBancarizacion({
    required double totalVenta,
    required double efectivo,
    required double bancarizado,
  }) async {
    final result = await ConfirmDialog.show(
      context: context,
      type: ConfirmDialogType.destructive,
      icon: Icons.warning_amber_rounded,
      title: 'Ley 28194 — bancarización',
      barrierDismissible: false,
      customContent: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Esta venta de S/ ${totalVenta.toStringAsFixed(2)} supera el límite '
            'de S/ ${umbralBancarizacionPen.toStringAsFixed(0)}, pero el pago en '
            'efectivo (S/ ${efectivo.toStringAsFixed(2)}) excede lo permitido por ley.',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Parte bancarizada actual: S/ ${bancarizado.toStringAsFixed(2)} '
            '(< S/ ${umbralBancarizacionPen.toStringAsFixed(0)}).',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
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
          const Text(
            'La boleta o factura se emitirá igualmente. ¿El cliente '
            'confirma asumir este riesgo?',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      confirmText: 'Cliente acepta',
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
    final bancarizable = aplicaBancarizacion(totalVentaPen: state.totalACobrar);
    final faltaBanco = bancarizable &&
        _otrosPagos.any((p) {
          final monto = CurrencyUtilsImproved.parseToDouble(p.montoCtrl.text);
          return monto > 0 &&
              requiereBancoPago(p.metodo) &&
              (p.banco == null || p.banco!.isEmpty);
        });
    final creditoSinCliente = state.esCredito &&
        (state.clienteGenerico ||
         state.numeroDocCliente.isEmpty ||
         state.numeroDocCliente == '00000000' ||
         (state.clienteId == null && state.clienteEmpresaId == null));
    final puedeCobrar = !state.procesando &&
        faltante <= 0 &&
        state.items.isNotEmpty &&
        !faltaBanco &&
        !creditoSinCliente;
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
      enabled: esModoMonto && faltante > 0 && _numpadCtrl != null,
      onTap: () {
        if (faltante <= 0) return;
        final actual = _numpadCtrl!.value;
        _numpadCtrl!.setValue(actual + faltante);
      },
    );

    final etiquetaCobrar = faltante > 0
        ? 'Falta S/ ${faltante.toStringAsFixed(2)}'
        : (faltaBanco
            ? 'Falta banco'
            : (creditoSinCliente ? 'Falta cliente' : 'Cobrar'));
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
  /// Cambia el tipo de documento desde el chip (casos raros: CE,
  /// Pasaporte, RUC en nota de venta) y limpia el campo.
  void _setTipoDoc(BuildContext context, String tipo) {
    context.read<VentaRapidaCubit>().setTipoDocCliente(tipo);
    _docCtrl.clear();
  }

  /// Verifica contra el catálogo local si el cliente persona resuelto
  /// tiene cuenta de app. Si el cliente no está aún en el catálogo
  /// (recién creado vía RENIEC) se asume SIN cuenta — ese flujo nunca
  /// crea Usuario.
  Future<void> _checkAccesoCliente(VentaRapidaState st) async {
    final id = st.clienteId;
    if (id == null ||
        st.nombreClienteResuelto.isEmpty ||
        st.clienteGenerico ||
        st.empresaId == null) {
      if (_clienteSinCuenta && mounted) {
        setState(() => _clienteSinCuenta = false);
      }
      _accesoCheckedParaId = null;
      return;
    }
    if (_accesoCheckedParaId == id) return;
    _accesoCheckedParaId = id;

    final lista =
        await ClienteCatalogoService.instance.hydrate(st.empresaId!);
    if (!mounted || _accesoCheckedParaId != id) return;
    Cliente? c;
    for (final x in lista) {
      if (x.id == id) {
        c = x;
        break;
      }
    }
    setState(() => _clienteSinCuenta =
        c == null || c.usuarioId == null || c.usuarioId!.isEmpty);
  }

  /// Crea el acceso al app para el cliente resuelto (login = DNI) y
  /// muestra el mensaje para dictarle las credenciales.
  Future<void> _crearAccesoCliente(String clienteId) async {
    setState(() => _clienteSinCuenta = false); // optimista
    final result =
        await locator<ClienteRepository>().crearAcceso(clienteId: clienteId);
    if (!mounted) return;
    if (result is Success<Map<String, dynamic>>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.data['mensaje']?.toString() ??
                'Acceso creado: que ingrese con su DNI como usuario y contraseña',
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 6),
        ),
      );
    } else if (result is Error<Map<String, dynamic>>) {
      setState(() => _clienteSinCuenta = true); // revertir
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  /// Abre el ClienteUnificadoSelector para buscar por NOMBRE en el
  /// catálogo local (instantáneo) — el camino para el cliente frecuente
  /// al que no quieres pedirle el documento. Para FACTURA solo empresas.
  Future<void> _abrirSelectorCliente(
    BuildContext context,
    VentaRapidaState state, {
    String? documentoInicial,
    TipoClienteSeleccion? tipoForzado,
  }) async {
    final empresaId = state.empresaId;
    if (empresaId == null || empresaId.isEmpty) return;
    FocusScope.of(context).unfocus();
    final cubit = context.read<VentaRapidaCubit>();
    final result = await ClienteUnificadoSelector.show(
      context: context,
      empresaId: empresaId,
      tipoPermitido: tipoForzado ??
          (state.tipoComprobante == 'FACTURA'
              ? TipoClienteSeleccion.empresa
              : null),
      documentoInicial: documentoInicial,
    );
    if (result == null || !mounted) return;

    if (result.tipo == TipoClienteSeleccion.persona) {
      cubit.setClienteDesdeSelector(
        clienteId: result.clienteId,
        clienteEmpresaId: null,
        nombre: result.nombreCompleto ?? '',
        tipoDoc: 'DNI',
        numeroDoc: result.dni,
      );
      _docCtrl.text = result.dni ?? '';
    } else {
      cubit.setClienteDesdeSelector(
        clienteId: null,
        clienteEmpresaId: result.clienteEmpresaId,
        nombre: result.razonSocial ?? '',
        tipoDoc: 'RUC',
        numeroDoc: result.ruc,
      );
      _docCtrl.text = result.ruc ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VentaRapidaCubit, VentaRapidaState>(
      listener: (context, state) {
        _checkAccesoCliente(state);
        if (state.docSinResultado != null) {
          // El documento no existe ni local ni en el sistema/API externa:
          // abrir el sheet de registro pre-llenado para crearlo al vuelo.
          final doc = state.docSinResultado!;
          context.read<VentaRapidaCubit>().limpiarDocSinResultado();
          _abrirSelectorCliente(
            context,
            state,
            documentoInicial: doc,
            tipoForzado: doc.length == 11
                ? TipoClienteSeleccion.empresa
                : TipoClienteSeleccion.persona,
          );
        }
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
          //
          // IMPORTANTE: usamos la instancia de GoRouter (global, estable) y NO
          // `context`. El primer `go` destruye esta página de cobro y su
          // `context`; si encadenáramos con `context.push` + `context.mounted`,
          // a veces el context ya está desmontado en el frame siguiente y el
          // push del TICKET se cancelaba → la venta terminaba en productos.
          // Bug flaky reportado: el router no se desmonta, así que siempre
          // completa los 3 pasos.
          final router = GoRouter.of(context);
          router.go('/empresa/dashboard');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            router.push('/empresa/venta-rapida');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              router.push('/empresa/ventas/$ventaId/ticket');
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

        // Lo que el cliente paga HOY: total − adelantos aplicados de
        // órdenes de servicio (el comprobante sale por el total).
        final totalCobrar = state.totalACobrar;
        final totalRecibido = _calcularTotalRecibido();
        final diferencia = totalRecibido - totalCobrar;
        final faltante = state.esCredito
            ? 0.0
            : (diferencia < -_kPenRoundingTolerance ? -diferencia : 0.0);
        final vuelto = diferencia > _kPenRoundingTolerance ? diferencia : 0.0;

        return Scaffold(
          // appBar: AppBar(
          //   backgroundColor: AppColors.blue1,
          //   foregroundColor: Colors.white,
          //   title: Text(tituloAppBar),
          //   actions: [
          //     if (_creditoPermitido(context)) ...[
          //       _AppBarCondicionChip(
          //         label: 'Contado',
          //         selected: !state.esCredito,
          //         onTap: () => context.read<VentaRapidaCubit>().setCondicionPago('CONTADO'),
          //       ),
          //       _AppBarCondicionChip(
          //         label: 'Credito',
          //         selected: state.esCredito,
          //         selectedColor: Colors.orange,
          //         onTap: () => context.read<VentaRapidaCubit>().setCondicionPago('CREDITO'),
          //       ),
          //       const SizedBox(width: 8),
          //     ],
          //   ],
          // ),
          appBar: SmartAppBar(
            title: tituloAppBar,
            backgroundColor: AppColors.blue1,
            foregroundColor: Colors.white,
            actions: [
              if (_creditoPermitido(context)) ...[
                _AppBarCondicionChip(
                  label: 'Contado',
                  selected: !state.esCredito,
                  onTap: () => context.read<VentaRapidaCubit>().setCondicionPago('CONTADO'),
                ),
                _AppBarCondicionChip(
                  label: 'Crédito',
                  selected: state.esCredito,
                  selectedColor: Colors.orange,
                  onTap: () => context.read<VentaRapidaCubit>().setCondicionPago('CREDITO'),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Con adelanto aplicado el contexto va en su propia
                      // línea (en una sola fila desbordaba en 400px).
                      if (state.adelantoAplicado > 0) ...[
                        Text(
                          'Total S/ ${state.total.toStringAsFixed(2)} · Adelanto -S/ ${state.adelantoAplicado.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Total a cobrar:  ',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.black87)),
                          AppSubtitle(
                            'S/ ${totalCobrar.toStringAsFixed(2)}',
                            color: AppColors.blue1,
                            fontSize: 18,
                            font: AppFont.amazonEmberBold
                          ),
                        ],
                      ),
                    ],
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

                // El tipo de documento se DERIVA del comprobante:
                // FACTURA → RUC fijo (SUNAT); TICKET/BOLETA → DNI por
                // defecto. El chip compacto cubre los casos raros
                // (CE/Pasaporte/RUC en nota de venta) sin gastar una fila.
                Row(
                  children: [
                    if (state.tipoComprobante == 'FACTURA')
                      Container(
                        height: 33,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: AppColors.blue1, width: 0.6),
                        ),
                        child: const Text(
                          'RUC',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.blue1,
                          ),
                        ),
                      )
                    else
                      CustomActionMenu(
                        // Misma config que el menú de productos: yNudge
                        // baja el menú para que se despliegue DEBAJO del
                        // chip (sin nudge queda centrado encima, muy arriba).
                        yNudge: 50,
                        menuWidth: 110,
                        borderRadius: 8,
                        itemHeight: 30,
                        items: [
                          ActionMenuItem(
                            type: ActionMenuType.dni,
                            label: 'DNI',
                            icon: Icons.badge_outlined,
                            color: AppColors.blue1,
                            onTap: () => _setTipoDoc(context, 'DNI'),
                          ),
                          ActionMenuItem(
                            type: ActionMenuType.ruc,
                            label: 'RUC',
                            icon: Icons.business_outlined,
                            color: AppColors.blue1,
                            onTap: () => _setTipoDoc(context, 'RUC'),
                          ),
                          ActionMenuItem(
                            type: ActionMenuType.ce,
                            label: 'CE',
                            icon: Icons.credit_card_outlined,
                            color: AppColors.blue1,
                            onTap: () => _setTipoDoc(context, 'CE'),
                          ),
                          ActionMenuItem(
                            type: ActionMenuType.pasaporte,
                            label: 'Pasaporte',
                            icon: Icons.flight_outlined,
                            color: AppColors.blue1,
                            onTap: () => _setTipoDoc(context, 'PASAPORTE'),
                          ),
                        ],
                        trigger: Container(
                          height: 33,
                          padding: const EdgeInsets.only(left: 10, right: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppColors.blue1, width: 0.6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                state.tipoDocCliente,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.blue1,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down,
                                  size: 16, color: AppColors.blue1),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
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
                    // Pegar documento desde el portapapeles (el campo es
                    // readOnly por el numpad, así que el "Pegar" nativo no
                    // aparece; este botón lo suple).
                    IconButton(
                      icon: const Icon(Icons.content_paste_rounded,
                          size: 18, color: AppColors.blue1),
                      tooltip: 'Pegar documento',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _pegarDocumento(state),
                    ),
                    // La búsqueda por documento es automática al completar
                    // los dígitos (ver _onDocChanged) — sin botón buscar.
                    if (state.buscandoCliente) ...[
                      const SizedBox(width: 10),
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.blue1,
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    // Buscar por NOMBRE en el catálogo local (cliente
                    // frecuente sin dictar el documento). FACTURA
                    // restringe al tab Empresas.
                    SizedBox(
                      height: 33,
                      child: OutlinedButton(
                        onPressed: () => _abrirSelectorCliente(context, state),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppColors.blue1, width: 0.5),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Icon(Icons.person_search,
                            size: 18, color: AppColors.blue1),
                      ),
                    ),
                    if (state.tipoComprobante != 'FACTURA') ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 33,
                        child: OutlinedButton(
                          onPressed: () {
                            context
                                .read<VentaRapidaCubit>()
                                .setClienteGenerico();
                            _docCtrl.text = '00000000';
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.green.shade500, width: 0.5),
                            foregroundColor: Colors.green.shade600,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                              
                            ),
                          ),
                          child: Text(
                            state.clienteGenerico ? 'Genérico ✓' : 'Genérico',
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (state.nombreClienteResuelto.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 18, color: Colors.green.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: AppSubtitle(
                            state.nombreClienteResuelto,
                            color: AppColors.greendark,
                            font: AppFont.amazonEmberMedium,
                            fontSize: 10,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Cliente persona sin cuenta de app: crearla al
                        // vuelo y dictarle "ingresa con tu DNI".
                        if (_clienteSinCuenta && state.clienteId != null)
                          ActionChip(
                            avatar: Icon(Icons.phone_iphone,
                                size: 14, color: Colors.green.shade700),
                            label: Text(
                              'Crear acceso',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: AppColors.green,
                              ),
                            ),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: Colors.green.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                              side: BorderSide(
                                  color: Colors.green.shade300, width: 0.6),
                            ),
                            onPressed: () =>
                                _crearAccesoCliente(state.clienteId!),
                          ),
                      ],
                    ),
                  ),
                //const SizedBox(height: 14),

                // Cliente VIP: precio especial aplicado (solo label, cursiva).
                if (state.tienePrecioVip)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 2),
                    child: Text(
                      state.ahorroVip > 0
                          ? 'Cliente VIP · precio especial (ahorra S/ ${state.ahorroVip.toStringAsFixed(2)})'
                          : 'Cliente VIP · precio especial aplicado',
                      style: TextStyle(
                        fontFamily: 'AmazonEmber-MediumItalic',
                        fontSize: 10,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),

                // Sección crédito (cuotas + preview)
                if (state.esCredito)
                  _buildCreditoSection(context, state),

                // Label adelanto opcional
                if (state.esCredito)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4, bottom: 2),
                    child: Text(
                      'Adelanto (opcional)',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic),
                    ),
                  ),

                _PagoRow(
                  label: 'Pago Efectivo',
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
                  // Compacto: sin CircleAvatar (40px fantasma) ni el
                  // mínimo 48x48 del IconButton — el área de tap queda
                  // del tamaño del ícono y pegado al input.
                  trailing: IconButton(
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    visualDensity: VisualDensity.compact,
                    splashRadius: 18,
                    icon: const Icon(Icons.add_circle_outline_rounded,
                        color: AppColors.blue1, size: 24),
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
                      // child: Text('Total recibido', style: TextStyle(fontSize: 14)),
                      child: AppSubtitle(
                        'Total recibido',
                        fontSize: 13,
                        color: AppColors.greendark,
                      ),
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
                          fontSize: 18,
                          color: AppColors.greendark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Builder(
                  builder: (_) {
                    if (state.esCredito && totalRecibido <= _kPenRoundingTolerance) {
                      return Row(
                        children: [
                          Text(
                            totalCobrar.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('a credito',
                              style: TextStyle(fontSize: 14, color: Colors.orange.shade700)),
                        ],
                      );
                    }
                    final mostrarFalta = faltante > 0;
                    final color = mostrarFalta
                        ? Colors.orange.shade800
                        : (vuelto > 0 ? Colors.green.shade700 : Colors.black54);
                    final monto = mostrarFalta ? faltante : vuelto;
                    final etiqueta = mostrarFalta ? 'Falta' : 'Vuelto';
                    if (state.esCredito && totalRecibido > 0) {
                      final montoCredito = totalCobrar - totalRecibido;
                      return Row(
                        children: [
                          Text(
                            montoCredito > 0 ? montoCredito.toStringAsFixed(2) : '0.00',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                                color: Colors.orange.shade800),
                          ),
                          const SizedBox(width: 10),
                          Text('a credito',
                              style: TextStyle(fontSize: 14, color: Colors.orange.shade700)),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Text(
                          monto.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
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
    const metodos = [
      ('TARJETA', 'Tarjeta', Icons.credit_card),
      ('PLIN', 'Plin', Icons.phone_android),
      ('TRANSFERENCIA', 'Transferencia', Icons.account_balance),
    ];
    final metodoElegido = await StyledDialog.show<String>(
      context,
      accentColor: AppColors.greendark,
      backgroundColor: Colors.white,
      icon: Icons.payments_outlined,
      titulo: 'Agregar método de pago',
      content: [
        for (final (valor, label, icono) in metodos)
          InkWell(
            onTap: () => Navigator.of(context, rootNavigator: true).pop(valor),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Row(
                children: [
                  Icon(icono, size: 18, color: AppColors.greendark),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right,
                      size: 18, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
      ],
    );
    if (metodoElegido == null || !context.mounted) return;
    _agregarOtraFila(metodoElegido);
  }

  /// Color del badge de motivo según el nivel de precio aplicado por el
  /// backend en la divergencia: Liquidación en naranja-rojizo (remate),
  /// Oferta en verde, y los niveles por mayor en azul.
  Color _colorNivelDivergencia(String? nivel) {
    switch (nivel) {
      case 'Liquidación':
        return Colors.deepOrange.shade700;
      case 'Oferta':
        return AppColors.greendark;
      default:
        return AppColors.blue1;
    }
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
    // Si NINGÚN precio subió, el cambio es a favor del cliente (liquidación/
    // oferta/por mayor ganaron) → tono verde. Si alguno subió, tono naranja.
    final algunoSubio = divergencias.any((d) {
      final viejo = (d['precioCliente'] as num?)?.toDouble() ?? 0;
      final nuevo = (d['precioServer'] as num?)?.toDouble() ?? 0;
      return nuevo > viejo;
    });
    final accent = algunoSubio ? Colors.orange.shade700 : AppColors.greendark;

    final accion = await showDialog<_AccionPrecios>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StyledDialog(
        accentColor: accent,
        icon: algunoSubio ? Icons.price_change_outlined : Icons.sell_outlined,
        titulo: algunoSubio
            ? 'Precios actualizados'
            : (divergencias.length == 1
                ? 'Precio más bajo disponible'
                : 'Precios más bajos disponibles'),
        content: [
          Text(
            algunoSubio
                ? (divergencias.length == 1
                    ? '1 producto del carrito tiene un precio nuevo:'
                    : '${divergencias.length} productos del carrito tienen precios nuevos:')
                : 'Se aplica el menor precio vigente (liquidación, oferta o por mayor):',
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: divergencias.map((d) {
                  final desc = (d['descripcion'] as String?) ?? 'Item';
                  final viejo = (d['precioCliente'] as num?)?.toDouble() ?? 0;
                  final nuevo = (d['precioServer'] as num?)?.toDouble() ?? 0;
                  final cant = (d['cantidad'] as num?)?.toDouble() ?? 0;
                  final nivel = d['nivelAplicado'] as String?;
                  final subio = nuevo > viejo;
                  final dirColor =
                      subio ? Colors.red.shade700 : AppColors.greendark;
                  final badge = _colorNivelDivergencia(nivel);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.grey.shade200, width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                desc,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Motivo del precio aplicado (Liquidación / Oferta /
                            // nombre del nivel por mayor).
                            if (nivel != null && nivel.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: badge.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: badge.withValues(alpha: 0.35),
                                      width: 0.5),
                                ),
                                child: Text(
                                  nivel,
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: badge),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              '${cant.toStringAsFixed(cant.truncateToDouble() == cant ? 0 : 2)} u  ·  ',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600),
                            ),
                            Text(
                              'S/ ${viejo.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              subio
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 12,
                              color: dirColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'S/ ${nuevo.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: dirColor,
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
        actions: [
          Expanded(
            child: CustomButton(
              text: 'Cancelar',
              isOutlined: true,
              borderColor: Colors.grey.shade400,
              textColor: Colors.grey.shade700,
              enableShadows: false,
              onPressed: () =>
                  Navigator.pop(dialogCtx, _AccionPrecios.cancelar),
            ),
          ),
          Expanded(
            child: CustomButton(
              text: 'Actualizar',
              backgroundColor: accent,
              textColor: Colors.white,
              onPressed: () =>
                  Navigator.pop(dialogCtx, _AccionPrecios.aplicar),
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

  Widget _buildCreditoSection(BuildContext context, VentaRapidaState state) {
    // El crédito es sobre lo que falta pagar HOY (los adelantos de
    // órdenes ya están pagados).
    final montoCredito = state.totalACobrar;
    final cuotas = CuotaCalculator.calcular(
      montoCredito: montoCredito,
      numeroCuotas: state.numeroCuotas,
      plazoDias: state.plazoDias,
    );
    final clienteOk = !state.clienteGenerico &&
        state.numeroDocCliente.isNotEmpty &&
        state.numeroDocCliente != '00000000' &&
        (state.clienteId != null || state.clienteEmpresaId != null);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cuotas + Plazo en una sola row
            Row(
              children: [
                Expanded(
                  child: CustomDropdown<int>(
                    label: 'Cuotas',
                    value: state.numeroCuotas,
                    borderColor: Colors.orange.shade700,
                    height: 36,
                    items: const [
                      DropdownItem(value: 1, label: '1 cuota'),
                      DropdownItem(value: 2, label: '2 cuotas'),
                      DropdownItem(value: 3, label: '3 cuotas'),
                      DropdownItem(value: 6, label: '6 cuotas'),
                      DropdownItem(value: 12, label: '12 cuotas'),
                    ],
                    onChanged: (v) {
                      if (v != null) context.read<VentaRapidaCubit>().setNumeroCuotas(v);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomDropdown<int>(
                    label: 'Plazo',
                    value: state.plazoDias,
                    borderColor: Colors.orange.shade700,
                    height: 36,
                    items: const [
                      DropdownItem(value: 30, label: '30 dias'),
                      DropdownItem(value: 60, label: '60 dias'),
                      DropdownItem(value: 90, label: '90 dias'),
                      DropdownItem(value: 120, label: '120 dias'),
                    ],
                    onChanged: (v) {
                      if (v != null) context.read<VentaRapidaCubit>().setPlazoDias(v);
                    },
                  ),
                ),
              ],
            ),
            // Preview cuotas
            if (cuotas.isNotEmpty && state.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${cuotas.length} cuota${cuotas.length > 1 ? 's' : ''} de S/ ${cuotas.first.monto.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                              color: Colors.blue.shade700),
                        ),
                        Text('Total: S/ ${montoCredito.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Primera: ${_fmtFecha(cuotas.first.fechaVencimiento)}'
                      '${cuotas.length > 1 ? '  ·  Ultima: ${_fmtFecha(cuotas.last.fechaVencimiento)}' : ''}',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
            // Warning sin cliente
            if (!clienteOk) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_off, size: 14, color: Colors.red.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Credito requiere cliente identificado (DNI o RUC)',
                      style: TextStyle(fontSize: 10, color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmtFecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

/// Acción elegida en el dialog de precios desactualizados.
enum _AccionPrecios { aplicar, cancelar }

/// Acción elegida en el dialog de stock insuficiente.
enum _AccionStock { ajustar, cancelar }

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
        Expanded(child: AppSubtitle(label, font: AppFont.amazonEmberMedium, fontSize: 12,)),
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

class _AppBarCondicionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _AppBarCondicionChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? selectedColor : Colors.white54,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? (selectedColor == Colors.white ? AppColors.blue1 : Colors.white)
                : Colors.white70,
          ),
        ),
      ),
    );
  }
}
