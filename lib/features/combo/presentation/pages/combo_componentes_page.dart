import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/floating_button_text.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../../core/di/injection_container.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../producto/presentation/bloc/sede_selection/sede_selection_cubit.dart';
import '../../domain/entities/componente_combo.dart';
import '../bloc/combo_cubit.dart';
import '../bloc/combo_state.dart';
import '../widgets/componente_list_tile.dart';
import '../widgets/agregar_componente_dialog.dart';

class ComboComponentesPage extends StatelessWidget {
  final String comboId;
  final String empresaId;

  const ComboComponentesPage({
    super.key,
    required this.comboId,
    required this.empresaId,
  });

  @override
  Widget build(BuildContext context) {
    final sedeId = _resolveSedeId(context);
    return BlocProvider(
      create: (_) => locator<ComboCubit>()
        ..loadComponentes(
          comboId: comboId,
          empresaId: empresaId,
          sedeId: sedeId,
        ),
      child: _ComboComponentesView(
        comboId: comboId,
        empresaId: empresaId,
        sedeId: sedeId,
      ),
    );
  }

  static String _resolveSedeId(BuildContext ctx) {
    final selected = ctx.read<SedeSelectionCubit>().selectedSedeId;
    if (selected != null) return selected;
    final empresaState = ctx.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded &&
        empresaState.context.sedes.isNotEmpty) {
      return empresaState.context.sedePrincipal!.id;
    }
    return '';
  }
}

class _ComboComponentesView extends StatefulWidget {
  final String comboId;
  final String empresaId;
  final String sedeId;

  const _ComboComponentesView({
    required this.comboId,
    required this.empresaId,
    required this.sedeId,
  });

  @override
  State<_ComboComponentesView> createState() => _ComboComponentesViewState();
}

class _ComboComponentesViewState extends State<_ComboComponentesView> {
  // Estado de selección múltiple
  bool _modoSeleccion = false;
  final Set<String> _componentesSeleccionados = {};

  // Flag para trackear si hubo cambios (agregar/eliminar componentes)
  bool _huboCambios = false;

  void _toggleModoSeleccion() {
    setState(() {
      _modoSeleccion = !_modoSeleccion;
      if (!_modoSeleccion) {
        _componentesSeleccionados.clear();
      }
    });
  }

  void _toggleSeleccion(String componenteId) {
    setState(() {
      if (_componentesSeleccionados.contains(componenteId)) {
        _componentesSeleccionados.remove(componenteId);
      } else {
        _componentesSeleccionados.add(componenteId);
      }
    });
  }

  void _seleccionarTodos(List<ComponenteCombo> componentes) {
    setState(() {
      _componentesSeleccionados.clear();
      _componentesSeleccionados.addAll(componentes.map((c) => c.id));
    });
  }

  void _deseleccionarTodos() {
    setState(() {
      _componentesSeleccionados.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // ← Impide el pop automático del sistema
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          // Ya se hizo pop (poco probable aquí porque canPop es false)
          return;
        }

        // Aquí haces lo que antes hacías en onWillPop
        if (context.mounted) {
          Navigator.of(context).pop(_huboCambios); // Envías el resultado
        }
        // No necesitas return false/true → canPop ya lo controla
      },
      child: Scaffold(
        appBar: SmartAppBar(
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          title: _modoSeleccion
              ? '${_componentesSeleccionados.length} seleccionados'
              : 'COMPONENTES DEL COMBO',
          leftWidget: _modoSeleccion
              ? IconButton(
                  icon: const Icon(Icons.close, color: AppColors.white),
                  onPressed: _toggleModoSeleccion,
                )
              : null,
          actions: [
            if (!_modoSeleccion)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  context.read<ComboCubit>().loadComponentes(
                    comboId: widget.comboId,
                    empresaId: widget.empresaId,
                    sedeId: widget.sedeId,
                  );
                },
              ),
          ],
        ),
        body: BlocConsumer<ComboCubit, ComboState>(
          listener: (context, state) {
            if (state is ComboOperationSuccess ||
                state is ComponenteDeleted ||
                state is ComponentesBatchDeleted) {
              final message = state is ComboOperationSuccess
                  ? state.message
                  : state is ComponenteDeleted
                  ? state.message
                  : (state as ComponentesBatchDeleted).message;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message), backgroundColor: Colors.green),
              );

              // Marcar que hubo cambios para actualizar la página anterior
              _huboCambios = true;

              // Recargar componentes después de agregar/eliminar
              context.read<ComboCubit>().loadComponentes(
                comboId: widget.comboId,
                empresaId: widget.empresaId,
                sedeId: widget.sedeId,
              );
              // Salir del modo selección
              if (_modoSeleccion) {
                setState(() {
                  _modoSeleccion = false;
                  _componentesSeleccionados.clear();
                });
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
            if (state is ComboLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ComponentesLoaded) {
              return Column(
                children: [
                  // Barra de acciones para modo selección
                  if (_modoSeleccion && state.componentes.isNotEmpty)
                    _buildBarraSeleccion(state.componentes),

                  // Lista de componentes
                  Expanded(
                    child: _buildComponentesList(context, state.componentes),
                  ),
                ],
              );
            }

            return const Center(
              child: Text('No se pudieron cargar los componentes'),
            );
          },
        ),
        floatingActionButton: _buildFloatingActionButton(context),
      ),
    );
  }

  Widget _buildBarraSeleccion(List<ComponenteCombo> componentes) {
    final todosSeleccionados =
        _componentesSeleccionados.length == componentes.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: AppColors.blue.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: todosSeleccionados
                ? _deseleccionarTodos
                : () => _seleccionarTodos(componentes),
            icon: Icon(
              todosSeleccionados ? Icons.deselect : Icons.select_all,
              size: 18,
            ),
            label: Text(
              todosSeleccionados ? 'Deseleccionar todos' : 'Seleccionar todos',
            ),
          ),
          const Spacer(),
          if (_componentesSeleccionados.isNotEmpty)
            TextButton.icon(
              onPressed: () => _confirmarEliminarSeleccionados(context),
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 18,
              ),
              label: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildComponentesList(
    BuildContext context,
    List<ComponenteCombo> componentes,
  ) {
    if (componentes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay componentes en este combo',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega productos para crear el combo',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: componentes.length,
      itemBuilder: (context, index) {
        final componente = componentes[index];
        final isSelected = _componentesSeleccionados.contains(componente.id);

        return ComponenteListTile(
          componente: componente,
          modoSeleccion: _modoSeleccion,
          isSelected: isSelected,
          onTap: _modoSeleccion ? () => _toggleSeleccion(componente.id) : null,
          onDelete: _modoSeleccion
              ? null
              : () => _confirmarEliminar(context, componente),
          onLongPress: !_modoSeleccion
              ? () {
                  setState(() {
                    _modoSeleccion = true;
                    _componentesSeleccionados.add(componente.id);
                  });
                }
              : null,
        );
      },
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    if (_modoSeleccion) {
      return null; // Ocultar FAB en modo selección
    }

    return FloatingButtonText(
      heroTag: 'combo_componentes_fab',
      onPressed: () => _mostrarAgregarComponenteDialog(context),
      label: 'Agregar Componente',
      icon: Icons.add,
    );
  }

  void _mostrarAgregarComponenteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<ComboCubit>(),
        child: AgregarComponenteDialog(
          comboId: widget.comboId,
          empresaId: widget.empresaId,
          sedeId: widget.sedeId,
        ),
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, ComponenteCombo componente) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Componente'),
        content: const Text(
          '¿Estás seguro de eliminar este componente del combo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ComboCubit>().deleteComponente(
                componenteId: componente.id,
                empresaId: widget.empresaId,
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminarSeleccionados(BuildContext context) {
    final cantidad = _componentesSeleccionados.length;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Componentes'),
        content: Text(
          '¿Estás seguro de eliminar $cantidad componente${cantidad > 1 ? 's' : ''} del combo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          CustomButton(
            text: 'Eliminar $cantidad',
            onPressed: () {
              Navigator.of(dialogContext).pop();

              // Eliminar componentes en batch (una sola petición)
              context.read<ComboCubit>().deleteComponentesBatch(
                componenteIds: _componentesSeleccionados.toList(),
                empresaId: widget.empresaId,
              );
            },
            backgroundColor: Colors.red,
            icon: const Icon(Icons.delete, size: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
