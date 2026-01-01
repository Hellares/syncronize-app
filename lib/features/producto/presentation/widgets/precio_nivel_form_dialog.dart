import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/precio_nivel.dart';
import '../../data/models/precio_nivel_model.dart';

/// Diálogo para crear o editar un nivel de precio
class PrecioNivelFormDialog extends StatefulWidget {
  final double? precioBase;
  final PrecioNivel? nivelToEdit;
  final List<PrecioNivel> nivelesExistentes;
  final Function(PrecioNivelDto) onSave;

  const PrecioNivelFormDialog({
    super.key,
    this.precioBase,
    this.nivelToEdit,
    required this.nivelesExistentes,
    required this.onSave,
  });

  @override
  State<PrecioNivelFormDialog> createState() => _PrecioNivelFormDialogState();
}

class _PrecioNivelFormDialogState extends State<PrecioNivelFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _cantidadMinimaController = TextEditingController();
  final _cantidadMaximaController = TextEditingController();
  final _precioController = TextEditingController();
  final _porcentajeController = TextEditingController();
  final _descripcionController = TextEditingController();

  TipoPrecioNivel _tipoPrecio = TipoPrecioNivel.precioFijo;
  bool _tieneCantidadMaxima = false;

  @override
  void initState() {
    super.initState();
    if (widget.nivelToEdit != null) {
      final nivel = widget.nivelToEdit!;
      _nombreController.text = nivel.nombre;
      _cantidadMinimaController.text = nivel.cantidadMinima.toString();
      if (nivel.cantidadMaxima != null) {
        _cantidadMaximaController.text = nivel.cantidadMaxima.toString();
        _tieneCantidadMaxima = true;
      }
      _tipoPrecio = nivel.tipoPrecio;
      if (nivel.precio != null) {
        _precioController.text = nivel.precio.toString();
      }
      if (nivel.porcentajeDesc != null) {
        _porcentajeController.text = nivel.porcentajeDesc.toString();
      }
      if (nivel.descripcion != null) {
        _descripcionController.text = nivel.descripcion!;
      }
    } else {
      // Valores por defecto para nuevo nivel
      _nombreController.text = _generarNombreSugerido();
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _cantidadMinimaController.dispose();
    _cantidadMaximaController.dispose();
    _precioController.dispose();
    _porcentajeController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  String _generarNombreSugerido() {
    final count = widget.nivelesExistentes.length;
    if (count == 0) return 'Precio Retail';
    if (count == 1) return 'Precio por Mayor';
    if (count == 2) return 'Precio Distribuidor';
    return 'Nivel ${count + 1}';
  }

  String? _validateCantidadMinima(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa la cantidad mínima';
    }
    final cantidad = int.tryParse(value);
    if (cantidad == null || cantidad < 1) {
      return 'Debe ser al menos 1';
    }
    return null;
  }

  String? _validateCantidadMaxima(String? value) {
    if (!_tieneCantidadMaxima) return null;
    if (value == null || value.isEmpty) {
      return 'Ingresa la cantidad máxima';
    }
    final max = int.tryParse(value);
    final min = int.tryParse(_cantidadMinimaController.text);
    if (max == null || max < 1) {
      return 'Debe ser al menos 1';
    }
    if (min != null && max <= min) {
      return 'Debe ser mayor que el mínimo';
    }
    return null;
  }

  String? _validatePrecio(String? value) {
    if (_tipoPrecio != TipoPrecioNivel.precioFijo) return null;
    if (value == null || value.isEmpty) {
      return 'Ingresa el precio';
    }
    final precio = double.tryParse(value);
    if (precio == null || precio <= 0) {
      return 'Precio inválido';
    }
    return null;
  }

  String? _validatePorcentaje(String? value) {
    if (_tipoPrecio != TipoPrecioNivel.porcentajeDescuento) return null;
    if (value == null || value.isEmpty) {
      return 'Ingresa el porcentaje';
    }
    final porcentaje = double.tryParse(value);
    if (porcentaje == null || porcentaje < 0 || porcentaje > 100) {
      return 'Debe estar entre 0 y 100';
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final dto = PrecioNivelDto(
      nombre: _nombreController.text.trim(),
      cantidadMinima: int.parse(_cantidadMinimaController.text),
      cantidadMaxima: _tieneCantidadMaxima
          ? int.tryParse(_cantidadMaximaController.text)
          : null,
      tipoPrecio: _tipoPrecio,
      precio: _tipoPrecio == TipoPrecioNivel.precioFijo
          ? double.tryParse(_precioController.text)
          : null,
      porcentajeDesc: _tipoPrecio == TipoPrecioNivel.porcentajeDescuento
          ? double.tryParse(_porcentajeController.text)
          : null,
      descripcion: _descripcionController.text.trim().isEmpty
          ? null
          : _descripcionController.text.trim(),
      orden: widget.nivelToEdit?.orden ?? widget.nivelesExistentes.length,
    );

    widget.onSave(dto);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.nivelToEdit != null;
    final precioCalculado = _calcularPrecioFinal();

    return AlertDialog(
      title: Text(isEditing ? 'Editar nivel de precio' : 'Nuevo nivel de precio'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del nivel *',
                  hintText: 'Ej: Por Mayor, Distribuidor',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Rango de cantidades
              const Text(
                'Rango de cantidades',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cantidadMinimaController,
                      decoration: const InputDecoration(
                        labelText: 'Mínimo *',
                        border: OutlineInputBorder(),
                        suffixText: 'unid.',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: _validateCantidadMinima,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cantidadMaximaController,
                      decoration: const InputDecoration(
                        labelText: 'Máximo',
                        border: OutlineInputBorder(),
                        suffixText: 'unid.',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      enabled: _tieneCantidadMaxima,
                      validator: _validateCantidadMaxima,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _tieneCantidadMaxima,
                onChanged: (value) {
                  setState(() {
                    _tieneCantidadMaxima = value ?? false;
                    if (!_tieneCantidadMaxima) {
                      _cantidadMaximaController.clear();
                    }
                  });
                },
                title: const Text(
                  'Establecer cantidad máxima',
                  style: TextStyle(fontSize: 13),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              const SizedBox(height: 16),

              // Tipo de precio
              const Text(
                'Tipo de precio',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<TipoPrecioNivel>(
                segments: const [
                  ButtonSegment(
                    value: TipoPrecioNivel.precioFijo,
                    label: Text('Precio Fijo'),
                    icon: Icon(Icons.attach_money, size: 18),
                  ),
                  ButtonSegment(
                    value: TipoPrecioNivel.porcentajeDescuento,
                    label: Text('% Descuento'),
                    icon: Icon(Icons.percent, size: 18),
                  ),
                ],
                selected: {_tipoPrecio},
                onSelectionChanged: (Set<TipoPrecioNivel> newSelection) {
                  setState(() {
                    _tipoPrecio = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Campo de precio o porcentaje
              if (_tipoPrecio == TipoPrecioNivel.precioFijo)
                TextFormField(
                  controller: _precioController,
                  decoration: const InputDecoration(
                    labelText: 'Precio unitario *',
                    border: OutlineInputBorder(),
                    prefixText: 'S/ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: _validatePrecio,
                  onChanged: (_) => setState(() {}),
                )
              else
                TextFormField(
                  controller: _porcentajeController,
                  decoration: const InputDecoration(
                    labelText: 'Porcentaje de descuento *',
                    border: OutlineInputBorder(),
                    suffixText: '%',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: _validatePorcentaje,
                  onChanged: (_) => setState(() {}),
                ),

              // Precio calculado (preview)
              if (precioCalculado != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Precio final:',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              'S/ ${precioCalculado.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Ej: 10% de descuento en compras mayores a 6 unidades',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(isEditing ? 'Actualizar' : 'Crear'),
        ),
      ],
    );
  }

  double? _calcularPrecioFinal() {
    if (widget.precioBase == null) return null;

    if (_tipoPrecio == TipoPrecioNivel.precioFijo) {
      return double.tryParse(_precioController.text);
    } else {
      final porcentaje = double.tryParse(_porcentajeController.text);
      if (porcentaje != null) {
        return widget.precioBase! * (1 - porcentaje / 100);
      }
    }
    return null;
  }
}
