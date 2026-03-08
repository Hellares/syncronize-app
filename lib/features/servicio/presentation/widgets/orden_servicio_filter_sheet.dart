import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/servicio_filtros.dart';

class OrdenServicioFilterSheet extends StatefulWidget {
  final OrdenServicioFiltros filtros;

  const OrdenServicioFilterSheet({super.key, required this.filtros});

  @override
  State<OrdenServicioFilterSheet> createState() =>
      _OrdenServicioFilterSheetState();
}

class _OrdenServicioFilterSheetState extends State<OrdenServicioFilterSheet> {
  late String? _tipoServicio;
  late String? _prioridad;
  late String? _fechaDesde;
  late String? _fechaHasta;

  static const _tiposServicio = {
    'REPARACION': 'Reparacion',
    'MANTENIMIENTO': 'Mantenimiento',
    'INSTALACION': 'Instalacion',
    'DIAGNOSTICO': 'Diagnostico',
    'ACTUALIZACION': 'Actualizacion',
    'LIMPIEZA': 'Limpieza',
    'RECUPERACION_DATOS': 'Recuperacion de datos',
    'CONFIGURACION': 'Configuracion',
    'CONSULTORIA': 'Consultoria',
    'FORMACION': 'Formacion',
    'SOPORTE': 'Soporte',
  };

  static const _prioridades = {
    'BAJA': 'Baja',
    'NORMAL': 'Normal',
    'ALTA': 'Alta',
    'URGENTE': 'Urgente',
    'EMERGENCIA': 'Emergencia',
  };

  @override
  void initState() {
    super.initState();
    _tipoServicio = widget.filtros.tipoServicio;
    _prioridad = widget.filtros.prioridad;
    _fechaDesde = widget.filtros.fechaDesde;
    _fechaHasta = widget.filtros.fechaHasta;
  }

  bool get _hasFilters =>
      _tipoServicio != null ||
      _prioridad != null ||
      _fechaDesde != null ||
      _fechaHasta != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Row(
              children: [
                const Icon(Icons.filter_list, color: AppColors.blue1, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Filtros avanzados',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                if (_hasFilters)
                  TextButton(
                    onPressed: _limpiarFiltros,
                    child: const Text('Limpiar',
                        style: TextStyle(color: Colors.red, fontSize: 13)),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Tipo de servicio
            DropdownButtonFormField<String>(
              value: _tipoServicio,
              decoration: InputDecoration(
                labelText: 'Tipo de servicio',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.blue1),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                ..._tiposServicio.entries.map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                ),
              ],
              onChanged: (v) => setState(() => _tipoServicio = v),
            ),
            const SizedBox(height: 12),

            // Prioridad
            DropdownButtonFormField<String>(
              value: _prioridad,
              decoration: InputDecoration(
                labelText: 'Prioridad',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.blue1),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ..._prioridades.entries.map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                ),
              ],
              onChanged: (v) => setState(() => _prioridad = v),
            ),
            const SizedBox(height: 12),

            // Fecha range
            Row(
              children: [
                Expanded(
                  child: _DatePickerField(
                    label: 'Desde',
                    value: _fechaDesde,
                    onChanged: (v) => setState(() => _fechaDesde = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DatePickerField(
                    label: 'Hasta',
                    value: _fechaHasta,
                    onChanged: (v) => setState(() => _fechaHasta = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _aplicarFiltros,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Aplicar filtros'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue1,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _limpiarFiltros() {
    setState(() {
      _tipoServicio = null;
      _prioridad = null;
      _fechaDesde = null;
      _fechaHasta = null;
    });
  }

  void _aplicarFiltros() {
    final filtros = OrdenServicioFiltros(
      search: widget.filtros.search,
      estado: widget.filtros.estado,
      tipoServicio: _tipoServicio,
      prioridad: _prioridad,
      clienteId: widget.filtros.clienteId,
      tecnicoId: widget.filtros.tecnicoId,
      fechaDesde: _fechaDesde,
      fechaHasta: _fechaHasta,
    );
    Navigator.pop(context, filtros);
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = value != null && value!.length >= 10
        ? DateFormatter.formatDate(DateTime.parse(value!))
        : value ?? '';

    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: displayText),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.blue1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        suffixIcon: value != null
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => onChanged(null),
              )
            : const Icon(Icons.calendar_today, size: 18),
      ),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value != null ? DateTime.parse(value!) : now,
          firstDate: DateTime(2020),
          lastDate: now.add(const Duration(days: 365)),
        );
        if (picked != null) {
          onChanged(picked.toIso8601String().substring(0, 10));
        }
      },
    );
  }
}
