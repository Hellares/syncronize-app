import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../empresa/domain/entities/sede.dart';
import '../../domain/entities/ubicacion_almacen.dart';
import '../bloc/ubicacion_almacen_cubit.dart';
import '../bloc/ubicacion_almacen_state.dart';
import '../widgets/ubicacion_form_dialog.dart';

class UbicacionesAlmacenPage extends StatelessWidget {
  const UbicacionesAlmacenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<UbicacionAlmacenCubit>(),
      child: const _UbicacionesAlmacenView(),
    );
  }
}

class _UbicacionesAlmacenView extends StatefulWidget {
  const _UbicacionesAlmacenView();

  @override
  State<_UbicacionesAlmacenView> createState() =>
      _UbicacionesAlmacenViewState();
}

class _UbicacionesAlmacenViewState extends State<_UbicacionesAlmacenView> {
  List<Sede> _sedes = [];
  String? _selectedSedeId;

  @override
  void initState() {
    super.initState();
    _loadSedes();
  }

  void _loadSedes() {
    final state = context.read<EmpresaContextCubit>().state;
    if (state is EmpresaContextLoaded) {
      setState(() {
        _sedes = state.context.sedes;
        if (_sedes.length == 1) {
          _selectedSedeId = _sedes.first.id;
          _loadUbicaciones(_selectedSedeId!);
        }
      });
    }
  }

  void _loadUbicaciones(String sedeId) {
    context.read<UbicacionAlmacenCubit>().loadUbicaciones(sedeId);
  }

  Future<void> _onCrear() async {
    if (_selectedSedeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione una sede primero')),
      );
      return;
    }

    // Obtener la lista actual para el selector de parent
    List<UbicacionAlmacen> currentList = [];
    final cubitState = context.read<UbicacionAlmacenCubit>().state;
    if (cubitState is UbicacionAlmacenLoaded) {
      currentList = cubitState.ubicaciones;
    }

    final result = await UbicacionFormDialog.show(
      context,
      ubicacionesDisponibles: currentList,
    );

    if (result != null && mounted) {
      context.read<UbicacionAlmacenCubit>().crear(_selectedSedeId!, result);
    }
  }

  Future<void> _onEditar(UbicacionAlmacen ubicacion) async {
    List<UbicacionAlmacen> currentList = [];
    final cubitState = context.read<UbicacionAlmacenCubit>().state;
    if (cubitState is UbicacionAlmacenLoaded) {
      currentList = cubitState.ubicaciones;
    }

    final result = await UbicacionFormDialog.show(
      context,
      ubicacion: ubicacion,
      ubicacionesDisponibles: currentList,
    );

    if (result != null && mounted) {
      context.read<UbicacionAlmacenCubit>().actualizar(ubicacion.id, result);
    }
  }

  Future<void> _onDesactivar(UbicacionAlmacen ubicacion) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactivar ubicacion'),
        content: Text(
          'Se desactivara "${ubicacion.nombre}" (${ubicacion.codigo}). Esta seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      context.read<UbicacionAlmacenCubit>().desactivar(ubicacion.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      style: GradientStyle.professional,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(title: 'Ubicaciones de Almacen'),
        floatingActionButton: FloatingActionButton(
          onPressed: _onCrear,
          backgroundColor: AppColors.blue1,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            if (_selectedSedeId != null) {
              _loadUbicaciones(_selectedSedeId!);
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSedeSelector(),
              const SizedBox(height: 16),
              _buildUbicacionesList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSedeSelector() {
    return GradientContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seleccionar Sede',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.blue3,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedSedeId,
            decoration: InputDecoration(
              hintText: 'Seleccione una sede',
              hintStyle: const TextStyle(fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            isExpanded: true,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            items: _sedes.map((sede) {
              return DropdownMenuItem<String>(
                value: sede.id,
                child:
                    Text(sede.nombre, style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedSedeId = val);
                _loadUbicaciones(val);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUbicacionesList() {
    return BlocBuilder<UbicacionAlmacenCubit, UbicacionAlmacenState>(
      builder: (context, state) {
        if (state is UbicacionAlmacenLoading) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is UbicacionAlmacenError) {
          return _buildEmptyState(state.message, isError: true);
        }

        if (state is UbicacionAlmacenLoaded) {
          if (state.ubicaciones.isEmpty) {
            return _buildEmptyState(
              'No hay ubicaciones en esta sede.\nPulse + para crear una.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ubicaciones (${state.ubicaciones.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.blue3,
                ),
              ),
              const SizedBox(height: 10),
              ...state.ubicaciones.map((ub) => _buildUbicacionCard(ub)),
            ],
          );
        }

        // Initial state -- show hint
        if (_selectedSedeId == null) {
          return _buildEmptyState('Seleccione una sede para ver ubicaciones');
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildUbicacionCard(UbicacionAlmacen ub) {
    return Dismissible(
      key: ValueKey(ub.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _onDesactivar(ub);
        return false; // El cubit ya recarga la lista
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      child: GestureDetector(
        onTap: () => _onEditar(ub),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _tipoColor(ub.tipo).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _tipoIcon(ub.tipo),
                  size: 20,
                  color: _tipoColor(ub.tipo),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          ub.codigo,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildTipoChip(ub),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ub.nombre,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (ub.parentNombre != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.subdirectory_arrow_right,
                              size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            ub.parentNombre!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Right side stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (ub.childrenCount > 0)
                    _buildBadge(
                      '${ub.childrenCount} sub',
                      AppColors.blue1,
                    ),
                  if (ub.productosEnUbicacion != null &&
                      ub.productosEnUbicacion! > 0) ...[
                    const SizedBox(height: 4),
                    _buildBadge(
                      '${ub.productosEnUbicacion} prod',
                      Colors.green.shade700,
                    ),
                  ],
                ],
              ),

              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipoChip(UbicacionAlmacen ub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _tipoColor(ub.tipo).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        ub.tipoLabel,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _tipoColor(ub.tipo),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, {bool isError = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.location_off,
              size: 48,
              color: isError ? Colors.red.shade300 : Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color:
                    isError ? Colors.red.shade400 : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _tipoColor(TipoUbicacion tipo) {
    switch (tipo) {
      case TipoUbicacion.zona:
        return AppColors.blue1;
      case TipoUbicacion.pasillo:
        return Colors.orange.shade700;
      case TipoUbicacion.estante:
        return Colors.teal.shade600;
      case TipoUbicacion.nivel:
        return Colors.purple.shade600;
      case TipoUbicacion.bin:
        return Colors.brown.shade600;
    }
  }

  IconData _tipoIcon(TipoUbicacion tipo) {
    switch (tipo) {
      case TipoUbicacion.zona:
        return Icons.map_outlined;
      case TipoUbicacion.pasillo:
        return Icons.view_column_outlined;
      case TipoUbicacion.estante:
        return Icons.shelves;
      case TipoUbicacion.nivel:
        return Icons.layers_outlined;
      case TipoUbicacion.bin:
        return Icons.inventory_2_outlined;
    }
  }
}
