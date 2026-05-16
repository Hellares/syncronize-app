import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/resource.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';
import 'package:syncronize/features/categoria_gasto/domain/entities/categoria_gasto.dart';
import 'package:syncronize/features/categoria_gasto/domain/repositories/categoria_gasto_repository.dart';
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

  List<CategoriaGasto> _categorias = [];
  bool _cargandoCategorias = true;
  String? _categoriaError;
  String? _editId;

  @override
  void initState() {
    super.initState();
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
    final dia = int.tryParse(_diaCtrl.text) ?? 0;
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
      );
    } else {
      cubit.crear(
        nombre: _nombreCtrl.text.trim(),
        categoriaGastoId: _categoriaId!,
        montoEstimado: monto,
        frecuencia: _frecuencia,
        diaVencimiento: dia,
        notas: notas.isEmpty ? null : notas,
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
                    TextFormField(
                      controller: _nombreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                        hintText: 'Ej: Recibo Luz local SJL',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 14),
                    _categoriasField(),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _montoCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Monto estimado *',
                              prefixText: 'S/ ',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                              if (n == null || n <= 0) return 'Monto inválido';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _diaCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              labelText: 'Día venc. *',
                              hintText: '1-31',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              if (n == null || n < 1 || n > 31) {
                                return '1 a 31';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<FrecuenciaGasto>(
                      initialValue: _frecuencia,
                      decoration: const InputDecoration(
                        labelText: 'Frecuencia *',
                        border: OutlineInputBorder(),
                      ),
                      items: FrecuenciaGasto.values
                          .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
                          .toList(),
                      onChanged: (v) => setState(() => _frecuencia = v ?? FrecuenciaGasto.mensual),
                    ),
                    const SizedBox(height: 14),
                    if (widget.isEdit)
                      SwitchListTile(
                        value: _activo,
                        onChanged: (v) => setState(() => _activo = v),
                        title: const Text('Activo'),
                        subtitle: Text(
                          _activo
                              ? 'Aparece en el dashboard y dispara alertas'
                              : 'Oculto del dashboard, no alerta',
                          style: const TextStyle(fontSize: 12),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    if (widget.isEdit) const SizedBox(height: 8),
                    TextFormField(
                      controller: _notasCtrl,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Notas (opcional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: widget.isEdit ? 'Guardar cambios' : 'Crear gasto',
                      onPressed: saving ? null : _submit,
                      isLoading: saving,
                    ),
                    const SizedBox(height: 8),
                    // TODO Fase 6c+: agregar selector de Sede y Proveedor.
                    // Ambos son opcionales en el backend, así que V1 funciona sin ellos.
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _categoriaId,
            decoration: const InputDecoration(
              labelText: 'Categoría *',
              border: OutlineInputBorder(),
            ),
            isExpanded: true,
            items: _categorias
                .map(
                  (c) => DropdownMenuItem<String>(
                    value: c.id,
                    child: Row(
                      children: [
                        Icon(c.iconData, size: 18, color: c.colorValue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(c.nombre, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _categoriaId = v),
            validator: (v) => v == null ? 'Selecciona una categoría' : null,
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          onPressed: _gestionarCategorias,
          icon: const Icon(Icons.add_circle_outline),
          color: AppColors.blue1,
          tooltip: 'Crear/gestionar categorías',
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
