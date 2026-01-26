import 'package:flutter/material.dart';

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
  final TextEditingController paisController;
  final TextEditingController codigoPostalController;

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
    required this.paisController,
    required this.codigoPostalController,
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
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sección: Identificación
        _buildSectionTitle('Identificación'),
        TextFormField(
          controller: nombreController,
          decoration: const InputDecoration(
            labelText: 'Nombre o Razón Social *',
            border: OutlineInputBorder(),
          ),
          enabled: !isLoading,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El nombre es requerido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: nombreComercialController,
          decoration: const InputDecoration(
            labelText: 'Nombre Comercial',
            border: OutlineInputBorder(),
          ),
          enabled: !isLoading,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: tipoDocumento,
          decoration: const InputDecoration(
            labelText: 'Tipo de Documento *',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'RUC', child: Text('RUC')),
            DropdownMenuItem(value: 'DNI', child: Text('DNI')),
            DropdownMenuItem(value: 'PASAPORTE', child: Text('Pasaporte')),
            DropdownMenuItem(
                value: 'CARNET_EXTRANJERIA',
                child: Text('Carnet de Extranjería')),
          ],
          onChanged: isLoading ? null : (value) => onTipoDocumentoChanged(value!),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: documentoController,
          decoration: const InputDecoration(
            labelText: 'Número de Documento *',
            border: OutlineInputBorder(),
          ),
          enabled: !isLoading,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El documento es requerido';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),

        // Sección: Información de Contacto
        _buildSectionTitle('Información de Contacto'),
        TextFormField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          enabled: !isLoading,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: telefonoController,
          decoration: const InputDecoration(
            labelText: 'Teléfono',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
          ),
          enabled: !isLoading,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: telefonoAlternativoController,
          decoration: const InputDecoration(
            labelText: 'Teléfono Alternativo',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone_android),
          ),
          enabled: !isLoading,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: sitioWebController,
          decoration: const InputDecoration(
            labelText: 'Sitio Web',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.language),
            hintText: 'https://ejemplo.com',
          ),
          enabled: !isLoading,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 24),

        // Sección: Dirección
        _buildSectionTitle('Dirección'),
        TextFormField(
          controller: direccionController,
          decoration: const InputDecoration(
            labelText: 'Dirección',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
          enabled: !isLoading,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: ciudadController,
          decoration: const InputDecoration(
            labelText: 'Ciudad',
            border: OutlineInputBorder(),
          ),
          enabled: !isLoading,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: provinciaController,
          decoration: const InputDecoration(
            labelText: 'Provincia / Departamento',
            border: OutlineInputBorder(),
          ),
          enabled: !isLoading,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: paisController,
          decoration: const InputDecoration(
            labelText: 'País',
            border: OutlineInputBorder(),
            hintText: 'PE',
          ),
          enabled: !isLoading,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: codigoPostalController,
          decoration: const InputDecoration(
            labelText: 'Código Postal',
            border: OutlineInputBorder(),
          ),
          enabled: !isLoading,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),

        // Sección: Términos Comerciales
        _buildSectionTitle('Términos Comerciales'),
        DropdownButtonFormField<String>(
          initialValue: terminosPago,
          decoration: const InputDecoration(
            labelText: 'Términos de Pago',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'CONTADO', child: Text('Contado')),
            DropdownMenuItem(
                value: 'CREDITO_7', child: Text('Crédito 7 días')),
            DropdownMenuItem(
                value: 'CREDITO_15', child: Text('Crédito 15 días')),
            DropdownMenuItem(
                value: 'CREDITO_30', child: Text('Crédito 30 días')),
            DropdownMenuItem(
                value: 'CREDITO_45', child: Text('Crédito 45 días')),
            DropdownMenuItem(
                value: 'CREDITO_60', child: Text('Crédito 60 días')),
          ],
          onChanged: isLoading ? null : onTerminosPagoChanged,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: limiteCreditoController,
          decoration: const InputDecoration(
            labelText: 'Límite de Crédito',
            border: OutlineInputBorder(),
            prefixText: 'S/ ',
            hintText: '0.00',
          ),
          enabled: !isLoading,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: descuentoPreferencialController,
          decoration: const InputDecoration(
            labelText: 'Descuento Preferencial',
            border: OutlineInputBorder(),
            suffixText: '%',
            hintText: '0',
          ),
          enabled: !isLoading,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value != null && value.trim().isNotEmpty) {
              final val = double.tryParse(value.trim());
              if (val == null || val < 0 || val > 100) {
                return 'Debe estar entre 0 y 100';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 24),

        // Sección: Contacto Principal
        _buildSectionTitle('Contacto Principal'),
        TextFormField(
          controller: contactoPrincipalController,
          decoration: const InputDecoration(
            labelText: 'Nombre del Contacto',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          enabled: !isLoading,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: cargoContactoController,
          decoration: const InputDecoration(
            labelText: 'Cargo',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.work),
          ),
          enabled: !isLoading,
        ),
        const SizedBox(height: 24),

        // Sección: Notas
        _buildSectionTitle('Notas Adicionales'),
        TextFormField(
          controller: notasController,
          decoration: const InputDecoration(
            labelText: 'Notas',
            border: OutlineInputBorder(),
            hintText: 'Información adicional sobre el proveedor',
          ),
          enabled: !isLoading,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }
}
