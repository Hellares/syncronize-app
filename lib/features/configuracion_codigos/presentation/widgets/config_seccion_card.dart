import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_switch_tile.dart';
import 'package:syncronize/core/widgets/compact_numeric_selector.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import 'package:syncronize/features/auth/presentation/widgets/widgets.dart';
import '../../domain/entities/configuracion_codigos.dart';

/// Card para configurar una sección (Productos, Variantes o Servicios)
class ConfigSeccionCard extends StatefulWidget {
  final String titulo;
  final String descripcion;
  final ConfigSeccion seccion;
  final RestriccionesCodigo restriccion;
  final String tipo; // 'producto', 'variante', 'servicio'
  final Function(String? codigo, String? separador, int? longitud, bool? incluirSede)
      onUpdate;
  final VoidCallback onPreview;
  final bool isLoading;

  const ConfigSeccionCard({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.seccion,
    required this.restriccion,
    required this.tipo,
    required this.onUpdate,
    required this.onPreview,
    this.isLoading = false,
  });

  @override
  State<ConfigSeccionCard> createState() => _ConfigSeccionCardState();
}

class _ConfigSeccionCardState extends State<ConfigSeccionCard> {
  late TextEditingController _codigoController;
  late String _separador;
  late int _longitud;
  bool _incluirSede = false;

  // Opciones de separador predefinidas (siempre debe haber separador)
  final List<DropdownItem<String>> _separadorOptions = [
    DropdownItem(value: '-', label: '- (Guión)'),
    DropdownItem(value: '_', label: '_ (Guión bajo)'),
  ];

  @override
  void initState() {
    super.initState();
    _codigoController = TextEditingController(text: widget.seccion.codigo);
    _separador = widget.seccion.separador;
    _longitud = widget.seccion.longitud;
    _incluirSede = widget.seccion.incluirSede ?? false;
  }

  @override
  void didUpdateWidget(ConfigSeccionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seccion != widget.seccion) {
      _codigoController.text = widget.seccion.codigo;
      _separador = widget.seccion.separador;
      _longitud = widget.seccion.longitud;
      _incluirSede = widget.seccion.incluirSede ?? false;
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  bool get _puedeModificar {
    if (widget.tipo == 'producto') {
      return widget.restriccion.puedeModificarProductoCodigo;
    } else if (widget.tipo == 'variante') {
      return widget.restriccion.puedeModificarVarianteCodigo;
    } else if (widget.tipo == 'servicio') {
      return widget.restriccion.puedeModificarServicioCodigo;
    }
    return false;
  }

  String? get _razon {
    if (widget.tipo == 'producto') {
      return widget.restriccion.razonProducto;
    } else if (widget.tipo == 'variante') {
      return widget.restriccion.razonVariante;
    } else if (widget.tipo == 'servicio') {
      return widget.restriccion.razonServicio;
    }
    return null;
  }

  /// Verifica si ya existen registros (productos, variantes, servicios, ventas)
  /// Si existen registros, no se puede modificar el formato (separador, longitud)
  bool get _tieneRegistros => widget.seccion.ultimoContador > 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Descripción
          GradientContainer(
            // color: Colors.blue.shade50,
            gradient: AppGradients.blueWhiteBlue(),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.descripcion,
                      style: TextStyle(color: Colors.blue.shade900, fontSize: 12),
                      
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Información actual
          AppSubtitle('Configuración actual', fontSize: 12,),
          const SizedBox(height: 12),

          _buildInfoRow('Último contador', widget.seccion.ultimoContador.toString()),
          _buildInfoRow('Próximo código', widget.seccion.proximoCodigo),

          const SizedBox(height: 20),

          // Formulario de edición
          AppSubtitle('Formato de código', fontSize: 12,),
          const SizedBox(height: 8),

          // Restricción (si existe)
          // if (!_puedeModificar && _razon != null)
          //   InfoChip(
          //     icon: Icons.lock,
          //     text: _razon!,
          //     height: 40,
          //     width: double.infinity,
          //     borderRadius: 8,
          //     backgroundColor: AppColors.amberShadow,
          //     textColor: AppColors.amberText,
          //   ),
          //   SizedBox(height: 15,),

          // Advertencia si ya existen registros
          if (_tieneRegistros && !_puedeModificar && _razon != null)
            GradientContainer(
            gradient: AppGradients.orangeOrange(),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                   Row(
                    children: [
                      Icon(Icons.lock, color: AppColors.amberText, size: 16,),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppSubtitle(_razon!,fontSize: 10, color: AppColors.amberText, font: AppFont.oxygenRegular,),
                      ),
                    ],
                  ),
                  SizedBox(height: 5,),
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: AppColors.amberText, size: 16,),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppSubtitle('Ya existen ${widget.seccion.ultimoContador} registro(s). El formato (separador y longitud) no puede modificarse.',fontSize: 10, color: AppColors.amberText,font: AppFont.oxygenRegular,),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

            SizedBox(height: 15,),

          CustomText(
            controller: _codigoController,
            borderColor: AppColors.blue1,
            label: 'Prefijo',
            enabled: _puedeModificar && !widget.isLoading,
            hintText: 'PROD, VAR, SERV, etc',
            prefixIcon: Icon(Icons.code),
            textCase: TextCase.upper,
            maxLength: 4,
          ),

          const SizedBox(height: 16),

          // Campo Separador (solo editable si no hay registros)
          CustomDropdown<String>(
            enabled: _puedeModificar && !widget.isLoading,
            label: 'Separador',
            items: _separadorOptions,
            value: _separador,
            onChanged: !_tieneRegistros && _puedeModificar && !widget.isLoading
                ? (value) {
                    setState(() {
                      _separador = value ?? '-';
                    });
                  }
                : null,
            hintText: 'Seleccionar separador',
            borderColor: AppColors.blue1,
          ),

          const SizedBox(height: 16),

          // Selector de Longitud (solo editable si no hay registros)
          CompactNumericSelector(
            minValue: 4,
            maxValue: 10,
            initialValue: _longitud,
            onChanged: (value) {
              setState(() {
                _longitud = value;
              });
            },
            label: 'Longitud del número',
            helperText: 'Cantidad de dígitos con ceros a la izquierda',
            suffix: 'dígitos',
            enabled: !_tieneRegistros && !widget.isLoading,
          ),

          const SizedBox(height: 16),

          // Switch Incluir Sede (solo para productos y servicios)
          if (widget.tipo == 'producto' || widget.tipo == 'servicio')
            CustomSwitchTile(
              title: 'Incluir código de sede', 
              value: _incluirSede,
              onChanged: widget.isLoading ? null : (value){ 
                setState(() => _incluirSede);
              },
            ),

          const SizedBox(height: 24),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  backgroundColor: AppColors.blue1,
                  icon: Icon(Icons.remove_red_eye_outlined),
                  text: 'Vista Previa',
                  onPressed: widget.isLoading ? null : widget.onPreview,
                ),
               
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  backgroundColor: AppColors.blue1,
                  icon: Icon(Icons.save),
                  text: 'Guardar',
                  onPressed: widget.isLoading ? null : _guardarCambios,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
              fontSize: 11
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _guardarCambios() {
    final codigo = _codigoController.text.trim();

    // Validaciones
    if (codigo.isEmpty) {
      _showError('El prefijo no puede estar vacío');
      return;
    }

    // Llamar al callback
    widget.onUpdate(
      codigo,
      _separador,
      _longitud,
      (widget.tipo == 'producto' || widget.tipo == 'servicio')
          ? _incluirSede
          : null,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
