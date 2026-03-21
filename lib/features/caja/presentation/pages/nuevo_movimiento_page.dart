import 'package:flutter/material.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/core/widgets/currency/currency_textfield.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../domain/entities/movimiento_caja.dart';
import '../../domain/usecases/crear_movimiento_usecase.dart';
import '../../../../core/utils/resource.dart';
import '../../../categoria_gasto/domain/entities/categoria_gasto.dart';
import '../../../categoria_gasto/domain/usecases/get_categorias_gasto_usecase.dart';

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

  // CategoriaGasto personalizada
  List<CategoriaGasto> _categoriasGasto = [];
  CategoriaGasto? _selectedCategoriaGasto;
  bool _loadingCategoriasGasto = false;

  List<CategoriaMovimientoCaja> get _categoriasFiltradas =>
      CategoriaMovimientoCaja.porTipo(_selectedTipo);

  /// Determina si la categoria seleccionada acepta una CategoriaGasto personalizada
  bool get _mostrarDropdownCategoriaGasto {
    return _selectedCategoria == CategoriaMovimientoCaja.gastoOperativo ||
        _selectedCategoria == CategoriaMovimientoCaja.otroEgreso ||
        _selectedCategoria == CategoriaMovimientoCaja.otroIngreso;
  }

  @override
  void initState() {
    super.initState();
    _selectedCategoria = _categoriasFiltradas.first;
    _cargarCategoriasGasto();
  }

  Future<void> _cargarCategoriasGasto() async {
    setState(() => _loadingCategoriasGasto = true);
    final useCase = locator<GetCategoriasGastoUseCase>();
    final result = await useCase();
    if (!mounted) return;
    if (result is Success<List<CategoriaGasto>>) {
      setState(() {
        _categoriasGasto = result.data;
        _loadingCategoriasGasto = false;
      });
    } else {
      setState(() => _loadingCategoriasGasto = false);
    }
  }

  List<CategoriaGasto> get _categoriasGastoFiltradas {
    if (_selectedCategoria == CategoriaMovimientoCaja.otroIngreso) {
      return _categoriasGasto.where((c) => c.tipo == 'INGRESO').toList();
    }
    return _categoriasGasto.where((c) => c.tipo == 'EGRESO').toList();
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
                fontSize: 12,
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
                            _selectedCategoriaGasto = null;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? tipo.color.withValues(alpha: 0.1)
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? tipo.color
                                  : AppColors.greyLight,
                              width: isSelected ? 1 : 0.6,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                tipo.icon,
                                size: 18,
                                color: isSelected
                                    ? tipo.color
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tipo.label,
                                style: TextStyle(
                                  fontSize: 13,
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
              CustomDropdown<CategoriaMovimientoCaja>(
                label: 'Categoria',
                hintText: 'Selecciona una categoria',
                value: _selectedCategoria,
                borderColor: AppColors.blue1,
                items: _categoriasFiltradas
                    .map((cat) => DropdownItem(
                          value: cat,
                          label: cat.label,
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedCategoria = value);
                },
              ),
              const SizedBox(height: 24),

              // Categoria de gasto personalizada (condicional)
              if (_mostrarDropdownCategoriaGasto) ...[
                if (_loadingCategoriasGasto)
                  const SizedBox.shrink()
                else
                  CustomDropdown<CategoriaGasto?>(
                    label: 'Categoria de Gasto (opcional)',
                    hintText: 'Sin categoria',
                    value: _selectedCategoriaGasto,
                    borderColor: AppColors.blue1,
                    items: [
                      const DropdownItem<CategoriaGasto?>(value: null, label: 'Sin categoria'),
                      ..._categoriasGastoFiltradas.map((cat) => DropdownItem<CategoriaGasto?>(
                        value: cat,
                        label: cat.nombre,
                      )),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedCategoriaGasto = value);
                    },
                  ),
                const SizedBox(height: 24),
              ],

              // Metodo de pago selector
              const AppSubtitle(
                'Metodo de Pago',
                fontSize: 12,
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
                            fontSize: 11,
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
              CurrencyTextField(
                controller: _montoController,
                label: 'Monto',
                borderColor: _selectedTipo.color,
                hintText: '0.00',
              ),
              const SizedBox(height: 24),

              // Descripcion
              CustomText(
                controller: _descripcionController,
                label: 'Descripcion (opcional)',
                hintText: 'Detalle del movimiento...',
                borderColor: AppColors.blue1,
                maxLines: 3,
                enableVoiceInput: true,
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Registrar Movimiento',
                  backgroundColor: _selectedTipo.color,
                  height: 35,
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
      categoriaGastoId: _selectedCategoriaGasto?.id,
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
