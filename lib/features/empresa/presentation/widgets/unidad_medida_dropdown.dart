import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../catalogo/domain/entities/unidad_medida.dart';
import '../../../catalogo/presentation/bloc/unidades_medida/unidades_medida_cubit.dart';
import '../../../catalogo/presentation/bloc/unidades_medida/unidades_medida_state.dart';

/// Dropdown reutilizable para seleccionar unidades de medida
class UnidadMedidaDropdown extends StatefulWidget {
  final String empresaId;
  final String? selectedUnidadId;
  final ValueChanged<String?> onChanged;
  final String? labelText;
  final String? hintText;
  final bool enabled;
  final String? errorText;
  final bool required;

  const UnidadMedidaDropdown({
    super.key,
    required this.empresaId,
    this.selectedUnidadId,
    required this.onChanged,
    this.labelText,
    this.hintText,
    this.enabled = true,
    this.errorText,
    this.required = false,
  });

  @override
  State<UnidadMedidaDropdown> createState() => _UnidadMedidaDropdownState();
}

class _UnidadMedidaDropdownState extends State<UnidadMedidaDropdown> {
  @override
  void initState() {
    super.initState();
    _loadUnidades();
  }

  @override
  void didUpdateWidget(UnidadMedidaDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.empresaId != widget.empresaId) {
      _loadUnidades();
    }
  }

  void _loadUnidades() {
    context.read<UnidadMedidaCubit>().getUnidadesEmpresa(widget.empresaId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UnidadMedidaCubit, UnidadMedidaState>(
      builder: (context, state) {
        if (state is UnidadesEmpresaLoading) {
          return _buildLoadingDropdown();
        }

        if (state is UnidadesEmpresaLoaded) {
          return _buildDropdown(state.unidadesEmpresa);
        }

        if (state is UnidadMedidaError) {
          return _buildErrorDropdown(state.message);
        }

        return _buildEmptyDropdown();
      },
    );
  }

  Widget _buildLoadingDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: widget.labelText ?? 'Unidad de medida',
        hintText: widget.hintText ?? 'Selecciona una unidad',
        border: const OutlineInputBorder(),
        suffixIcon: const SizedBox(
          width: 20,
          height: 20,
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      items: const [],
      onChanged: null,
    );
  }

  Widget _buildDropdown(List<EmpresaUnidadMedida> unidades) {
    if (unidades.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: widget.labelText ?? 'Unidad de medida',
              hintText: 'No hay unidades disponibles',
              border: const OutlineInputBorder(),
              errorText: widget.errorText,
            ),
            items: const [],
            onChanged: null,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _activarUnidadesPopulares(),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Activar unidades populares'),
          ),
        ],
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: widget.selectedUnidadId,
      decoration: InputDecoration(
        labelText: widget.labelText ?? 'Unidad de medida',
        hintText: widget.hintText ?? 'Selecciona una unidad',
        border: const OutlineInputBorder(),
        errorText: widget.errorText,
      ),
      items: unidades.map((unidad) {
        return DropdownMenuItem<String>(
          value: unidad.id,
          child: Row(
            children: [
              Text(unidad.displayCorto),
              const SizedBox(width: 8),
              Text(
                '- ${unidad.nombreEfectivo}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              if (unidad.esPersonalizada)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Personalizada',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
      onChanged: widget.enabled ? widget.onChanged : null,
      validator: widget.required
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor selecciona una unidad de medida';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildErrorDropdown(String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: widget.labelText ?? 'Unidad de medida',
            hintText: widget.hintText ?? 'Selecciona una unidad',
            border: const OutlineInputBorder(),
            errorText: 'Error al cargar unidades',
          ),
          items: const [],
          onChanged: null,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 16),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: _loadUnidades,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      ],
    );
  }

  Widget _buildEmptyDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: widget.labelText ?? 'Unidad de medida',
        hintText: widget.hintText ?? 'Selecciona una unidad',
        border: const OutlineInputBorder(),
        errorText: widget.errorText,
      ),
      items: const [],
      onChanged: null,
    );
  }

  void _activarUnidadesPopulares() {
    context
        .read<UnidadMedidaCubit>()
        .activarUnidadesPopulares(widget.empresaId)
        .then((_) {
      _loadUnidades();
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
