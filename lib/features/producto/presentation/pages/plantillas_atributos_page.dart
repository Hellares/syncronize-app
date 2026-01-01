import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/di/injection_container.dart';
import '../../domain/entities/atributo_plantilla.dart';
import '../bloc/atributo_plantilla/atributo_plantilla_cubit.dart';
import '../bloc/atributo_plantilla/atributo_plantilla_state.dart';
import '../widgets/plantilla_card.dart';
import '../widgets/plantilla_form_dialog.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';

/// Página para listar y gestionar plantillas de atributos
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
  State<_PlantillasAtributosView> createState() => _PlantillasAtributosViewState();
}

class _PlantillasAtributosViewState extends State<_PlantillasAtributosView> {
  String? _currentEmpresaId;

  @override
  Widget build(BuildContext context) {
    return BlocListener<EmpresaContextCubit, EmpresaContextState>(
      listener: (context, empresaState) {
        if (empresaState is EmpresaContextLoaded) {
          final newEmpresaId = empresaState.context.empresa.id;
          // Solo recargar si realmente cambió la empresa
          if (_currentEmpresaId != null && _currentEmpresaId != newEmpresaId) {
            _currentEmpresaId = newEmpresaId;
            // Recargar plantillas de la nueva empresa
            context.read<AtributoPlantillaCubit>().loadPlantillas();
          } else {
            _currentEmpresaId ??= newEmpresaId;
          }
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Plantillas de Atributos'),
        actions: [
          BlocBuilder<AtributoPlantillaCubit, AtributoPlantillaState>(
            builder: (context, state) {
              if (state is AtributoPlantillaLoaded) {
                return IconButton(
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'Información del plan',
                  onPressed: () => _mostrarInfoLimites(context, state),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<AtributoPlantillaCubit, AtributoPlantillaState>(
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

          if (state is AtributoPlantillaLoaded) {
            return _buildPlantillasList(context, state);
          }

          if (state is AtributoPlantillaError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<AtributoPlantillaCubit>().loadPlantillas(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: BlocBuilder<AtributoPlantillaCubit, AtributoPlantillaState>(
        builder: (context, state) {
          if (state is AtributoPlantillaLoaded) {
            return FloatingActionButton.extended(
              onPressed: state.puedeCrearMas
                  ? () => _mostrarFormularioCrear(context)
                  : () => _mostrarLimiteAlcanzado(context, state),
              icon: const Icon(Icons.add),
              label: const Text('Nueva Plantilla'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    ),
    );
  }

  Widget _buildPlantillasList(BuildContext context, AtributoPlantillaLoaded state) {
    if (state.plantillas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard_customize, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No hay plantillas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea plantillas de atributos para reutilizarlas en tus productos',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (state.puedeCrearMas)
              ElevatedButton(
                onPressed: () => _mostrarFormularioCrear(context),
                child: const Text('Crear primera plantilla'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AtributoPlantillaCubit>().loadPlantillas(),
      child: Column(
        children: [
          // Info de límites
          if (state.mensajeLimite != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: state.puedeCrearMas
                  ? Colors.blue.shade50
                  : Colors.orange.shade50,
              child: Row(
                children: [
                  Icon(
                    state.puedeCrearMas ? Icons.info : Icons.warning,
                    color: state.puedeCrearMas ? Colors.blue : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.mensajeLimite!,
                      style: TextStyle(
                        color: state.puedeCrearMas
                            ? Colors.blue.shade900
                            : Colors.orange.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Lista de plantillas
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.plantillas.length,
              itemBuilder: (context, index) {
                final plantilla = state.plantillas[index];
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
          ),
        ],
      ),
    );
  }

  void _mostrarInfoLimites(BuildContext context, AtributoPlantillaLoaded state) {
    final info = state.limitsInfo;
    if (info == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información del Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan actual: ${info.plan}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Plantillas de Atributos',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            _buildLimitRow(
              'Límite:',
              info.plantillasAtributos.esIlimitado
                  ? 'Ilimitado'
                  : '${info.plantillasAtributos.limite}',
            ),
            _buildLimitRow('En uso:', '${info.plantillasAtributos.actual}'),
            if (!info.plantillasAtributos.esIlimitado)
              _buildLimitRow(
                'Disponibles:',
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
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

  void _mostrarFormularioEditar(BuildContext context, AtributoPlantilla plantilla) {
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
        child: PlantillaFormDialog(plantilla: plantilla, empresaId: empresaId!),
      ),
    );
  }

  void _verDetallePlantilla(BuildContext context, AtributoPlantilla plantilla) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            if (plantilla.icono != null) ...[
              Text(plantilla.icono!, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(plantilla.nombre)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (plantilla.descripcion != null) ...[
                Text(plantilla.descripcion!),
                const Divider(height: 24),
              ],
              Text(
                'Atributos (${plantilla.cantidadAtributos})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ...plantilla.atributos.map((pa) => ListTile(
                    dense: true,
                    leading: Icon(
                      _getIconForTipo(pa.atributo.tipoEnum),
                      size: 20,
                    ),
                    title: Text(pa.atributo.nombre),
                    subtitle: Text(pa.atributo.clave),
                    trailing: pa.esRequerido
                        ? Chip(
                            label: const Text('Requerido', style: TextStyle(fontSize: 11)),
                            backgroundColor: Colors.orange.shade100,
                            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                          )
                        : null,
                  )),
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

  IconData _getIconForTipo(dynamic tipo) {
    final tipoStr = tipo.toString().split('.').last;
    switch (tipoStr) {
      case 'texto':
        return Icons.text_fields;
      case 'numero':
        return Icons.numbers;
      case 'select':
        return Icons.arrow_drop_down_circle;
      case 'boolean':
        return Icons.toggle_on;
      case 'fecha':
        return Icons.calendar_today;
      case 'color':
        return Icons.palette;
      default:
        return Icons.help_outline;
    }
  }

  void _confirmarEliminar(BuildContext context, AtributoPlantilla plantilla) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar la plantilla "${plantilla.nombre}"?',
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

  void _mostrarLimiteAlcanzado(BuildContext context, AtributoPlantillaLoaded state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Límite alcanzado'),
        content: Text(
          'Has alcanzado el límite de plantillas de tu plan ${state.limitsInfo?.plan ?? ""}. '
          'Actualiza tu plan para crear más plantillas personalizadas.',
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
