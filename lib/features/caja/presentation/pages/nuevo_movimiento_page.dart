import 'package:flutter/material.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';
import '../../domain/entities/movimiento_caja.dart';
import '../../domain/usecases/crear_movimiento_usecase.dart';
import '../../../../core/utils/resource.dart';

class NuevoMovimientoPage extends StatefulWidget {
  final String cajaId;

  const NuevoMovimientoPage({super.key, required this.cajaId});

  @override
  State<NuevoMovimientoPage> createState() => _NuevoMovimientoPageState();
}

class _NuevoMovimientoPageState extends State<NuevoMovimientoPage> {
  TipoMovimientoCaja _selectedTipo = TipoMovimientoCaja.ingreso;
  CategoriaMovimientoCaja? _selectedCategoria;
  MetodoPago _selectedMetodoPago = MetodoPago.efectivo;
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  bool _isSubmitting = false;

  List<CategoriaMovimientoCaja> get _categoriasFiltradas =>
      CategoriaMovimientoCaja.porTipo(_selectedTipo);

  @override
  void initState() {
    super.initState();
    _selectedCategoria = _categoriasFiltradas.first;
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Nuevo Movimiento',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
      ),
      body: GradientContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tipo selector
              const AppSubtitle(
                'Tipo de Movimiento',
                fontSize: 14,
                color: AppColors.blue3,
              ),
              const SizedBox(height: 10),
              Row(
                children: TipoMovimientoCaja.values.map((tipo) {
                  final isSelected = _selectedTipo == tipo;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right:
                            tipo == TipoMovimientoCaja.ingreso ? 6 : 0,
                        left: tipo == TipoMovimientoCaja.egreso ? 6 : 0,
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTipo = tipo;
                            _selectedCategoria =
                                CategoriaMovimientoCaja.porTipo(tipo).first;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? tipo.color.withValues(alpha: 0.1)
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? tipo.color
                                  : AppColors.greyLight,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                tipo.icon,
                                size: 20,
                                color: isSelected
                                    ? tipo.color
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tipo.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? tipo.color
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Categoria dropdown
              const AppSubtitle(
                'Categoria',
                fontSize: 14,
                color: AppColors.blue3,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<CategoriaMovimientoCaja>(
                value: _selectedCategoria,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    _selectedCategoria?.icon ?? Icons.category_rounded,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: _categoriasFiltradas
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Row(
                            children: [
                              Icon(cat.icon,
                                  size: 18, color: AppColors.blue3),
                              const SizedBox(width: 10),
                              Text(
                                cat.label,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedCategoria = value);
                },
              ),
              const SizedBox(height: 24),

              // Metodo de pago selector
              const AppSubtitle(
                'Metodo de Pago',
                fontSize: 14,
                color: AppColors.blue3,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MetodoPago.values.map((metodo) {
                  final isSelected = _selectedMetodoPago == metodo;
                  return ChoiceChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          metodo.icon,
                          size: 16,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.blue3,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          metodo.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? AppColors.white
                                : AppColors.blue3,
                          ),
                        ),
                      ],
                    ),
                    selectedColor: AppColors.blue1,
                    backgroundColor: AppColors.white,
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.blue1
                          : AppColors.greyLight,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedMetodoPago = metodo);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Monto
              const AppSubtitle(
                'Monto',
                fontSize: 14,
                color: AppColors.blue3,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _montoController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                  prefixText: 'S/ ',
                  hintText: '0.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),

              // Descripcion
              const AppSubtitle(
                'Descripcion (opcional)',
                fontSize: 14,
                color: AppColors.blue3,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descripcionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Detalle del movimiento...',
                  prefixIcon: const Icon(Icons.note_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Registrar Movimiento',
                  backgroundColor: _selectedTipo.color,
                  height: 48,
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _registrarMovimiento,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _registrarMovimiento() async {
    if (_selectedCategoria == null) {
      SnackBarHelper.showError(context, 'Selecciona una categoria');
      return;
    }

    final monto =
        double.tryParse(_montoController.text.replaceAll(',', '.'));
    if (monto == null || monto <= 0) {
      SnackBarHelper.showError(context, 'Ingresa un monto valido');
      return;
    }

    setState(() => _isSubmitting = true);

    final useCase = locator<CrearMovimientoUseCase>();
    final result = await useCase(
      cajaId: widget.cajaId,
      tipo: _selectedTipo,
      categoria: _selectedCategoria!,
      metodoPago: _selectedMetodoPago,
      monto: monto,
      descripcion: _descripcionController.text.isNotEmpty
          ? _descripcionController.text
          : null,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result is Success<void>) {
      SnackBarHelper.showSuccess(context, 'Movimiento registrado');
      Navigator.of(context).pop(true);
    } else if (result is Error<void>) {
      SnackBarHelper.showError(context, result.message);
    }
  }
}
