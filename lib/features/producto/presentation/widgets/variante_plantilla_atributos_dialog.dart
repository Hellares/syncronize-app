import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Expanded(child: _buildAtributosForm()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantillaSelector() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSelectorHeader(),
            Expanded(child: _buildPlantillasList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.list_alt, color: Colors.blue.shade700, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seleccionar Plantilla',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Elige una plantilla para ${widget.nombre}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantillasList() {
    return BlocBuilder<AtributoPlantillaCubit, AtributoPlantillaState>(
      builder: (context, state) {
        if (state is AtributoPlantillaLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AtributoPlantillaError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<AtributoPlantillaCubit>().loadPlantillas();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (state is AtributoPlantillaLoaded) {
          if (state.plantillas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No hay plantillas disponibles'),
                  const SizedBox(height: 8),
                  const Text(
                    'Crea plantillas en la sección de configuración',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.plantillas.length,
            itemBuilder: (context, index) {
              final plantilla = state.plantillas[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: plantilla.icono != null
                      ? Text(plantilla.icono!, style: const TextStyle(fontSize: 24))
                      : const Icon(Icons.list_alt),
                  title: Text(plantilla.nombre),
                  subtitle: Text(
                    '${plantilla.cantidadAtributos} atributos • ${plantilla.cantidadRequeridos} requeridos',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    setState(() {
                      _plantillaSeleccionada = plantilla;
                    });
                  },
                ),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.tune, color: Colors.blue.shade700, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Atributos - ${widget.nombre}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Plantilla: ${_plantillaSeleccionada!.nombre}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _buildAtributosForm() {
    if (_plantillaSeleccionada!.atributos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'La plantilla no tiene atributos',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Ordenar atributos por orden
    final atributosOrdenados = List.from(_plantillaSeleccionada!.atributos)
      ..sort((a, b) => a.orden.compareTo(b.orden));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Completa los atributos de esta variante',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 16),
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
              onChanged: (valor) {
                setState(() {
                  _valores[plantillaAtributo.atributoId] = valor;
                });
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: CustomButton(
              text: 'Guardar Atributos',
              isLoading: _isLoading,
              onPressed: _guardar,
            ),
          ),
        ],
      ),
    );
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
      categoriaId: null,
      nombre: atributoInfo.nombre,
      clave: atributoInfo.clave,
      tipo: atributoInfo.tipoEnum,
      requerido: requerido,
      descripcion: atributoInfo.descripcion,
      unidad: atributoInfo.unidad,
      valores: valores,
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
