import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../domain/entities/producto_atributo.dart';

class AtributoInputWidget extends StatefulWidget {
  final ProductoAtributo atributo;
  final String? valorActual;
  final Function(String) onChanged;

  const AtributoInputWidget({
    super.key,
    required this.atributo,
    this.valorActual,
    required this.onChanged,
  });

  @override
  State<AtributoInputWidget> createState() => _AtributoInputWidgetState();
}

class _AtributoInputWidgetState extends State<AtributoInputWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.valorActual ?? '');
  }

  @override
  void didUpdateWidget(AtributoInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.valorActual != oldWidget.valorActual) {
      _controller.text = widget.valorActual ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildIcon(),
            const SizedBox(width: 8),
            Expanded(
              child: AppSubtitle(
                widget.atributo.nombre,
                fontSize: 10,
              ),
            ),
            if (widget.atributo.requerido)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  'Requerido',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
          ],
        ),
        if (widget.atributo.descripcion != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.atributo.descripcion!,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
        const SizedBox(height: 2),
        _buildInputByType(),
      ],
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;

    switch (widget.atributo.tipo) {
      case AtributoTipo.color:
        icon = Icons.palette;
        color = Colors.purple;
        break;
      case AtributoTipo.talla:
        icon = Icons.straighten;
        color = Colors.orange;
        break;
      case AtributoTipo.material:
        icon = Icons.category;
        color = Colors.brown;
        break;
      case AtributoTipo.capacidad:
        icon = Icons.storage;
        color = Colors.blue;
        break;
      case AtributoTipo.numero:
        icon = Icons.numbers;
        color = Colors.green;
        break;
      case AtributoTipo.texto:
        icon = Icons.text_fields;
        color = Colors.indigo;
        break;
      case AtributoTipo.select:
      case AtributoTipo.multiSelect:
        icon = Icons.list;
        color = Colors.teal;
        break;
      case AtributoTipo.boolean:
        icon = Icons.toggle_on;
        color = Colors.amber;
        break;
    }

    return Icon(icon, size: 16, color: color);
  }

  Widget _buildInputByType() {
    switch (widget.atributo.tipo) {
      case AtributoTipo.select:
      case AtributoTipo.color:
      case AtributoTipo.talla:
      case AtributoTipo.material:
      case AtributoTipo.capacidad:
        return _buildSelectInput();

      case AtributoTipo.multiSelect:
        return _buildMultiSelectInput();

      case AtributoTipo.numero:
        return _buildNumberInput();

      case AtributoTipo.texto:
        return _buildTextInput();

      case AtributoTipo.boolean:
        return _buildBooleanInput();
    }
  }

  Widget _buildSelectInput() {
    if (widget.atributo.valores.isEmpty) {
      return Text(
        'No hay valores disponibles para este atributo',
        style: TextStyle(color: Colors.grey[600], fontSize: 10),
      );
    }

    // Solo usar value si no está vacío y existe en la lista de valores
    final currentValue = widget.valorActual;
    final validValue = (currentValue != null &&
                        currentValue.isNotEmpty &&
                        widget.atributo.valores.contains(currentValue))
        ? currentValue
        : null;

    return CustomDropdown<String>(
      value: validValue,
      hintText: 'Seleccionar ${widget.atributo.nombre.toLowerCase()}',
      borderColor: AppColors.blue1,
      items: [
        // Agregar opción vacía solo si el atributo no es requerido
        if (!widget.atributo.requerido)
          const DropdownItem(
            value: '',
            label: '-- Seleccionar --',
          ),
        ...widget.atributo.valores.map((valor) {
          return DropdownItem(
            value: valor,
            label: widget.atributo.unidad != null ? '$valor ${widget.atributo.unidad}' : valor,
          );
        }),
      ],
      onChanged: (value) {
        widget.onChanged(value ?? '');
      },
    );
  }

  Widget _buildMultiSelectInput() {
    // Para multiselect, mostrar checkboxes
    final selectedValues = widget.valorActual?.split(',') ?? [];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.atributo.valores.map((valor) {
        final isSelected = selectedValues.contains(valor);
        return FilterChip(
          label: Text(valor),
          selected: isSelected,
          onSelected: (selected) {
            final newValues = List<String>.from(selectedValues);
            if (selected) {
              newValues.add(valor);
            } else {
              newValues.remove(valor);
            }
            widget.onChanged(newValues.join(','));
          },
        );
      }).toList(),
    );
  }

  Widget _buildNumberInput() {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: 'Ingrese un número',
        border: const OutlineInputBorder(),
        isDense: true,
        suffixText: widget.atributo.unidad,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      onChanged: widget.onChanged,
    );
  }

  Widget _buildTextInput() {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: 'Ingrese ${widget.atributo.nombre.toLowerCase()}',
        border: const OutlineInputBorder(),
        isDense: true,
        suffixText: widget.atributo.unidad,
      ),
      maxLines: widget.atributo.descripcion != null ? 3 : 1,
      onChanged: widget.onChanged,
    );
  }

  Widget _buildBooleanInput() {
    final isTrue = widget.valorActual?.toLowerCase() == 'true';

    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(isTrue ? 'Sí' : 'No'),
      value: isTrue,
      onChanged: (value) {
        widget.onChanged(value.toString());
      },
    );
  }
}
