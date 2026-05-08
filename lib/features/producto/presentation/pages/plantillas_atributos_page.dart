import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_search_field.dart';
import 'package:syncronize/core/widgets/floating_button_icon.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../domain/entities/atributo_plantilla.dart';
import '../../domain/entities/producto_atributo.dart';
import '../bloc/atributo_plantilla/atributo_plantilla_cubit.dart';
import '../bloc/atributo_plantilla/atributo_plantilla_state.dart';
import '../widgets/plantilla_card.dart';
import '../widgets/plantilla_form_dialog.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';

/// Página de gestión de plantillas de atributos con el lenguaje visual del app.
class PlantillasAtributosPage extends StatelessWidget {
  const PlantillasAtributosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<AtributoPlantillaCubit>()..loadPlantillas(),
      child: const _PlantillasAtributosView(),
    );
  }
}

class _PlantillasAtributosView extends StatefulWidget {
  const _PlantillasAtributosView();

  @override
  State<_PlantillasAtributosView> createState() =>
      _PlantillasAtributosViewState();
}

class _PlantillasAtributosViewState extends State<_PlantillasAtributosView> {
  String? _currentEmpresaId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  /// null = todas, true = solo predefinidas, false = solo personalizadas
  bool? _filtroPredefinida;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AtributoPlantilla> _filterPlantillas(List<AtributoPlantilla> source) {
    return source.where((p) {
      if (_filtroPredefinida == true && !p.esPredefinida) return false;
      if (_filtroPredefinida == false && p.esPredefinida) return false;

      if (_searchQuery.isNotEmpty) {
        final txt =
            '${p.nombre} ${p.descripcion ?? ''} ${p.nombreCategoria ?? ''}'
                .toLowerCase();
        if (!txt.contains(_searchQuery)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EmpresaContextCubit, EmpresaContextState>(
      listener: (context, empresaState) {
        if (empresaState is EmpresaContextLoaded) {
          final newEmpresaId = empresaState.context.empresa.id;
          if (_currentEmpresaId != null &&
              _currentEmpresaId != newEmpresaId) {
            _currentEmpresaId = newEmpresaId;
            context.read<AtributoPlantillaCubit>().loadPlantillas();
          } else {
            _currentEmpresaId ??= newEmpresaId;
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: SmartAppBar(
          title: 'Plantillas de Atributos',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          showLogo: false,
          centerTitle: false,
          actions: [
            BlocBuilder<AtributoPlantillaCubit, AtributoPlantillaState>(
              builder: (context, state) {
                if (state is AtributoPlantillaLoaded) {
                  return IconButton(
                    icon: const Icon(Icons.info_outline, size: 18),
                    tooltip: 'Información del plan',
                    onPressed: () => _mostrarInfoLimites(context, state),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              tooltip: 'Actualizar',
              onPressed: () =>
                  context.read<AtributoPlantillaCubit>().loadPlantillas(),
            ),
          ],
        ),
        body: GradientBackground(
          style: GradientStyle.professional,
          child: SafeArea(
            child: BlocConsumer<AtributoPlantillaCubit,
                AtributoPlantillaState>(
              listener: (context, state) {
                if (state is AtributoPlantillaError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (state is AtributoPlantillaSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is AtributoPlantillaLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is AtributoPlantillaError) {
                  return _buildErrorView(context, state.message);
                }

                if (state is AtributoPlantillaLoaded) {
                  return _buildContent(context, state);
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        floatingActionButton:
            BlocBuilder<AtributoPlantillaCubit, AtributoPlantillaState>(
          builder: (context, state) {
            if (state is AtributoPlantillaLoaded) {
              return FloatingButtonIcon(
                icon: Icons.add,
                onPressed: state.puedeCrearMas
                    ? () => _mostrarFormularioCrear(context)
                    : () => _mostrarLimiteAlcanzado(context, state),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  // ============================================
  // CONTENT
  // ============================================

  Widget _buildContent(
      BuildContext context, AtributoPlantillaLoaded state) {
    final plantillas = _filterPlantillas(state.plantillas);

    return Column(
      children: [
        const SizedBox(height: 8),
        _buildSearchBar(),
        const SizedBox(height: 6),
        _buildFilterChips(state, plantillas.length),
        const SizedBox(height: 4),
        if (state.mensajeLimite != null) _buildLimitBanner(state),
        Expanded(
          child: state.plantillas.isEmpty
              ? _buildEmptyState(context, state)
              : plantillas.isEmpty
                  ? _buildEmptyFilteredState()
                  : _buildPlantillasList(context, plantillas),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: CustomSearchField(
        controller: _searchController,
        hintText: 'Buscar plantilla...',
        borderColor: AppColors.blue1,
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
        onClear: () {
          setState(() {
            _searchQuery = '';
            _searchController.clear();
          });
        },
      ),
    );
  }

  Widget _buildFilterChips(AtributoPlantillaLoaded state, int filtradas) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          _buildChip(
            label: 'Sistema',
            value: true,
            icon: Icons.shield_outlined,
            color: AppColors.blue1,
          ),
          const SizedBox(width: 6),
          _buildChip(
            label: 'Personalizadas',
            value: false,
            icon: Icons.star_outline,
            color: Colors.deepPurple,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.blue1.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.blue1.withValues(alpha: 0.3),
                  width: 0.5),
            ),
            child: Text(
              filtradas == state.plantillas.length
                  ? '$filtradas ${filtradas == 1 ? 'plantilla' : 'plantillas'}'
                  : '$filtradas de ${state.plantillas.length}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.blue1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool? value,
    required IconData icon,
    required Color color,
  }) {
    final selected = _filtroPredefinida == value;
    return InkWell(
      onTap: () {
        setState(() {
          _filtroPredefinida = selected ? null : value;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                selected ? color : Colors.grey.withValues(alpha: 0.4),
            width: selected ? 0.6 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 12, color: selected ? color : Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? color : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitBanner(AtributoPlantillaLoaded state) {
    final puede = state.puedeCrearMas;
    final color = puede ? AppColors.blue1 : Colors.orange.shade700;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
      child: GradientContainer(
        shadowStyle: ShadowStyle.neumorphic,
        borderColor: color.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(puede ? Icons.info_outline : Icons.warning_amber_outlined,
                size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                state.mensajeLimite!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantillasList(
      BuildContext context, List<AtributoPlantilla> plantillas) {
    return RefreshIndicator(
      onRefresh: () =>
          context.read<AtributoPlantillaCubit>().loadPlantillas(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 80),
        itemCount: plantillas.length,
        itemBuilder: (context, index) {
          final plantilla = plantillas[index];
          return PlantillaCard(
            plantilla: plantilla,
            onTap: () => _verDetallePlantilla(context, plantilla),
            onEdit: plantilla.esPredefinida
                ? null
                : () => _mostrarFormularioEditar(context, plantilla),
            onDelete: plantilla.esPredefinida
                ? null
                : () => _confirmarEliminar(context, plantilla),
          );
        },
      ),
    );
  }

  // ============================================
  // EMPTY / ERROR
  // ============================================

  Widget _buildEmptyState(
      BuildContext context, AtributoPlantillaLoaded state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard_customize_outlined,
                size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No hay plantillas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Creá plantillas de atributos para reutilizarlas en tus productos',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            if (state.puedeCrearMas) ...[
              const SizedBox(height: 20),
              CustomButton(
                text: 'Crear primera plantilla',
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                backgroundColor: AppColors.blue1,
                onPressed: () => _mostrarFormularioCrear(context),
                height: 38,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilteredState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_alt_off_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Sin coincidencias',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Probá quitar los filtros o cambiar la búsqueda',
              style:
                  TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Limpiar filtros',
              icon: const Icon(Icons.clear, size: 16, color: Colors.white),
              backgroundColor: AppColors.blue1,
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _filtroPredefinida = null;
                });
              },
              height: 36,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Reintentar',
              icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
              backgroundColor: AppColors.blue1,
              onPressed: () =>
                  context.read<AtributoPlantillaCubit>().loadPlantillas(),
              height: 36,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // DIALOGS
  // ============================================

  void _mostrarInfoLimites(
      BuildContext context, AtributoPlantillaLoaded state) {
    final info = state.limitsInfo;
    if (info == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Icon(Icons.workspace_premium_outlined,
                color: AppColors.blue1, size: 20),
            const SizedBox(width: 8),
            const Text('Información del Plan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.blue1.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: AppColors.blue1.withValues(alpha: 0.3),
                    width: 0.5),
              ),
              child: Text(
                'Plan: ${info.plan}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.blue1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Plantillas de Atributos',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            _buildLimitRow(
              'Límite',
              info.plantillasAtributos.esIlimitado
                  ? 'Ilimitado'
                  : '${info.plantillasAtributos.limite}',
            ),
            _buildLimitRow('En uso', '${info.plantillasAtributos.actual}'),
            if (!info.plantillasAtributos.esIlimitado)
              _buildLimitRow(
                'Disponibles',
                '${info.plantillasAtributos.disponible}',
                color: info.plantillasAtributos.alcanzado
                    ? Colors.red
                    : Colors.green,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarFormularioCrear(BuildContext context) {
    final empresaState = context.read<EmpresaContextCubit>().state;
    String? empresaId;
    if (empresaState is EmpresaContextLoaded) {
      empresaId = empresaState.context.empresa.id;
    }
    if (empresaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener la empresa')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<AtributoPlantillaCubit>(),
        child: PlantillaFormDialog(empresaId: empresaId!),
      ),
    );
  }

  void _mostrarFormularioEditar(
      BuildContext context, AtributoPlantilla plantilla) {
    final empresaState = context.read<EmpresaContextCubit>().state;
    String? empresaId;
    if (empresaState is EmpresaContextLoaded) {
      empresaId = empresaState.context.empresa.id;
    }
    if (empresaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener la empresa')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<AtributoPlantillaCubit>(),
        child: PlantillaFormDialog(
          plantilla: plantilla,
          empresaId: empresaId!,
        ),
      ),
    );
  }

  void _verDetallePlantilla(
      BuildContext context, AtributoPlantilla plantilla) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            if (plantilla.icono != null) ...[
              Text(plantilla.icono!,
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                plantilla.nombre,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (plantilla.descripcion != null) ...[
                Text(
                  plantilla.descripcion!,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'Atributos (${plantilla.cantidadAtributos})',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...plantilla.atributos.map((pa) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        _getIconForTipo(pa.atributo.tipoEnum),
                        size: 14,
                        color: AppColors.blue1,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              pa.atributo.nombre,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              pa.atributo.clave,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      if (pa.esRequerido)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3),
                                width: 0.5),
                          ),
                          child: Text(
                            'Requerido',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  IconData _getIconForTipo(AtributoTipo tipo) {
    switch (tipo) {
      case AtributoTipo.texto:
        return Icons.text_fields;
      case AtributoTipo.numero:
        return Icons.numbers;
      case AtributoTipo.select:
        return Icons.arrow_drop_down_circle_outlined;
      case AtributoTipo.boolean:
        return Icons.toggle_on_outlined;
      case AtributoTipo.color:
        return Icons.palette_outlined;
      case AtributoTipo.talla:
        return Icons.straighten;
      case AtributoTipo.material:
        return Icons.layers_outlined;
      case AtributoTipo.capacidad:
        return Icons.inventory_2_outlined;
      case AtributoTipo.multiSelect:
        return Icons.checklist;
    }
  }

  void _confirmarEliminar(
      BuildContext context, AtributoPlantilla plantilla) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Confirmar eliminación',
            style:
                TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        content: Text(
          '¿Estás seguro de que deseas eliminar la plantilla "${plantilla.nombre}"?',
          style: const TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AtributoPlantillaCubit>().eliminarPlantilla(
                    plantilla.id,
                    plantilla.nombre,
                  );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _mostrarLimiteAlcanzado(
      BuildContext context, AtributoPlantillaLoaded state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_outlined,
                color: Colors.orange.shade700, size: 20),
            const SizedBox(width: 8),
            const Text('Límite alcanzado',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Has alcanzado el límite de plantillas de tu plan ${state.limitsInfo?.plan ?? ""}. '
          'Actualiza tu plan para crear más plantillas personalizadas.',
          style: const TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
