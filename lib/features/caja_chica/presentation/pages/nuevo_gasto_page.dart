import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../../core/utils/resource.dart';
import '../../../categoria_gasto/domain/entities/categoria_gasto.dart';
import '../../../categoria_gasto/domain/usecases/get_categorias_gasto_usecase.dart';
import '../../../cuentas_por_pagar/domain/usecases/comprobante_pago_usecases.dart';
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

  File? _comprobante;
  final _picker = ImagePicker();

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
                fontSize: 10,
                color: AppColors.blue3,
              ),
              // const SizedBox(height: 10),
              CustomText(
                controller: _montoController,
                // Sin fieldType.number: ese formatter elimina el punto y
                // rompería los decimales. El keyboard decimal basta.
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                borderColor: AppColors.blue1,
                hintText: '0.00',
                prefixText: 'S/ ',
                prefixIcon: const Icon(Icons.attach_money_rounded),
              ),
              const SizedBox(height: 14),

              // Descripcion
              const AppSubtitle(
                'Descripcion',
                fontSize: 10,
                color: AppColors.blue3,
              ),
              // const SizedBox(height: 10),
              CustomText(
                controller: _descripcionController,
                maxLines: 3,
                height: null,
                borderColor: AppColors.blue1,
                hintText: 'Detalle del gasto...',
                prefixIcon: const Icon(Icons.note_rounded),
              ),
              const SizedBox(height: 14),

              // Categoria
              const AppSubtitle(
                'Categoria',
                fontSize: 10,
                color: AppColors.blue3,
              ),
              // const SizedBox(height: 10),
              if (_isLoadingCategorias)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                CustomDropdown<CategoriaGasto>(
                  value: _selectedCategoria,
                  borderColor: AppColors.blue1,
                  hintText: 'Seleccionar categoria',
                  // El ícono del campo refleja la categoría seleccionada.
                  prefixIcon: Icon(
                    _selectedCategoria?.iconData ?? Icons.category_rounded,
                    color: _selectedCategoria?.colorValue ?? AppColors.blue1,
                    size: 18,
                  ),
                  items: _categorias
                      .map((cat) => DropdownItem<CategoriaGasto>(
                            value: cat,
                            label: cat.nombre,
                            leading: Icon(
                              cat.iconData,
                              size: 18,
                              color: cat.colorValue,
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategoria = value);
                  },
                ),
              const SizedBox(height: 24),

              // Comprobante (foto del recibo, opcional)
              const AppSubtitle(
                'Comprobante (opcional)',
                fontSize: 10,
                color: AppColors.blue3,
              ),
              const SizedBox(height: 10),
              _buildComprobantePicker(),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Registrar Gasto',
                  backgroundColor: const Color(0xFFF54D85),
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

  Widget _buildComprobantePicker() {
    if (_comprobante == null) {
      return InkWell(
        onTap: _isSubmitting ? null : _pickComprobante,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.blue1.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              const Icon(Icons.add_a_photo_rounded, color: AppColors.blue1, size: 16,),
              const SizedBox(width: 12),
              const AppSubtitle('Adjuntar foto del comprobante',
                  fontSize: 10, color: AppColors.blue1),
            ],
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.greendark.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(_comprobante!,
                width: 48, height: 48, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: AppSubtitle('Comprobante adjuntado',
                fontSize: 10, color: AppColors.greendark),
          ),
          IconButton(
            onPressed: _isSubmitting
                ? null
                : () => setState(() => _comprobante = null),
            icon: const Icon(Icons.close, size: 20),
          ),
          IconButton(
            onPressed: _isSubmitting ? null : _pickComprobante,
            icon: const Icon(Icons.edit, size: 20),
          ),
        ],
      ),
    );
  }

  Future<void> _pickComprobante() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Elegir de galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (picked != null) setState(() => _comprobante = File(picked.path));
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

    // Si adjuntó comprobante, súbelo primero para obtener la URL (S3).
    String? comprobanteUrl;
    if (_comprobante != null) {
      final up =
          await locator<SubirComprobantePagoUseCase>().call(_comprobante!.path);
      if (!mounted) return;
      if (up is Success<String>) {
        comprobanteUrl = up.data;
      } else {
        setState(() => _isSubmitting = false);
        SnackBarHelper.showError(
            context, 'No se pudo subir el comprobante. Intenta de nuevo.');
        return;
      }
    }

    final useCase = locator<RegistrarGastoUseCase>();
    final result = await useCase(
      cajaChicaId: widget.cajaChicaId,
      monto: monto,
      descripcion: _descripcionController.text.trim(),
      categoriaGastoId: _selectedCategoria!.id,
      comprobanteUrl: comprobanteUrl,
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
