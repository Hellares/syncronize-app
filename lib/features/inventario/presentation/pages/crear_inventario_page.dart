import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/resource.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/inventario.dart';
import '../../domain/usecases/crear_inventario_usecase.dart';

class CrearInventarioPage extends StatefulWidget {
  const CrearInventarioPage({super.key});

  @override
  State<CrearInventarioPage> createState() => _CrearInventarioPageState();
}

class _CrearInventarioPageState extends State<CrearInventarioPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _observacionesController = TextEditingController();

  TipoInventario? _selectedTipo;
  String? _selectedSedeId;
  DateTime? _fechaPlanificada;
  bool _incluirTodosProductos = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final empresaState = context.watch<EmpresaContextCubit>().state;
    final sedes = empresaState is EmpresaContextLoaded
        ? empresaState.context.sedes
        : [];

    return Scaffold(
      appBar: SmartAppBar(
        title: 'Crear Inventario',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
      ),
      body: GradientContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSubtitle(
                  'Nuevo Inventario Fisico',
                  fontSize: 18,
                  color: AppColors.blue3,
                ),
                const SizedBox(height: 20),
                // Nombre
                CustomText(
                  controller: _nombreController,
                  label: 'Nombre del Inventario',
                  hintText: 'Ej: Inventario Mensual Marzo',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                // Tipo inventario
                CustomDropdown<TipoInventario>(
                  label: 'Tipo de Inventario',
                  hintText: 'Seleccione un tipo',
                  value: _selectedTipo,
                  items: TipoInventario.values
                      .map(
                        (tipo) => DropdownItem<TipoInventario>(
                          value: tipo,
                          label: tipo.label,
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedTipo = value);
                  },
                  validator: (value) {
                    if (value == null) return 'Seleccione un tipo';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                // Sede
                CustomDropdown<String>(
                  label: 'Sede',
                  hintText: 'Seleccione una sede',
                  value: _selectedSedeId,
                  items: sedes
                      .map(
                        (sede) => DropdownItem<String>(
                          value: sede.id,
                          label: sede.nombre,
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedSedeId = value);
                  },
                  validator: (value) {
                    if (value == null || (value is String && value.isEmpty)) {
                      return 'Seleccione una sede';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                // Fecha planificada
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _fechaPlanificada ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _fechaPlanificada = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Fecha Planificada',
                      prefixIcon: const Icon(Icons.calendar_today_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      _fechaPlanificada != null
                          ? DateFormat('dd/MM/yyyy').format(_fechaPlanificada!)
                          : 'Seleccionar fecha',
                      style: TextStyle(
                        fontSize: 14,
                        color: _fechaPlanificada != null
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Descripcion
                CustomText(
                  controller: _descripcionController,
                  label: 'Descripcion',
                  hintText: 'Opcional: descripcion del inventario',
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                // Observaciones
                CustomText(
                  controller: _observacionesController,
                  label: 'Observaciones',
                  hintText: 'Opcional: notas adicionales',
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                // Incluir todos los productos
                SwitchListTile(
                  title: const Text(
                    'Incluir todos los productos',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: const Text(
                    'Agrega automaticamente todos los productos con stock en la sede seleccionada',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  value: _incluirTodosProductos,
                  onChanged: (value) {
                    setState(() => _incluirTodosProductos = value);
                  },
                  activeColor: AppColors.blue1,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Crear Inventario',
                    onPressed: _isLoading ? null : _crearInventario,
                  ),
                ),
                if (_isLoading) ...[
                  const SizedBox(height: 12),
                  const Center(child: CircularProgressIndicator()),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _crearInventario() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTipo == null) {
      SnackBarHelper.showError(context, 'Seleccione un tipo de inventario');
      return;
    }
    if (_selectedSedeId == null) {
      SnackBarHelper.showError(context, 'Seleccione una sede');
      return;
    }

    setState(() => _isLoading = true);

    final data = <String, dynamic>{
      'nombre': _nombreController.text.trim(),
      'tipoInventario': _selectedTipo!.apiValue,
      'sedeId': _selectedSedeId,
      'incluirTodosProductos': _incluirTodosProductos,
    };

    if (_fechaPlanificada != null) {
      data['fechaPlanificada'] = _fechaPlanificada!.toIso8601String();
    }
    if (_descripcionController.text.trim().isNotEmpty) {
      data['descripcion'] = _descripcionController.text.trim();
    }
    if (_observacionesController.text.trim().isNotEmpty) {
      data['observaciones'] = _observacionesController.text.trim();
    }

    try {
      final useCase = locator<CrearInventarioUseCase>();
      final result = await useCase(data: data);

      if (!mounted) return;

      if (result is Success<Inventario>) {
        SnackBarHelper.showSuccess(context, 'Inventario creado exitosamente');
        context.pop(true);
      } else if (result is Error<Inventario>) {
        SnackBarHelper.showError(context, result.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
