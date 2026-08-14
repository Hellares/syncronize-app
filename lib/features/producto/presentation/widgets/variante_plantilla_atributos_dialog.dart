import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../domain/entities/atributo_plantilla.dart';
import '../../domain/entities/producto_atributo.dart';
import '../../data/datasources/producto_remote_datasource.dart';
import '../../data/models/producto_atributo_valor_dto.dart';
import '../bloc/atributo_plantilla/atributo_plantilla_cubit.dart';
import '../bloc/atributo_plantilla/atributo_plantilla_state.dart';
import 'atributo_input_widget.dart';

/// Diálogo para gestionar atributos de productos/variantes usando plantillas
class VariantePlantillaAtributosDialog extends StatefulWidget {
  final String empresaId;
  final String? productoId;
  final String? varianteId;
  final String nombre;
  final AtributoPlantilla? plantilla; // Ahora es opcional
  final Map<String, String> valoresIniciales;

  const VariantePlantillaAtributosDialog({
    super.key,
    required this.empresaId,
    this.productoId,
    this.varianteId,
    required this.nombre,
    this.plantilla, // Opcional: si no se provee, se muestra selector
    this.valoresIniciales = const {},
  }) : assert(productoId != null || varianteId != null, 'Debe especificar productoId o varianteId'),
       assert(productoId == null || varianteId == null, 'No puede especificar ambos productoId y varianteId');

  @override
  State<VariantePlantillaAtributosDialog> createState() =>
      _VariantePlantillaAtributosDialogState();
}

class _VariantePlantillaAtributosDialogState
    extends State<VariantePlantillaAtributosDialog> {
  late Map<String, String> _valores;
  bool _isLoading = false;
  AtributoPlantilla? _plantillaSeleccionada;

  @override
  void initState() {
    super.initState();
    _valores = Map.from(widget.valoresIniciales);
    _plantillaSeleccionada = widget.plantilla;
  }

  @override
  Widget build(BuildContext context) {
    // Si no hay plantilla seleccionada, mostrar selector
    if (_plantillaSeleccionada == null) {
      return BlocProvider(
        create: (_) => locator<AtributoPlantillaCubit>()..loadPlantillas(),
        child: _buildPlantillaSelector(),
      );
    }

    // Si ya hay plantilla, mostrar formulario de atributos
    return StyledDialog(
      accentColor: AppColors.blue1,
      icon: Icons.tune,
      titulo: 'Atributos · ${widget.nombre}',
      content: _buildAtributosForm(),
      actions: [
        Expanded(
          child: CustomButton(
            text: 'Cancelar',
            backgroundColor: AppColors.white,
            borderColor: Colors.grey.shade400,
            textColor: Colors.grey.shade700,
            onPressed:
                _isLoading ? null : () => Navigator.of(context).pop(),
          ),
        ),
        Expanded(
          flex: 2,
          child: CustomButton(
            text: 'Guardar',
            isLoading: _isLoading,
            onPressed: _guardar,
          ),
        ),
      ],
    );
  }

  Widget _buildPlantillaSelector() {
    return StyledDialog(
      accentColor: AppColors.blue1,
      icon: Icons.list_alt,
      titulo: 'Plantilla para ${widget.nombre}',
      content: [_buildPlantillasList()],
      actions: [
        Expanded(
          child: CustomButton(
            text: 'Cancelar',
            backgroundColor: AppColors.white,
            borderColor: Colors.grey.shade400,
            textColor: Colors.grey.shade700,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }

  Widget _buildPlantillasList() {
    return BlocBuilder<AtributoPlantillaCubit, AtributoPlantillaState>(
      builder: (context, state) {
        // 🔴 Todos los estados van con alto ACOTADO: adentro del
        // SingleChildScrollView de StyledDialog, un Center con un Column de
        // `mainAxisSize.max` no tiene contra qué medirse y revienta.
        if (state is AtributoPlantillaLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is AtributoPlantillaError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 32, color: Colors.red.shade400),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                CustomButton(
                  text: 'Reintentar',
                  backgroundColor: AppColors.white,
                  borderColor: AppColors.blue1,
                  textColor: AppColors.blue1,
                  onPressed: () =>
                      context.read<AtributoPlantillaCubit>().loadPlantillas(),
                ),
              ],
            ),
          );
        }

        if (state is AtributoPlantillaLoaded) {
          if (state.plantillas.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 36, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'No hay plantillas disponibles',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Creá plantillas desde la configuración de atributos',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // `shrinkWrap` + sin física propia: el scroll lo pone StyledDialog.
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: state.plantillas.length,
            itemBuilder: (context, index) {
              final plantilla = state.plantillas[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () =>
                      setState(() => _plantillaSeleccionada = plantilla),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        plantilla.icono != null
                            ? Text(plantilla.icono!,
                                style: const TextStyle(fontSize: 16))
                            : Icon(Icons.list_alt,
                                size: 16, color: AppColors.blue1),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                plantilla.nombre,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${plantilla.cantidadAtributos} atributos · ${plantilla.cantidadRequeridos} requeridos',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            size: 16, color: Colors.grey.shade500),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  // El header y el footer los pone StyledDialog —título con ícono acentuado y
  // fila de acciones—, así que los que había armados a mano se borraron.

  /// Devuelve la LISTA de widgets, no un scroll propio: `StyledDialog` ya
  /// scrollea su contenido y anidar dos scrolls rompe el alto.
  List<Widget> _buildAtributosForm() {
    if (_plantillaSeleccionada!.atributos.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 40, color: Colors.grey.shade400),
                const SizedBox(height: 10),
                Text(
                  'La plantilla no tiene atributos',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    // Ordenar atributos por orden
    final atributosOrdenados = List.from(_plantillaSeleccionada!.atributos)
      ..sort((a, b) => a.orden.compareTo(b.orden));

    return [
      // Chip con la plantilla en uso: el título ya dice de qué producto es.
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.blue1.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.list_alt, size: 12, color: AppColors.blue1),
            const SizedBox(width: 4),
            Text(
              _plantillaSeleccionada!.nombre,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.blue1,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      ...atributosOrdenados.map((plantillaAtributo) {
          final valorActual = _valores[plantillaAtributo.atributoId];
          // Convertir PlantillaAtributoInfo a ProductoAtributo
          final productoAtributo = _convertirAtributoInfoAProductoAtributo(
            plantillaAtributo.atributo,
            plantillaAtributo.valoresActuales,
            plantillaAtributo.orden,
            plantillaAtributo.esRequerido,
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: AtributoInputWidget(
              atributo: productoAtributo,
              valorActual: valorActual,
              empresaId: widget.empresaId,
              // De acá sale la cascada: este diálogo es el único que tiene el
              // mapa completo, así que es el que puede decirle a un atributo
              // dependiente qué eligió su padre.
              valorDelPadre: productoAtributo.dependeDeAtributoId == null
                  ? null
                  : _valores[productoAtributo.dependeDeAtributoId],
              onChanged: (valor) {
                setState(() {
                  _valores[plantillaAtributo.atributoId] = valor;
                  _limpiarDependientes(plantillaAtributo.atributoId);
                });
              },
            ),
          );
      }),
    ];
  }

  /// Vacía los atributos que dependen de [atributoId], en cascada.
  ///
  /// Al cambiar FABRICANTE, lo elegido en FAMILIA queda apuntando a una rama
  /// que ya no existe — y lo de PROCESADOR, que cuelga de FAMILIA, también.
  /// Por eso baja por toda la cadena y no solo un nivel.
  void _limpiarDependientes(String atributoId) {
    final plantilla = _plantillaSeleccionada;
    if (plantilla == null) return;
    for (final pa in plantilla.atributos) {
      if (pa.atributo.dependeDeAtributoId != atributoId) continue;
      _valores.remove(pa.atributoId);
      _limpiarDependientes(pa.atributoId);
    }
  }

  /// Convierte PlantillaAtributoInfo a ProductoAtributo para compatibilidad con el widget
  ProductoAtributo _convertirAtributoInfoAProductoAtributo(
    PlantillaAtributoInfo atributoInfo,
    List<String> valores,
    int orden,
    bool requerido,
  ) {
    return ProductoAtributo(
      id: atributoInfo.id,
      empresaId: widget.empresaId,
      categoriaIds: const [],
      nombre: atributoInfo.nombre,
      clave: atributoInfo.clave,
      tipo: atributoInfo.tipoEnum,
      requerido: requerido,
      descripcion: atributoInfo.descripcion,
      unidad: atributoInfo.unidad,
      valores: valores,
      // La jerarquía viaja hasta acá: sin ella, un atributo dependiente dentro
      // de una plantilla ofrecía la lista plana.
      opciones: atributoInfo.opciones,
      dependeDeAtributoId: atributoInfo.dependeDeAtributoId,
      orden: orden,
      mostrarEnListado: true,
      usarParaFiltros: true,
      mostrarEnMarketplace: true,
      isActive: true,
      creadoEn: DateTime.now(),
      actualizadoEn: DateTime.now(),
    );
  }

  Future<void> _guardar() async {
    // Validar campos requeridos
    final atributosRequeridos = _plantillaSeleccionada!.atributos
        .where((pa) => pa.esRequerido)
        .toList();

    for (var plantillaAtributo in atributosRequeridos) {
      final valor = _valores[plantillaAtributo.atributoId];
      if (valor == null || valor.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'El atributo "${plantillaAtributo.atributo.nombre}" es requerido',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Usar el datasource
      final dataSource = locator<ProductoRemoteDataSource>();

      // Preparar DTOs
      final atributos = _valores.entries
          .where((e) => e.value.isNotEmpty)
          .map((e) => VarianteAtributoDto(
                atributoId: e.key,
                valor: e.value,
              ))
          .toList();

      // Guardar en el backend (producto o variante)
      if (widget.varianteId != null) {
        await dataSource.setVarianteAtributos(
          varianteId: widget.varianteId!,
          empresaId: widget.empresaId,
          data: {'atributos': atributos.map((a) => a.toJson()).toList()},
        );
      } else {
        await dataSource.setProductoAtributos(
          productoId: widget.productoId!,
          empresaId: widget.empresaId,
          data: {'atributos': atributos.map((a) => a.toJson()).toList()},
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atributos guardados exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar atributos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
