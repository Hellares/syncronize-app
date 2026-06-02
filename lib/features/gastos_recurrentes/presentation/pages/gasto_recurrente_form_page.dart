import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/resource.dart';
import 'package:syncronize/core/widgets/currency/currency_textfield.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import 'package:syncronize/features/categoria_gasto/domain/entities/categoria_gasto.dart';
import 'package:syncronize/features/categoria_gasto/domain/repositories/categoria_gasto_repository.dart';
import 'package:syncronize/core/storage/local_storage_service.dart';
import 'package:syncronize/core/constants/storage_constants.dart';
import 'package:syncronize/core/widgets/custom_proveedor_selector.dart';
import 'package:syncronize/features/empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import 'package:syncronize/features/empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import 'package:syncronize/features/empresa/domain/entities/sede.dart';
import '../../domain/entities/gasto_recurrente.dart';
import '../bloc/gasto_form_cubit.dart';
import '../bloc/gasto_form_state.dart';

class GastoRecurrenteFormPage extends StatelessWidget {
  final String? gastoId; // null = crear, no null = editar

  const GastoRecurrenteFormPage({super.key, this.gastoId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = locator<GastoFormCubit>();
        if (gastoId != null) cubit.cargarParaEditar(gastoId!);
        return cubit;
      },
      child: _FormView(isEdit: gastoId != null),
    );
  }
}

class _FormView extends StatefulWidget {
  final bool isEdit;
  const _FormView({required this.isEdit});

  @override
  State<_FormView> createState() => _FormViewState();
}

class _FormViewState extends State<_FormView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _diaCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  FrecuenciaGasto _frecuencia = FrecuenciaGasto.mensual;
  String? _categoriaId;
  bool _activo = true;

  // Sede y proveedor (opcionales). El backend, repo y cubit ya los aceptan.
  String? _sedeId;
  String? _proveedorId;
  String? _proveedorNombre;
  late final String _empresaId;

  List<CategoriaGasto> _categorias = [];
  bool _cargandoCategorias = true;
  String? _categoriaError;
  String? _editId;

  @override
  void initState() {
    super.initState();
    _empresaId =
        locator<LocalStorageService>().getString(StorageConstants.tenantId) ??
            '';
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    final repo = locator<CategoriaGastoRepository>();
    final r = await repo.listar(tipo: 'EGRESO');
    if (!mounted) return;
    setState(() {
      _cargandoCategorias = false;
      if (r is Success<List<CategoriaGasto>>) {
        _categorias = r.data;
      } else if (r is Error<List<CategoriaGasto>>) {
        _categoriaError = r.message;
      }
    });
  }

  void _hidratarDesdeEntity(GastoRecurrente g) {
    _editId = g.id;
    _nombreCtrl.text = g.nombre;
    _montoCtrl.text = g.montoEstimado.toStringAsFixed(2);
    _diaCtrl.text = g.diaVencimiento.toString();
    _notasCtrl.text = g.notas ?? '';
    _frecuencia = g.frecuencia;
    _categoriaId = g.categoriaGastoId;
    _activo = g.activo;
    _sedeId = g.sedeId;
    _proveedorId = g.proveedorId;
    _proveedorNombre = g.proveedorNombre;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _montoCtrl.dispose();
    _diaCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaId == null) {
      SnackBarHelper.showError(context, 'Selecciona una categoría');
      return;
    }
    final monto = double.tryParse(_montoCtrl.text.replaceAll(',', '.')) ?? 0;
    if (monto <= 0) {
      SnackBarHelper.showError(context, 'El monto debe ser mayor a 0');
      return;
    }
    final dia = int.tryParse(_diaCtrl.text) ?? 0;
    if (dia < 1 || dia > 31) {
      SnackBarHelper.showError(context, 'El día de vencimiento debe estar entre 1 y 31');
      return;
    }
    final notas = _notasCtrl.text.trim();
    final cubit = context.read<GastoFormCubit>();

    if (widget.isEdit && _editId != null) {
      cubit.actualizar(
        id: _editId!,
        nombre: _nombreCtrl.text.trim(),
        categoriaGastoId: _categoriaId,
        montoEstimado: monto,
        frecuencia: _frecuencia,
        diaVencimiento: dia,
        activo: _activo,
        notas: notas.isEmpty ? null : notas,
        sedeId: _sedeId,
        proveedorId: _proveedorId,
      );
    } else {
      cubit.crear(
        nombre: _nombreCtrl.text.trim(),
        categoriaGastoId: _categoriaId!,
        montoEstimado: monto,
        frecuencia: _frecuencia,
        diaVencimiento: dia,
        notas: notas.isEmpty ? null : notas,
        sedeId: _sedeId,
        proveedorId: _proveedorId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: widget.isEdit ? 'Editar gasto recurrente' : 'Nuevo gasto recurrente',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
      ),
      body: GradientContainer(
        child: BlocConsumer<GastoFormCubit, GastoFormState>(
          listener: (context, state) {
            if (state is GastoFormEditing) {
              _hidratarDesdeEntity(state.gasto);
            } else if (state is GastoFormSaved) {
              SnackBarHelper.showSuccess(
                context,
                widget.isEdit ? 'Gasto actualizado' : 'Gasto creado',
              );
              Navigator.of(context).pop(true);
            } else if (state is GastoFormError) {
              SnackBarHelper.showError(context, state.message);
            }
          },
          builder: (context, state) {
            if (state is GastoFormLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final saving = state is GastoFormSaving;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomText(
                      controller: _nombreCtrl,
                      label: 'Nombre',
                      hintText: 'Ej: Recibo Luz local SJL',
                      required: true,
                      borderColor: AppColors.blue1,
                      maxLength: 120,
                      autovalidateMode: AutovalidateModeX.onUnfocus,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requerido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _categoriasField(),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: CurrencyTextField(
                            controller: _montoCtrl,
                            label: 'Monto estimado',
                            borderColor: AppColors.blue1,
                            hintText: '0.00',
                            requiredField: true,
                            //allowZero: false,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: CustomText(
                            controller: _diaCtrl,
                            label: 'Día vencimiento',
                            hintText: '1-31',
                            required: true,
                            borderColor: AppColors.blue1,
                            fieldType: FieldType.number,
                            maxLength: 2,
                            autovalidateMode: AutovalidateModeX.onUnfocus,
                            // validator: (v) {
                            //   final n = int.tryParse(v ?? '');
                            //   if (n == null || n < 1 || n > 31) return '1 a 31';
                            //   return null;
                            // },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    CustomDropdown<FrecuenciaGasto>(
                      label: 'Frecuencia',
                      value: _frecuencia,
                      borderColor: AppColors.blue1,
                      hintText: 'Selecciona la frecuencia',
                      items: FrecuenciaGasto.values
                          .map((f) => DropdownItem<FrecuenciaGasto>(
                                value: f,
                                label: f.label,
                                leading: Icon(
                                  _frecuenciaIcon(f),
                                  size: 16,
                                  color: AppColors.blue1,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _frecuencia = v);
                      },
                      validator: (v) => v == null ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 14),
                    if (widget.isEdit) ...[
                      SwitchListTile(
                        value: _activo,
                        onChanged: (v) => setState(() => _activo = v),
                        title: const Text(
                          'Activo',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          _activo
                              ? 'Aparece en el dashboard y dispara alertas'
                              : 'Oculto del dashboard, no alerta',
                          style: const TextStyle(fontSize: 11),
                        ),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        activeThumbColor: AppColors.blue1,
                      ),
                      const SizedBox(height: 8),
                    ],
                    CustomText(
                      controller: _notasCtrl,
                      label: 'Notas (opcional)',
                      hintText: 'Detalles o referencias internas',
                      borderColor: AppColors.blue1,
                      maxLines: 3,
                      maxLength: 500,
                      height: null,
                      enableVoiceInput: true,
                    ),
                    const SizedBox(height: 12),
                    _sedeField(),
                    const SizedBox(height: 12),
                    CustomProveedorSelector(
                      empresaId: _empresaId,
                      proveedorId: _proveedorId,
                      proveedorNombre: _proveedorNombre,
                      label: 'Proveedor (opcional)',
                      onSelected: (result) {
                        setState(() {
                          _proveedorId = result.proveedorId;
                          _proveedorNombre = result.nombre;
                        });
                      },
                      onCleared: () {
                        setState(() {
                          _proveedorId = null;
                          _proveedorNombre = null;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      borderColor: AppColors.blue1,
                      textColor: AppColors.blue1,
                      text: widget.isEdit ? 'Guardar cambios' : 'Crear gasto',
                      onPressed: saving ? null : _submit,
                      isLoading: saving,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Dropdown de Sede (opcional). Las sedes salen del contexto de empresa
  /// ya cargado; incluye la opción "Sin sede asignada" (value '' → null).
  Widget _sedeField() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    final sedes = empresaState is EmpresaContextLoaded
        ? empresaState.context.sedes.where((s) => s.isActive).toList()
        : <Sede>[];
    if (sedes.isEmpty) return const SizedBox.shrink();

    return CustomDropdown<String>(
      borderColor: AppColors.blue1,
      label: 'Sede (opcional)',
      value: _sedeId ?? '',
      items: [
        const DropdownItem(value: '', label: 'Sin sede asignada'),
        ...sedes.map((s) => DropdownItem(
              value: s.id,
              label: s.esPrincipal ? '${s.nombre} (Principal)' : s.nombre,
            )),
      ],
      onChanged: (value) => setState(() {
        _sedeId = (value == null || value.isEmpty) ? null : value;
      }),
    );
  }

  IconData _frecuenciaIcon(FrecuenciaGasto f) {
    switch (f) {
      case FrecuenciaGasto.mensual:
        return Icons.calendar_view_month;
      case FrecuenciaGasto.bimestral:
        return Icons.calendar_view_week;
      case FrecuenciaGasto.trimestral:
        return Icons.calendar_today;
      case FrecuenciaGasto.anual:
        return Icons.event_note;
    }
  }

  Widget _categoriasField() {
    if (_cargandoCategorias) {
      return const LinearProgressIndicator(minHeight: 2);
    }
    if (_categoriaError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 18, color: AppColors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(_categoriaError!, style: const TextStyle(fontSize: 12))),
            TextButton(
              onPressed: () {
                setState(() {
                  _cargandoCategorias = true;
                  _categoriaError = null;
                });
                _cargarCategorias();
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_categorias.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No hay categorías de tipo EGRESO en tu empresa todavía.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _gestionarCategorias,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Gestionar categorías'),
                style: TextButton.styleFrom(foregroundColor: AppColors.blue1),
              ),
            ),
          ],
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: CustomDropdown<String>(
            label: 'Categoría',
            value: _categoriaId,
            borderColor: AppColors.blue1,
            hintText: 'Selecciona una categoría',
            dropdownStyle: _categorias.length > 8
                ? DropdownStyle.searchable
                : DropdownStyle.standard,
            showSearchBox: _categorias.length > 8,
            items: _categorias
                .map(
                  (c) => DropdownItem<String>(
                    value: c.id,
                    label: c.nombre,
                    leading: Icon(c.iconData, size: 16, color: c.colorValue),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _categoriaId = v),
            validator: (v) => v == null ? 'Selecciona una categoría' : null,
          ),
        ),
        const SizedBox(width: 6),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: IconButton(
            onPressed: _gestionarCategorias,
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.blue1,
            tooltip: 'Crear/gestionar categorías',
            iconSize: 22,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  Future<void> _gestionarCategorias() async {
    await context.push('/empresa/categorias-gasto');
    if (!mounted) return;
    // Al volver, recargar las categorías por si el user creó alguna.
    setState(() {
      _cargandoCategorias = true;
      _categoriaError = null;
    });
    await _cargarCategorias();
  }
}
