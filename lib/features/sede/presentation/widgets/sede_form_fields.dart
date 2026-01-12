import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/custom_switch_tile.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../empresa/domain/entities/sede.dart';

class SedeFormFields extends StatelessWidget {
  final TextEditingController nombreController;
  final TextEditingController codigoController;
  final TextEditingController telefonoController;
  final TextEditingController emailController;
  final TextEditingController direccionController;
  final TextEditingController referenciaController;
  final TextEditingController distritoController;
  final TextEditingController provinciaController;
  final TextEditingController departamentoController;
  final TextEditingController serieFacturaController;
  final TextEditingController serieBoletaController;
  final TextEditingController serieNotaCreditoController;
  final TextEditingController serieNotaDebitoController;
  final TextEditingController serieGuiaRemisionController;
  final TipoSede selectedTipoSede;
  final bool isActive;
  final bool isEditing;
  final ValueChanged<TipoSede> onTipoSedeChanged;
  final ValueChanged<bool> onIsActiveChanged;

  const SedeFormFields({
    super.key,
    required this.nombreController,
    required this.codigoController,
    required this.telefonoController,
    required this.emailController,
    required this.direccionController,
    required this.referenciaController,
    required this.distritoController,
    required this.provinciaController,
    required this.departamentoController,
    required this.serieFacturaController,
    required this.serieBoletaController,
    required this.serieNotaCreditoController,
    required this.serieNotaDebitoController,
    required this.serieGuiaRemisionController,
    required this.selectedTipoSede,
    required this.isActive,
    required this.isEditing,
    required this.onTipoSedeChanged,
    required this.onIsActiveChanged,
  });

  /// Determina si el tipo de sede requiere emisión de comprobantes
  bool get _requiereEmision {
    return selectedTipoSede == TipoSede.operativaCompleta ||
           selectedTipoSede == TipoSede.puntoVenta;
  }

  /// Determina si un campo de serie específico debe ser editable
  bool _isSerieEditable(String serieTipo) {
    if (selectedTipoSede == TipoSede.operativaCompleta) {
      return true; // Todas las series editables
    } else if (selectedTipoSede == TipoSede.puntoVenta) {
      // Solo factura y boleta editables
      return serieTipo == 'factura' || serieTipo == 'boleta';
    }
    return false; // Resto de tipos: no editable
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Información Básica
        AppSubtitle('Información Básica'),
        const SizedBox(height: 12),
        CustomText(
          controller: nombreController,
          borderColor: AppColors.blue1,
          label: 'Nombre de la Sede *',
          hintText: 'Ej: Sede Lima Centro',
          prefixIcon: Icon(Icons.business, size: 16,),
          textCase: TextCase.upper,
          validator: (value){
            if(value == null || value.trim().isEmpty){
              return 'El nombre es requerido';
            }
            if (value.trim().length < 3) {
              return 'El nombre debe tener al menos 3 caracteres';
            }
            return null;
          },
        ),

        const SizedBox(height: 12),

        // Código de Sede - Solo visible durante la edición (solo lectura)
        if (isEditing) ...[
          CustomText(
            controller: codigoController,
            borderColor: AppColors.blue1,
            prefixIcon: const Icon(Icons.qr_code, size: 16,),
            label: 'Código de Sede',
            hintText: '',
            helperText: 'Generado automáticamente, no se puede modificar',
            enabled: false, // Siempre deshabilitado
            textCase: TextCase.upper,
          ),
          const SizedBox(height: 12),
        ],

        // Tipo de Sede
        CustomDropdown<TipoSede>(
          borderColor: AppColors.blue1,
          label: 'Tipo de Sede *',
          hintText: 'Selecciona un tipo de sede',
          value: selectedTipoSede,
          items: TipoSede.values.map((tipo) {
            return DropdownItem<TipoSede>(
              value: tipo,
              label: tipo.displayName,
              leading: Icon(
                IconData(
                  _getIconForTipo(tipo),
                  fontFamily: 'MaterialIcons',
                ),
                size: 16,
                color: Color(_getColorForTipo(tipo)),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onTipoSedeChanged(value);
            }
          },
          validator: (value) {
            if (value == null) {
              return 'Selecciona un tipo de sede';
            }
            return null;
          },
        ),

        const SizedBox(height: 20),

        // Información de Contacto
        AppSubtitle('Información de Contacto'),
        const SizedBox(height: 12),

        CustomText(
          controller: telefonoController,
          borderColor: AppColors.blue1,
          label: 'Teléfono',
          hintText: 'Ej: +51 987654321',
          prefixIcon: Icon(Icons.phone_android_rounded),
          keyboardType: TextInputType.phone,
          maxLength: 9,
        ),

        const SizedBox(height: 16),

        CustomTextFieldHelpers.email(
          label: 'Email',
          borderColor: AppColors.blue1,
          hintText: 'Ej: lima@miempresa.com', 
          controller: emailController,
          
        ),

        const SizedBox(height: 24),

        // Ubicación
        AppSubtitle('Ubicación'),
        const SizedBox(height: 12),
        CustomText(
          borderColor: AppColors.blue1,
          prefixIcon: Icon(Icons.location_on),
          controller: direccionController,
          label: 'Dirección',
          hintText: 'Ej: Av. Javier Prado 123',
          maxLines: null,
          minLines: 2,
        ),

        const SizedBox(height: 12),

        CustomText(
          borderColor: AppColors.blue1,
          prefixIcon: Icon(Icons.info_outline),
          controller: referenciaController,
          label: 'Referencia',
          hintText: 'Ej: Al frente del banco',
          maxLines: null,
          minLines: 2,
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: CustomText(
                controller: distritoController,
                label: 'Distrito',
                borderColor: AppColors.blue1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomText(
                controller: provinciaController,
                label: 'Provincia',
                borderColor: AppColors.blue1,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),
        CustomText(
          controller: departamentoController,
          label: 'Departamento',
          prefixIcon: Icon(Icons.map),
          borderColor: AppColors.blue1,
        ),

        // Series de Comprobantes - Solo mostrar cuando se está editando
        if (isEditing) ...[
          const SizedBox(height: 24),

          AppSubtitle('Series de Comprobantes'),
          const SizedBox(height: 8),

          // Mensaje informativo según el tipo de sede
          if (!_requiereEmision) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Series generadas automáticamente. Aunque esta sede no emite comprobantes actualmente, las series quedan reservadas para uso futuro.',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          Row(
            children: [
              Expanded(
                child: CustomText(
                  controller: serieFacturaController,
                  label: _isSerieEditable('factura') ? 'Serie Factura *' : 'Serie Factura',
                  hintText: 'F001',
                  borderColor: AppColors.blue1,
                  enabled: _isSerieEditable('factura'),
                  helperText: !_isSerieEditable('factura')
                      ? 'Generada automáticamente'
                      : null,
                  validator: (value){
                    // Solo validar si el campo es editable
                    if (_isSerieEditable('factura') && (value == null || value.trim().isEmpty)) {
                      return 'Requerido';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomText(
                  controller: serieBoletaController,
                  label: _isSerieEditable('boleta') ? 'Serie Boleta *' : 'Serie Boleta',
                  hintText: 'B001',
                  borderColor: AppColors.blue1,
                  enabled: _isSerieEditable('boleta'),
                  helperText: !_isSerieEditable('boleta')
                      ? 'Generada automáticamente'
                      : null,
                  validator: (value){
                    // Solo validar si el campo es editable
                    if (_isSerieEditable('boleta') && (value == null || value.trim().isEmpty)) {
                      return 'Requerido';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: CustomText(
                  controller: serieNotaCreditoController,
                  label: _isSerieEditable('notaCredito') ? 'Serie N. Crédito *' : 'Serie N. Crédito',
                  hintText: 'NC01',
                  borderColor: AppColors.blue1,
                  enabled: _isSerieEditable('notaCredito'),
                  helperText: !_isSerieEditable('notaCredito')
                      ? 'Generada automáticamente'
                      : null,
                  validator: (value){
                    // Solo validar si el campo es editable
                    if (_isSerieEditable('notaCredito') && (value == null || value.trim().isEmpty)) {
                      return 'Requerido';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomText(
                  controller: serieNotaDebitoController,
                  label: _isSerieEditable('notaDebito') ? 'Serie N. Débito *' : 'Serie N. Débito',
                  hintText: 'ND01',
                  borderColor: AppColors.blue1,
                  enabled: _isSerieEditable('notaDebito'),
                  helperText: !_isSerieEditable('notaDebito')
                      ? 'Generada automáticamente'
                      : null,
                  validator: (value){
                    // Solo validar si el campo es editable
                    if (_isSerieEditable('notaDebito') && (value == null || value.trim().isEmpty)) {
                      return 'Requerido';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          CustomText(
            controller: serieGuiaRemisionController,
            label: 'Serie Guía Remisión',
            hintText: 'GR01 (opcional)',
            borderColor: AppColors.blue1,
            enabled: _isSerieEditable('guiaRemision'),
            helperText: !_isSerieEditable('guiaRemision')
                ? 'Generada automáticamente'
                : null,
          ),

          const SizedBox(height: 24),
        ],

        // Espaciado antes de Estado
        if (!isEditing) const SizedBox(height: 24),

        // Estado
        AppSubtitle('Estado'),
        // const SizedBox(height: 12),

        // SwitchListTile(
        //   title: const Text('Sede Activa'),
        //   subtitle: Text(
        //     isActive ? 'La sede está operativa' : 'La sede está inactiva',
        //     style: TextStyle(
        //       fontSize: 12,
        //       color: isActive ? Colors.green : Colors.red,
        //     ),
        //   ),
        //   value: isActive,
        //   onChanged: onIsActiveChanged,
        //   activeThumbColor: Colors.green,
        // ),
        CustomSwitchTile(
          title: 'Sede Activa', 
          subtitle: isActive ? 'La sede está operativa' : 'La sede está inactiva',
          subtitleStyle: TextStyle(
            color: isActive ? Colors.green : Colors.red,
          ),
          value: isActive,
          onChanged: onIsActiveChanged,
          activeColor: Colors.green,
        )
      ],
    );
  }

  // Widget _buildSectionTitle(String title) {
  //   return Text(
  //     title,
  //     style: const TextStyle(
  //       fontSize: 12,
  //       fontWeight: FontWeight.bold,
  //     ),
  //   );
  // }

  int _getIconForTipo(TipoSede tipo) {
    switch (tipo) {
      case TipoSede.operativaCompleta:
        return 0xe559; // Icons.business
      case TipoSede.soloAlmacen:
        return 0xe1b1; // Icons.warehouse
      case TipoSede.puntoVenta:
        return 0xe59c; // Icons.shopping_cart
      case TipoSede.oficinaAdministrativa:
        return 0xe3f7; // Icons.corporate_fare
      case TipoSede.tallerLaboratorio:
        return 0xe869; // Icons.handyman
    }
  }

  int _getColorForTipo(TipoSede tipo) {
    switch (tipo) {
      case TipoSede.operativaCompleta:
        return 0xFF4CAF50; // Verde
      case TipoSede.soloAlmacen:
        return 0xFF2196F3; // Azul
      case TipoSede.puntoVenta:
        return 0xFFFF9800; // Naranja
      case TipoSede.oficinaAdministrativa:
        return 0xFF9C27B0; // Púrpura
      case TipoSede.tallerLaboratorio:
        return 0xFF00BCD4; // Cian
    }
  }
}
