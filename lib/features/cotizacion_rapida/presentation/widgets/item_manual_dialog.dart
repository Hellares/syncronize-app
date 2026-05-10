import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/currency/currency_formatter.dart';
import 'package:syncronize/core/widgets/currency/currency_textfield.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';

class ItemManualResult {
  final String descripcion;
  final double cantidad;
  final double precioUnitario;

  const ItemManualResult({
    required this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get total => cantidad * precioUnitario;
}

/// Dialog para agregar uno o varios items manuales (sin productoId) al
/// carrito de cotización rápida. Soporta agregar múltiples items en una
/// sola sesión: el cajero compone la lista, revisa, y confirma todo a la vez.
///
/// Retorna la lista completa cuando confirma; `null` si cancela.
Future<List<ItemManualResult>?> showItemManualDialog(BuildContext context) {
  return showDialog<List<ItemManualResult>>(
    context: context,
    builder: (_) => const _ItemManualDialog(),
  );
}

class _ItemManualDialog extends StatefulWidget {
  const _ItemManualDialog();

  @override
  State<_ItemManualDialog> createState() => _ItemManualDialogState();
}

class _ItemManualDialogState extends State<_ItemManualDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController(text: '1');
  final _precioCtrl = TextEditingController();
  final _descFocus = FocusNode();

  /// Items que el cajero está componiendo. Se confirman todos a la vez al
  /// cerrar con "Agregar todos" para evitar N llamadas repetidas al dialog.
  final List<ItemManualResult> _pendientes = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _descFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _cantidadCtrl.dispose();
    _precioCtrl.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  void _agregarALista() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final descripcion = _descCtrl.text.trim();
    final cantidad =
        double.tryParse(_cantidadCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    final precio = CurrencyUtilsImproved.parseToDouble(_precioCtrl.text);
    if (descripcion.isEmpty || cantidad <= 0 || precio < 0) return;

    setState(() {
      _pendientes.add(ItemManualResult(
        descripcion: descripcion,
        cantidad: cantidad,
        precioUnitario: precio,
      ));
      _descCtrl.clear();
      _cantidadCtrl.text = '1';
      _precioCtrl.clear();
    });
    _descFocus.requestFocus();
  }

  void _quitar(int index) {
    setState(() => _pendientes.removeAt(index));
  }

  void _confirmar() {
    // Si hay datos en el form pero no se ha agregado a la lista, agregamos.
    final tieneDescPendiente = _descCtrl.text.trim().isNotEmpty;
    if (tieneDescPendiente) {
      _agregarALista();
    }
    if (_pendientes.isEmpty) return;
    Navigator.of(context).pop(List<ItemManualResult>.from(_pendientes));
  }

  double get _totalPendientes =>
      _pendientes.fold(0, (sum, it) => sum + it.total);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: GradientContainer(
        gradient: AppGradients.blueWhiteDialog(),
        padding: const EdgeInsets.only(left: 15, right: 15, top: 10),
        borderRadius: BorderRadius.circular(10.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.bluechip,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_note,
                    color: AppColors.blue1,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTitle('Items manuales'),
                      AppSubtitle(
                        'Para servicios o productos fuera del catálogo',
                        fontSize: 10,
                        color: AppColors.blue1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            // ── Form para nuevo item ──
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            label: 'Descripción',
                            hintText: 'Ej. Servicio de instalación',
                            controller: _descCtrl,
                            focusNode: _descFocus,
                            fieldType: FieldType.text,
                            textCase: TextCase.normal,
                            borderColor: AppColors.blue1,
                            required: true,
                            maxLength: 200,
                            autovalidateMode: AutovalidateModeX.onUnfocus,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Requerido'
                                : null,
                            onSubmitted: (_) => _agregarALista(),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: CustomText(
                                  label: 'Cantidad',
                                  controller: _cantidadCtrl,
                                  fieldType: FieldType.number,
                                  borderColor: AppColors.blue1,
                                  required: true,
                                  autovalidateMode:
                                      AutovalidateModeX.onUnfocus,
                                  validator: (v) {
                                    final n = double.tryParse(
                                      (v ?? '').trim().replaceAll(',', '.'),
                                    );
                                    if (n == null || n <= 0) {
                                      return 'Inválido';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: CurrencyTextField(
                                  label: 'Precio (incluye IGV)',
                                  controller: _precioCtrl,
                                  hintText: '0.00',
                                  borderColor: AppColors.blue1,
                                  validator: (v) {
                                    final n =
                                        CurrencyUtilsImproved.parseToDouble(
                                            v ?? '');
                                    if (n <= 0) return 'Inválido';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Botón "+ Agregar a la lista"
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _agregarALista,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text(
                                'Agregar a la lista',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.blue1,
                                side: const BorderSide(
                                    color: AppColors.blue1),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── Lista pendiente ──
                    if (_pendientes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          AppSubtitle(
                            'Pendientes (${_pendientes.length})',
                            fontSize: 11,
                            color: AppColors.blue1,
                          ),
                          const Spacer(),
                          AppSubtitle(
                            'Total S/ ${_totalPendientes.toStringAsFixed(2)}',
                            fontSize: 11,
                            color: AppColors.blue1,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border:
                              Border.all(color: AppColors.blue1, width: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < _pendientes.length; i++) ...[
                              if (i > 0)
                                Divider(
                                    height: 1,
                                    color: Colors.grey.shade200),
                              _PendienteRow(
                                item: _pendientes[i],
                                onQuitar: () => _quitar(i),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            // ── Footer ──
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: (_pendientes.isEmpty &&
                              _descCtrl.text.trim().isEmpty)
                          ? null
                          : _confirmar,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.blue1,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      icon: const Icon(Icons.check, size: 16),
                      label: Text(
                        _pendientes.isEmpty
                            ? 'Confirmar'
                            : 'Agregar ${_pendientes.length} item${_pendientes.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendienteRow extends StatelessWidget {
  final ItemManualResult item;
  final VoidCallback onQuitar;

  const _PendienteRow({required this.item, required this.onQuitar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.descripcion,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.cantidad.toStringAsFixed(item.cantidad.truncateToDouble() == item.cantidad ? 0 : 2)} '
                  '× S/ ${item.precioUnitario.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'S/ ${item.total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.blue1,
            ),
          ),
          IconButton(
            onPressed: onQuitar,
            icon: Icon(Icons.close, size: 16, color: Colors.red.shade400),
            tooltip: 'Quitar',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
