import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../catalogo/presentation/bloc/unidades_medida/unidades_medida_cubit.dart';
import '../../../catalogo/presentation/bloc/unidades_medida/unidades_medida_state.dart';

/// Dropdown reutilizable para seleccionar unidades de medida
/// Usa CustomDropdown para consistencia visual con otros dropdowns
class UnidadMedidaDropdown extends StatefulWidget {
  final String empresaId;
  final String? selectedUnidadId;
  final ValueChanged<String?> onChanged;
  final String? labelText;
  final String? hintText;
  final bool enabled;
  final bool required;
  final Color? borderColor;
  final Widget? prefixIcon;

  /// Si es true y no hay valor seleccionado, auto-selecciona "Unidad" (NIU) por defecto
  final bool autoSelectDefault;

  const UnidadMedidaDropdown({
    super.key,
    required this.empresaId,
    this.selectedUnidadId,
    required this.onChanged,
    this.labelText,
    this.hintText,
    this.enabled = true,
    this.required = false,
    this.borderColor,
    this.prefixIcon,
    this.autoSelectDefault = false,
  });

  @override
  State<UnidadMedidaDropdown> createState() => _UnidadMedidaDropdownState();
}

class _UnidadMedidaDropdownState extends State<UnidadMedidaDropdown> {
  bool _hasAutoSelected = false;

  @override
  void initState() {
    super.initState();
    _loadUnidadesIfNeeded();
  }

  @override
  void didUpdateWidget(UnidadMedidaDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.empresaId != widget.empresaId) {
      _hasAutoSelected = false;
      _forceLoadUnidades();
    }
  }

  /// Carga unidades solo si no están ya cargadas
  void _loadUnidadesIfNeeded() {
    final state = context.read<UnidadMedidaCubit>().state;
    // Solo cargar si no está en estado cargado
    if (state is! UnidadesEmpresaLoaded) {
      context.read<UnidadMedidaCubit>().getUnidadesEmpresa(widget.empresaId);
    }
  }

  /// Fuerza la recarga de unidades (usado cuando cambia empresaId)
  void _forceLoadUnidades() {
    context.read<UnidadMedidaCubit>().getUnidadesEmpresa(widget.empresaId);
  }

  void _tryAutoSelectDefault(UnidadesEmpresaLoaded state) {
    if (!widget.autoSelectDefault ||
        _hasAutoSelected ||
        widget.selectedUnidadId != null ||
        state.unidadesEmpresa.isEmpty) {
      return;
    }

    _hasAutoSelected = true;

    try {
      final unidadPorDefecto = state.unidadesEmpresa.firstWhere(
        (u) => u.unidadMaestra?.codigo == 'NIU',
        orElse: () => state.unidadesEmpresa.first,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onChanged(unidadPorDefecto.id);
        }
      });
    } catch (e) {
      // Si hay error buscando la unidad, no hacer nada
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UnidadMedidaCubit, UnidadMedidaState>(
      builder: (context, state) {
        if (state is UnidadesEmpresaLoading) {
          return _buildLoadingState();
        }

        if (state is UnidadesEmpresaLoaded) {
          // Auto-seleccionar si corresponde
          _tryAutoSelectDefault(state);

          if (state.unidadesEmpresa.isEmpty) {
            return _buildEmptyState();
          }

          return CustomDropdown<String>(
            label: widget.labelText ?? 'Unidad de medida',
            hintText: widget.hintText ?? 'Selecciona una unidad',
            borderColor: widget.borderColor ?? AppColors.blue1,
            value: widget.selectedUnidadId,
            enabled: widget.enabled,
            prefixIcon: widget.prefixIcon ?? const Icon(
              Icons.straighten,
              size: 16,
              color: AppColors.blue1,
            ),
            items: state.unidadesEmpresa.map((unidad) {
              final label = unidad.esPersonalizada
                  ? '${unidad.displayCorto} - ${unidad.nombreEfectivo} (Personalizada)'
                  : '${unidad.displayCorto} - ${unidad.nombreEfectivo}';
              return DropdownItem(
                value: unidad.id,
                label: label,
              );
            }).toList(),
            onChanged: widget.onChanged,
            validator: widget.required
                ? (value) {
                    if (value == null || (value is String && value.isEmpty)) {
                      return 'Debe seleccionar una unidad de medida';
                    }
                    return null;
                  }
                : null,
          );
        }

        if (state is UnidadMedidaError) {
          return _buildErrorState(state.message);
        }

        return _buildLoadingState();
      },
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 35,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomDropdown<String>(
          label: widget.labelText ?? 'Unidad de medida',
          hintText: 'No hay unidades disponibles',
          borderColor: widget.borderColor ?? AppColors.blue1,
          enabled: false,
          items: const [],
          onChanged: null,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _activarUnidadesPopulares,
          icon: const Icon(Icons.add_circle_outline, size: 16),
          label: const Text(
            'Activar unidades populares',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomDropdown<String>(
          label: widget.labelText ?? 'Unidad de medida',
          hintText: 'Error al cargar',
          borderColor: Colors.red,
          enabled: false,
          items: const [],
          onChanged: null,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 14),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 10,
                ),
              ),
            ),
            TextButton(
              onPressed: _forceLoadUnidades,
              child: const Text(
                'Reintentar',
                style: TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _activarUnidadesPopulares() {
    context
        .read<UnidadMedidaCubit>()
        .activarUnidadesPopulares(widget.empresaId)
        .then((_) {
      _forceLoadUnidades();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unidades populares activadas exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al activar unidades: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }
}
