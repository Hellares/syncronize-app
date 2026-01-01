import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/cliente_form/cliente_form_cubit.dart';
import '../bloc/cliente_form/cliente_form_state.dart';

class ClienteFormPage extends StatefulWidget {
  final String empresaId;

  const ClienteFormPage({
    super.key,
    required this.empresaId,
  });

  @override
  State<ClienteFormPage> createState() => _ClienteFormPageState();
}

class _ClienteFormPageState extends State<ClienteFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _dniController = TextEditingController();
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _direccionController = TextEditingController();
  final _distritoController = TextEditingController();
  final _provinciaController = TextEditingController();
  final _departamentoController = TextEditingController();

  @override
  void dispose() {
    _dniController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    _distritoController.dispose();
    _provinciaController.dispose();
    _departamentoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<ClienteFormCubit>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Registrar Cliente'),
        ),
        body: BlocConsumer<ClienteFormCubit, ClienteFormState>(
          listener: (context, state) {
            if (state is ClienteFormSuccess) {
              final response = state.response;

              // Mostrar mensaje según el tipo de registro
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(response.mensaje),
                  backgroundColor: response.yaExistia
                      ? Colors.orange
                      : Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );

              // Si ya existía, mostrar diálogo informativo
              if (response.yaExistia) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Cliente Existente'),
                    content: Text(
                      response.yaEraClienteEmpresa
                          ? 'Este cliente ya está registrado en tu empresa.'
                          : 'Este cliente ya existe en el sistema y ha sido asociado a tu empresa.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Cerrar diálogo
                          context.pop(true); // Volver a lista
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              } else {
                // Cliente nuevo registrado, volver a la lista
                context.pop(true);
              }
            } else if (state is ClienteFormError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is ClienteFormLoading;

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Datos Obligatorios',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dniController,
                    decoration: const InputDecoration(
                      labelText: 'DNI *',
                      hintText: '12345678',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    enabled: !isLoading,
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
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nombresController,
                    decoration: const InputDecoration(
                      labelText: 'Nombres *',
                      hintText: 'Juan Carlos',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    textCapitalization: TextCapitalization.words,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Los nombres son obligatorios';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _apellidosController,
                    decoration: const InputDecoration(
                      labelText: 'Apellidos *',
                      hintText: 'Pérez García',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Los apellidos son obligatorios';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _telefonoController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono *',
                      hintText: '987654321',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    maxLength: 9,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El teléfono es obligatorio';
                      }
                      if (value.length != 9) {
                        return 'El teléfono debe tener 9 dígitos';
                      }
                      if (!RegExp(r'^\d{9}$').hasMatch(value)) {
                        return 'El teléfono debe contener solo números';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Datos Opcionales',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email (opcional)',
                      hintText: 'cliente@example.com',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Email inválido';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _direccionController,
                    decoration: const InputDecoration(
                      labelText: 'Dirección (opcional)',
                      hintText: 'Av. Principal 123',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home),
                    ),
                    textCapitalization: TextCapitalization.words,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _distritoController,
                    decoration: const InputDecoration(
                      labelText: 'Distrito (opcional)',
                      hintText: 'Miraflores',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    textCapitalization: TextCapitalization.words,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _provinciaController,
                    decoration: const InputDecoration(
                      labelText: 'Provincia (opcional)',
                      hintText: 'Lima',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    textCapitalization: TextCapitalization.words,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _departamentoController,
                    decoration: const InputDecoration(
                      labelText: 'Departamento (opcional)',
                      hintText: 'Lima',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.map),
                    ),
                    textCapitalization: TextCapitalization.words,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              context
                                  .read<ClienteFormCubit>()
                                  .registrarCliente(
                                    empresaId: widget.empresaId,
                                    dni: _dniController.text.trim(),
                                    nombres: _nombresController.text.trim(),
                                    apellidos: _apellidosController.text.trim(),
                                    telefono: _telefonoController.text.trim(),
                                    email: _emailController.text.trim().isEmpty
                                        ? null
                                        : _emailController.text.trim(),
                                    direccion:
                                        _direccionController.text.trim().isEmpty
                                            ? null
                                            : _direccionController.text.trim(),
                                    distrito:
                                        _distritoController.text.trim().isEmpty
                                            ? null
                                            : _distritoController.text.trim(),
                                    provincia: _provinciaController.text
                                            .trim()
                                            .isEmpty
                                        ? null
                                        : _provinciaController.text.trim(),
                                    departamento: _departamentoController.text
                                            .trim()
                                            .isEmpty
                                        ? null
                                        : _departamentoController.text.trim(),
                                  );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Registrar Cliente',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
