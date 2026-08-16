import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';
import 'package:syncronize/core/widgets/styled_dialog.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../../../core/utils/resource.dart';
import '../../bloc/categorias_empresa/categorias_empresa_cubit.dart';

/// Diálogo para crear una categoría personalizada.
///
/// Usa `StyledDialog` y los inputs del proyecto. Antes era un `AlertDialog`
/// pelado con `TextFormField` de Material: no compartía nada con el resto del
/// módulo —ni el borde, ni el encabezado, ni los botones— y encima el acento
/// era violeta cuando toda la pantalla de categorías es azul.
class CrearCategoriaPersonalizadaDialog extends StatefulWidget {
  final String empresaId;

  const CrearCategoriaPersonalizadaDialog({
    super.key,
    required this.empresaId,
  });

  @override
  State<CrearCategoriaPersonalizadaDialog> createState() =>
      _CrearCategoriaPersonalizadaDialogState();
}

class _CrearCategoriaPersonalizadaDialogState
    extends State<CrearCategoriaPersonalizadaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _ordenController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _ordenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      accentColor: AppColors.blue1,
      icon: Icons.new_label_outlined,
      titulo: 'Nueva categoría',
      // El aviso de "es exclusiva de tu empresa" vivía en un recuadro violeta
      // que ocupaba cuatro renglones para decir una línea. Como subtítulo dice
      // lo mismo y el diálogo entra sin scroll.
      subtitulo: 'Exclusiva de tu empresa',
      content: [
        Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomText(
                controller: _nombreController,
                borderColor: AppColors.blue1,
                label: 'Nombre *',
                hintText: 'Ej: Productos Refurbished',
                prefixIcon: const Icon(Icons.label_outline),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  if (value.trim().length < 3) {
                    return 'El nombre debe tener al menos 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CustomText(
                controller: _descripcionController,
                borderColor: AppColors.blue1,
                label: 'Descripción (opcional)',
                hintText: 'Describe esta categoría…',
                maxLines: 3,
                maxLength: 200,
              ),
              const SizedBox(height: 12),
              CustomText(
                controller: _ordenController,
                borderColor: AppColors.blue1,
                label: 'Orden (opcional)',
                hintText: 'Ej: 1, 2, 3…',
                helperText: 'El menor número aparece primero',
                prefixIcon: const Icon(Icons.sort),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final orden = int.tryParse(value);
                    if (orden == null || orden < 1) {
                      return 'Ingrese un número válido mayor a 0';
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
      actions: [
        Expanded(
          child: CustomButton(
            text: 'Cancelar',
            backgroundColor: AppColors.white,
            borderColor: Colors.grey.shade400,
            textColor: Colors.grey.shade700,
            enabled: !_isLoading,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
        Expanded(
          child: CustomButton(
            text: _isLoading ? 'Creando…' : 'Crear',
            backgroundColor: AppColors.blue1,
            enabled: !_isLoading,
            icon: const Icon(Icons.check, size: 16, color: Colors.white),
            onPressed: _crearCategoria,
          ),
        ),
      ],
    );
  }

  Future<void> _crearCategoria() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final cubit = context.read<CategoriasEmpresaCubit>();

    final result = await cubit.activarCategoria(
      empresaId: widget.empresaId,
      nombrePersonalizado: _nombreController.text.trim(),
      descripcionPersonalizada: _descripcionController.text.isNotEmpty
          ? _descripcionController.text.trim()
          : null,
      orden: _ordenController.text.isNotEmpty
          ? int.tryParse(_ordenController.text)
          : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result is Success) {
      Navigator.of(context).pop(true);
    } else if (result is Error) {
      SnackBarHelper.showError(context, result.message);
    }
  }
}
