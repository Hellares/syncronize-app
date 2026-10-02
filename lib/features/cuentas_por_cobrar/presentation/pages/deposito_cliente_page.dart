import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../../empresa_banco/domain/entities/empresa_banco.dart';
import '../../../empresa_banco/domain/usecases/get_cuentas_bancarias_usecase.dart';
import '../../domain/entities/deposito_cliente.dart';
import '../../domain/repositories/cuentas_cobrar_repository.dart';

/// `nuevo`: entra plata ahora (se registra el depósito) y se reparte.
/// `repartir`: la plata ya entró; solo se reparte el saldo a favor.
enum ModoDeposito { nuevo, repartir }

/// Depósito del cliente sin indicar qué paga + su reparto entre las ventas.
///
/// El backend PROPONE (cuotas completas, de la que vence primero a la última,
/// hasta donde alcance) y acá se puede cambiar cualquier monto. Lo que no se
/// reparte no se pierde: queda como saldo a favor del cliente.
///
/// Es una página y no un sheet: lleva una lista de ventas con un campo cada
/// una, y con el teclado abierto un sheet no deja ver ni la lista ni el total.
/// Devuelve (Navigator.pop) el mensaje de lo que se hizo, o null si se canceló.
class DepositoClientePage extends StatefulWidget {
  final String? clienteId;
  final String? clienteEmpresaId;
  final String nombreCliente;
  final ModoDeposito modo;

  const DepositoClientePage({
    super.key,
    this.clienteId,
    this.clienteEmpresaId,
    required this.nombreCliente,
    required this.modo,
  });

  @override
  State<DepositoClientePage> createState() => _DepositoClientePageState();
}

class _DepositoClientePageState extends State<DepositoClientePage> {
  final _montoCtrl = TextEditingController();
  final _refCtrl = TextEditingController();

  /// Un campo por venta: cuánto se le aplica.
  final Map<String, TextEditingController> _aplicar = {};

  String _metodo = 'TRANSFERENCIA';
  String _fuente = 'BANCO';
  String? _bancoId;
  List<EmpresaBanco> _bancos = [];
  bool _cargandoBancos = true;

  SugerenciaReparto? _sugerencia;
  double _saldoPrevio = 0;
  bool _cargando = true;
  bool _procesando = false;
  String? _error;
  Timer? _debounce;

  /// Descarta la respuesta de una propuesta vieja si ya se pidió otra.
  int _pedido = 0;

  bool get _esNuevo => widget.modo == ModoDeposito.nuevo;
  CuentasCobrarRepository get _repo => locator<CuentasCobrarRepository>();

  static double _r2(double n) => (n * 100).round() / 100;
  static double _num(String t) => double.tryParse(t.trim().replaceAll(',', '.')) ?? 0;
  static String _soles(double n) => 'S/ ${n.toStringAsFixed(2)}';

  double get _monto => _r2(_num(_montoCtrl.text));
  double get _disponible => _r2((_esNuevo ? _monto : 0) + _saldoPrevio);
  double get _repartido =>
      _r2(_aplicar.values.fold<double>(0, (s, c) => s + _num(c.text)));
  double get _queda => _r2(_disponible - _repartido);
  double get _deuda => _sugerencia?.deuda ?? 0;
  List<VentaReparto> get _ventas => _sugerencia?.ventas ?? const [];

  bool get _esBancario => _metodo != 'EFECTIVO';
  List<EmpresaBanco> get _bancosPen =>
      _bancos.where((b) => (b.moneda ?? 'PEN').toUpperCase() == 'PEN').toList();

  @override
  void initState() {
    super.initState();
    if (_esNuevo) _cargarBancos();
    _abrir();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _montoCtrl.dispose();
    _refCtrl.dispose();
    for (final c in _aplicar.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarBancos() async {
    final res = await locator<GetCuentasBancariasUseCase>().call();
    if (!mounted) return;
    setState(() {
      _bancos = res is Success<List<EmpresaBanco>>
          ? res.data.where((b) => b.isActive).toList()
          : [];
      _cargandoBancos = false;
      if (_fuente == 'BANCO') _bancoId = _bancoPreseleccionado();
    });
  }

  String? _bancoPreseleccionado() {
    final compat = _bancosPen;
    if (compat.isEmpty) return null;
    return compat.firstWhere((b) => b.esPrincipal, orElse: () => compat.first).id;
  }

  /// Al abrir: primero con 0 para conocer la deuda y el saldo que ya tenía;
  /// si tenía saldo, se propone cómo repartirlo.
  Future<void> _abrir() async {
    final s = await _proponer(0);
    if (!mounted) return;
    if (s != null) {
      _saldoPrevio = s.saldoAFavor;
      if (s.saldoAFavor > 0) await _proponer(s.saldoAFavor);
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<SugerenciaReparto?> _proponer(double total) async {
    final n = ++_pedido;
    final res = await _repo.sugerirReparto(
      clienteId: widget.clienteId,
      clienteEmpresaId: widget.clienteEmpresaId,
      monto: total,
    );
    if (!mounted || n != _pedido) return null;
    if (res is Success<SugerenciaReparto>) {
      final s = res.data;
      setState(() {
        _sugerencia = s;
        _error = null;
        final vigentes = s.ventas.map((v) => v.ventaId).toSet();
        // Una venta que ya no está en la deuda suelta su campo.
        _aplicar.keys.where((id) => !vigentes.contains(id)).toList().forEach((id) {
          _aplicar.remove(id)?.dispose();
        });
        for (final v in s.ventas) {
          final texto = v.sugerido > 0 ? v.sugerido.toStringAsFixed(2) : '';
          final c = _aplicar[v.ventaId];
          if (c == null) {
            _aplicar[v.ventaId] = TextEditingController(text: texto);
          } else {
            c.text = texto;
          }
        }
      });
      return s;
    }
    if (res is Error<SugerenciaReparto>) {
      setState(() => _error = res.message);
    }
    return null;
  }

  /// Cada vez que cambia el monto se vuelve a proponer, con una pausa para no
  /// pedir en cada tecla.
  void _onMontoChanged(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) _proponer(_r2(_monto + _saldoPrevio));
    });
  }

  void _onMetodoChanged(String metodo) {
    setState(() {
      _metodo = metodo;
      // El efectivo no entra a un banco; lo digital, por defecto, sí.
      _fuente = metodo == 'EFECTIVO' ? 'TESORERIA' : 'BANCO';
      _bancoId = _fuente == 'BANCO' ? (_bancoId ?? _bancoPreseleccionado()) : null;
    });
  }

  void _onFuenteChanged(String fuente) {
    setState(() {
      _fuente = fuente;
      _bancoId = fuente == 'BANCO' ? (_bancoId ?? _bancoPreseleccionado()) : null;
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _confirmar() async {
    final lineas = <LineaReparto>[];
    for (final v in _ventas) {
      final m = _r2(_num(_aplicar[v.ventaId]?.text ?? ''));
      if (m <= 0) continue;
      if (m > v.saldo + 0.001) {
        _snack('A ${v.codigo} se le puede aplicar hasta ${_soles(v.saldo)}');
        return;
      }
      lineas.add(LineaReparto(ventaId: v.ventaId, monto: m));
    }
    if (_esNuevo) {
      if (_monto <= 0) {
        _snack('Escribe cuánto depositó el cliente');
        return;
      }
      if (_fuente == 'BANCO' && (_bancoId == null || _bancoId!.isEmpty)) {
        _snack('Elige la cuenta a la que entró el depósito');
        return;
      }
    } else if (lineas.isEmpty) {
      _snack('Indica cuánto va a cada venta');
      return;
    }
    if (_queda < -0.001) {
      _snack('El reparto supera lo disponible por ${_soles(-_queda)}');
      return;
    }

    final repartido = _repartido;
    final queda = _queda;
    final monto = _monto;
    setState(() => _procesando = true);
    final Resource<void> res;
    if (_esNuevo) {
      final ref = _refCtrl.text.trim();
      res = await _repo.registrarDeposito(
        clienteId: widget.clienteId,
        clienteEmpresaId: widget.clienteEmpresaId,
        monto: monto,
        metodoPago: _metodo,
        // Bancarización: lo digital lleva N° de operación (00000 si no lo dan).
        referencia: _esBancario ? (ref.isEmpty ? '00000' : ref) : (ref.isEmpty ? null : ref),
        fuente: _fuente,
        bancoId: _fuente == 'BANCO' ? _bancoId : null,
        lineas: lineas,
      );
    } else {
      res = await _repo.aplicarSaldoAFavor(
        clienteId: widget.clienteId,
        clienteEmpresaId: widget.clienteEmpresaId,
        lineas: lineas,
      );
    }
    if (!mounted) return;
    if (res is Error<void>) {
      setState(() => _procesando = false);
      _snack(res.message);
      return;
    }
    final partes = <String>[
      _esNuevo ? 'Depósito de ${_soles(monto)} registrado' : 'Saldo repartido',
      if (lineas.isNotEmpty)
        '${_soles(repartido)} en ${lineas.length} ${lineas.length == 1 ? 'venta' : 'ventas'}',
      if (queda > 0.001) '${_soles(queda)} quedan a favor',
    ];
    Navigator.of(context).pop(partes.join(' · '));
  }

  String _fecha(DateTime? d) {
    if (d == null) return '—';
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: _esNuevo ? 'Registrar depósito' : 'Repartir saldo a favor',
        ),
        body: _cargando
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                children: [
                  _cabecera(),
                  if (_esNuevo) ...[
                    const SizedBox(height: 10),
                    _datosDeposito(),
                  ],
                  const SizedBox(height: 10),
                  _cifras(),
                  const SizedBox(height: 14),
                  _tituloVentas(),
                  const SizedBox(height: 6),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(_error!,
                          style: TextStyle(fontSize: 12, color: Colors.red.shade400)),
                    ),
                  if (_ventas.isEmpty)
                    _sinVentas()
                  else
                    ..._ventas.map(_ventaTile),
                  if (_queda > 0.001 && _ventas.isNotEmpty && _deuda - _repartido > 0.001) ...[
                    const SizedBox(height: 6),
                    _avisoSobrante(),
                  ],
                ],
              ),
        bottomNavigationBar: _cargando
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                  child: CustomButton(
                    text: _esNuevo ? 'Registrar depósito' : 'Repartir',
                    backgroundColor: AppColors.blue1,
                    textColor: Colors.white,
                    isLoading: _procesando,
                    onPressed: _procesando ? null : _confirmar,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _cabecera() {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSubtitle(widget.nombreCliente, color: AppColors.blue1),
            const SizedBox(height: 2),
            AppLabelText(
              _esNuevo
                  ? 'El cliente pagó sin decir qué compras cancela. Repártelo entre sus ventas; lo que no alcance queda a su favor.'
                  : 'Plata que el cliente ya entregó y todavía no se aplicó a ninguna venta.',
              color: AppColors.black54,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _datosDeposito() {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomText(
              label: 'Monto depositado',
              controller: _montoCtrl,
              fieldType: FieldType.number,
              hintText: '0.00',
              borderColor: AppColors.blueborder,
              onChanged: _onMontoChanged,
            ),
            const SizedBox(height: 12),
            CustomDropdown<String>(
              label: 'Método de pago',
              value: _metodo,
              borderColor: AppColors.blueborder,
              items: const [
                DropdownItem(value: 'TRANSFERENCIA', label: 'Transferencia'),
                DropdownItem(value: 'YAPE', label: 'Yape'),
                DropdownItem(value: 'PLIN', label: 'Plin'),
                DropdownItem(value: 'EFECTIVO', label: 'Efectivo'),
                DropdownItem(value: 'TARJETA', label: 'Tarjeta'),
              ],
              onChanged: (v) => _onMetodoChanged(v ?? _metodo),
            ),
            const SizedBox(height: 12),
            CustomDropdown<String>(
              label: 'Entra a',
              value: _fuente,
              borderColor: AppColors.blueborder,
              items: [
                const DropdownItem(value: 'TESORERIA', label: 'Tesorería (Caja Central)'),
                const DropdownItem(value: 'CAJA', label: 'Caja (mi caja abierta)'),
                if (_esBancario)
                  const DropdownItem(value: 'BANCO', label: 'Banco (cuenta de la empresa)'),
              ],
              onChanged: (v) => _onFuenteChanged(v ?? _fuente),
            ),
            if (_fuente == 'BANCO') ...[
              const SizedBox(height: 12),
              if (_cargandoBancos)
                const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_bancosPen.isEmpty)
                Text(
                  'No hay cuentas bancarias en soles. Crea una en Cuentas bancarias.',
                  style: TextStyle(fontSize: 11, color: Colors.orange.shade900),
                )
              else
                CustomDropdown<String>(
                  label: 'Cuenta bancaria',
                  value: _bancoId,
                  borderColor: AppColors.blueborder,
                  items: _bancosPen
                      .map((b) => DropdownItem(
                            value: b.id,
                            label: '${b.nombreBanco} ·· ${b.numeroCuenta}',
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _bancoId = v),
                ),
            ],
            if (_esBancario) ...[
              const SizedBox(height: 12),
              CustomText(
                label: 'N° de operación (opcional)',
                controller: _refCtrl,
                fieldType: FieldType.number,
                hintText: 'N° op.',
                borderColor: AppColors.blueborder,
                maxLength: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// De dónde sale lo que se reparte y cuánto debe.
  Widget _cifras() {
    final pasado = _queda < -0.001;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _cifra('Deuda del cliente', _deuda, Colors.red.shade700)),
            const SizedBox(width: 6),
            Expanded(child: _cifra('Para repartir', _disponible, AppColors.blue1)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _cifra('Repartido', _repartido, Colors.green.shade700)),
            const SizedBox(width: 6),
            Expanded(
              child: _cifra(
                pasado ? 'Te pasaste por' : 'Queda a favor',
                _queda.abs(),
                pasado ? Colors.red.shade700 : Colors.orange.shade800,
              ),
            ),
          ],
        ),
        if (_esNuevo && _saldoPrevio > 0) ...[
          const SizedBox(height: 4),
          AppLabelText(
            'Para repartir incluye ${_soles(_saldoPrevio)} que ya tenía a favor.',
            color: AppColors.black54,
          ),
        ],
      ],
    );
  }

  Widget _cifra(String etiqueta, double valor, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.blueborder, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          const SizedBox(height: 2),
          Text(_soles(valor),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _tituloVentas() {
    return Row(
      children: [
        const Expanded(
          child: Text('Ventas con deuda',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        if (_ventas.isNotEmpty)
          InkWell(
            onTap: _procesando ? null : () => _proponer(_disponible),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text('Volver a proponer',
                  style: TextStyle(fontSize: 11, color: AppColors.blue1, fontWeight: FontWeight.w600)),
            ),
          ),
      ],
    );
  }

  Widget _sinVentas() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        'Este cliente no tiene ventas a crédito con saldo.'
        '${_esNuevo ? ' El depósito queda entero a su favor.' : ''}',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
    );
  }

  Widget _ventaTile(VentaReparto v) {
    final ctrl = _aplicar[v.ventaId]!;
    final aplica = _r2(_num(ctrl.text));
    final pasada = aplica > v.saldo + 0.001;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: aplica > 0 ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: pasada ? Colors.red.shade300 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.codigo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                Text('Saldo ${_soles(v.saldo)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade800)),
                Text(
                  '${v.proximaCuotaNumero != null ? 'Cuota ${v.proximaCuotaNumero}: ' : 'Vence: '}'
                  '${_soles(v.proximaCuotaMonto)} · ${_fecha(v.proximaCuotaVence)}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                if (pasada)
                  Text('máx. ${_soles(v.saldo)}',
                      style: TextStyle(fontSize: 10, color: Colors.red.shade600))
                else if (aplica < v.saldo - 0.001)
                  InkWell(
                    onTap: () => setState(() => ctrl.text = v.saldo.toStringAsFixed(2)),
                    child: const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Text('Saldar esta venta',
                          style: TextStyle(fontSize: 10, color: AppColors.blue1, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: CustomText(
              label: 'Aplicar',
              controller: ctrl,
              fieldType: FieldType.number,
              hintText: '0.00',
              borderColor: AppColors.blueborder,
              // Los totales de arriba se recalculan con cada tecla.
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avisoSobrante() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Text(
        '${_soles(_queda)} no alcanzan para cubrir una cuota entera: quedan a favor del cliente, '
        'que aún deberá ${_soles(_r2(_deuda - _repartido))}. '
        'Si prefieres, escríbelos como pago parcial en la venta que quieras.',
        style: TextStyle(fontSize: 11, color: Colors.orange.shade900),
      ),
    );
  }
}
