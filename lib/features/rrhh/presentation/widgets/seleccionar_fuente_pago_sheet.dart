import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../empresa_banco/domain/entities/empresa_banco.dart';
import '../../../empresa_banco/domain/usecases/get_cuentas_bancarias_usecase.dart';

/// Sheet para elegir de DÓNDE sale el pago de un egreso de RRHH (adelanto /
/// boleta de planilla): método + fuente (Tesorería / Caja / Banco) + banco.
/// Devuelve `{ metodoPago, fuente, bancoId? }` o null si se cancela.
/// Monto fijo (no editable) y moneda PEN — las planillas/adelantos son en soles.
class SeleccionarFuentePagoSheet extends StatefulWidget {
  final double monto;
  final String titulo;
  final String subtitulo;

  const SeleccionarFuentePagoSheet({
    super.key,
    required this.monto,
    this.titulo = '¿De dónde sale el pago?',
    this.subtitulo = '',
  });

  static Future<Map<String, dynamic>?> mostrar(
    BuildContext context, {
    required double monto,
    String titulo = '¿De dónde sale el pago?',
    String subtitulo = '',
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SeleccionarFuentePagoSheet(
        monto: monto,
        titulo: titulo,
        subtitulo: subtitulo,
      ),
    );
  }

  @override
  State<SeleccionarFuentePagoSheet> createState() =>
      _SeleccionarFuentePagoSheetState();
}

class _SeleccionarFuentePagoSheetState
    extends State<SeleccionarFuentePagoSheet> {
  String _metodo = 'EFECTIVO';
  late String _fuente;
  String? _bancoId;
  List<EmpresaBanco> _bancos = [];
  bool _cargandoBancos = true;

  bool get _esBancario =>
      _metodo == 'TRANSFERENCIA' ||
      _metodo == 'YAPE' ||
      _metodo == 'PLIN' ||
      _metodo == 'TARJETA';

  List<EmpresaBanco> get _bancosCompatibles => _bancos
      .where((b) => (b.moneda ?? 'PEN').toUpperCase() == 'PEN')
      .toList();

  String _defaultFuente(String metodo) =>
      metodo == 'EFECTIVO' ? 'TESORERIA' : 'BANCO';

  @override
  void initState() {
    super.initState();
    _fuente = _defaultFuente(_metodo);
    _cargarBancos();
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

  void _confirmar() {
    if (_fuente == 'BANCO' && (_bancoId == null || _bancoId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Seleccioná la cuenta bancaria de la que sale el pago')),
      );
      return;
    }
    Navigator.of(context).pop(<String, dynamic>{
      'metodoPago': _metodo,
      'fuente': _fuente,
      if (_fuente == 'BANCO') 'bancoId': _bancoId,
    });
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
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                AppTitle(widget.titulo, fontSize: 16, color: AppColors.blue1),
                const SizedBox(height: 2),
                AppSubtitle(
                  widget.subtitulo.isNotEmpty
                      ? '${widget.subtitulo} · S/ ${widget.monto.toStringAsFixed(2)}'
                      : 'Monto: S/ ${widget.monto.toStringAsFixed(2)}',
                  fontSize: 12,
                  color: AppColors.blueGrey,
                ),
                const SizedBox(height: 14),
                CustomDropdown<String>(
                  label: 'Método de pago',
                  value: _metodo,
                  borderColor: AppColors.blueborder,
                  items: const [
                    DropdownItem(value: 'EFECTIVO', label: 'Efectivo'),
                    DropdownItem(
                        value: 'TRANSFERENCIA', label: 'Transferencia'),
                    DropdownItem(value: 'YAPE', label: 'Yape'),
                    DropdownItem(value: 'PLIN', label: 'Plin'),
                    DropdownItem(value: 'TARJETA', label: 'Tarjeta'),
                  ],
                  onChanged: (v) => _onMetodoChanged(v ?? 'EFECTIVO'),
                ),
                const SizedBox(height: 12),
                _buildFuenteSelector(),
                const SizedBox(height: 18),
                CustomButton(
                  text: 'Confirmar pago',
                  backgroundColor: AppColors.blue1,
                  textColor: Colors.white,
                  onPressed: _confirmar,
                ),
                const SizedBox(height: 4),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancelar',
                        style: TextStyle(color: Colors.grey.shade600)),
                  ),
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
      const DropdownItem(value: 'TESORERIA', label: 'Tesorería (Caja Central)'),
      const DropdownItem(value: 'CAJA', label: 'Caja (mi caja abierta)'),
      if (_esBancario)
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
            _bancoId =
                _fuente == 'BANCO' ? (_bancoId ?? _bancoPreseleccionado()) : null;
          }),
        ),
        if (_fuente == 'BANCO') ...[
          const SizedBox(height: 12),
          if (_cargandoBancos)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else if (_bancosCompatibles.isEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                  'No hay cuentas bancarias en PEN. Creá una en Cuentas bancarias.',
                  style:
                      TextStyle(fontSize: 11, color: Colors.orange.shade900)),
            )
          else
            CustomDropdown<String>(
              label: 'Cuenta bancaria',
              value: _bancoId,
              borderColor: AppColors.blueborder,
              items: _bancosCompatibles
                  .map((b) => DropdownItem(
                        value: b.id,
                        label:
                            '${b.nombreBanco} ·· ${b.numeroCuenta} (${b.moneda ?? 'PEN'})',
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _bancoId = v),
            ),
        ],
      ],
    );
  }
}
