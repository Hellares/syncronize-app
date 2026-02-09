import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/info_chip.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../domain/entities/producto_atributo.dart';
import '../../domain/entities/atributo_plantilla.dart';
import '../bloc/atributo_plantilla/atributo_plantilla_cubit.dart';
import '../bloc/atributo_plantilla/atributo_plantilla_state.dart';

/// Representa un atributo con sus valores para el generador de combinaciones
class _AtributoParaCombinar {
  final String atributoId;
  final String nombre;
  final List<String> valores;

  _AtributoParaCombinar({
    required this.atributoId,
    required this.nombre,
    required this.valores,
  });
}

class GenerarCombinacionesDialog extends StatefulWidget {
  final String productoId;
  final String productoNombre;
  final List<ProductoAtributo> atributosDisponibles;
  final void Function(Map<String, dynamic> data) onSave;

  const GenerarCombinacionesDialog({
    super.key,
    required this.productoId,
    required this.productoNombre,
    required this.atributosDisponibles,
    required this.onSave,
  });

  @override
  State<GenerarCombinacionesDialog> createState() =>
      _GenerarCombinacionesDialogState();
}

class _GenerarCombinacionesDialogState
    extends State<GenerarCombinacionesDialog> {
  final _formKey = GlobalKey<FormState>();
  final _precioBaseController = TextEditingController();
  final _precioCostoController = TextEditingController();

  // Map de atributoId -> Set de valores seleccionados
  final Map<String, Set<String>> _selectedValues = {};

  // Atributos cargados (desde atributosDisponibles o desde plantilla)
  List<_AtributoParaCombinar> _atributos = [];

  // Plantilla seleccionada (si se eligió una)
  String? _plantillaSeleccionadaNombre;

  @override
  void initState() {
    super.initState();
    // Inicializar con atributos disponibles que tengan valores
    _atributos = widget.atributosDisponibles
        .where((a) => a.isActive && a.valores.isNotEmpty)
        .map((a) => _AtributoParaCombinar(
              atributoId: a.id,
              nombre: a.nombre,
              valores: a.valores,
            ))
        .toList();
  }

  /// Retorna los atributos que tienen valores seleccionados
  List<_AtributoParaCombinar> get _atributosConSeleccion {
    return _atributos
        .where((a) =>
            _selectedValues.containsKey(a.atributoId) &&
            _selectedValues[a.atributoId]!.isNotEmpty)
        .toList();
  }

  List<List<String>> get _combinaciones {
    final atributos = _atributosConSeleccion;
    if (atributos.isEmpty) return [];

    final arrays = atributos
        .map((a) => _selectedValues[a.atributoId]!.toList())
        .toList();

    return _cartesianProduct(arrays);
  }

  /// Genera el nombre descriptivo de una combinación: "RAM 4 / Color Rojo"
  String _nombreCombinacion(List<String> combo) {
    final atributos = _atributosConSeleccion;
    final partes = <String>[];
    for (var i = 0; i < combo.length && i < atributos.length; i++) {
      partes.add('${atributos[i].nombre} ${combo[i]}');
    }
    return partes.join(' / ');
  }

  List<List<String>> _cartesianProduct(List<List<String>> arrays) {
    if (arrays.isEmpty) return [];
    return arrays.fold<List<List<String>>>(
      [[]],
      (acc, curr) {
        final result = <List<String>>[];
        for (final a in acc) {
          for (final b in curr) {
            result.add([...a, b]);
          }
        }
        return result;
      },
    );
  }

  void _cargarDesdePlantilla(AtributoPlantilla plantilla) {
    setState(() {
      _plantillaSeleccionadaNombre = plantilla.nombre;
      _selectedValues.clear();
      _atributos = plantilla.atributos
          .where((pa) => pa.valoresActuales.isNotEmpty)
          .map((pa) => _AtributoParaCombinar(
                atributoId: pa.atributoId,
                nombre: pa.atributo.nombre,
                valores: pa.valoresActuales,
              ))
          .toList();
    });
  }

  @override
  void dispose() {
    _precioBaseController.dispose();
    _precioCostoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final combos = _combinaciones;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: screenHeight * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.blue1,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Generar Variantes por Combinacion',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.productoNombre,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Botón para cargar plantilla
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _plantillaSeleccionadaNombre != null
                                  ? 'Plantilla: $_plantillaSeleccionadaNombre'
                                  : 'Selecciona una plantilla de atributos',
                              style: TextStyle(
                                fontSize: 12,
                                color: _plantillaSeleccionadaNombre != null
                                    ? AppColors.blue1
                                    : Colors.grey.shade600,
                                fontWeight: _plantillaSeleccionadaNombre != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showPlantillaSelector(context),
                            icon: const Icon(Icons.auto_awesome, size: 16, color: AppColors.blue1),
                            label: Text(
                              _plantillaSeleccionadaNombre != null ? 'Cambiar' : 'Cargar Plantilla',
                              style: const TextStyle(color: AppColors.blue1, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 8),

                      // Atributos con chips seleccionables
                      if (_atributos.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.label_off_outlined, size: 48, color: Colors.grey),
                                const SizedBox(height: 8),
                                const Text(
                                  'No hay atributos con valores disponibles.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () => _showPlantillaSelector(context),
                                  icon: const Icon(Icons.auto_awesome, size: 16),
                                  label: const Text('Cargar desde Plantilla'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        ..._atributos.map((atributo) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  atributo.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppColors.blue1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: atributo.valores.map((valor) {
                                    final isSelected =
                                        _selectedValues[atributo.atributoId]
                                                ?.contains(valor) ??
                                            false;
                                    return InfoChip(
                                      text: valor,
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedValues.putIfAbsent(
                                              atributo.atributoId, () => {});
                                          if (selected) {
                                            _selectedValues[atributo.atributoId]!
                                                .add(valor);
                                          } else {
                                            _selectedValues[atributo.atributoId]!
                                                .remove(valor);
                                          }
                                        });
                                      },
                                      backgroundColor: AppColors.bluechip,
                                      textColor: AppColors.blue2,
                                      selectedBackgroundColor: AppColors.blue1,
                                      selectedTextColor: Colors.white,
                                      borderColor: AppColors.blue1,
                                      borderWidth: 1,
                                      borderRadius: 20,
                                      showCheckmark: true,
                                      fontSize: 12,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],

                      const Divider(),
                      const SizedBox(height: 8),

                      // Precio base
                      CustomText(
                        borderColor: AppColors.blue1,
                        controller: _precioBaseController,
                        label: 'Precio base *',
                        hintText: 'Ej: 45.00',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        prefixIcon: const Icon(Icons.attach_money, size: 20),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El precio base es requerido';
                          }
                          final precio = double.tryParse(value);
                          if (precio == null || precio <= 0) {
                            return 'Ingrese un precio valido mayor a 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Precio costo
                      CustomText(
                        borderColor: AppColors.blue1,
                        controller: _precioCostoController,
                        label: 'Precio costo',
                        hintText: 'Ej: 25.00 (opcional)',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        prefixIcon:
                            const Icon(Icons.price_change_outlined, size: 20),
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final precio = double.tryParse(value);
                            if (precio == null || precio < 0) {
                              return 'Ingrese un precio valido';
                            }
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Preview
                      if (combos.isNotEmpty) ...[
                        GradientContainer(
                          gradient: AppGradients.blueWhiteBlue(),
                          borderColor: AppColors.blueborder,
                          shadowStyle: ShadowStyle.none,
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.preview,
                                      size: 16, color: AppColors.blue1),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Preview: ${combos.length} variantes',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.blue1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (combos.length > 50)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    'Maximo 50 combinaciones permitidas. Reduzca la seleccion.',
                                    style: TextStyle(
                                        color: Colors.red, fontSize: 12),
                                  ),
                                ),
                              ...combos.take(20).map((combo) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.circle,
                                          size: 6, color: AppColors.blue1),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _nombreCombinacion(combo),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              if (combos.length > 20)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '... y ${combos.length - 20} mas',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed:
                        combos.isNotEmpty && combos.length <= 50
                            ? _onGenerate
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue1,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: Text(
                      combos.isNotEmpty
                          ? 'Generar ${combos.length}'
                          : 'Generar',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlantillaSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider(
        create: (_) => locator<AtributoPlantillaCubit>()..loadPlantillas(),
        child: BlocBuilder<AtributoPlantillaCubit, AtributoPlantillaState>(
          builder: (builderContext, state) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Container(
                constraints:
                    const BoxConstraints(maxWidth: 500, maxHeight: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.blue1.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: AppColors.blue1, size: 24),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Seleccionar Plantilla',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildPlantillaList(
                          builderContext, state, dialogContext),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlantillaList(
    BuildContext builderContext,
    AtributoPlantillaState state,
    BuildContext dialogContext,
  ) {
    if (state is AtributoPlantillaLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is AtributoPlantillaError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(state.message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => builderContext
                    .read<AtributoPlantillaCubit>()
                    .loadPlantillas(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is AtributoPlantillaLoaded) {
      if (state.plantillas.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('No hay plantillas disponibles'),
                SizedBox(height: 4),
                Text(
                  'Crea plantillas en la seccion de configuracion',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: state.plantillas.length,
        itemBuilder: (context, index) {
          final plantilla = state.plantillas[index];
          final atributosConValores = plantilla.atributos
              .where((pa) => pa.valoresActuales.isNotEmpty)
              .toList();

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              dense: true,
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: plantilla.icono != null
                    ? Text(plantilla.icono!,
                        style: const TextStyle(fontSize: 20))
                    : const Icon(Icons.list_alt,
                        color: AppColors.blue1, size: 20),
              ),
              title: Text(
                plantilla.nombre,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: Text(
                '${plantilla.cantidadAtributos} atributos'
                '${atributosConValores.isNotEmpty ? ' - ${atributosConValores.length} con valores' : ''}',
                style: const TextStyle(fontSize: 11),
              ),
              trailing:
                  const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: atributosConValores.isNotEmpty
                  ? () {
                      Navigator.of(dialogContext).pop();
                      _cargarDesdePlantilla(plantilla);
                    }
                  : null,
              enabled: atributosConValores.isNotEmpty,
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  void _onGenerate() {
    if (!_formKey.currentState!.validate()) return;

    final atributosConSeleccion = _atributos
        .where((a) =>
            _selectedValues.containsKey(a.atributoId) &&
            _selectedValues[a.atributoId]!.isNotEmpty)
        .toList();

    if (atributosConSeleccion.isEmpty) return;

    final data = <String, dynamic>{
      'atributos': atributosConSeleccion.map((a) {
        return {
          'atributoId': a.atributoId,
          'valores': _selectedValues[a.atributoId]!.toList(),
        };
      }).toList(),
      'precioBase': double.parse(_precioBaseController.text.trim()),
    };

    final costText = _precioCostoController.text.trim();
    if (costText.isNotEmpty) {
      data['precioCosto'] = double.parse(costText);
    }

    widget.onSave(data);
  }
}
