import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../data/models/create_combo_dto.dart';
import '../../domain/entities/combo.dart';
import '../bloc/combo_cubit.dart';
import '../bloc/combo_state.dart';

/// Página para crear un nuevo combo directamente
class ComboCreatePage extends StatelessWidget {
  const ComboCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<ComboCubit>(),
      child: const _ComboCreateContent(),
    );
  }
}

class _ComboCreateContent extends StatefulWidget {
  const _ComboCreateContent();

  @override
  State<_ComboCreateContent> createState() => _ComboCreateContentState();
}

class _ComboCreateContentState extends State<_ComboCreateContent> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioFijoController = TextEditingController();
  final _descuentoPorcentajeController = TextEditingController();

  TipoPrecioCombo _tipoPrecioCombo = TipoPrecioCombo.calculado;

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioFijoController.dispose();
    _descuentoPorcentajeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nuevo Combo'),
        elevation: 0,
      ),
      body: BlocConsumer<ComboCubit, ComboState>(
        listener: (context, state) {
          if (state is ComboOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            // Navegar al detalle del combo creado
            if (state.combo != null) {
              context.pop();
              // Opcional: navegar al detalle del combo
              final empresaState = context.read<EmpresaContextCubit>().state;
              if (empresaState is EmpresaContextLoaded) {
                context.push(
                  '/empresa/combos/${state.combo!.id}?empresaId=${empresaState.context.empresa.id}',
                );
              }
            }
          } else if (state is ComboError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is ComboLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Información del combo
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Información Básica',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nombreController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre del Combo *',
                              hintText: 'Ej: COMBO OFICINA COMPLETO',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.label),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'El nombre es requerido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descripcionController,
                            decoration: const InputDecoration(
                              labelText: 'Descripción (opcional)',
                              hintText: 'Incluye PC + Monitor + Teclado + Mouse',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.description),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Configuración de precio
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.attach_money, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Configuración de Precio',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // // Tipo de precio: FIJO
                          // RadioListTile<TipoPrecioCombo>(
                          //   title: const Text('Precio Fijo'),
                          //   subtitle: const Text(
                          //     'Defines un precio fijo, independiente del precio de los componentes',
                          //     style: TextStyle(fontSize: 12),
                          //   ),
                          //   value: TipoPrecioCombo.fijo,
                          //   groupValue: _tipoPrecioCombo,
                          //   onChanged: (value) {
                          //     setState(() => _tipoPrecioCombo = value!);
                          //   },
                          // ),

                          // if (_tipoPrecioCombo == TipoPrecioCombo.fijo) ...[
                          //   Padding(
                          //     padding: const EdgeInsets.only(left: 56, right: 16, bottom: 16),
                          //     child: TextFormField(
                          //       controller: _precioFijoController,
                          //       decoration: const InputDecoration(
                          //         labelText: 'Precio Fijo *',
                          //         hintText: '2999.99',
                          //         border: OutlineInputBorder(),
                          //         prefixText: '\$ ',
                          //       ),
                          //       keyboardType: TextInputType.number,
                          //       validator: (value) {
                          //         if (_tipoPrecioCombo == TipoPrecioCombo.fijo) {
                          //           if (value == null || value.isEmpty) {
                          //             return 'El precio fijo es requerido';
                          //           }
                          //           final precio = double.tryParse(value);
                          //           if (precio == null || precio <= 0) {
                          //             return 'Ingresa un precio válido';
                          //           }
                          //         }
                          //         return null;
                          //       },
                          //     ),
                          //   ),
                          // ],

                          // const Divider(),

                          // // Tipo de precio: CALCULADO
                          // RadioListTile<TipoPrecioCombo>(
                          //   title: const Text('Precio Calculado'),
                          //   subtitle: const Text(
                          //     'El precio es la suma del precio de todos los componentes',
                          //     style: TextStyle(fontSize: 12),
                          //   ),
                          //   value: TipoPrecioCombo.calculado,
                          //   groupValue: _tipoPrecioCombo,
                          //   onChanged: (value) {
                          //     setState(() => _tipoPrecioCombo = value!);
                          //   },
                          // ),

                          // const Divider(),

                          // // Tipo de precio: CALCULADO_CON_DESCUENTO
                          // RadioListTile<TipoPrecioCombo>(
                          //   title: const Text('Precio Calculado con Descuento'),
                          //   subtitle: const Text(
                          //     'Suma de componentes menos un porcentaje de descuento',
                          //     style: TextStyle(fontSize: 12),
                          //   ),
                          //   value: TipoPrecioCombo.calculadoConDescuento,
                          //   groupValue: _tipoPrecioCombo,
                          //   onChanged: (value) {
                          //     setState(() => _tipoPrecioCombo = value!);
                          //   },
                          // ),

                          // if (_tipoPrecioCombo == TipoPrecioCombo.calculadoConDescuento) ...[
                          //   Padding(
                          //     padding: const EdgeInsets.only(left: 56, right: 16, bottom: 16),
                          //     child: TextFormField(
                          //       controller: _descuentoPorcentajeController,
                          //       decoration: const InputDecoration(
                          //         labelText: 'Porcentaje de Descuento *',
                          //         hintText: '10',
                          //         border: OutlineInputBorder(),
                          //         suffixText: '%',
                          //       ),
                          //       keyboardType: TextInputType.number,
                          //       validator: (value) {
                          //         if (_tipoPrecioCombo == TipoPrecioCombo.calculadoConDescuento) {
                          //           if (value == null || value.isEmpty) {
                          //             return 'El porcentaje de descuento es requerido';
                          //           }
                          //           final porcentaje = double.tryParse(value);
                          //           if (porcentaje == null || porcentaje <= 0 || porcentaje > 100) {
                          //             return 'Ingresa un porcentaje válido (1-100)';
                          //           }
                          //         }
                          //         return null;
                          //       },
                          //     ),
                          //   ),
                          // ],
                          RadioGroup<TipoPrecioCombo>(
  groupValue: _tipoPrecioCombo,
  onChanged: (value) {
    setState(() => _tipoPrecioCombo = value!);
  },
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Tipo de precio: FIJO
      RadioListTile<TipoPrecioCombo>(
        title: const Text('Precio Fijo'),
        subtitle: const Text(
          'Defines un precio fijo, independiente del precio de los componentes',
          style: TextStyle(fontSize: 12),
        ),
        value: TipoPrecioCombo.fijo,
        // ✅ sin groupValue
        // ✅ sin onChanged
      ),

      if (_tipoPrecioCombo == TipoPrecioCombo.fijo) ...[
        Padding(
          padding: const EdgeInsets.only(left: 56, right: 16, bottom: 16),
          child: TextFormField(
            controller: _precioFijoController,
            decoration: const InputDecoration(
              labelText: 'Precio Fijo *',
              hintText: '2999.99',
              border: OutlineInputBorder(),
              prefixText: '\$ ',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (_tipoPrecioCombo == TipoPrecioCombo.fijo) {
                if (value == null || value.isEmpty) {
                  return 'El precio fijo es requerido';
                }
                final precio = double.tryParse(value);
                if (precio == null || precio <= 0) {
                  return 'Ingresa un precio válido';
                }
              }
              return null;
            },
          ),
        ),
      ],

      const Divider(),

      // Tipo de precio: CALCULADO
      RadioListTile<TipoPrecioCombo>(
        title: const Text('Precio Calculado'),
        subtitle: const Text(
          'El precio es la suma del precio de todos los componentes',
          style: TextStyle(fontSize: 12),
        ),
        value: TipoPrecioCombo.calculado,
      ),

      const Divider(),

      // Tipo de precio: CALCULADO_CON_DESCUENTO
      RadioListTile<TipoPrecioCombo>(
        title: const Text('Precio Calculado con Descuento'),
        subtitle: const Text(
          'Suma de componentes menos un porcentaje de descuento',
          style: TextStyle(fontSize: 12),
        ),
        value: TipoPrecioCombo.calculadoConDescuento,
      ),

      if (_tipoPrecioCombo == TipoPrecioCombo.calculadoConDescuento) ...[
        Padding(
          padding: const EdgeInsets.only(left: 56, right: 16, bottom: 16),
          child: TextFormField(
            controller: _descuentoPorcentajeController,
            decoration: const InputDecoration(
              labelText: 'Porcentaje de Descuento *',
              hintText: '10',
              border: OutlineInputBorder(),
              suffixText: '%',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (_tipoPrecioCombo == TipoPrecioCombo.calculadoConDescuento) {
                if (value == null || value.isEmpty) {
                  return 'El porcentaje de descuento es requerido';
                }
                final porcentaje = double.tryParse(value);
                if (porcentaje == null || porcentaje <= 0 || porcentaje > 100) {
                  return 'Ingresa un porcentaje válido (1-100)';
                }
              }
              return null;
            },
          ),
        ),
      ],
    ],
  ),
                          )

                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Información adicional
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Una vez creado el combo, podrás agregar componentes (productos) que lo conforman.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLoading ? null : () => context.pop(),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: isLoading ? null : _crearCombo,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Crear Combo'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _crearCombo() {
    if (!_formKey.currentState!.validate()) return;

    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay empresa seleccionada'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Construir DTO
    final dto = CreateComboDto(
      empresaId: empresaState.context.empresa.id,
      nombre: _nombreController.text.trim(),
      tipoPrecioCombo: _tipoPrecioCombo,
      descripcion: _descripcionController.text.trim().isEmpty
          ? null
          : _descripcionController.text.trim(),
      precioFijo: _tipoPrecioCombo == TipoPrecioCombo.fijo
          ? double.tryParse(_precioFijoController.text)
          : null,
      descuentoPorcentaje: _tipoPrecioCombo == TipoPrecioCombo.calculadoConDescuento
          ? double.tryParse(_descuentoPorcentajeController.text)
          : null,
    );

    // Llamar al cubit
    context.read<ComboCubit>().createCombo(dto: dto);
  }
}

                