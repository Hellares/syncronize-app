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
/// Firma del registro del abono: devuelve `null` si salió bien o el mensaje
/// de error a mostrar. Cada pantalla decide cómo persistirlo (el cubit de
/// CxC recarga su lista; el detalle de venta llama al usecase y recarga la
/// venta).
typedef RegistrarAbono = Future<String?> Function({
  required String metodoPago,
  required double monto,
  String? referencia,
  String? fuente,
  String? bancoId,
});

/// Hoja para registrar un abono sobre una venta a crédito.
/// Devuelve `true` (Navigator.pop) si el abono quedó registrado.
///
/// Vive en CxC pero la usan también las ventas a crédito desde su detalle:
/// es el único camino que rutea el ingreso a Tesorería/Caja/Banco. Por eso
/// recibe datos sueltos y un callback en vez de la entidad `CuentaPorCobrar`
/// y su cubit — así no arrastra el módulo entero a quien la reuse.
class AbonoClienteSheet extends StatefulWidget {
  final String codigoVenta;
  final String nombreCliente;
  final double saldoPendiente;
  final double totalMora;
  final RegistrarAbono onRegistrar;

  const AbonoClienteSheet({
    super.key,
    required this.codigoVenta,
    required this.nombreCliente,
    required this.saldoPendiente,
    required this.onRegistrar,
    this.totalMora = 0,
  });

  static Future<bool?> mostrar(
    BuildContext context, {
    required String codigoVenta,
    required String nombreCliente,
    required double saldoPendiente,
    required RegistrarAbono onRegistrar,
    double totalMora = 0,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AbonoClienteSheet(
        codigoVenta: codigoVenta,
        nombreCliente: nombreCliente,
        saldoPendiente: saldoPendiente,
        totalMora: totalMora,
        onRegistrar: onRegistrar,
      ),
    );
  }

  @override
  State<AbonoClienteSheet> createState() => _AbonoClienteSheetState();
}

class _AbonoClienteSheetState extends State<AbonoClienteSheet> {
  String _metodo = 'EFECTIVO';
  late final TextEditingController _montoCtrl;
  final _refCtrl = TextEditingController();
  bool _procesando = false;

  // Fuente del dinero que ENTRA (TESORERIA / CAJA / BANCO). CxC en PEN.
  late String _fuente;
  String? _bancoId;
  List<EmpresaBanco> _bancos = [];
  bool _cargandoBancos = true;

  // Total a cobrar incluye la mora (el backend la aplica primero).
  double get _maximo => widget.saldoPendiente + widget.totalMora;

  bool get _esBancario =>
      _metodo == 'TRANSFERENCIA' || _metodo == 'YAPE' || _metodo == 'PLIN' || _metodo == 'TARJETA';

  /// Cuentas bancarias en PEN (los abonos de CxC son en soles).
  List<EmpresaBanco> get _bancosCompatibles =>
      _bancos.where((b) => (b.moneda ?? 'PEN').toUpperCase() == 'PEN').toList();

  String _defaultFuente(String metodo) => metodo == 'EFECTIVO' ? 'TESORERIA' : 'BANCO';

  @override
  void initState() {
    super.initState();
    _montoCtrl = TextEditingController(text: _maximo.toStringAsFixed(2));
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

  void _onFuenteChanged(String fuente) {
    setState(() {
      _fuente = fuente;
      _bancoId = fuente == 'BANCO' ? (_bancoId ?? _bancoPreseleccionado()) : null;
    });
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    var monto = double.tryParse(_montoCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    if (monto <= 0) {
      _snack('Ingresá un monto válido');
      return;
    }
    if (monto > _maximo + 0.001) {
      _snack('El monto no puede superar el saldo (S/ ${_maximo.toStringAsFixed(2)})');
      return;
    }
    if (_fuente == 'BANCO' && (_bancoId == null || _bancoId!.isEmpty)) {
      _snack('Seleccioná la cuenta bancaria donde entra el abono');
      return;
    }
    monto = (monto * 100).round() / 100;
    // En métodos digitales la bancarización (ventas ≥ umbral) exige N° de
    // operación → default 00000 si lo dejan vacío.
    final esDigital = _metodo != 'EFECTIVO';
    final ref = _refCtrl.text.trim();
    final referencia = esDigital ? (ref.isEmpty ? '00000' : ref) : (ref.isEmpty ? null : ref);

    setState(() => _procesando = true);
    final err = await widget.onRegistrar(
      metodoPago: _metodo,
      monto: monto,
      referencia: referencia,
      fuente: _fuente,
      bancoId: _fuente == 'BANCO' ? _bancoId : null,
    );
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _procesando = false);
      _snack(err);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Selector de fuente: Tesorería / Caja / Banco (a dónde ENTRA el dinero).
  /// EFECTIVO no permite Banco. Si Banco → dropdown de cuentas bancarias.
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
          label: 'Entra a',
          value: _fuente,
          borderColor: AppColors.blueborder,
          items: opciones,
          onChanged: (v) => _onFuenteChanged(v ?? _fuente),
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
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
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
                style: TextStyle(fontSize: 11, color: Colors.orange.shade900),
              ),
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
                            '${b.nombreBanco} ·· ${b.numeroCuenta} (${b.moneda ?? 'PEN'} ${b.saldoActual.toStringAsFixed(2)})',
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _bancoId = v),
            ),
        ],
      ],
    );
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
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                AppTitle('Registrar abono', fontSize: 17, color: AppColors.blue1),
                const SizedBox(height: 2),
                AppSubtitle(widget.nombreCliente,
                    fontSize: 12, color: AppColors.blueGrey),
                const SizedBox(height: 2),
                AppSubtitle(
                  '${widget.codigoVenta}  ·  Saldo: S/ ${widget.saldoPendiente.toStringAsFixed(2)}'
                  '${widget.totalMora > 0 ? '  + mora S/ ${widget.totalMora.toStringAsFixed(2)}' : ''}',
                  fontSize: 11,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                CustomDropdown<String>(
                  label: 'Método de pago',
                  value: _metodo,
                  borderColor: AppColors.blueborder,
                  items: const [
                    DropdownItem(value: 'EFECTIVO', label: 'Efectivo'),
                    DropdownItem(value: 'YAPE', label: 'Yape'),
                    DropdownItem(value: 'PLIN', label: 'Plin'),
                    DropdownItem(value: 'TRANSFERENCIA', label: 'Transferencia'),
                    DropdownItem(value: 'TARJETA', label: 'Tarjeta'),
                  ],
                  onChanged: (v) => _onMetodoChanged(v ?? 'EFECTIVO'),
                ),
                const SizedBox(height: 12),
                _buildFuenteSelector(),
                const SizedBox(height: 12),
                CustomText(
                  label: 'Monto (máx S/ ${_maximo.toStringAsFixed(2)})',
                  controller: _montoCtrl,
                  fieldType: FieldType.number,
                  borderColor: AppColors.blueborder,
                ),
                if (_metodo != 'EFECTIVO') ...[
                  const SizedBox(height: 12),
                  CustomText(
                    label: 'N° de operación / voucher (opcional)',
                    controller: _refCtrl,
                    fieldType: FieldType.number,
                    hintText: 'N° op.',
                    borderColor: AppColors.blueborder,
                    maxLength: 20,
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Cancelar',
                        isOutlined: true,
                        borderColor: Colors.grey.shade400,
                        textColor: Colors.grey.shade700,
                        enableShadows: false,
                        onPressed: _procesando ? null : () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Registrar abono',
                        backgroundColor: AppColors.blue1,
                        textColor: Colors.white,
                        isLoading: _procesando,
                        onPressed: _procesando ? null : _registrar,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
