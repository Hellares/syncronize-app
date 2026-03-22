import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/ubicacion_almacen.dart';

/// Dialog para crear o editar una ubicacion de almacen.
class UbicacionFormDialog extends StatefulWidget {
  /// Si se pasa una ubicacion, se edita; si no, se crea una nueva.
  final UbicacionAlmacen? ubicacion;

  /// Lista de ubicaciones disponibles como posibles parents.
  final List<UbicacionAlmacen> ubicacionesDisponibles;

  const UbicacionFormDialog({
    super.key,
    this.ubicacion,
    this.ubicacionesDisponibles = const [],
  });

  /// Muestra el dialog y retorna un Map con los datos del formulario, o null si se cancelo.
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    UbicacionAlmacen? ubicacion,
    List<UbicacionAlmacen> ubicacionesDisponibles = const [],
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UbicacionFormDialog(
        ubicacion: ubicacion,
        ubicacionesDisponibles: ubicacionesDisponibles,
      ),
    );
  }

  @override
  State<UbicacionFormDialog> createState() => _UbicacionFormDialogState();
}

class _UbicacionFormDialogState extends State<UbicacionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigoCtrl;
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _capacidadCtrl;

  TipoUbicacion _tipoSeleccionado = TipoUbicacion.zona;
  String? _parentIdSeleccionado;

  bool get _isEditing => widget.ubicacion != null;

  @override
  void initState() {
    super.initState();
    final ub = widget.ubicacion;
    _codigoCtrl = TextEditingController(text: ub?.codigo ?? '');
    _nombreCtrl = TextEditingController(text: ub?.nombre ?? '');
    _descripcionCtrl = TextEditingController(text: ub?.descripcion ?? '');
    _capacidadCtrl = TextEditingController(
      text: ub?.capacidadMaxima != null ? '${ub!.capacidadMaxima}' : '',
    );
    if (ub != null) {
      _tipoSeleccionado = ub.tipo;
      _parentIdSeleccionado = ub.parentId;
    }
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _capacidadCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'codigo': _codigoCtrl.text.trim(),
      'nombre': _nombreCtrl.text.trim(),
      'tipo': _tipoSeleccionado.name.toUpperCase(),
    };

    if (_descripcionCtrl.text.trim().isNotEmpty) {
      data['descripcion'] = _descripcionCtrl.text.trim();
    }
    if (_capacidadCtrl.text.trim().isNotEmpty) {
      data['capacidadMaxima'] = int.tryParse(_capacidadCtrl.text.trim());
    }
    if (_parentIdSeleccionado != null) {
      data['parentId'] = _parentIdSeleccionado;
    }

    Navigator.of(context).pop(data);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  _isEditing ? 'Editar Ubicacion' : 'Nueva Ubicacion',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),

                // Codigo
                TextFormField(
                  controller: _codigoCtrl,
                  decoration: _inputDecoration('Codigo *', Icons.qr_code),
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingrese un codigo' : null,
                ),
                const SizedBox(height: 14),

                // Nombre
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: _inputDecoration('Nombre *', Icons.label_outline),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingrese un nombre' : null,
                ),
                const SizedBox(height: 14),

                // Tipo
                DropdownButtonFormField<TipoUbicacion>(
                  value: _tipoSeleccionado,
                  decoration: _inputDecoration('Tipo', Icons.category_outlined),
                  items: TipoUbicacion.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(
                        t.name.toUpperCase(),
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _tipoSeleccionado = v);
                  },
                ),
                const SizedBox(height: 14),

                // Capacidad maxima
                TextFormField(
                  controller: _capacidadCtrl,
                  decoration:
                      _inputDecoration('Capacidad maxima (opcional)', Icons.straighten),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 14),

                // Descripcion
                TextFormField(
                  controller: _descripcionCtrl,
                  decoration:
                      _inputDecoration('Descripcion (opcional)', Icons.notes),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 14),

                // Parent selector
                if (widget.ubicacionesDisponibles.isNotEmpty) ...[
                  DropdownButtonFormField<String?>(
                    value: _parentIdSeleccionado,
                    decoration: _inputDecoration(
                        'Ubicacion padre (opcional)', Icons.account_tree_outlined),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Ninguna (raiz)',
                            style: TextStyle(fontSize: 14)),
                      ),
                      ...widget.ubicacionesDisponibles
                          .where((u) => u.id != widget.ubicacion?.id)
                          .map((u) {
                        return DropdownMenuItem<String?>(
                          value: u.id,
                          child: Text(
                            '${u.codigo} - ${u.nombre}',
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: (v) =>
                        setState(() => _parentIdSeleccionado = v),
                  ),
                  const SizedBox(height: 20),
                ] else
                  const SizedBox(height: 6),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue1,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          _isEditing ? 'Actualizar' : 'Crear',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      prefixIcon: Icon(icon, size: 20, color: AppColors.blue1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      isDense: true,
    );
  }
}
