import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/utils/date_formatter.dart' as date_utils;
import 'package:syncronize/core/utils/resource.dart';
import 'package:syncronize/core/widgets/autorizacion_dialog.dart';
import 'package:syncronize/core/widgets/currency/currency_textfield.dart';
import 'package:syncronize/core/widgets/styled_dialog.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/date/custom_date.dart';
import '../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../domain/entities/producto_stock.dart';
import '../../domain/repositories/producto_stock_repository.dart';

/// Dialog para activar / desactivar liquidación (remate bajo costo) sobre un
/// ProductoStock. Requiere autorización gerencial via DNI+password (flujo
/// /auth/autorizar-operacion). El precio de liquidación DEBE ser menor al
/// precio de costo (caso contrario debería usar oferta normal).
class GestionarLiquidacionDialog extends StatefulWidget {
  final ProductoStock stock;

  const GestionarLiquidacionDialog({super.key, required this.stock});

  @override
  State<GestionarLiquidacionDialog> createState() =>
      _GestionarLiquidacionDialogState();
}

class _GestionarLiquidacionDialogState
    extends State<GestionarLiquidacionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _precioController = TextEditingController();
  final _observacionesController = TextEditingController();
  MotivoLiquidacion _motivo = MotivoLiquidacion.fueraDeCampana;
  DateTime? _fechaFin;
  bool _loading = false;
  String? _error;

  late final ProductoStockRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = locator<ProductoStockRepository>();
    if (widget.stock.isLiquidacionActiva) {
      _precioController.text =
          widget.stock.precioLiquidacion!.toStringAsFixed(2);
      _motivo = widget.stock.motivoLiquidacion ?? MotivoLiquidacion.fueraDeCampana;
      _observacionesController.text = widget.stock.observacionesLiquidacion ?? '';
      _fechaFin = widget.stock.fechaFinLiquidacion?.toLocal();
    }
  }

  @override
  void dispose() {
    _precioController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _activar() async {
    if (!_formKey.currentState!.validate()) return;
    final precio = double.tryParse(_precioController.text.replaceAll(',', '.'));
    if (precio == null || precio <= 0) {
      setState(() => _error = 'Precio inválido');
      return;
    }
    final costo = widget.stock.precioCosto ?? 0;
    if (costo <= 0) {
      setState(() => _error =
          'Configura primero el precio de costo del producto antes de liquidar.');
      return;
    }
    if (precio > costo) {
      setState(() => _error =
          'El precio de liquidación debe ser igual o menor al costo (S/${costo.toStringAsFixed(2)}). Si es mayor, usa una oferta normal.');
      return;
    }
    if (_motivo == MotivoLiquidacion.otro &&
        _observacionesController.text.trim().isEmpty) {
      setState(() =>
          _error = 'Cuando el motivo es OTRO, las observaciones son obligatorias.');
      return;
    }

    // Default: usar el usuario en sesion como autorizador. El backend
    // valida que tenga rol GERENTE_SEDE/ADMINISTRADOR/SUPER_ADMIN/
    // EMPRESA_ADMIN (assertAutorizadorGerencial). Si el usuario logueado
    // tiene ese rol (lo normal: solo admins acceden a este dialog),
    // pasa directo sin pedir DNI+password — UX más fluido.
    String? autorizadoPorId;
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      autorizadoPorId = authState.user.id;
    }

    // Si por algun motivo no hay user en sesion, caer al flow clasico.
    if (autorizadoPorId == null) {
      final auth = await showAutorizacionDialog(
        context,
        operacion: 'ACTIVAR_LIQUIDACION',
        titulo: 'Autorizar liquidación',
        descripcion:
            'Un GERENTE o ADMINISTRADOR debe autorizar la liquidación de "${widget.stock.nombreProducto}".',
      );
      if (auth == null) return;
      autorizadoPorId = auth.autorizadoPorId;
    }

    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    var result = await _repo.activarLiquidacion(
      productoStockId: widget.stock.id,
      precioLiquidacion: precio,
      motivo: _motivo,
      autorizadoPorId: autorizadoPorId,
      fechaFin: _fechaFin,
      observaciones: _observacionesController.text.trim().isEmpty
          ? null
          : _observacionesController.text.trim(),
    );

    // Fallback: si el backend rechaza por rol insuficiente del usuario
    // actual (caso raro: vendedor que llego acá por accion), pedir
    // autorizacion de un gerente y reintentar.
    final errInicial = result;
    if (errInicial is Error<ProductoStock> &&
        errInicial.message.toLowerCase().contains('rol gerente')) {
      if (!mounted) return;
      setState(() => _loading = false);
      final auth = await showAutorizacionDialog(
        context,
        operacion: 'ACTIVAR_LIQUIDACION',
        titulo: 'Autorizar liquidación',
        descripcion:
            'Tu usuario no tiene rol gerencial. Un GERENTE o ADMINISTRADOR debe autorizar la liquidación de "${widget.stock.nombreProducto}".',
      );
      if (auth == null) return;
      if (!mounted) return;
      setState(() => _loading = true);
      result = await _repo.activarLiquidacion(
        productoStockId: widget.stock.id,
        precioLiquidacion: precio,
        motivo: _motivo,
        autorizadoPorId: auth.autorizadoPorId,
        fechaFin: _fechaFin,
        observaciones: _observacionesController.text.trim().isEmpty
            ? null
            : _observacionesController.text.trim(),
      );
    }

    if (!mounted) return;
    final finalResult = result;
    if (finalResult is Success<ProductoStock>) {
      Navigator.of(context).pop(finalResult.data);
    } else if (finalResult is Error<ProductoStock>) {
      setState(() {
        _loading = false;
        _error = finalResult.message;
      });
    }
  }

  Future<void> _desactivar() async {
    final confirmed = await StyledDialog.show<bool>(
      context,
      accentColor: Colors.deepOrange.shade700,
      icon: Icons.local_fire_department,
      titulo: 'Desactivar liquidación',
      content: [
        Text(
          '¿Desactivar la liquidación de "${widget.stock.nombreProducto}"?',
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 6),
        Text(
          'El producto volverá a venderse a precio regular u oferta.',
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
      actions: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
          ),
        ),
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Desactivar', style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
    if (confirmed != true) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repo.desactivarLiquidacion(productoStockId: widget.stock.id);
    if (!mounted) return;
    if (result is Success<ProductoStock>) {
      Navigator.of(context).pop(result.data);
    } else if (result is Error<ProductoStock>) {
      setState(() {
        _loading = false;
        _error = result.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activa = widget.stock.isLiquidacionActiva;
    final costo = widget.stock.precioCosto;
    final precioBase = widget.stock.precio;

    final accentColor = Colors.deepOrange.shade700;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: GradientContainer(
        borderColor: accentColor.withValues(alpha: 0.4),
        borderWidth: 1,
        customShadows: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.18),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.local_fire_department,
                          color: accentColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Liquidación',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ),
                    if (activa)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ACTIVA',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange.shade900),
                            ),
                          ),
                          if (widget.stock.fechaInicioLiquidacion != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'desde ${date_utils.DateFormatter.formatDate(widget.stock.fechaInicioLiquidacion!.toLocal())}',
                              style: TextStyle(
                                fontSize: 9,
                                color: accentColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Card resumen precios
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.blue1.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    children: [
                      _resumenRow('Precio base', precioBase),
                      _resumenRow('Precio costo', costo, color: Colors.grey.shade700),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Form
                if (!activa) ...[
                  const Text('Precio de liquidación',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  CurrencyTextField(
                    borderColor: AppColors.blue1,
                    controller: _precioController,
                    label: 'Precio liquidación',
                  ),
                  if (costo != null && costo > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Debe ser igual o menor al precio costo S/${costo.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 11, color: Colors.deepOrange.shade400),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Text('Motivo',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  CustomDropdown<MotivoLiquidacion>(
                    borderColor: AppColors.blue1,
                    value: _motivo,
                    items: MotivoLiquidacion.values
                        .map((m) => DropdownItem(value: m, label: m.label))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _motivo = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('Vence el (opcional)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  CustomDate(
                    borderColor: AppColors.blue1,
                    initialDate: _fechaFin,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    onDateSelected: (d) => setState(() => _fechaFin = d),
                    hintText: 'Sin vencimiento',
                    validator: (_) => null,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _motivo == MotivoLiquidacion.otro
                        ? 'Observaciones (obligatorio)'
                        : 'Observaciones (opcional)',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  CustomText(
                    controller: _observacionesController,
                    maxLines: 2,
                    contentPadding: const EdgeInsets.all(12),
                    hintText: 'Ej: campaña navideña terminada',
                  ),
                ] else ...[
                  _readonlyField('Precio liquidación', 'S/ ${widget.stock.precioLiquidacion!.toStringAsFixed(2)}'),
                  _readonlyField('Motivo', widget.stock.motivoLiquidacion?.label ?? '—'),
                  if (widget.stock.fechaFinLiquidacion != null)
                    _readonlyField(
                        'Vence',
                        date_utils.DateFormatter.formatDate(
                            widget.stock.fechaFinLiquidacion!.toLocal())),
                  if ((widget.stock.observacionesLiquidacion ?? '').isNotEmpty)
                    _readonlyField('Obs.', widget.stock.observacionesLiquidacion!),
                ],

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!, style: TextStyle(color: Colors.red.shade800, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Cerrar',
                        isOutlined: true,
                        borderColor: Colors.grey.shade400,
                        borderWidth: 1,
                        textColor: Colors.grey.shade600,
                        onPressed: _loading ? null : () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (activa)
                      Expanded(
                        child: CustomButton(
                          text: 'Desactivar',
                          icon: Icon(Icons.cancel_outlined, size: 16, color: Colors.white),
                          backgroundColor: Colors.red.shade600,
                          textColor: Colors.white,
                          onPressed: _loading ? null : _desactivar,
                        ),
                      )
                    else
                      Expanded(
                        flex: 2,
                        child: CustomButton(
                          text: 'Activar liquidación',
                          isLoading: _loading,
                          icon: const Icon(Icons.local_fire_department, size: 16, color: Colors.white),
                          backgroundColor: accentColor,
                          textColor: Colors.white,
                          onPressed: _loading ? null : _activar,
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

  Widget _resumenRow(String label, double? value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          Text(
            value != null ? 'S/ ${value.toStringAsFixed(2)}' : '—',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _readonlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.green)),
        ],
      ),
    );
  }
}
