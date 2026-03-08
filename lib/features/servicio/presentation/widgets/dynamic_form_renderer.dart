import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/custom_switch_tile.dart';
import '../../../../core/widgets/date/custom_date.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../domain/entities/configuracion_campo.dart';

class DynamicFormRenderer extends StatefulWidget {
  final List<ConfiguracionCampo> campos;
  final Map<String, dynamic> values;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final String empresaId;

  const DynamicFormRenderer({
    super.key,
    required this.campos,
    required this.values,
    required this.onChanged,
    required this.empresaId,
  });

  @override
  State<DynamicFormRenderer> createState() => _DynamicFormRendererState();
}

class _DynamicFormRendererState extends State<DynamicFormRenderer> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, TextEditingController> _dateControllers = {};

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant DynamicFormRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.campos != widget.campos) {
      _disposeControllers();
      _initControllers();
    }
  }

  void _initControllers() {
    for (final campo in widget.campos) {
      final tipo = campo.tipoCampo;
      if (tipo == 'TEXTO' ||
          tipo == 'EMAIL' ||
          tipo == 'TELEFONO' ||
          tipo == 'URL' ||
          tipo == 'NUMERO' ||
          tipo == 'TEXTO_AREA') {
        final value = widget.values[campo.nombre];
        _controllers[campo.nombre] = TextEditingController(
          text: value is String ? value : value?.toString() ?? '',
        );
      } else if (tipo == 'FECHA') {
        _dateControllers[campo.nombre] = TextEditingController();
      }
    }
  }

  void _disposeControllers() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    for (final c in _dateControllers.values) {
      c.dispose();
    }
    _dateControllers.clear();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _updateValue(String nombre, dynamic value) {
    final newValues = Map<String, dynamic>.from(widget.values);
    newValues[nombre] = value;
    widget.onChanged(newValues);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          widget.campos.map((campo) => _buildField(context, campo)).toList(),
    );
  }

  Widget _buildField(BuildContext context, ConfiguracionCampo campo) {
    switch (campo.tipoCampo) {
      case 'TEXTO':
      case 'EMAIL':
      case 'TELEFONO':
      case 'URL':
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CustomText(
            controller: _controllers[campo.nombre],
            label: '${campo.nombre}${campo.esRequerido ? " *" : ""}',
            hintText: campo.placeholder,
            borderColor: AppColors.blue1,
            keyboardType: _keyboardType(campo.tipoCampo),
            prefixIcon: Icon(_iconForType(campo.tipoCampo)),
            validator: campo.esRequerido
                ? (v) => v == null || v.isEmpty ? 'Campo requerido' : null
                : null,
            onChanged: (v) => _updateValue(campo.nombre, v),
          ),
        );

      case 'NUMERO':
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CustomText(
            controller: _controllers[campo.nombre],
            label: '${campo.nombre}${campo.esRequerido ? " *" : ""}',
            hintText: campo.placeholder,
            borderColor: AppColors.blue1,
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.numbers_outlined),
            onChanged: (v) => _updateValue(campo.nombre, num.tryParse(v)),
          ),
        );

      case 'TEXTO_AREA':
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CustomText(
            controller: _controllers[campo.nombre],
            label: '${campo.nombre}${campo.esRequerido ? " *" : ""}',
            hintText: campo.placeholder,
            borderColor: AppColors.blue1,
            prefixIcon: const Icon(Icons.notes_outlined),
            maxLines: null,
            minLines: 3,
            onChanged: (v) => _updateValue(campo.nombre, v),
          ),
        );

      case 'CHECKBOX':
        final value = widget.values[campo.nombre];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CustomSwitchTile(
            title: campo.nombre,
            subtitle: campo.descripcion,
            value: value is bool ? value : false,
            onChanged: (v) => _updateValue(campo.nombre, v),
          ),
        );

      case 'OPCION_SIMPLES':
        final opciones = campo.opciones is List
            ? (campo.opciones as List).map((e) => e.toString()).toList()
            : <String>[];
        final value = widget.values[campo.nombre];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CustomDropdown<String>(
            label: '${campo.nombre}${campo.esRequerido ? " *" : ""}',
            value: value is String ? value : null,
            borderColor: AppColors.blue1,
            items: opciones
                .map((o) => DropdownItem(value: o, label: o))
                .toList(),
            onChanged: (v) => _updateValue(campo.nombre, v),
          ),
        );

      case 'FECHA':
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CustomDate(
            label: '${campo.nombre}${campo.esRequerido ? " *" : ""}',
            controller: _dateControllers[campo.nombre] ?? TextEditingController(),
            borderColor: AppColors.blue1,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            onChanged: (value) {
              if (value.isNotEmpty) {
                final parts = value.split('/');
                if (parts.length == 3) {
                  final day = int.tryParse(parts[0]) ?? 1;
                  final month = int.tryParse(parts[1]) ?? 1;
                  final year = int.tryParse(parts[2]) ?? 2026;
                  _updateValue(campo.nombre,
                      '${year}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}');
                }
              } else {
                _updateValue(campo.nombre, null);
              }
            },
          ),
        );

      case 'ARCHIVO':
        final value = widget.values[campo.nombre];
        final isEnabled = value is bool ? value : false;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CustomSwitchTile(
            title: campo.nombre,
            subtitle: isEnabled
                ? 'Se habilitara la seccion de imagenes en el detalle'
                : 'Habilitar para adjuntar archivos desde el detalle',
            value: isEnabled,
            activeColor: Colors.green,
            onChanged: (v) => _updateValue(campo.nombre, v),
          ),
        );

      case 'OBJETO':
        return _buildObjetoField(campo);

      case 'OPCION_MULTIPLE':
      case 'CHECKBOX_MULTIPLE':
        final opciones = campo.opciones is List
            ? (campo.opciones as List).cast<String>()
            : <String>[];
        final selected = widget.values[campo.nombre] is List
            ? (widget.values[campo.nombre] as List).cast<String>()
            : <String>[];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CustomDropdown<String>(
            label: '${campo.nombre}${campo.esRequerido ? " *" : ""}',
            borderColor: AppColors.blue1,
            dropdownStyle: DropdownStyle.multiSelect,
            selectedValues: selected,
            items: opciones
                .map((o) => DropdownItem(value: o, label: o))
                .toList(),
            onMultiChanged: (v) => _updateValue(campo.nombre, v),
          ),
        );

      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CustomText(
            controller: _controllers[campo.nombre] ??
                TextEditingController(
                    text: widget.values[campo.nombre]?.toString() ?? ''),
            label: campo.nombre,
            borderColor: AppColors.blue1,
            onChanged: (v) => _updateValue(campo.nombre, v),
          ),
        );
    }
  }

  Widget _buildObjetoField(ConfiguracionCampo campo) {
    final subCampos = campo.opciones is List
        ? (campo.opciones as List)
            .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
            .where((e) => e['nombre'] != null)
            .toList()
        : <Map<String, dynamic>>[];

    if (subCampos.isEmpty) return const SizedBox.shrink();

    // Get current object value
    final currentObj = widget.values[campo.nombre] is Map
        ? Map<String, dynamic>.from(widget.values[campo.nombre] as Map)
        : <String, dynamic>{};

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.blue1.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_tree_outlined, size: 16, color: AppColors.blue1),
                const SizedBox(width: 8),
                Text(
                  '${campo.nombre}${campo.esRequerido ? " *" : ""}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...subCampos.map((sub) {
              final subNombre = sub['nombre'] as String? ?? '';
              final subTipo = sub['tipo'] as String? ?? 'TEXTO';
              final subKey = '${campo.nombre}__$subNombre';

              if (subTipo == 'CHECKBOX') {
                final val = currentObj[subNombre] is bool
                    ? currentObj[subNombre] as bool
                    : false;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CustomSwitchTile(
                    title: subNombre,
                    value: val,
                    onChanged: (v) {
                      currentObj[subNombre] = v;
                      _updateValue(campo.nombre, Map<String, dynamic>.from(currentObj));
                    },
                  ),
                );
              }

              // OPCION_SIMPLES → dropdown
              if (subTipo == 'OPCION_SIMPLES') {
                final subOpciones = sub['opciones'] is List
                    ? (sub['opciones'] as List).map((e) => e.toString()).toList()
                    : <String>[];
                final val = currentObj[subNombre];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CustomDropdown<String>(
                    label: subNombre,
                    value: val is String ? val : null,
                    borderColor: AppColors.blue1,
                    items: subOpciones
                        .map((o) => DropdownItem(value: o, label: o))
                        .toList(),
                    onChanged: (v) {
                      currentObj[subNombre] = v;
                      _updateValue(campo.nombre, Map<String, dynamic>.from(currentObj));
                    },
                  ),
                );
              }

              // TEXTO or NUMERO
              if (!_controllers.containsKey(subKey)) {
                final subVal = currentObj[subNombre];
                _controllers[subKey] = TextEditingController(
                  text: subVal is String ? subVal : subVal?.toString() ?? '',
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CustomText(
                  controller: _controllers[subKey],
                  label: subNombre,
                  borderColor: AppColors.blue1,
                  keyboardType: subTipo == 'NUMERO'
                      ? TextInputType.number
                      : TextInputType.text,
                  prefixIcon: Icon(
                    subTipo == 'NUMERO'
                        ? Icons.numbers_outlined
                        : Icons.text_fields_outlined,
                    size: 18,
                  ),
                  onChanged: (v) {
                    currentObj[subNombre] =
                        subTipo == 'NUMERO' ? (num.tryParse(v) ?? v) : v;
                    _updateValue(campo.nombre, Map<String, dynamic>.from(currentObj));
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  TextInputType _keyboardType(String tipoCampo) {
    switch (tipoCampo) {
      case 'EMAIL':
        return TextInputType.emailAddress;
      case 'TELEFONO':
        return TextInputType.phone;
      case 'URL':
        return TextInputType.url;
      default:
        return TextInputType.text;
    }
  }

  IconData _iconForType(String tipoCampo) {
    switch (tipoCampo) {
      case 'EMAIL':
        return Icons.email_outlined;
      case 'TELEFONO':
        return Icons.phone_outlined;
      case 'URL':
        return Icons.link_outlined;
      default:
        return Icons.text_fields_outlined;
    }
  }
}
