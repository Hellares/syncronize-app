import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../../empresa_banco/domain/entities/empresa_banco.dart';
import '../../../empresa_banco/domain/usecases/get_cuentas_bancarias_usecase.dart';

/// Resultado del sheet: pagar (con datos) u omitir (cae en CxP). null = cancelar.
class ResultadoPagoContado {
  final bool omitir;
  final Map<String, dynamic>? pago; // { metodoPago, fuente, bancoId? }
  const ResultadoPagoContado.pagar(this.pago) : omitir = false;
  const ResultadoPagoContado.omitir()
      : omitir = true,
        pago = null;
}

/// Sheet para registrar el pago al confirmar una compra al CONTADO. Captura
/// método + fuente (+ banco) y devuelve el pago; o "omitir" → la compra queda
/// pendiente en Cuentas por Pagar.
class ConfirmarPagoCompraSheet extends StatefulWidget {
  final double total;
  final String moneda;

  const ConfirmarPagoCompraSheet({super.key, required this.total, required this.moneda});

  static Future<ResultadoPagoContado?> mostrar(
    BuildContext context, {
    required double total,
    required String moneda,
  }) {
    return showModalBottomSheet<ResultadoPagoContado>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ConfirmarPagoCompraSheet(total: total, moneda: moneda),
    );
  }

  @override
  State<ConfirmarPagoCompraSheet> createState() => _ConfirmarPagoCompraSheetState();
}

class _ConfirmarPagoCompraSheetState extends State<ConfirmarPagoCompraSheet> {
  String _metodo = 'EFECTIVO';
  late String _fuente;
  String? _bancoId;
  List<EmpresaBanco> _bancos = [];
  bool _cargandoBancos = true;
  late final TextEditingController _montoCtrl;

  bool get _esBancario =>
      _metodo == 'TRANSFERENCIA' || _metodo == 'YAPE' || _metodo == 'PLIN' || _metodo == 'TARJETA';
  bool get _esMonedaExtranjera => widget.moneda.toUpperCase() != 'PEN';

  List<EmpresaBanco> get _bancosCompatibles => _bancos
      .where((b) => (b.moneda ?? 'PEN').toUpperCase() == widget.moneda.toUpperCase())
      .toList();

  String _defaultFuente(String metodo) {
    if (_esMonedaExtranjera) return 'BANCO';
    return metodo == 'EFECTIVO' ? 'TESORERIA' : 'BANCO';
  }

  String _sim() {
    switch (widget.moneda.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'PEN':
        return 'S/';
      default:
        return '${widget.moneda.toUpperCase()} ';
    }
  }

  @override
  void initState() {
    super.initState();
    _fuente = _defaultFuente(_metodo);
    _montoCtrl = TextEditingController(text: widget.total.toStringAsFixed(2));
    _cargarBancos();
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarBancos() async {
    final res = await locator<GetCuentasBancariasUseCase>().call();
    if (!mounted) return;
    setState(() {
      _bancos = res is Success<List<EmpresaBanco>> ? res.data.where((b) => b.isActive).toList() : [];
      _cargandoBancos = false;
      if (_fuente == 'BANCO') _bancoId = _bancoPreseleccionado();
    });
  }

  String? _bancoPreseleccionado() {
    final compat = _bancosCompatibles;
    if (compat.isEmpty) return null;
    return compat.firstWhere((b) => b.esPrincipal, orElse: () => compat.first).id;
  }

  void _onMetodoChanged(String metodo) {
    setState(() {
      _metodo = metodo;
      _fuente = _defaultFuente(metodo);
      _bancoId = _fuente == 'BANCO' ? _bancoPreseleccionado() : null;
    });
  }

  void _registrar() {
    if (_fuente == 'BANCO' && (_bancoId == null || _bancoId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccioná la cuenta bancaria de la que sale el pago')),
      );
      return;
    }
    var monto = double.tryParse(_montoCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresá un monto válido')));
      return;
    }
    if (monto > widget.total + 0.001) monto = widget.total; // no más que el total
    monto = (monto * 100).round() / 100;
    Navigator.of(context).pop(ResultadoPagoContado.pagar({
      'metodoPago': _metodo,
      'fuente': _fuente,
      'monto': monto,
      if (_fuente == 'BANCO') 'bancoId': _bancoId,
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                AppTitle('¿Cómo pagaste la compra?', fontSize: 16, color: AppColors.blue1),
                const SizedBox(height: 2),
                AppSubtitle('Total: ${_sim()} ${widget.total.toStringAsFixed(2)}', fontSize: 12, color: AppColors.blueGrey),
                const SizedBox(height: 14),
                CustomDropdown<String>(
                  label: 'Método de pago',
                  value: _metodo,
                  borderColor: AppColors.blueborder,
                  items: const [
                    DropdownItem(value: 'EFECTIVO', label: 'Efectivo'),
                    DropdownItem(value: 'TRANSFERENCIA', label: 'Transferencia'),
                    DropdownItem(value: 'YAPE', label: 'Yape'),
                    DropdownItem(value: 'PLIN', label: 'Plin'),
                    DropdownItem(value: 'TARJETA', label: 'Tarjeta'),
                  ],
                  onChanged: (v) => _onMetodoChanged(v ?? 'EFECTIVO'),
                ),
                const SizedBox(height: 12),
                CustomText(
                  label: 'Monto (máx ${_sim()} ${widget.total.toStringAsFixed(2)})',
                  controller: _montoCtrl,
                  fieldType: FieldType.number,
                ),
                const SizedBox(height: 12),
                _buildFuenteSelector(),
                const SizedBox(height: 18),
                CustomButton(
                  text: 'Registrar pago',
                  backgroundColor: AppColors.blue1,
                  textColor: Colors.white,
                  onPressed: _registrar,
                ),
                const SizedBox(height: 8),
                CustomButton(
                  text: 'Omitir (lo pago después)',
                  isOutlined: true,
                  borderColor: Colors.grey.shade400,
                  textColor: Colors.grey.shade700,
                  enableShadows: false,
                  onPressed: () => Navigator.of(context).pop(const ResultadoPagoContado.omitir()),
                ),
                const SizedBox(height: 4),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade600)),
                  ),
                ),
                Text(
                  'Si lo omitís, la compra queda pendiente en Cuentas por Pagar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFuenteSelector() {
    final opciones = <DropdownItem<String>>[
      if (!_esMonedaExtranjera) ...const [
        DropdownItem(value: 'TESORERIA', label: 'Tesorería (Caja Central)'),
        DropdownItem(value: 'CAJA', label: 'Caja (mi caja abierta)'),
      ],
      if (_esBancario || _esMonedaExtranjera)
        const DropdownItem(value: 'BANCO', label: 'Banco (cuenta de la empresa)'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomDropdown<String>(
          label: 'Sale de',
          value: _fuente,
          borderColor: AppColors.blueborder,
          items: opciones,
          onChanged: (v) => setState(() {
            _fuente = v ?? _fuente;
            _bancoId = _fuente == 'BANCO' ? (_bancoId ?? _bancoPreseleccionado()) : null;
          }),
        ),
        if (_fuente == 'BANCO') ...[
          const SizedBox(height: 12),
          if (_cargandoBancos)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else if (_bancosCompatibles.isEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text('No hay cuentas bancarias en ${widget.moneda}. Creá una en Cuentas bancarias.',
                  style: TextStyle(fontSize: 11, color: Colors.orange.shade900)),
            )
          else
            CustomDropdown<String>(
              label: 'Cuenta bancaria',
              value: _bancoId,
              borderColor: AppColors.blueborder,
              items: _bancosCompatibles
                  .map((b) => DropdownItem(
                        value: b.id,
                        label: '${b.nombreBanco} ·· ${b.numeroCuenta} (${b.moneda ?? 'PEN'})',
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _bancoId = v),
            ),
        ],
      ],
    );
  }
}
