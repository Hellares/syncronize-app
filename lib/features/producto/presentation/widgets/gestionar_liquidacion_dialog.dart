import 'package:flutter/material.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/utils/date_formatter.dart' as date_utils;
import 'package:syncronize/core/utils/resource.dart';
import 'package:syncronize/core/widgets/autorizacion_dialog.dart';
import 'package:syncronize/core/widgets/currency/currency_textfield.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/core/widgets/date/custom_date.dart';
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
    if (precio >= costo) {
      setState(() => _error =
          'El precio de liquidación debe ser menor al costo (S/${costo.toStringAsFixed(2)}). Si es mayor, usa una oferta normal.');
      return;
    }
    if (_motivo == MotivoLiquidacion.otro &&
        _observacionesController.text.trim().isEmpty) {
      setState(() =>
          _error = 'Cuando el motivo es OTRO, las observaciones son obligatorias.');
      return;
    }

    // Autorización gerencial
    final auth = await showAutorizacionDialog(
      context,
      operacion: 'ACTIVAR_LIQUIDACION',
      titulo: 'Autorizar liquidación',
      descripcion:
          'Un GERENTE o ADMINISTRADOR debe autorizar la liquidación de "${widget.stock.nombreProducto}".',
    );
    if (auth == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _repo.activarLiquidacion(
      productoStockId: widget.stock.id,
      precioLiquidacion: precio,
      motivo: _motivo,
      autorizadoPorId: auth.autorizadoPorId,
      fechaFin: _fechaFin,
      observaciones: _observacionesController.text.trim().isEmpty
          ? null
          : _observacionesController.text.trim(),
    );

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

  Future<void> _desactivar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactivar liquidación'),
        content: Text(
          '¿Desactivar la liquidación de "${widget.stock.nombreProducto}"? El producto volverá a venderse a precio regular u oferta.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desactivar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
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
                    Icon(Icons.local_fire_department,
                        color: Colors.deepOrange.shade700, size: 26),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Liquidación',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (activa)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  ],
                ),
                const SizedBox(height: 12),

                // Card resumen precios actuales
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
                    controller: _precioController,
                    label: 'Precio liquidación',
                  ),
                  if (costo != null && costo > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Debe ser menor a S/${costo.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Text('Motivo',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  CustomDropdown<MotivoLiquidacion>(
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
                    initialDate: _fechaFin,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    onDateSelected: (d) => setState(() => _fechaFin = d),
                    hintText: 'Sin vencimiento',
                    // Campo 100% opcional: vacío = liquidación permanente
                    // hasta desactivación manual. El validator por defecto
                    // de CustomDate exige fecha, lo anulamos.
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
                  TextField(
                    controller: _observacionesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12),
                      hintText: 'Ej: campaña navideña terminada',
                    ),
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
                      child: TextButton(
                        onPressed: _loading ? null : () => Navigator.pop(context),
                        child: const Text('Cerrar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (activa)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _desactivar,
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Desactivar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      )
                    else
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _activar,
                          icon: _loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.local_fire_department),
                          label: const Text('Activar liquidación'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange.shade700,
                            foregroundColor: Colors.white,
                          ),
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
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
