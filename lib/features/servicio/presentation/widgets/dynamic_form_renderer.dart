import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/barcode_scanner_button.dart';
import '../../../../core/widgets/currency/currency_textfield.dart';
import '../../../../core/widgets/custom_switch_tile.dart';
import '../../../consultas_externas/domain/entities/consulta_dni.dart';
import '../../../consultas_externas/domain/entities/consulta_ruc.dart';
import '../../../consultas_externas/domain/repositories/consultas_repository.dart';
import 'firma_sheet.dart';
import '../../../../core/widgets/date/custom_date.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../widgets/patron_desbloqueo_sheet.dart';
import '../widgets/inspeccion_visual_sheet.dart';
import '../widgets/siluetas/auto_superior_painter.dart' show parseSilueta, siluetaAssets;
import 'dart:convert';
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
  // OPCION_SIMPLES con permiteOtro: texto libre + qué campos están en modo "Otro".
  final Map<String, TextEditingController> _otroControllers = {};
  final Set<String> _otroActivo = {};
  // DOCUMENTO_IDENTIDAD: nombre resuelto por RENIEC/SUNAT (solo visual) y
  // qué campos están consultando ahora mismo.
  final Map<String, String> _docNombres = {};
  final Set<String> _docConsultando = {};
  // FIRMA: campos con una subida al storage en curso.
  final Set<String> _firmaSubiendo = {};
  // TABLA: un controller por celda, con clave "campo##fila##columna".
  final Map<String, TextEditingController> _tablaControllers = {};

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
          tipo == 'TEXTO_AREA' ||
          tipo == 'CODIGO_BARRAS' ||
          tipo == 'PIN_CLAVE' ||
          tipo == 'MONEDA' ||
          tipo == 'DOCUMENTO_IDENTIDAD') {
        final value = widget.values[campo.nombre];
        _controllers[campo.nombre] = TextEditingController(
          text: value is String ? value : value?.toString() ?? '',
        );
      } else if (tipo == 'FECHA') {
        _dateControllers[campo.nombre] = TextEditingController();
      } else if (tipo == 'OPCION_SIMPLES' && campo.permiteOtro) {
        // Si el valor guardado no está entre las opciones, es un "Otro" escrito.
        final opciones = campo.opciones is List
            ? (campo.opciones as List).map((e) => e.toString()).toList()
            : <String>[];
        final value = widget.values[campo.nombre];
        final esOtro = value is String && value.isNotEmpty && !opciones.contains(value);
        _otroControllers[campo.nombre] =
            TextEditingController(text: esOtro ? value : '');
        if (esOtro) _otroActivo.add(campo.nombre);
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
    for (final c in _otroControllers.values) {
      c.dispose();
    }
    _otroControllers.clear();
    _otroActivo.clear();
    for (final c in _tablaControllers.values) {
      c.dispose();
    }
    _tablaControllers.clear();
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
            textCase: _textCase(campo.tipoCampo, campo.nombre),
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
            textCase: _textCase(campo.tipoCampo, campo.nombre),
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
        const otroSentinel = '__OTRO__';
        final permiteOtro = campo.permiteOtro;
        final esOtro = permiteOtro && _otroActivo.contains(campo.nombre);
        // El dropdown muestra "Otro" si está en ese modo; si no, la opción guardada.
        final dropdownValue = esOtro
            ? otroSentinel
            : (value is String && opciones.contains(value) ? value : null);
        // Asegurar controller del texto libre (por si el campo se volvió permiteOtro).
        if (permiteOtro) {
          _otroControllers.putIfAbsent(
              campo.nombre, () => TextEditingController());
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomDropdown<String>(
                label: '${campo.nombre}${campo.esRequerido ? " *" : ""}',
                value: dropdownValue,
                borderColor: AppColors.blue1,
                items: [
                  ...opciones.map((o) => DropdownItem(value: o, label: o)),
                  if (permiteOtro)
                    const DropdownItem(
                      value: otroSentinel,
                      label: 'Otro (especificar)',
                      leading: Icon(Icons.edit_note, size: 16, color: AppColors.blue1),
                    ),
                ],
                onChanged: (v) {
                  if (v == otroSentinel) {
                    setState(() => _otroActivo.add(campo.nombre));
                    // Persistir el texto actual (puede estar vacío hasta que escriba).
                    _updateValue(
                        campo.nombre, _otroControllers[campo.nombre]?.text ?? '');
                  } else {
                    setState(() => _otroActivo.remove(campo.nombre));
                    _updateValue(campo.nombre, v);
                  }
                },
              ),
              if (esOtro) ...[
                const SizedBox(height: 8),
                CustomText(
                  controller: _otroControllers[campo.nombre],
                  label: 'Especificar ${campo.nombre.toLowerCase()}',
                  textCase: TextCase.upper,
                  hintText: 'Escribe el detalle...',
                  borderColor: AppColors.blue1,
                  prefixIcon: const Icon(Icons.edit_outlined, size: 18),
                  validator: campo.esRequerido
                      ? (v) =>
                          v == null || v.trim().isEmpty ? 'Campo requerido' : null
                      : null,
                  onChanged: (v) => _updateValue(campo.nombre, v),
                ),
              ],
            ],
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
                      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}');
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

      case 'CODIGO_BARRAS':
        {
          // Un lector físico (pistola/anillo) se comporta como teclado, así
          // que el campo tiene que seguir siendo escribible: la cámara es
          // solo una vía más, no la única. Sirve para IMEI, series, SKUs.
          final ctrl = _controllers[campo.nombre] ??= TextEditingController(
            text: widget.values[campo.nombre]?.toString() ?? '',
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CustomText(
              controller: ctrl,
              label: '${campo.nombre}${campo.esRequerido ? " *" : ""}',
              hintText: 'Escanea o escribe el código',
              textCase: _textCase('CODIGO_BARRAS', campo.nombre),
              borderColor: AppColors.blue1,
              prefixIcon: const Icon(Icons.barcode_reader),
              suffixIcon: BarcodeScannerButton(
                onScanned: (code) {
                  ctrl.text = code;
                  _updateValue(campo.nombre, code);
                },
              ),
              onChanged: (v) => _updateValue(campo.nombre, v),
            ),
          );
        }

      case 'PIN_CLAVE':
        {
          // Obscurecido con el ojo de CustomText: quien firma la recepción
          // suele estar al lado, y la clave no debe quedar a la vista. NUNCA
          // en mayúsculas ni recortado: un PIN puede empezar en 0.
          final ctrl = _controllers[campo.nombre] ??= TextEditingController(
            text: widget.values[campo.nombre]?.toString() ?? '',
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CustomText(
              controller: ctrl,
              label: '${campo.nombre}${campo.esRequerido ? " *" : ""}',
              hintText: 'PIN o contraseña del equipo',
              obscureText: true,
              textCase: TextCase.normal,
              borderColor: AppColors.blue1,
              prefixIcon: const Icon(Icons.lock_outline),
              onChanged: (v) => _updateValue(campo.nombre, v),
            ),
          );
        }

      case 'MONEDA':
        {
          final ctrl = _controllers[campo.nombre] ??= TextEditingController(
            text: widget.values[campo.nombre]?.toString() ?? '',
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CurrencyTextField(
              controller: ctrl,
              label: '${campo.nombre}${campo.esRequerido ? " *" : ""}',
              hintText: '0.00',
              borderColor: AppColors.blue1,
              // Se guarda el NÚMERO, no el texto formateado: el backend
              // valida que sea numérico y los reportes lo suman.
              onChanged: (v) => _updateValue(campo.nombre, v),
            ),
          );
        }

      case 'TABLA':
        return _buildTablaField(campo);

      case 'DOCUMENTO_IDENTIDAD':
        return _buildDocumentoField(campo);

      case 'FIRMA':
        return _buildFirmaField(campo);

      case 'PATRON_DESBLOQUEO':
        return _buildPatronField(campo);

      case 'INSPECCION_VISUAL':
        return _buildInspeccionField(campo);

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
            textCase: _textCase(campo.tipoCampo, campo.nombre),
            borderColor: AppColors.blue1,
            onChanged: (v) => _updateValue(campo.nombre, v),
          ),
        );
    }
  }

  // ── TABLA ──────────────────────────────────────────────────────────────
  // Columnas en `campo.opciones` (misma forma que los sub-campos de OBJETO);
  // el valor es una lista de filas {columna: valor}. La grilla scrollea en
  // horizontal: en un celular no entran 4 columnas de ancho útil.

  static const double _anchoCelda = 128;
  static const double _anchoCeldaChica = 74; // NUMERO, MONEDA, CHECKBOX

  double _anchoDeColumna(String tipo) =>
      (tipo == 'NUMERO' || tipo == 'MONEDA' || tipo == 'CHECKBOX')
          ? _anchoCeldaChica
          : _anchoCelda;

  Widget _buildTablaField(ConfiguracionCampo campo) {
    final columnas = campo.opciones is List
        ? (campo.opciones as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((e) => (e['nombre'] as String?)?.isNotEmpty == true)
            .toList()
        : <Map<String, dynamic>>[];

    if (columnas.isEmpty) return const SizedBox.shrink();

    final filas = widget.values[campo.nombre] is List
        ? (widget.values[campo.nombre] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    void guardar() =>
        _updateValue(campo.nombre, filas.map(Map<String, dynamic>.from).toList());

    // Totales por columna de monto: es la razón principal para tener tabla
    // en vez de un texto libre.
    final totales = <String, double>{};
    for (final col in columnas.where((c) => c['tipo'] == 'MONEDA')) {
      final nombre = col['nombre'] as String;
      totales[nombre] = filas.fold<double>(
        0,
        (acc, f) => acc + (double.tryParse('${f[nombre] ?? ''}') ?? 0),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.table_chart_outlined,
                  size: 16, color: AppColors.blue1),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${campo.nombre}${campo.esRequerido ? " *" : ""}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue1),
                ),
              ),
              Text(
                '${filas.length} ${filas.length == 1 ? "fila" : "filas"}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: AppColors.blue1.withValues(alpha: 0.2)),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezados
                  Container(
                    color: AppColors.blue1.withValues(alpha: 0.06),
                    child: Row(
                      children: [
                        for (final col in columnas)
                          SizedBox(
                            width: _anchoDeColumna(col['tipo'] as String? ?? 'TEXTO'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 7),
                              child: Text(
                                col['nombre'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.blue1,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 34),
                      ],
                    ),
                  ),
                  if (filas.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                      child: Text(
                        'Sin filas todavía',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ),
                  ...filas.asMap().entries.map((entry) {
                    final i = entry.key;
                    final fila = entry.value;
                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          for (final col in columnas)
                            SizedBox(
                              width: _anchoDeColumna(
                                  col['tipo'] as String? ?? 'TEXTO'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 4),
                                child: _buildCelda(
                                  campo: campo,
                                  columna: col,
                                  fila: fila,
                                  indiceFila: i,
                                  onCambio: guardar,
                                ),
                              ),
                            ),
                          SizedBox(
                            width: 34,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 34, minHeight: 34),
                              tooltip: 'Quitar fila',
                              icon: Icon(Icons.close,
                                  size: 15, color: Colors.red.shade300),
                              onPressed: () {
                                // Los controllers se indexan por fila; al
                                // borrar una, los de abajo se corren.
                                _limpiarControllersTabla(campo.nombre);
                                setState(() => filas.removeAt(i));
                                guardar();
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() => filas.add(<String, dynamic>{}));
                  guardar();
                },
                icon: const Icon(Icons.add, size: 15),
                label: const Text('Agregar fila',
                    style: TextStyle(fontSize: 11.5)),
              ),
              const Spacer(),
              if (totales.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: totales.entries
                        .map((t) => Text(
                              'Total ${t.key}: S/ ${t.value.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.blue1,
                              ),
                            ))
                        .toList(),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Una celda. Los tipos altos (firma, patrón, archivo) no llegan aquí:
  /// el editor de columnas solo ofrece los seis que caben en una fila.
  Widget _buildCelda({
    required ConfiguracionCampo campo,
    required Map<String, dynamic> columna,
    required Map<String, dynamic> fila,
    required int indiceFila,
    required VoidCallback onCambio,
  }) {
    final nombreCol = columna['nombre'] as String;
    final tipo = columna['tipo'] as String? ?? 'TEXTO';
    final key = '${campo.nombre}##$indiceFila##$nombreCol';

    if (tipo == 'CHECKBOX') {
      return Checkbox(
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        value: fila[nombreCol] == true,
        onChanged: (v) {
          setState(() => fila[nombreCol] = v ?? false);
          onCambio();
        },
      );
    }

    if (tipo == 'OPCION_SIMPLES') {
      final opciones = columna['opciones'] is List
          ? (columna['opciones'] as List).map((e) => e.toString()).toList()
          : <String>[];
      final valor = fila[nombreCol];
      return DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isDense: true,
          isExpanded: true,
          value: valor is String && opciones.contains(valor) ? valor : null,
          hint: const Text('—', style: TextStyle(fontSize: 11)),
          style: const TextStyle(fontSize: 11, color: Colors.black87),
          items: opciones
              .map((o) => DropdownMenuItem(
                    value: o,
                    child: Text(o,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) {
            setState(() => fila[nombreCol] = v);
            onCambio();
          },
        ),
      );
    }

    final ctrl = _tablaControllers[key] ??= TextEditingController(
      text: fila[nombreCol]?.toString() ?? '',
    );

    return TextField(
      controller: ctrl,
      style: const TextStyle(fontSize: 11.5),
      textAlign: (tipo == 'NUMERO' || tipo == 'MONEDA')
          ? TextAlign.right
          : TextAlign.start,
      keyboardType: (tipo == 'NUMERO' || tipo == 'MONEDA')
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        border: InputBorder.none,
        hintText: tipo == 'MONEDA' ? '0.00' : null,
        hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
        // El escáner vive DENTRO de la celda: es lo que hace útil una
        // columna de IMEI o serie.
        suffixIcon: tipo == 'CODIGO_BARRAS'
            ? BarcodeScannerButton(
                iconSize: 14,
                onScanned: (code) {
                  ctrl.text = code;
                  setState(() => fila[nombreCol] = code);
                  onCambio();
                },
              )
            : null,
        suffixIconConstraints:
            const BoxConstraints(minWidth: 22, minHeight: 22),
      ),
      onChanged: (v) {
        // NUMERO y MONEDA se guardan como número para poder sumarlos.
        fila[nombreCol] = (tipo == 'NUMERO' || tipo == 'MONEDA')
            ? (num.tryParse(v) ?? v)
            : v;
        onCambio();
        if (tipo == 'MONEDA') setState(() {}); // refresca el total
      },
    );
  }

  void _limpiarControllersTabla(String nombreCampo) {
    final prefijo = '$nombreCampo##';
    for (final k in _tablaControllers.keys.toList()) {
      if (k.startsWith(prefijo)) {
        _tablaControllers.remove(k)?.dispose();
      }
    }
  }

  /// DNI (8) / CE (9) / RUC (11) con botón que resuelve el nombre contra
  /// RENIEC o SUNAT. Se guarda SOLO el número: el nombre es ayuda visual
  /// para confirmar que no hubo tipeo, no un dato que debamos congelar.
  Widget _buildDocumentoField(ConfiguracionCampo campo) {
    final ctrl = _controllers[campo.nombre] ??= TextEditingController(
      text: widget.values[campo.nombre]?.toString() ?? '',
    );
    final consultando = _docConsultando.contains(campo.nombre);
    final resuelto = _docNombres[campo.nombre];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            controller: ctrl,
            label: '${campo.nombre}${campo.esRequerido ? " *" : ""}',
            hintText: 'DNI (8), CE (9) o RUC (11)',
            textCase: TextCase.normal,
            keyboardType: TextInputType.number,
            borderColor: AppColors.blue1,
            prefixIcon: const Icon(Icons.badge_outlined),
            suffixIcon: consultando
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : GestureDetector(
                    onTap: () => _consultarDocumento(campo.nombre, ctrl.text),
                    child: const Icon(Icons.search, color: AppColors.blue1),
                  ),
            onChanged: (v) {
              _updateValue(campo.nombre, v);
              // El nombre resuelto deja de valer si cambia el número.
              if (_docNombres.remove(campo.nombre) != null) setState(() {});
            },
          ),
          if (resuelto != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      size: 12, color: Colors.green),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      resuelto,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _consultarDocumento(String nombreCampo, String doc) async {
    final numero = doc.trim();
    if (![8, 9, 11].contains(numero.length)) {
      _snack('Ingresa un DNI (8), CE (9) o RUC (11 dígitos)');
      return;
    }
    setState(() => _docConsultando.add(nombreCampo));
    final repo = locator<ConsultasRepository>();
    final result = numero.length == 11
        ? await repo.consultarRuc(numero)
        : numero.length == 9
            ? await repo.consultarCee(numero)
            : await repo.consultarDni(numero);
    if (!mounted) return;
    setState(() {
      _docConsultando.remove(nombreCampo);
      if (result is Success) {
        final data = (result as Success).data;
        // ConsultaDni y ConsultaRuc exponen nombres distintos.
        _docNombres[nombreCampo] = data is ConsultaRuc
            ? data.razonSocial
            : (data as ConsultaDni).nombreCompleto;
      }
    });
    if (result is Error) _snack((result as Error).message);
  }

  /// La firma se sube al storage y en la orden queda solo su URL: meter el
  /// PNG en `datosPersonalizados` inflaría el JSON de cada orden.
  Widget _buildFirmaField(ConfiguracionCampo campo) {
    final url = widget.values[campo.nombre];
    final tieneFirma = url is String && url.isNotEmpty;
    final subiendo = _firmaSubiendo.contains(campo.nombre);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.draw_outlined, size: 16, color: AppColors.blue1),
              const SizedBox(width: 6),
              Text(
                '${campo.nombre}${campo.esRequerido ? " *" : ""}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blue1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: subiendo ? null : () => _capturarFirma(campo),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              height: tieneFirma ? 110 : 64,
              decoration: BoxDecoration(
                color: tieneFirma ? Colors.white : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: tieneFirma
                      ? AppColors.blue1.withValues(alpha: 0.3)
                      : Colors.grey.shade300,
                ),
              ),
              child: subiendo
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : tieneFirma
                      ? Padding(
                          padding: const EdgeInsets.all(6),
                          child: Image.network(
                            url,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Text('Firma guardada',
                                  style: TextStyle(fontSize: 11)),
                            ),
                          ),
                        )
                      : Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.gesture,
                                  size: 16, color: Colors.grey.shade500),
                              const SizedBox(width: 6),
                              Text(
                                'Toca para firmar',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
            ),
          ),
          if (tieneFirma)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: subiendo ? null : () => _capturarFirma(campo),
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Volver a firmar',
                    style: TextStyle(fontSize: 11)),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _capturarFirma(ConfiguracionCampo campo) async {
    final bytes = await FirmaSheet.show(context, titulo: campo.nombre);
    if (bytes == null || !mounted) return;

    setState(() => _firmaSubiendo.add(campo.nombre));
    try {
      // Archivo temporal: uploadFile trabaja con File, no con bytes.
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/firma_${campo.nombre.hashCode}_'
        '${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);

      final res = await locator<StorageService>().uploadFile(
        file: file,
        empresaId: widget.empresaId,
        categoria: 'firma-servicio',
      );
      if (!mounted) return;
      _updateValue(campo.nombre, res.url);
    } catch (e) {
      if (mounted) _snack('No se pudo guardar la firma: $e');
    } finally {
      if (mounted) setState(() => _firmaSubiendo.remove(campo.nombre));
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildPatronField(ConfiguracionCampo campo) {
    final value = widget.values[campo.nombre];
    final patronStr = value is String ? value : '';
    final hasPatron = patronStr.isNotEmpty;
    final patronNodos = hasPatron
        ? patronStr.split('-').map((s) => int.tryParse(s)).where((n) => n != null).cast<int>().toList()
        : <int>[];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pattern, size: 16, color: AppColors.blue1),
              const SizedBox(width: 6),
              Text(
                '${campo.nombre}${campo.esRequerido ? " *" : ""}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.blue1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final result = await PatronDesbloqueoSheet.show(
                context,
                initialValue: patronStr.isEmpty ? null : patronStr,
              );
              if (result != null) {
                _updateValue(campo.nombre, result);
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasPatron ? AppColors.blue1.withValues(alpha: 0.05) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasPatron ? AppColors.blue1.withValues(alpha: 0.3) : Colors.grey.shade300,
                ),
              ),
              child: hasPatron
                  ? Row(
                      children: [
                        // Mini preview del patrón
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: CustomPaint(
                            painter: _MiniPatronPainter(patron: patronNodos, color: AppColors.blue1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Patron registrado',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.blue1),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Secuencia: ${patronNodos.map((n) => n + 1).join(" → ")}',
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.edit_outlined, size: 16, color: AppColors.blue1.withValues(alpha: 0.6)),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app_outlined, size: 16, color: Colors.grey.shade400),
                        const SizedBox(width: 8),
                        Text(
                          'Toque para capturar patron',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspeccionField(ConfiguracionCampo campo) {
    final value = widget.values[campo.nombre];
    final jsonStr = value is String ? value : '';
    final hasData = jsonStr.isNotEmpty;

    int puntosCount = 0;
    String? silueta;
    List<Map<String, dynamic>> puntos = [];
    if (hasData) {
      try {
        final data = jsonDecode(jsonStr);
        if (data is Map) {
          silueta = data['silueta'] as String?;
          if (data['puntos'] is List) {
            puntos = (data['puntos'] as List)
                .map((p) => Map<String, dynamic>.from(p as Map))
                .toList();
            puntosCount = puntos.length;
          }
        }
      } catch (_) {}
    }

    // Obtener silueta configurada en opciones del campo
    final configSilueta = campo.opciones is List && (campo.opciones as List).isNotEmpty
        ? (campo.opciones as List).first.toString()
        : silueta;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.car_crash_outlined, size: 16, color: AppColors.blue1),
              const SizedBox(width: 6),
              Text(
                '${campo.nombre}${campo.esRequerido ? " *" : ""}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.blue1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final result = await InspeccionVisualSheet.show(
                context,
                initialValue: jsonStr.isEmpty ? null : jsonStr,
                silueta: configSilueta,
              );
              if (result != null) {
                _updateValue(campo.nombre, result);
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasData ? AppColors.blue1.withValues(alpha: 0.05) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasData ? AppColors.blue1.withValues(alpha: 0.3) : Colors.grey.shade300,
                ),
              ),
              child: hasData
                  ? Row(
                      children: [
                        // Mini preview
                        SizedBox(
                          width: 50,
                          height: 70,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.asset(
                                  siluetaAssets[parseSilueta(configSilueta)]!,
                                  fit: BoxFit.contain,
                                  opacity: const AlwaysStoppedAnimation(0.3),
                                ),
                              ),
                              CustomPaint(
                                painter: _MiniInspeccionPuntosPainter(puntos: puntos),
                                size: const Size(50, 70),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Inspeccion registrada',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.blue1),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$puntosCount punto${puntosCount != 1 ? 's' : ''} marcado${puntosCount != 1 ? 's' : ''}',
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.edit_outlined, size: 16, color: AppColors.blue1.withValues(alpha: 0.6)),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app_outlined, size: 16, color: Colors.grey.shade400),
                        const SizedBox(width: 8),
                        Text(
                          'Toque para iniciar inspeccion',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
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

              // TEXTO, NUMERO o CODIGO_BARRAS
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
                  textCase: _textCase(subTipo, subNombre),
                  label: subNombre,
                  borderColor: AppColors.blue1,
                  keyboardType: subTipo == 'NUMERO'
                      ? TextInputType.number
                      : TextInputType.text,
                  prefixIcon: Icon(
                    subTipo == 'NUMERO'
                        ? Icons.numbers_outlined
                        : subTipo == 'CODIGO_BARRAS'
                            ? Icons.barcode_reader
                            : Icons.text_fields_outlined,
                    size: 18,
                  ),
                  suffixIcon: subTipo == 'CODIGO_BARRAS'
                      ? BarcodeScannerButton(
                          onScanned: (code) {
                            _controllers[subKey]?.text = code;
                            currentObj[subNombre] = code;
                            _updateValue(
                                campo.nombre, Map<String, dynamic>.from(currentObj));
                          },
                        )
                      : null,
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

  /// MAYÚSCULAS por defecto, salvo correos/URLs/números, códigos escaneados
  /// y campos sensibles (contraseñas/clave/PIN), donde alterar mayúsculas
  /// rompería el valor. Un código de barras se guarda TAL CUAL lo entregó el
  /// lector: Code 128 y QR distinguen mayúsculas de minúsculas.
  TextCase _textCase(String tipoCampo, String nombre) {
    if (tipoCampo == 'EMAIL' ||
        tipoCampo == 'URL' ||
        tipoCampo == 'NUMERO' ||
        tipoCampo == 'CODIGO_BARRAS') {
      return TextCase.normal;
    }
    final n = nombre.toLowerCase();
    const sensibles = ['contraseña', 'contrasena', 'clave', 'password', 'pin'];
    if (sensibles.any(n.contains)) return TextCase.normal;
    return TextCase.upper;
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

class _MiniInspeccionPuntosPainter extends CustomPainter {
  final List<Map<String, dynamic>> puntos;

  _MiniInspeccionPuntosPainter({required this.puntos});

  static const _colores = {
    'RAYON': Colors.orange,
    'ABOLLADURA': Colors.red,
    'ROTURA': Colors.purple,
    'OXIDO': Colors.brown,
    'FALTANTE': Colors.grey,
    'OTRO': Colors.blue,
  };

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in puntos) {
      final x = (p['x'] as num).toDouble() * size.width;
      final y = (p['y'] as num).toDouble() * size.height;
      final tipo = p['tipo'] as String? ?? 'OTRO';
      final color = _colores[tipo] ?? Colors.blue;

      canvas.drawCircle(Offset(x, y), 4, Paint()..color = color.withValues(alpha: 0.8));
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = Colors.white..strokeWidth = 1..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniInspeccionPuntosPainter oldDelegate) => true;
}

class _MiniPatronPainter extends CustomPainter {
  final List<int> patron;
  final Color color;

  _MiniPatronPainter({required this.patron, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final spacing = size.width / 3;

    Offset center(int index) {
      final row = index ~/ 3;
      final col = index % 3;
      return Offset(spacing * col + spacing / 2, spacing * row + spacing / 2);
    }

    // Lines
    if (patron.length >= 2) {
      final paint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < patron.length - 1; i++) {
        canvas.drawLine(center(patron[i]), center(patron[i + 1]), paint);
      }
    }

    // Nodes
    for (int i = 0; i < 9; i++) {
      final c = center(i);
      final selected = patron.contains(i);
      if (selected) {
        canvas.drawCircle(c, 5, Paint()..color = color.withValues(alpha: 0.2));
        canvas.drawCircle(c, 5, Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke);
      } else {
        canvas.drawCircle(c, 2, Paint()..color = Colors.grey.shade400);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniPatronPainter oldDelegate) =>
      oldDelegate.patron != patron;
}
