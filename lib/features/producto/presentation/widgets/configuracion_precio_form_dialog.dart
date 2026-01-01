import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../data/models/configuracion_precio_model.dart';
import '../../domain/entities/configuracion_precio.dart';
import '../../domain/entities/precio_nivel.dart';
import '../bloc/configuracion_precio/configuracion_precio_cubit.dart';

/// Diálogo para crear o editar una configuración de precios
class ConfiguracionPrecioFormDialog extends StatefulWidget {
  final ConfiguracionPrecio? configuracion;

  const ConfiguracionPrecioFormDialog({
    super.key,
    this.configuracion,
  });

  @override
  State<ConfiguracionPrecioFormDialog> createState() =>
      _ConfiguracionPrecioFormDialogState();
}

class _ConfiguracionPrecioFormDialogState
    extends State<ConfiguracionPrecioFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();

  final List<_NivelFormData> _niveles = [];

  @override
  void initState() {
    super.initState();
    if (widget.configuracion != null) {
      final config = widget.configuracion!;
      _nombreController.text = config.nombre;
      _descripcionController.text = config.descripcion ?? '';
      _niveles.addAll(config.niveles.map((nivel) => _NivelFormData(
            nombre: nivel.nombre,
            cantidadMinima: nivel.cantidadMinima.toString(),
            cantidadMaxima: nivel.cantidadMaxima?.toString(),
            tipoPrecio: nivel.tipoPrecio,
            porcentajeDesc: nivel.porcentajeDesc?.toString(),
            descripcion: nivel.descripcion,
          )));
    } else {
      // Agregar un nivel por defecto
      _niveles.add(_NivelFormData(
        nombre: 'Precio Retail',
        cantidadMinima: '1',
        tipoPrecio: TipoPrecioNivel.porcentajeDescuento,
        porcentajeDesc: '0',
      ));
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    // Hacer dispose de todos los controladores de los niveles
    for (var nivel in _niveles) {
      nivel.dispose();
    }
    super.dispose();
  }

  void _agregarNivel() {
    setState(() {
      final count = _niveles.length;
      String nombre = 'Nivel ${count + 1}';
      if (count == 1) nombre = 'Precio por Mayor';
      if (count == 2) nombre = 'Precio Distribuidor';

      _niveles.add(_NivelFormData(
        nombre: nombre,
        cantidadMinima: '',
        tipoPrecio: TipoPrecioNivel.porcentajeDescuento,
        porcentajeDesc: '10',
      ));
    });
  }

  void _eliminarNivel(int index) {
    setState(() {
      // Hacer dispose de los controladores antes de eliminar
      _niveles[index].dispose();
      _niveles.removeAt(index);
    });
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    final nivelesDto = _niveles.asMap().entries.map((entry) {
      final index = entry.key;
      final nivel = entry.value;

      return ConfiguracionPrecioNivelDto(
        nombre: nivel.nombre,
        cantidadMinima: int.parse(nivel.cantidadMinima),
        cantidadMaxima: nivel.cantidadMaxima != null && nivel.cantidadMaxima!.isNotEmpty
            ? int.parse(nivel.cantidadMaxima!)
            : null,
        tipoPrecio: nivel.tipoPrecio == TipoPrecioNivel.precioFijo
            ? 'PRECIO_FIJO'
            : 'PORCENTAJE_DESCUENTO',
        porcentajeDesc: nivel.tipoPrecio == TipoPrecioNivel.porcentajeDescuento &&
                nivel.porcentajeDesc != null &&
                nivel.porcentajeDesc!.isNotEmpty
            ? double.parse(nivel.porcentajeDesc!)
            : null,
        descripcion: nivel.descripcion,
        orden: index,
      );
    }).toList();

    final dto = ConfiguracionPrecioDto(
      nombre: _nombreController.text.trim(),
      descripcion: _descripcionController.text.trim().isEmpty
          ? null
          : _descripcionController.text.trim(),
      niveles: nivelesDto,
    );

    if (widget.configuracion != null) {
      context
          .read<ConfiguracionPrecioCubit>()
          .actualizar(widget.configuracion!.id, dto);
    } else {
      context.read<ConfiguracionPrecioCubit>().crear(dto);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.configuracion != null;

    return AlertDialog(
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 500),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      title: Container(
        alignment: Alignment.center,
        child: Text(isEditing
            ? 'Editar configuración'
            : 'Nueva configuración de precios', style: TextStyle(fontSize: 12),),
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  controller: _nombreController,
                  borderWidth: 0.6,
                  label: 'Nombre de la configuración *',
                  borderColor: AppColors.blue1,
                  hintText: 'Ej: Estándar 3 Niveles, Solo Mayoreo',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa un nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                CustomText(
                  controller: _descripcionController,
                  borderWidth: 0.6,
                  height: 70,
                  label: 'Descripción (opcional)',
                  borderColor: AppColors.blue1,
                  hintText: 'Ej: Para productos de uso general',
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Niveles de Precio',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _agregarNivel,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Agregar nivel',style: TextStyle(
                        fontSize: 12,
                      ),),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._niveles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final nivel = entry.value;
                  return _buildNivelCard(index, nivel);
                }),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardar,
          child: Text(isEditing ? 'Actualizar' : 'Crear'),
        ),
      ],
    );
  }

  Widget _buildNivelCard(int index, _NivelFormData nivel) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 13),
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomText(
                      controller: nivel.nombreController,
                      borderWidth: 0.6,
                      label: 'Nombre del nivel *',
                      borderColor: AppColors.blue1,
                      hintText: 'Ej: Precio Retail, Precio por Mayor',
                      onChanged: (value) {
                        nivel.nombre = value;
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Requerido';
                        }
                        return null;
                      },
                    ),
                  ),
                  if (_niveles.length > 1)
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: Colors.red),
                      onPressed: () => _eliminarNivel(index),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  // child: TextFormField(
                  //   initialValue: nivel.cantidadMinima,
                  //   decoration: const InputDecoration(
                  //     labelText: 'Cantidad mínima',
                  //     isDense: true,
                  //     border: OutlineInputBorder(),
                  //     suffixText: 'unid.',
                  //   ),
                  //   keyboardType: TextInputType.number,
                  //   inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  //   onChanged: (value) {
                  //     setState(() {
                  //       nivel.cantidadMinima = value;
                  //     });
                  //   },
                  //   validator: (value) {
                  //     if (value == null || value.isEmpty) {
                  //       return 'Requerido';
                  //     }
                  //     final num = int.tryParse(value);
                  //     if (num == null || num < 1) {
                  //       return 'Mínimo 1';
                  //     }
                  //     return null;
                  //   },
                  // ),
                  child: CustomText(
                    controller: nivel.cantidadMinimaController,
                    borderWidth: 0.6,
                    label: 'Cantidad mínima *',
                    borderColor: AppColors.blue1,
                    hintText: 'Ej: 1',
                    keyboardType: TextInputType.number,
                    // inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      nivel.cantidadMinima = value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requerido';
                      }
                      final num = int.tryParse(value);
                      if (num == null || num < 1) {
                        return 'Mínimo 1';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  // child: TextFormField(
                  //   initialValue: nivel.cantidadMaxima,
                  //   decoration: const InputDecoration(
                  //     labelText: 'Cantidad máxima',
                  //     isDense: true,
                  //     border: OutlineInputBorder(),
                  //     suffixText: 'unid.',
                  //     hintText: 'Opcional',
                  //   ),
                  //   keyboardType: TextInputType.number,
                  //   inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  //   onChanged: (value) {
                  //     setState(() {
                  //       nivel.cantidadMaxima = value;
                  //     });
                  //   },
                  //   validator: (value) {
                  //     if (value != null && value.isNotEmpty) {
                  //       final max = int.tryParse(value);
                  //       final min = int.tryParse(nivel.cantidadMinima);
                  //       if (max == null || max < 1) {
                  //         return 'Inválido';
                  //       }
                  //       if (min != null && max <= min) {
                  //         return '> mínimo';
                  //       }
                  //     }
                  //     return null;
                  //   },
                  // ),
                  child: CustomText(
                    controller: nivel.cantidadMaximaController,
                    borderWidth: 0.6,
                    label: 'Cantidad máxima',
                    borderColor: AppColors.blue1,
                    hintText: 'Opcional',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      nivel.cantidadMaxima = value;
                    },
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final max = int.tryParse(value);
                        final min = int.tryParse(nivel.cantidadMinima);
                        if (max == null || max < 1) {
                          return 'Inválido';
                        }
                        if (min != null && max <= min) {
                          return '> mínimo';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    child: SegmentedButton<TipoPrecioNivel>(
                      style: SegmentedButton.styleFrom(
                        minimumSize: const Size(0, 30),
                        backgroundColor: AppColors.blue1.withValues(alpha: 0.1),
                        selectedBackgroundColor: AppColors.blue1,
                        side: BorderSide(color: AppColors.blue1.withValues(alpha: 0.6)),
                        selectedForegroundColor: Colors.white,
                        foregroundColor: AppColors.blue1,
                        
                      ),
                      segments: const [
                        
                        ButtonSegment(                          
                          value: TipoPrecioNivel.precioFijo,
                          label: Text('P. Fijo', style: TextStyle(fontSize: 8)),
                        ),
                        ButtonSegment(
                          value: TipoPrecioNivel.porcentajeDescuento,
                          label: Text('% Desc.', style: TextStyle(fontSize: 8)),
                        ),
                      ],
                      selected: {nivel.tipoPrecio},
                      onSelectionChanged: (Set<TipoPrecioNivel> newSelection) {
                        setState(() {
                          nivel.tipoPrecio = newSelection.first;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (nivel.tipoPrecio == TipoPrecioNivel.porcentajeDescuento)
                  Expanded(
                    // child: TextFormField(
                    //   initialValue: nivel.porcentajeDesc,
                    //   decoration: const InputDecoration(
                    //     labelText: 'Descuento',
                    //     isDense: true,
                    //     border: OutlineInputBorder(),
                    //     suffixText: '%',
                    //   ),
                    //   keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    //   inputFormatters: [
                    //     FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    //   ],
                    //   onChanged: (value) {
                    //     setState(() {
                    //       nivel.porcentajeDesc = value;
                    //     });
                    //   },
                    //   validator: (value) {
                    //     if (nivel.tipoPrecio == TipoPrecioNivel.porcentajeDescuento) {
                    //       if (value == null || value.isEmpty) {
                    //         return 'Requerido';
                    //       }
                    //       final num = double.tryParse(value);
                    //       if (num == null || num < 0 || num > 100) {
                    //         return '0-100';
                    //       }
                    //     }
                    //     return null;
                    //   },
                    // ),
                    child: CustomText(
                      controller: nivel.porcentajeDescController,
                      borderWidth: 0.6,
                      label: 'Descuento *',
                      borderColor: AppColors.blue1,
                      hintText: 'Ej: 10',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      onChanged: (value) {
                        nivel.porcentajeDesc = value;
                      },
                      validator: (value) {
                        if (nivel.tipoPrecio == TipoPrecioNivel.porcentajeDescuento) {
                          if (value == null || value.isEmpty) {
                            return 'Requerido';
                          }
                          final num = double.tryParse(value);
                          if (num == null || num < 0 || num > 100) {
                            return '0-100';
                          }
                        }
                        return null;
                      },
                    ),
                  )
                else
                  const Expanded(
                    child: Text(
                      'Se define en el producto',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Clase para manejar los datos del formulario de nivel
class _NivelFormData {
  String nombre;
  String cantidadMinima;
  String? cantidadMaxima;
  TipoPrecioNivel tipoPrecio;
  String? porcentajeDesc;
  String? descripcion;

  // Controladores para los campos de texto
  late final TextEditingController nombreController;
  late final TextEditingController cantidadMinimaController;
  late final TextEditingController cantidadMaximaController;
  late final TextEditingController porcentajeDescController;

  _NivelFormData({
    required this.nombre,
    required this.cantidadMinima,
    this.cantidadMaxima,
    required this.tipoPrecio,
    this.porcentajeDesc,
    this.descripcion,
  }) {
    // Inicializar controladores con los valores
    nombreController = TextEditingController(text: nombre);
    cantidadMinimaController = TextEditingController(text: cantidadMinima);
    cantidadMaximaController = TextEditingController(text: cantidadMaxima ?? '');
    porcentajeDescController = TextEditingController(text: porcentajeDesc ?? '');
  }

  // Dispose de los controladores
  void dispose() {
    nombreController.dispose();
    cantidadMinimaController.dispose();
    cantidadMaximaController.dispose();
    porcentajeDescController.dispose();
  }
}
