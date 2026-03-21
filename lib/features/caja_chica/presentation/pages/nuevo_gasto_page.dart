import 'package:flutter/material.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';
import '../../../../core/utils/resource.dart';
import '../../../categoria_gasto/domain/entities/categoria_gasto.dart';
import '../../../categoria_gasto/domain/usecases/get_categorias_gasto_usecase.dart';
import '../../domain/entities/gasto_caja_chica.dart';
import '../../domain/usecases/registrar_gasto_usecase.dart';

class NuevoGastoPage extends StatefulWidget {
  final String cajaChicaId;

  const NuevoGastoPage({super.key, required this.cajaChicaId});

  @override
  State<NuevoGastoPage> createState() => _NuevoGastoPageState();
}

class _NuevoGastoPageState extends State<NuevoGastoPage> {
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();

  List<CategoriaGasto> _categorias = [];
  CategoriaGasto? _selectedCategoria;
  bool _isLoadingCategorias = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategorias();
  }

  Future<void> _loadCategorias() async {
    final useCase = locator<GetCategoriasGastoUseCase>();
    final result = await useCase(tipo: 'EGRESO');

    if (!mounted) return;

    if (result is Success<List<CategoriaGasto>>) {
      setState(() {
        _categorias = result.data;
        _isLoadingCategorias = false;
      });
    } else if (result is Error<List<CategoriaGasto>>) {
      setState(() {
        _isLoadingCategorias = false;
      });
      SnackBarHelper.showError(context, 'Error al cargar categorias');
    }
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
        title: 'Nuevo Gasto',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
      ),
      body: GradientContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                'Descripcion',
                fontSize: 14,
                color: AppColors.blue3,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descripcionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Detalle del gasto...',
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
              const SizedBox(height: 24),

              // Categoria
              const AppSubtitle(
                'Categoria',
                fontSize: 14,
                color: AppColors.blue3,
              ),
              const SizedBox(height: 10),
              if (_isLoadingCategorias)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                DropdownButtonFormField<CategoriaGasto>(
                  value: _selectedCategoria,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      _selectedCategoria?.iconData ?? Icons.category_rounded,
                      color: _selectedCategoria?.colorValue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  hint: const Text(
                    'Seleccionar categoria',
                    style: TextStyle(fontSize: 14),
                  ),
                  items: _categorias
                      .map((cat) => DropdownMenuItem<CategoriaGasto>(
                            value: cat,
                            child: Row(
                              children: [
                                Icon(
                                  cat.iconData,
                                  size: 18,
                                  color: cat.colorValue,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  cat.nombre,
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
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Registrar Gasto',
                  backgroundColor: const Color(0xFFF54D85),
                  height: 48,
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _registrarGasto,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _registrarGasto() async {
    final monto =
        double.tryParse(_montoController.text.replaceAll(',', '.'));
    if (monto == null || monto <= 0) {
      SnackBarHelper.showError(context, 'Ingresa un monto valido');
      return;
    }

    if (_descripcionController.text.trim().isEmpty) {
      SnackBarHelper.showError(context, 'Ingresa una descripcion');
      return;
    }

    if (_selectedCategoria == null) {
      SnackBarHelper.showError(context, 'Selecciona una categoria');
      return;
    }

    setState(() => _isSubmitting = true);

    final useCase = locator<RegistrarGastoUseCase>();
    final result = await useCase(
      cajaChicaId: widget.cajaChicaId,
      monto: monto,
      descripcion: _descripcionController.text.trim(),
      categoriaGastoId: _selectedCategoria!.id,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result is Success<GastoCajaChica>) {
      SnackBarHelper.showSuccess(context, 'Gasto registrado');
      Navigator.of(context).pop(true);
    } else if (result is Error<GastoCajaChica>) {
      SnackBarHelper.showError(context, result.message);
    }
  }
}
