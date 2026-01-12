import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/constants/storage_constants.dart';
import '../../domain/entities/usuario_filtros.dart';
import '../bloc/usuario_form/usuario_form_cubit.dart';
import '../bloc/usuario_form/usuario_form_state.dart';

/// Página para registrar un nuevo usuario/empleado
class UsuarioFormPage extends StatefulWidget {
  const UsuarioFormPage({super.key});

  @override
  State<UsuarioFormPage> createState() => _UsuarioFormPageState();
}

class _UsuarioFormPageState extends State<UsuarioFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final UsuarioFormCubit _cubit;
  String? _empresaId;

  // Controllers
  final _dniController = TextEditingController();
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();

  // Form values
  RolUsuario? _selectedRol;
  bool _puedeAbrirCaja = false;
  bool _puedeCerrarCaja = false;

  @override
  void initState() {
    super.initState();
    _cubit = locator<UsuarioFormCubit>();
    _loadEmpresaId();
  }

  void _loadEmpresaId() {
    final localStorage = locator<LocalStorageService>();
    _empresaId = localStorage.getString(StorageConstants.tenantId);
  }

  @override
  void dispose() {
    _dniController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Usuario'),
      ),
      body: BlocProvider.value(
        value: _cubit,
        child: BlocConsumer<UsuarioFormCubit, UsuarioFormState>(
          listener: (context, state) {
            if (state is UsuarioFormSuccess) {
              _showSuccessDialog(context, state.response.mensaje);
            } else if (state is UsuarioFormError) {
              _showErrorSnackBar(context, state.message);
            }
          },
          builder: (context, state) {
            final isSubmitting = state is UsuarioFormSubmitting;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionTitle('Datos Personales'),
                    const SizedBox(height: 16),
                    _buildDniField(),
                    const SizedBox(height: 16),
                    _buildNombresField(),
                    const SizedBox(height: 16),
                    _buildApellidosField(),
                    const SizedBox(height: 16),
                    _buildTelefonoField(),
                    const SizedBox(height: 16),
                    _buildEmailField(),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Información Laboral'),
                    const SizedBox(height: 16),
                    _buildRolDropdown(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Permisos de Caja'),
                    const SizedBox(height: 8),
                    _buildCheckbox(
                      'Puede abrir caja',
                      _puedeAbrirCaja,
                      (value) => setState(() => _puedeAbrirCaja = value ?? false),
                    ),
                    _buildCheckbox(
                      'Puede cerrar caja',
                      _puedeCerrarCaja,
                      (value) =>
                          setState(() => _puedeCerrarCaja = value ?? false),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Registrar Usuario'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDniField() {
    return TextFormField(
      controller: _dniController,
      decoration: const InputDecoration(
        labelText: 'DNI *',
        hintText: '12345678',
        prefixIcon: Icon(Icons.badge),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      maxLength: 8,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'El DNI es obligatorio';
        }
        if (value.length != 8) {
          return 'El DNI debe tener 8 dígitos';
        }
        if (!RegExp(r'^\d{8}$').hasMatch(value)) {
          return 'El DNI debe contener solo números';
        }
        return null;
      },
    );
  }

  Widget _buildNombresField() {
    return TextFormField(
      controller: _nombresController,
      decoration: const InputDecoration(
        labelText: 'Nombres *',
        hintText: 'Juan Carlos',
        prefixIcon: Icon(Icons.person),
        border: OutlineInputBorder(),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Los nombres son obligatorios';
        }
        return null;
      },
    );
  }

  Widget _buildApellidosField() {
    return TextFormField(
      controller: _apellidosController,
      decoration: const InputDecoration(
        labelText: 'Apellidos *',
        hintText: 'Pérez García',
        prefixIcon: Icon(Icons.person_outline),
        border: OutlineInputBorder(),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Los apellidos son obligatorios';
        }
        return null;
      },
    );
  }

  Widget _buildTelefonoField() {
    return TextFormField(
      controller: _telefonoController,
      decoration: const InputDecoration(
        labelText: 'Teléfono *',
        hintText: '987654321',
        prefixIcon: Icon(Icons.phone),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.phone,
      maxLength: 9,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'El teléfono es obligatorio';
        }
        if (value.length != 9) {
          return 'El teléfono debe tener 9 dígitos';
        }
        if (!RegExp(r'^9\d{8}$').hasMatch(value)) {
          return 'El teléfono debe comenzar con 9';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(
        labelText: 'Email (opcional)',
        hintText: 'usuario@example.com',
        prefixIcon: Icon(Icons.email),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final emailRegex = RegExp(
            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
          );
          if (!emailRegex.hasMatch(value)) {
            return 'Email inválido';
          }
        }
        return null;
      },
    );
  }

  Widget _buildRolDropdown() {
    return DropdownButtonFormField<RolUsuario>(
      initialValue: _selectedRol,
      decoration: const InputDecoration(
        labelText: 'Rol *',
        prefixIcon: Icon(Icons.work),
        border: OutlineInputBorder(),
      ),
      items: RolUsuario.values.map((rol) {
        return DropdownMenuItem(
          value: rol,
          child: Text(rol.label),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedRol = value);
      },
      validator: (value) {
        if (value == null) {
          return 'Debe seleccionar un rol';
        }
        return null;
      },
    );
  }

  Widget _buildCheckbox(
    String label,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_empresaId == null) {
        _showErrorSnackBar(context, 'No se pudo obtener la empresa');
        return;
      }

      _cubit.registrarUsuario(
        empresaId: _empresaId!,
        dni: _dniController.text.trim(),
        nombres: _nombresController.text.trim(),
        apellidos: _apellidosController.text.trim(),
        telefono: _telefonoController.text.trim(),
        rol: _selectedRol!.value,
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        puedeAbrirCaja: _puedeAbrirCaja,
        puedeCerrarCaja: _puedeCerrarCaja,
      );
    }
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¡Éxito!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cierra el diálogo
              context.pop(); // Regresa a la lista
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
