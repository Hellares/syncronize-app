import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/unidad_medida.dart';
import '../../bloc/unidades_medida/unidades_medida_cubit.dart';
import '../../bloc/unidades_medida/unidades_medida_state.dart';

/// Diálogo para activar una unidad de medida maestra
class ActivarUnidadDialog extends StatefulWidget {
  final UnidadMedidaMaestra maestra;
  final String empresaId;

  const ActivarUnidadDialog({
    super.key,
    required this.maestra,
    required this.empresaId,
  });

  @override
  State<ActivarUnidadDialog> createState() => _ActivarUnidadDialogState();
}

class _ActivarUnidadDialogState extends State<ActivarUnidadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreLocalController = TextEditingController();
  final _simboloLocalController = TextEditingController();
  final _ordenController = TextEditingController();
  bool _isLoading = false;
  bool _usarNombreLocal = false;
  bool _usarSimboloLocal = false;

  @override
  void dispose() {
    _nombreLocalController.dispose();
    _simboloLocalController.dispose();
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
        title: const Text('Activar Unidad de Medida'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información de la unidad maestra
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
                        widget.maestra.displayConCodigo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Categoría: ${widget.maestra.categoria.label}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
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
                      hintText: 'Ej: ${widget.maestra.nombre} local',
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

                // Opción de usar símbolo personalizado
                SwitchListTile(
                  title: const Text('Personalizar símbolo'),
                  subtitle: const Text(
                    'Usar un símbolo diferente',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _usarSimboloLocal,
                  onChanged: (value) {
                    setState(() => _usarSimboloLocal = value);
                  },
                  contentPadding: EdgeInsets.zero,
                ),

                // Campo símbolo local (condicional)
                if (_usarSimboloLocal) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _simboloLocalController,
                    decoration: InputDecoration(
                      labelText: 'Símbolo personalizado',
                      hintText: widget.maestra.simbolo != null
                          ? 'Ej: ${widget.maestra.simbolo}'
                          : 'Ej: u',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (_usarSimboloLocal &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Ingrese un símbolo';
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
            onPressed: _isLoading ? null : _activarUnidad,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Activar'),
          ),
        ],
      ),
    );
  }

  Future<void> _activarUnidad() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    context.read<UnidadMedidaCubit>().activarUnidad(
          empresaId: widget.empresaId,
          unidadMaestraId: widget.maestra.id,
          nombreLocal: _usarNombreLocal && _nombreLocalController.text.isNotEmpty
              ? _nombreLocalController.text.trim()
              : null,
          simboloLocal:
              _usarSimboloLocal && _simboloLocalController.text.isNotEmpty
                  ? _simboloLocalController.text.trim()
                  : null,
          orden: _ordenController.text.isNotEmpty
              ? int.tryParse(_ordenController.text)
              : null,
        );
  }
}
