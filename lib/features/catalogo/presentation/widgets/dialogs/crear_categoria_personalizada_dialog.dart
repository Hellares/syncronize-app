import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/utils/resource.dart';
import '../../bloc/categorias_empresa/categorias_empresa_cubit.dart';

/// Diálogo para crear una categoría personalizada
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
    return AlertDialog(
      title: const Text('Crear Categoría Personalizada'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.purple),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta categoría será exclusiva de tu empresa',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Campo nombre (requerido)
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  hintText: 'Ej: Productos Refurbished',
                  border: OutlineInputBorder(),
                ),
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
              const SizedBox(height: 16),

              // Campo descripción (opcional)
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Describe esta categoría...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 200,
              ),
              const SizedBox(height: 16),

              // Campo orden (opcional)
              TextFormField(
                controller: _ordenController,
                decoration: const InputDecoration(
                  labelText: 'Orden de visualización (opcional)',
                  hintText: 'Ej: 1, 2, 3...',
                  border: OutlineInputBorder(),
                  helperText: 'Menor número aparece primero',
                ),
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
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _crearCategoria,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Crear'),
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

    setState(() => _isLoading = false);

    if (result is Success) {
      if (mounted) Navigator.of(context).pop(true);
    } else if (result is Error) {
      final error = result;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
