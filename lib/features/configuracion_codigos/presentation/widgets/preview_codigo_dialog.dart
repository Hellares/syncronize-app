import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/configuracion_codigos_cubit.dart';
import '../bloc/configuracion_codigos_state.dart';
import '../../domain/entities/configuracion_codigos.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';

/// Diálogo para vista previa de códigos
class PreviewCodigoDialog extends StatefulWidget {
  final String tipo; // 'PRODUCTO', 'VARIANTE', 'SERVICIO'

  const PreviewCodigoDialog({
    super.key,
    required this.tipo,
  });

  @override
  State<PreviewCodigoDialog> createState() => _PreviewCodigoDialogState();
}

class _PreviewCodigoDialogState extends State<PreviewCodigoDialog> {
  final _numeroController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _generarPreview();
  }

  @override
  void dispose() {
    _numeroController.dispose();
    super.dispose();
  }

  void _generarPreview() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;

    final empresaId = empresaState.context.empresa.id;

    final numero = int.tryParse(_numeroController.text);

    TipoCodigo tipo;
    switch (widget.tipo) {
      case 'PRODUCTO':
        tipo = TipoCodigo.producto;
        break;
      case 'VARIANTE':
        tipo = TipoCodigo.variante;
        break;
      case 'SERVICIO':
        tipo = TipoCodigo.servicio;
        break;
      case 'VENTA':
        tipo = TipoCodigo.venta;
        break;
      case 'FACTURA':
        tipo = TipoCodigo.factura;
        break;
      case 'BOLETA':
        tipo = TipoCodigo.boleta;
        break;
      case 'NOTA_CREDITO':
        tipo = TipoCodigo.notaCredito;
        break;
      case 'NOTA_DEBITO':
        tipo = TipoCodigo.notaDebito;
        break;
      default:
        return;
    }

    context.read<ConfiguracionCodigosCubit>().previewCodigo(
          empresaId: empresaId,
          tipo: tipo,
          numero: numero,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: BlocBuilder<ConfiguracionCodigosCubit, ConfiguracionCodigosState>(
          builder: (context, state) {
            if (state is! ConfiguracionCodigosLoaded) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final preview = state.preview;
            final isLoading = state.isLoading;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.visibility, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Vista Previa - ${widget.tipo}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const Divider(height: 32),

                // Campo para ingresar número
                TextFormField(
                  controller: _numeroController,
                  decoration: const InputDecoration(
                    labelText: 'Número a previsualizar',
                    hintText: '1',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    // Auto-generar preview al escribir
                    if (value.isNotEmpty) {
                      _generarPreview();
                    }
                  },
                ),

                const SizedBox(height: 24),

                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (preview != null) ...[
                  // Código generado
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Código generado:',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          preview.codigo,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Formato desglosado
                  Text(
                    'Formato desglosado:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  _buildFormatoRow('Prefijo', preview.formato.prefijo),
                  _buildFormatoRow('Separador',
                      preview.formato.separador.isEmpty
                          ? '(sin separador)'
                          : preview.formato.separador),
                  _buildFormatoRow('Número', preview.formato.numero),
                  if (preview.formato.sede != null)
                    _buildFormatoRow('Sede', preview.formato.sede!),
                ] else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No hay vista previa disponible',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : _generarPreview,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Actualizar'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFormatoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
