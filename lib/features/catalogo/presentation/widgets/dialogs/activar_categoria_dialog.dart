import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/categoria_maestra.dart';
import '../../bloc/categorias_empresa/categorias_empresa_cubit.dart';

/// Diálogo para activar una categoría maestra
class ActivarCategoriaDialog extends StatefulWidget {
  final CategoriaMaestra maestra;
  final String empresaId;

  const ActivarCategoriaDialog({
    super.key,
    required this.maestra,
    required this.empresaId,
  });

  @override
  State<ActivarCategoriaDialog> createState() => _ActivarCategoriaDialogState();
}

class _ActivarCategoriaDialogState extends State<ActivarCategoriaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreLocalController = TextEditingController();
  final _ordenController = TextEditingController();
  bool _isLoading = false;
  bool _usarNombreLocal = false;

  @override
  void dispose() {
    _nombreLocalController.dispose();
    _ordenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Activar Categoría'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información de la categoría maestra
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.maestra.nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.maestra.descripcion != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.maestra.descripcion!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Opción de usar nombre personalizado
              SwitchListTile(
                title: const Text('Personalizar nombre'),
                subtitle: const Text(
                  'Usar un nombre diferente en tu empresa',
                  style: TextStyle(fontSize: 12),
                ),
                value: _usarNombreLocal,
                onChanged: (value) {
                  setState(() => _usarNombreLocal = value);
                },
                contentPadding: EdgeInsets.zero,
              ),

              // Campo nombre local (condicional)
              if (_usarNombreLocal) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nombreLocalController,
                  decoration: InputDecoration(
                    labelText: 'Nombre personalizado',
                    hintText: 'Ej: ${widget.maestra.nombre} Premium',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_usarNombreLocal &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Ingrese un nombre';
                    }
                    return null;
                  },
                ),
              ],

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
          onPressed: _isLoading ? null : _activarCategoria,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Activar'),
        ),
      ],
    );
  }

  Future<void> _activarCategoria() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final cubit = context.read<CategoriasEmpresaCubit>();

    final result = await cubit.activarCategoria(
      empresaId: widget.empresaId,
      categoriaMaestraId: widget.maestra.id,
      nombreLocal: _usarNombreLocal && _nombreLocalController.text.isNotEmpty
          ? _nombreLocalController.text.trim()
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
