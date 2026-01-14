import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/unidades_medida/unidades_medida_cubit.dart';
import '../../bloc/unidades_medida/unidades_medida_state.dart';

/// Diálogo para crear una unidad de medida personalizada
class CrearUnidadPersonalizadaDialog extends StatefulWidget {
  final String empresaId;

  const CrearUnidadPersonalizadaDialog({
    super.key,
    required this.empresaId,
  });

  @override
  State<CrearUnidadPersonalizadaDialog> createState() =>
      _CrearUnidadPersonalizadaDialogState();
}

class _CrearUnidadPersonalizadaDialogState
    extends State<CrearUnidadPersonalizadaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _simboloController = TextEditingController();
  final _codigoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _ordenController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _simboloController.dispose();
    _codigoController.dispose();
    _descripcionController.dispose();
    _ordenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UnidadMedidaCubit, UnidadMedidaState>(
      listener: (context, state) {
        if (state is UnidadActivada) {
          Navigator.of(context).pop(true);
        } else if (state is UnidadMedidaError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: AlertDialog(
        title: const Text('Crear Unidad Personalizada'),
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
                          'Esta unidad será exclusiva de tu empresa',
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
                    hintText: 'Ej: Paquete',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es requerido';
                    }
                    if (value.trim().length < 2) {
                      return 'El nombre debe tener al menos 2 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo símbolo (requerido)
                TextFormField(
                  controller: _simboloController,
                  decoration: const InputDecoration(
                    labelText: 'Símbolo *',
                    hintText: 'Ej: paq',
                    border: OutlineInputBorder(),
                    helperText: 'Abreviatura corta',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El símbolo es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo código (opcional)
                TextFormField(
                  controller: _codigoController,
                  decoration: const InputDecoration(
                    labelText: 'Código SUNAT (opcional)',
                    hintText: 'Ej: ZZ',
                    border: OutlineInputBorder(),
                    helperText: 'Código de 2-3 letras mayúsculas',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 3,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (value.length < 2) {
                        return 'El código debe tener al menos 2 caracteres';
                      }
                      if (!RegExp(r'^[A-Z]+$').hasMatch(value)) {
                        return 'Solo letras mayúsculas';
                      }
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
                    hintText: 'Describe esta unidad...',
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
            onPressed: _isLoading ? null : _crearUnidad,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _crearUnidad() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    context.read<UnidadMedidaCubit>().activarUnidad(
          empresaId: widget.empresaId,
          nombrePersonalizado: _nombreController.text.trim(),
          simboloPersonalizado: _simboloController.text.trim(),
          codigoPersonalizado: _codigoController.text.isNotEmpty
              ? _codigoController.text.trim()
              : null,
          descripcion: _descripcionController.text.isNotEmpty
              ? _descripcionController.text.trim()
              : null,
          orden: _ordenController.text.isNotEmpty
              ? int.tryParse(_ordenController.text)
              : null,
        );
  }
}
