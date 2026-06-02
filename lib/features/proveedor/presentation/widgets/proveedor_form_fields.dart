import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';

class ProveedorFormFields extends StatelessWidget {
  // Controllers - Identificación
  final TextEditingController nombreController;
  final TextEditingController nombreComercialController;
  final TextEditingController documentoController;

  // Controllers - Contacto
  final TextEditingController emailController;
  final TextEditingController telefonoController;
  final TextEditingController telefonoAlternativoController;
  final TextEditingController sitioWebController;

  // Controllers - Dirección
  final TextEditingController direccionController;
  final TextEditingController ciudadController;
  final TextEditingController provinciaController;
  final TextEditingController departamentoController;
  final TextEditingController paisController;

  // Controllers - Términos Comerciales
  final TextEditingController limiteCreditoController;
  final TextEditingController descuentoPreferencialController;

  // Controllers - Contacto Principal
  final TextEditingController contactoPrincipalController;
  final TextEditingController cargoContactoController;

  // Controllers - Notas
  final TextEditingController notasController;

  // State values
  final String tipoDocumento;
  final String? terminosPago;
  final bool isLoading;
  final bool isEditing;

  // Callbacks
  final ValueChanged<String> onTipoDocumentoChanged;
  final ValueChanged<String?> onTerminosPagoChanged;

  // New callbacks for document search
  final VoidCallback? onSearchDocument;
  final VoidCallback? onCancelSearch;
  final bool isSearching;

  const ProveedorFormFields({
    super.key,
    required this.nombreController,
    required this.nombreComercialController,
    required this.documentoController,
    required this.emailController,
    required this.telefonoController,
    required this.telefonoAlternativoController,
    required this.sitioWebController,
    required this.direccionController,
    required this.ciudadController,
    required this.provinciaController,
    required this.departamentoController,
    required this.paisController,
    required this.limiteCreditoController,
    required this.descuentoPreferencialController,
    required this.contactoPrincipalController,
    required this.cargoContactoController,
    required this.notasController,
    required this.tipoDocumento,
    required this.terminosPago,
    required this.isLoading,
    required this.isEditing,
    required this.onTipoDocumentoChanged,
    required this.onTerminosPagoChanged,
    this.onSearchDocument,
    this.onCancelSearch,
    this.isSearching = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Sección 1: Identificación ───
        _buildSectionHeader('Identificación', Icons.badge_outlined),
        // Tipo + Número de documento en una sola fila. El número se busca
        // automáticamente al completar la longitud del tipo (RUC=11, DNI=8).
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: CustomDropdown<String>(
                label: 'Tipo de Documento *',
                items: const [
                  DropdownItem(value: 'RUC', label: 'RUC'),
                  DropdownItem(value: 'DNI', label: 'DNI'),
                  DropdownItem(value: 'PASAPORTE', label: 'Pasaporte'),
                  DropdownItem(
                      value: 'CARNET_EXTRANJERIA', label: 'C. Extranjería'),
                ],
                value: tipoDocumento,
                onChanged: isLoading
                    ? null
                    : (value) {
                        if (value != null) onTipoDocumentoChanged(value);
                      },
                borderColor: AppColors.blue1,
                enabled: !isLoading,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 6,
              child: CustomText(
                controller: documentoController,
                label: 'Número de Documento *',
                hintText: _hintDoc(),
                keyboardType: _esNumerico()
                    ? TextInputType.number
                    : TextInputType.text,
                borderColor: AppColors.blue1,
                inputFormatters: _formattersDoc(),
                autovalidateMode: AutovalidateModeX.onUserInteraction,
                validator: _validarDocumento,
                showValidationIndicator: false,
                enabled: !isLoading,
                // Búsqueda automática: al alcanzar la longitud exacta del tipo
                // (solo RUC/DNI, que tienen consulta externa) se dispara solo.
                onChanged: (value) {
                  final autoLen = _autoSearchLen();
                  if (autoLen != null &&
                      value.trim().length == autoLen &&
                      !isSearching) {
                    onSearchDocument?.call();
                  }
                },
                // Mientras busca: spinner + X para detener (la consulta puede
                // demorar). En reposo: lupa para disparar manualmente (RUC/DNI).
                suffixIcon: isSearching
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.blue1),
                          ),
                          GestureDetector(
                            onTap: onCancelSearch,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.close,
                                  size: 18, color: AppColors.red),
                            ),
                          ),
                        ],
                      )
                    : (_autoSearchLen() != null
                        ? GestureDetector(
                            onTap: isLoading ? null : onSearchDocument,
                            child: const Icon(Icons.search,
                                size: 18, color: AppColors.blue1),
                          )
                        : null),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        CustomText(
          controller: nombreController,
          label: 'Nombre o Razón Social *',
          borderColor: AppColors.blue1,
          enabled: !isLoading,
        ),
        const SizedBox(height: 10),
        CustomText(
          controller: nombreComercialController,
          label: 'Nombre Comercial',
          borderColor: AppColors.blue1,
          enabled: !isLoading,
        ),
        //const SizedBox(height: 8),

        // ─── Sección 2: Contacto ───
        _buildSectionHeader('Contacto', Icons.contact_phone_outlined),
        CustomText(
          controller: emailController,
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          borderColor: AppColors.blue1,
          enabled: !isLoading,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CustomText(
                controller: telefonoController,
                label: 'Teléfono',
                keyboardType: TextInputType.phone,
                borderColor: AppColors.blue1,
                enabled: !isLoading,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomText(
                controller: telefonoAlternativoController,
                label: 'Teléfono Alternativo',
                keyboardType: TextInputType.phone,
                borderColor: AppColors.blue1,
                enabled: !isLoading,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CustomText(
          controller: sitioWebController,
          label: 'Sitio Web',
          keyboardType: TextInputType.url,
          hintText: 'https://ejemplo.com',
          borderColor: AppColors.blue1,
          enabled: !isLoading,
        ),
        const SizedBox(height: 8),

        // ─── Sección 3: Dirección ───
        _buildSectionHeader('Dirección', Icons.location_on_outlined),
        CustomText(
          controller: direccionController,
          label: 'Dirección',
          borderColor: AppColors.blue1,
          enabled: !isLoading,
        ),
        const SizedBox(height: 12),
        CustomText(
          controller: ciudadController,
          label: 'Ciudad / Distrito',
          borderColor: AppColors.blue1,
          enabled: !isLoading,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CustomText(
                controller: provinciaController,
                label: 'Provincia',
                borderColor: AppColors.blue1,
                enabled: !isLoading,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomText(
                controller: departamentoController,
                label: 'Departamento',
                borderColor: AppColors.blue1,
                enabled: !isLoading,
              ),
            ),
          ],
        ),
        // País oculto: por ahora siempre se envía 'PE' desde el submit.
        const SizedBox(height: 8),

        // ─── Sección 4: Términos Comerciales ───
        _buildSectionHeader('Términos Comerciales', Icons.handshake_outlined),
        CustomDropdown<String>(
          label: 'Términos de Pago',
          items: const [
            DropdownItem(value: 'CONTADO', label: 'Contado'),
            DropdownItem(value: 'CREDITO_7', label: 'Crédito 7 días'),
            DropdownItem(value: 'CREDITO_15', label: 'Crédito 15 días'),
            DropdownItem(value: 'CREDITO_30', label: 'Crédito 30 días'),
            DropdownItem(value: 'CREDITO_45', label: 'Crédito 45 días'),
            DropdownItem(value: 'CREDITO_60', label: 'Crédito 60 días'),
          ],
          value: terminosPago,
          onChanged: isLoading ? null : onTerminosPagoChanged,
          borderColor: AppColors.blue1,
          hintText: 'Seleccionar',
          enabled: !isLoading,
        ),
        const SizedBox(height: 12),
        CustomText(
          controller: limiteCreditoController,
          label: 'Límite de Crédito',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefixText: 'S/ ',
          hintText: '0.00',
          borderColor: AppColors.blue1,
          enabled: !isLoading,
        ),
        const SizedBox(height: 12),
        CustomText(
          controller: descuentoPreferencialController,
          label: 'Descuento Preferencial',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          suffixText: '%',
          hintText: '0',
          borderColor: AppColors.blue1,
          enabled: !isLoading,
        ),
        const SizedBox(height: 8),

        // ─── Sección 5: Contacto Principal ───
        _buildSectionHeader('Contacto Principal', Icons.person_outline),
        CustomText(
          controller: contactoPrincipalController,
          label: 'Nombre del Contacto',
          borderColor: AppColors.blue1,
          enabled: !isLoading,
        ),
        const SizedBox(height: 12),
        CustomText(
          controller: cargoContactoController,
          label: 'Cargo',
          borderColor: AppColors.blue1,
          enabled: !isLoading,
        ),
        const SizedBox(height: 8),

        // ─── Sección 6: Notas ───
        _buildSectionHeader('Notas', Icons.notes_outlined),
        CustomText(
          controller: notasController,
          label: 'Notas',
          hintText: 'Información adicional sobre el proveedor',
          maxLines: 3,
          borderColor: AppColors.blue1,
          enabled: !isLoading,
        ),
      ],
    );
  }

  // ── Helpers por tipo de documento ──

  /// Longitud que dispara la búsqueda automática. null = sin consulta externa
  /// (Pasaporte / Carnet de Extranjería no tienen lookup SUNAT/RENIEC).
  int? _autoSearchLen() {
    switch (tipoDocumento) {
      case 'RUC':
        return 11;
      case 'DNI':
        return 8;
      default:
        return null;
    }
  }

  /// Longitud máxima permitida en el campo según el tipo.
  int _maxLenDoc() {
    switch (tipoDocumento) {
      case 'RUC':
        return 11;
      case 'DNI':
        return 8;
      case 'CARNET_EXTRANJERIA':
        return 12;
      default: // PASAPORTE
        return 20;
    }
  }

  /// RUC/DNI son solo dígitos; Pasaporte/CE admiten alfanumérico.
  bool _esNumerico() => tipoDocumento == 'RUC' || tipoDocumento == 'DNI';

  List<TextInputFormatter> _formattersDoc() {
    return [
      if (_esNumerico())
        FilteringTextInputFormatter.digitsOnly
      else ...[
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
        TextInputFormatter.withFunction(
          (oldV, newV) => newV.copyWith(text: newV.text.toUpperCase()),
        ),
      ],
      LengthLimitingTextInputFormatter(_maxLenDoc()),
    ];
  }

  String _hintDoc() {
    switch (tipoDocumento) {
      case 'RUC':
        return '11 dígitos';
      case 'DNI':
        return '8 dígitos';
      case 'PASAPORTE':
        return 'N° de pasaporte';
      default:
        return 'N° de carnet';
    }
  }

  String? _validarDocumento(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Requerido';
    switch (tipoDocumento) {
      case 'RUC':
        if (value.length != 11) return 'El RUC debe tener 11 dígitos';
        break;
      case 'DNI':
        if (value.length != 8) return 'El DNI debe tener 8 dígitos';
        break;
      case 'PASAPORTE':
        if (value.length < 6) return 'Pasaporte inválido';
        break;
      case 'CARNET_EXTRANJERIA':
        if (value.length < 9) return 'Carnet inválido';
        break;
    }
    return null;
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.blue1),
          const SizedBox(width: 6),
          AppSubtitle(title, fontSize: 10, color: AppColors.blue1),
        ],
      ),
    );
  }
}
