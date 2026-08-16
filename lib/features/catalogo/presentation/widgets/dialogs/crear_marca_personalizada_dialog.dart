import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';
import 'package:syncronize/core/widgets/styled_dialog.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../../../core/utils/resource.dart';
import '../../bloc/marcas_empresa/marcas_empresa_cubit.dart';

/// Diálogo para crear una marca personalizada.
///
/// Gemelo del de categorías: mismo `StyledDialog`, mismos inputs y el acento
/// azul de la pantalla a la que pertenece. Antes era un `AlertDialog` pelado
/// con `TextFormField` de Material y acento violeta.
class CrearMarcaPersonalizadaDialog extends StatefulWidget {
  final String empresaId;

  const CrearMarcaPersonalizadaDialog({
    super.key,
    required this.empresaId,
  });

  @override
  State<CrearMarcaPersonalizadaDialog> createState() =>
      _CrearMarcaPersonalizadaDialogState();
}

class _CrearMarcaPersonalizadaDialogState
    extends State<CrearMarcaPersonalizadaDialog> {
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
      icon: Icons.sell_outlined,
      titulo: 'Nueva marca',
      // El "es exclusiva de tu empresa" vivía en un recuadro de cuatro
      // renglones para decir una línea; como subtítulo dice lo mismo y el
      // diálogo entra sin scroll.
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
                hintText: 'Ej: Mi Marca Exclusiva',
                prefixIcon: const Icon(Icons.label_outline),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  // Dos y no tres como en categorías: hay marcas de dos letras
                  // (3M, LG) y el mínimo de categorías las rechazaría.
                  if (value.trim().length < 2) {
                    return 'El nombre debe tener al menos 2 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CustomText(
                controller: _descripcionController,
                borderColor: AppColors.blue1,
                label: 'Descripción (opcional)',
                hintText: 'Describe esta marca…',
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
            onPressed: _crearMarca,
          ),
        ),
      ],
    );
  }

  Future<void> _crearMarca() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final cubit = context.read<MarcasEmpresaCubit>();

    final result = await cubit.activarMarca(
      empresaId: widget.empresaId,
      nombrePersonalizado: _nombreController.text.trim(),
      descripcionPersonalizada: _descripcionController.text.isNotEmpty
          ? _descripcionController.text.trim()
          : null,
      orden: _ordenController.text.isNotEmpty
          ? int.tryParse(_ordenController.text)
          : null,
    );

    // El `mounted` va ANTES del setState: si se cerró el diálogo mientras se
    // creaba, el setState corría sobre un widget muerto.
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result is Success) {
      Navigator.of(context).pop(true);
    } else if (result is Error) {
      SnackBarHelper.showError(context, result.message);
    }
  }
}
