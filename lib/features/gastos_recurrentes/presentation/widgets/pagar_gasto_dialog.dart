import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/utils/resource.dart';
import 'package:syncronize/core/widgets/currency/currency_textfield.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import 'package:syncronize/features/caja/data/datasources/caja_remote_datasource.dart';
import 'package:syncronize/features/empresa_banco/domain/entities/empresa_banco.dart';
import 'package:syncronize/features/empresa_banco/domain/repositories/empresa_banco_repository.dart';
import '../../domain/entities/gasto_recurrente.dart';
import '../../domain/entities/pago_gasto_recurrente.dart';
import '../bloc/pagar_cubit.dart';
import '../bloc/pagar_state.dart';

class PagarGastoDialog extends StatelessWidget {
  final GastoRecurrente gasto;
  final String periodo; // YYYY-MM

  const PagarGastoDialog({
    super.key,
    required this.gasto,
    required this.periodo,
  });

  /// Devuelve `true` si el pago se registró.
  static Future<bool?> show(
    BuildContext context, {
    required GastoRecurrente gasto,
    required String periodo,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PagarGastoDialog(gasto: gasto, periodo: periodo),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<PagarGastoCubit>(),
      child: _DialogContent(gasto: gasto, periodo: periodo),
    );
  }
}

class _DialogContent extends StatefulWidget {
  final GastoRecurrente gasto;
  final String periodo;
  const _DialogContent({required this.gasto, required this.periodo});

  @override
  State<_DialogContent> createState() => _DialogContentState();
}

class _DialogContentState extends State<_DialogContent> {
  final _formKey = GlobalKey<FormState>();
  final _montoCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  final _imagePicker = ImagePicker();

  FuentePagoGasto _fuente = FuentePagoGasto.caja;
  MetodoPagoGasto _metodo = MetodoPagoGasto.efectivo;
  String? _cajaId;
  String? _bancoId;
  File? _comprobanteFile;

  bool _cargandoFuentes = true;
  String? _fuentesError;
  List<EmpresaBanco> _bancos = [];

  @override
  void initState() {
    super.initState();
    _montoCtrl.text = widget.gasto.montoEstimado.toStringAsFixed(2);
    _cargarFuentes();
  }

  Future<void> _cargarFuentes() async {
    try {
      final cajaDS = locator<CajaRemoteDataSource>();
      final bancoRepo = locator<EmpresaBancoRepository>();
      final results = await Future.wait([
        cajaDS.getCajaActiva(),
        bancoRepo.listar(),
      ]);
      if (!mounted) return;

      final cajaActiva = results[0];
      final bancosResource = results[1] as Resource<List<EmpresaBanco>>;
      final List<EmpresaBanco> bancos = bancosResource is Success<List<EmpresaBanco>>
          ? bancosResource.data.where((b) => b.isActive).toList()
          : <EmpresaBanco>[];

      setState(() {
        _cajaId = cajaActiva != null ? (cajaActiva as dynamic).id as String : null;
        _bancos = bancos;
        _cargandoFuentes = false;
        // Defaults sensatos: si no hay caja abierta pero sí bancos, arranca en BANCO
        if (_cajaId == null && bancos.isNotEmpty) {
          _fuente = FuentePagoGasto.banco;
          _metodo = MetodoPagoGasto.transferencia;
          _bancoId = bancos.firstWhere((b) => b.esPrincipal, orElse: () => bancos.first).id;
        } else if (bancos.isNotEmpty) {
          _bancoId = bancos.firstWhere((b) => b.esPrincipal, orElse: () => bancos.first).id;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargandoFuentes = false;
        _fuentesError = 'Error cargando caja/bancos: $e';
      });
    }
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  List<MetodoPagoGasto> get _metodosValidos {
    if (_fuente == FuentePagoGasto.banco) {
      // Sin EFECTIVO: no tiene sentido pagar EFECTIVO desde cuenta bancaria
      return MetodoPagoGasto.values
          .where((m) => m != MetodoPagoGasto.efectivo)
          .toList();
    }
    return MetodoPagoGasto.values;
  }

  Future<void> _adjuntarFoto({required ImageSource source}) async {
    try {
      final XFile? picked = source == ImageSource.camera
          ? await _imagePicker.pickImage(source: source, maxWidth: 1600, maxHeight: 1600)
          : await _imagePicker.pickImage(source: source);
      if (picked == null) return;
      setState(() => _comprobanteFile = File(picked.path));
      if (!mounted) return;
      await context.read<PagarGastoCubit>().subirComprobante(picked.path);
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'No se pudo seleccionar la foto');
    }
  }

  void _quitarComprobante() {
    setState(() => _comprobanteFile = null);
    context.read<PagarGastoCubit>().quitarComprobante();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_fuente == FuentePagoGasto.caja && _cajaId == null) {
      SnackBarHelper.showError(
        context,
        'No tienes una caja abierta. Cambia a BANCO o abre una caja primero.',
      );
      return;
    }
    if (_fuente == FuentePagoGasto.banco && _bancoId == null) {
      SnackBarHelper.showError(context, 'Selecciona una cuenta bancaria');
      return;
    }
    final monto = double.tryParse(_montoCtrl.text.replaceAll(',', '.')) ?? 0;
    final notas = _notasCtrl.text.trim();

    context.read<PagarGastoCubit>().pagar(
          gastoId: widget.gasto.id,
          periodo: widget.periodo,
          montoReal: monto,
          fuente: _fuente,
          metodoPago: _metodo,
          cajaId: _fuente == FuentePagoGasto.caja ? _cajaId : null,
          bancoId: _fuente == FuentePagoGasto.banco ? _bancoId : null,
          notas: notas.isEmpty ? null : notas,
        );
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: BlocConsumer<PagarGastoCubit, PagarGastoState>(
        listener: (context, state) {
          if (state is PagarGastoOk) {
            SnackBarHelper.showSuccess(context, 'Pago registrado');
            Navigator.of(context).pop(true);
          } else if (state is PagarGastoError) {
            SnackBarHelper.showError(context, state.message);
          }
        },
        builder: (context, state) {
          final enviando = state is PagarGastoEnviando;
          final subiendo = state is PagarGastoUploading;

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
                  decoration: const BoxDecoration(
                    color: AppColors.blue1,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Marcar pagado',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${widget.gasto.nombre} · ${widget.periodo}',
                              style: TextStyle(
                                color: AppColors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.white),
                        onPressed: enviando ? null : () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CurrencyTextField(
                            controller: _montoCtrl,
                            label: 'Monto real',
                            borderColor: AppColors.blue1,
                            hintText: '0.00',
                            requiredField: true,
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              'Estimado: ${money.format(widget.gasto.montoEstimado)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _fuenteSelector(),
                          const SizedBox(height: 12),
                          if (_cargandoFuentes)
                            const LinearProgressIndicator(minHeight: 2)
                          else if (_fuentesError != null)
                            Text(_fuentesError!,
                                style: const TextStyle(color: AppColors.red, fontSize: 12))
                          else if (_fuente == FuentePagoGasto.caja)
                            _cajaInfo()
                          else
                            _bancoDropdown(),
                          const SizedBox(height: 12),
                          CustomDropdown<MetodoPagoGasto>(
                            label: 'Método de pago',
                            borderColor: AppColors.blue1,
                            hintText: 'Selecciona el método',
                            value: _metodosValidos.contains(_metodo)
                                ? _metodo
                                : _metodosValidos.first,
                            items: _metodosValidos
                                .map(
                                  (m) => DropdownItem<MetodoPagoGasto>(
                                    value: m,
                                    label: m.label,
                                    leading: Icon(
                                      _metodoIcon(m),
                                      size: 16,
                                      color: AppColors.blue1,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _metodo = v);
                            },
                            validator: (v) => v == null ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 14),
                          _comprobanteSection(subiendo),
                          const SizedBox(height: 12),
                          CustomText(
                            controller: _notasCtrl,
                            label: 'Notas (opcional)',
                            hintText: 'Detalles del pago',
                            borderColor: AppColors.blue1,
                            maxLines: 2,
                            maxLength: 500,
                            height: null,
                            enableVoiceInput: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  decoration: BoxDecoration(
                    color: AppColors.grey.withValues(alpha: 0.06),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: CustomButton(
                    text: 'Registrar pago',
                    onPressed: (enviando || subiendo || _cargandoFuentes) ? null : _submit,
                    isLoading: enviando,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _fuenteSelector() {
    return SegmentedButton<FuentePagoGasto>(
      segments: const [
        ButtonSegment(
          value: FuentePagoGasto.caja,
          label: Text('Caja'),
          icon: Icon(Icons.point_of_sale, size: 18),
        ),
        ButtonSegment(
          value: FuentePagoGasto.banco,
          label: Text('Banco'),
          icon: Icon(Icons.account_balance, size: 18),
        ),
      ],
      selected: {_fuente},
      onSelectionChanged: (s) {
        setState(() {
          _fuente = s.first;
          // Si cambias a banco y el método actual no aplica, ajustar
          if (!_metodosValidos.contains(_metodo)) {
            _metodo = _metodosValidos.first;
          }
        });
      },
    );
  }

  Widget _cajaInfo() {
    if (_cajaId == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: 0.1),
          border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.orange, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'No tienes caja abierta. Cambia a BANCO o abre una caja primero.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.blue1.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.blue1, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Se descontará de la caja abierta del usuario.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bancoDropdown() {
    if (_bancos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'No hay cuentas bancarias registradas. Agrégalas en Cuentas Bancarias.',
          style: TextStyle(fontSize: 12),
        ),
      );
    }
    return CustomDropdown<String>(
      label: 'Cuenta bancaria',
      borderColor: AppColors.blue1,
      hintText: 'Selecciona una cuenta',
      value: _bancoId,
      dropdownStyle: _bancos.length > 6
          ? DropdownStyle.searchable
          : DropdownStyle.standard,
      showSearchBox: _bancos.length > 6,
      items: _bancos
          .map(
            (b) => DropdownItem<String>(
              value: b.id,
              label: '${b.nombreBanco} · ${b.numeroCuenta}${b.esPrincipal ? ' ★' : ''}',
              leading: const Icon(Icons.account_balance, size: 16, color: AppColors.blue1),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _bancoId = v),
      validator: (v) => v == null ? 'Selecciona una cuenta' : null,
    );
  }

  IconData _metodoIcon(MetodoPagoGasto m) {
    switch (m) {
      case MetodoPagoGasto.efectivo:
        return Icons.payments;
      case MetodoPagoGasto.tarjeta:
        return Icons.credit_card;
      case MetodoPagoGasto.yape:
        return Icons.phone_iphone;
      case MetodoPagoGasto.plin:
        return Icons.phone_iphone;
      case MetodoPagoGasto.transferencia:
        return Icons.swap_horiz;
    }
  }

  Widget _comprobanteSection(bool subiendo) {
    if (_comprobanteFile != null) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.blue1.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.blue1.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                _comprobanteFile!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: AppColors.grey.withValues(alpha: 0.2),
                  child: const Icon(Icons.insert_drive_file, color: AppColors.grey),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Comprobante adjunto',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            if (subiendo)
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: _quitarComprobante,
                tooltip: 'Quitar',
              ),
          ],
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _adjuntarFoto(source: ImageSource.camera),
            icon: const Icon(Icons.photo_camera, size: 18),
            label: const Text('Foto'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _adjuntarFoto(source: ImageSource.gallery),
            icon: const Icon(Icons.image, size: 18),
            label: const Text('Galería'),
          ),
        ),
      ],
    );
  }
}
