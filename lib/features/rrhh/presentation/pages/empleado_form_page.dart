import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/resource.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart'
    show CustomText;
import 'package:syncronize/features/empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import 'package:syncronize/features/empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import 'package:syncronize/features/usuario/domain/entities/registro_usuario_response.dart';
import 'package:syncronize/features/usuario/domain/entities/usuario.dart';
import 'package:syncronize/features/usuario/domain/entities/usuario_filtros.dart';
import 'package:syncronize/features/usuario/domain/usecases/get_usuarios_usecase.dart';

import '../../domain/entities/empleado.dart';
import '../bloc/empleado_form/empleado_form_cubit.dart';
import '../bloc/empleado_form/empleado_form_state.dart';

class EmpleadoFormPage extends StatefulWidget {
  final Empleado? empleado;

  const EmpleadoFormPage({super.key, this.empleado});

  @override
  State<EmpleadoFormPage> createState() => _EmpleadoFormPageState();
}

class _EmpleadoFormPageState extends State<EmpleadoFormPage> {
  late final EmpleadoFormCubit _formCubit;
  final _formKey = GlobalKey<FormState>();

  bool get isEditing => widget.empleado != null;

  // Selectores
  String? _selectedUsuarioId;
  String? _selectedSedeId;

  // Controllers
  final _cargoController = TextEditingController();
  final _departamentoController = TextEditingController();
  final _salarioBaseController = TextEditingController();
  final _bancoController = TextEditingController();
  final _numeroCuentaController = TextEditingController();
  final _cciController = TextEditingController();

  TipoContrato _tipoContrato = TipoContrato.planilla;
  DateTime _fechaIngreso = DateTime.now();

  // Usuarios cargados
  List<Usuario> _usuarios = [];
  bool _isLoadingUsuarios = true;
  bool _didLoad = false;

  @override
  void initState() {
    super.initState();
    _formCubit = locator<EmpleadoFormCubit>();

    if (isEditing) {
      final e = widget.empleado!;
      _selectedUsuarioId = e.usuarioId;
      _selectedSedeId = e.sedeId;
      _cargoController.text = e.cargo ?? '';
      _departamentoController.text = e.departamento ?? '';
      _salarioBaseController.text = e.salarioBase.toStringAsFixed(2);
      _bancoController.text = e.banco ?? '';
      _numeroCuentaController.text = e.numeroCuenta ?? '';
      _cciController.text = e.cci ?? '';
      _tipoContrato = e.tipoContrato;
      _fechaIngreso = e.fechaIngreso;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      _loadUsuarios();
    }
  }

  Future<void> _loadUsuarios() async {
    try {
      final empresaState = context.read<EmpresaContextCubit>().state;
      if (empresaState is! EmpresaContextLoaded) {
        if (mounted) setState(() => _isLoadingUsuarios = false);
        return;
      }

      final empresaId = empresaState.context.empresa.id;
      final useCase = locator<GetUsuariosUseCase>();
      final result = await useCase(
        empresaId: empresaId,
        filtros: const UsuarioFiltros(limit: 100, isActive: true),
      );
      if (!mounted) return;
      if (result is Success<UsuariosPaginados>) {
        setState(() {
          _usuarios = result.data.data;
          _isLoadingUsuarios = false;
        });
      } else if (result is Error) {
        setState(() => _isLoadingUsuarios = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingUsuarios = false);
    }
  }

  @override
  void dispose() {
    _formCubit.close();
    _cargoController.dispose();
    _departamentoController.dispose();
    _salarioBaseController.dispose();
    _bancoController.dispose();
    _numeroCuentaController.dispose();
    _cciController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaIngreso,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _fechaIngreso = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedUsuarioId == null || _selectedUsuarioId!.isEmpty) {
      SnackBarHelper.showError(context, 'Selecciona un usuario');
      return;
    }
    if (_selectedSedeId == null || _selectedSedeId!.isEmpty) {
      SnackBarHelper.showError(context, 'Selecciona una sede');
      return;
    }

    final data = <String, dynamic>{
      'usuarioId': _selectedUsuarioId,
      'sedeId': _selectedSedeId,
      'fechaIngreso': _fechaIngreso.toIso8601String(),
      'tipoContrato': _tipoContrato.apiValue,
      'salarioBase': double.tryParse(_salarioBaseController.text) ?? 0,
    };

    if (_cargoController.text.trim().isNotEmpty) {
      data['cargo'] = _cargoController.text.trim();
    }
    if (_departamentoController.text.trim().isNotEmpty) {
      data['departamento'] = _departamentoController.text.trim();
    }
    if (_bancoController.text.trim().isNotEmpty) {
      data['banco'] = _bancoController.text.trim();
    }
    if (_numeroCuentaController.text.trim().isNotEmpty) {
      data['numeroCuenta'] = _numeroCuentaController.text.trim();
    }
    if (_cciController.text.trim().isNotEmpty) {
      data['cci'] = _cciController.text.trim();
    }

    if (isEditing) {
      _formCubit.actualizarEmpleado(widget.empleado!.id, data);
    } else {
      _formCubit.crearEmpleado(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final empresaState = context.watch<EmpresaContextCubit>().state;
    final sedes = empresaState is EmpresaContextLoaded
        ? empresaState.context.sedes
        : [];

    return BlocProvider.value(
      value: _formCubit,
      child: BlocConsumer<EmpleadoFormCubit, EmpleadoFormState>(
        listener: (context, state) {
          if (state is EmpleadoFormSuccess) {
            SnackBarHelper.showSuccess(
              context,
              isEditing
                  ? 'Empleado actualizado exitosamente'
                  : 'Empleado creado exitosamente',
            );
            context.pop(true);
          } else if (state is EmpleadoFormError) {
            SnackBarHelper.showError(context, state.message);
          }
        },
        builder: (context, state) {
          final isSubmitting = state is EmpleadoFormSubmitting;

          return Scaffold(
            appBar: SmartAppBar(
              title: isEditing ? 'Editar Empleado' : 'Nuevo Empleado',
              backgroundColor: AppColors.blue1,
              foregroundColor: AppColors.white,
            ),
            body: GradientContainer(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ======= SECCION: DATOS DEL EMPLEADO =======
                    _buildSectionTitle('Datos del Empleado', Icons.badge),
                    const SizedBox(height: 12),

                    // Usuario selector
                    _buildUsuarioSelector(),
                    const SizedBox(height: 14),

                    // Sede selector
                    CustomDropdown<String>(
                      label: 'Sede',
                      hintText: 'Seleccionar sede...',
                      value: _selectedSedeId,
                      items: sedes
                          .map((sede) => DropdownItem<String>(
                                value: sede.id,
                                label: sede.nombre,
                                leading: const Icon(Icons.store,
                                    size: 18, color: AppColors.blue1),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedSedeId = value),
                      validator: (v) =>
                          v == null ? 'Selecciona una sede' : null,
                      borderColor: AppColors.blue1,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 14),

                    // Cargo
                    CustomText(
                      controller: _cargoController,
                      label: 'Cargo',
                      hintText: 'Ej: Vendedor Senior',
                      prefixIcon: const Icon(Icons.work_outline),
                      borderColor: AppColors.blue1,
                    ),
                    const SizedBox(height: 14),

                    // Departamento
                    CustomText(
                      controller: _departamentoController,
                      label: 'Departamento',
                      hintText: 'Ej: Ventas',
                      prefixIcon: const Icon(Icons.business),
                      borderColor: AppColors.blue1,
                    ),
                    const SizedBox(height: 14),

                    // Fecha de ingreso
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Fecha de Ingreso',
                          prefixIcon:
                              const Icon(Icons.calendar_today, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          isDense: true,
                        ),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(_fechaIngreso),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Tipo contrato
                    CustomDropdown<TipoContrato>(
                      label: 'Tipo de Contrato',
                      hintText: 'Seleccionar...',
                      value: _tipoContrato,
                      items: TipoContrato.values
                          .map((tipo) => DropdownItem<TipoContrato>(
                                value: tipo,
                                label: tipo.label,
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _tipoContrato = v);
                      },
                      borderColor: AppColors.blue1,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 14),

                    // Salario base
                    CustomText(
                      controller: _salarioBaseController,
                      label: 'Salario Base',
                      hintText: '0.00',
                      prefixIcon: const Icon(Icons.attach_money),
                      prefixText: 'S/ ',
                      borderColor: AppColors.blue1,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (double.tryParse(v) == null) return 'Monto invalido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // ======= SECCION: DATOS BANCARIOS =======
                    _buildSectionTitle(
                        'Datos Bancarios', Icons.account_balance),
                    const SizedBox(height: 12),

                    CustomText(
                      controller: _bancoController,
                      label: 'Banco',
                      hintText: 'Ej: BCP, Interbank, BBVA',
                      prefixIcon: const Icon(Icons.account_balance),
                      borderColor: AppColors.blue1,
                    ),
                    const SizedBox(height: 14),

                    CustomText(
                      controller: _numeroCuentaController,
                      label: 'Numero de Cuenta',
                      hintText: 'Numero de cuenta bancaria',
                      prefixIcon: const Icon(Icons.credit_card),
                      borderColor: AppColors.blue1,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),

                    CustomText(
                      controller: _cciController,
                      label: 'CCI',
                      hintText: 'Codigo de Cuenta Interbancario',
                      prefixIcon: const Icon(Icons.credit_card),
                      borderColor: AppColors.blue1,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 28),

                    // ======= SUBMIT =======
                    CustomButton(
                      text:
                          isEditing ? 'Actualizar Empleado' : 'Crear Empleado',
                      backgroundColor: AppColors.blue1,
                      isLoading: isSubmitting,
                      onPressed: isSubmitting ? null : _submit,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.blue3),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.blue3,
          ),
        ),
      ],
    );
  }

  Widget _buildUsuarioSelector() {
    if (_isLoadingUsuarios) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_usuarios.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'No se encontraron usuarios con rol de trabajo. '
                'Registra un usuario primero.',
                style: TextStyle(fontSize: 13, color: Colors.orange),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () {
                setState(() => _isLoadingUsuarios = true);
                _loadUsuarios();
              },
            ),
          ],
        ),
      );
    }

    return AbsorbPointer(
      absorbing: isEditing,
      child: Opacity(
        opacity: isEditing ? 0.6 : 1.0,
        child: CustomDropdown<String>(
          label: 'Usuario',
          hintText: 'Buscar usuario...',
          value: _selectedUsuarioId,
          items: _usuarios.map((u) {
            final rol = u.rolEnEmpresa;
            return DropdownItem<String>(
              value: u.id,
              label: '${u.nombreCompleto} · ${u.dni} · $rol',
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.blue1.withValues(alpha: 0.1),
                child: Text(
                  u.iniciales,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blue1,
                  ),
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedUsuarioId = value;
              if (value != null) {
                _usuarios.firstWhere((u) => u.id == value);
              }
            });
          },
          dropdownStyle: DropdownStyle.searchable,
          showSearchBox: true,
          validator: (v) => v == null ? 'Selecciona un usuario' : null,
          borderColor: AppColors.blue1,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}
