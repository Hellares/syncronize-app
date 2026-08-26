import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/core/widgets/custom_loading.dart';
import 'package:syncronize/core/widgets/custom_proveedor_selector.dart';
import 'package:syncronize/core/widgets/date/custom_date.dart' hide DateFormatter;
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/date_formatter.dart';
import '../bloc/gastos_factura/gastos_factura_cubit.dart';
import '../bloc/gastos_factura/gastos_factura_state.dart';
import '../widgets/analytics/gastos_factura_card.dart';

/// Pantalla dedicada a los gastos de la factura del proveedor: flete,
/// movilidad, embalaje, intereses.
///
/// La tarjeta de Analytics de Compras muestra el panorama del período por
/// defecto; acá se puede apretar el filtro —un proveedor, un rango, el corte
/// anual— para contestar preguntas concretas: cuánto me cobró de movilidad
/// este proveedor en el año, cuánto llevo de flete en total.
class GastosFacturaPage extends StatefulWidget {
  const GastosFacturaPage({super.key, required this.empresaId});

  final String empresaId;

  @override
  State<GastosFacturaPage> createState() => _GastosFacturaPageState();
}

class _GastosFacturaPageState extends State<GastosFacturaPage> {
  /// Atajos: cubren el 90% de las consultas sin abrir el calendario.
  static const _atajos = {
    'ANIO': 'Este año',
    'MES': 'Este mes',
    'ANIO_PASADO': 'Año pasado',
    'RANGO': 'Personalizado',
  };

  String _atajo = 'ANIO';
  DateRange _rango = DateRange();
  String _periodo = 'mensual';
  String? _proveedorId;
  String? _proveedorNombre;

  late final GastosFacturaCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = locator<GastosFacturaCubit>();
    _consultar();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  /// Las fechas del atajo elegido. El rango personalizado manda null cuando
  /// todavía no se eligió nada: sin fechas el backend trae todo el historial,
  /// que es justo lo que se quiere ver al entrar.
  ({String? inicio, String? fin}) _fechas() {
    final hoy = DateTime.now();
    switch (_atajo) {
      case 'ANIO':
        return (
          inicio: DateFormatter.formatForApi(DateTime(hoy.year, 1, 1)),
          fin: DateFormatter.formatForApi(hoy),
        );
      case 'MES':
        return (
          inicio: DateFormatter.formatForApi(DateTime(hoy.year, hoy.month, 1)),
          fin: DateFormatter.formatForApi(hoy),
        );
      case 'ANIO_PASADO':
        return (
          inicio: DateFormatter.formatForApi(DateTime(hoy.year - 1, 1, 1)),
          fin: DateFormatter.formatForApi(DateTime(hoy.year - 1, 12, 31)),
        );
      default:
        return (
          inicio: _rango.startDate != null
              ? DateFormatter.formatForApi(_rango.startDate!)
              : null,
          fin: _rango.endDate != null
              ? DateFormatter.formatForApi(_rango.endDate!)
              : null,
        );
    }
  }

  void _consultar() {
    final f = _fechas();
    _cubit.cargar(
      empresaId: widget.empresaId,
      fechaInicio: f.inicio,
      fechaFin: f.fin,
      periodo: _periodo,
      proveedorId: _proveedorId,
      limpiarProveedor: _proveedorId == null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: SmartAppBar(
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          title: 'Gastos de Factura',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: _consultar,
              tooltip: 'Actualizar',
            ),
          ],
        ),
        body: GradientBackground(
          style: GradientStyle.minimal,
          child: Column(
            children: [
              _buildFiltros(),
              Expanded(
                child: BlocBuilder<GastosFacturaCubit, GastosFacturaState>(
                  builder: (context, state) {
                    if (state is GastosFacturaLoading) {
                      return CustomLoading.small(message: 'Consultando...');
                    }
                    if (state is GastosFacturaError) {
                      return _buildError(state.message);
                    }
                    if (state is GastosFacturaLoaded) {
                      return RefreshIndicator(
                        onRefresh: () async => _consultar(),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildResumenFiltro(),
                              const SizedBox(height: 8),
                              GastosFacturaCard(reporte: state.reporte),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _atajos.entries
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _Chip(
                          texto: e.value,
                          activo: _atajo == e.key,
                          onTap: () {
                            setState(() => _atajo = e.key);
                            // El rango personalizado espera a que elijan las
                            // fechas: consultar acá traería todo el historial
                            // y después se recargaría al elegirlas.
                            if (e.key != 'RANGO') _consultar();
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
          if (_atajo == 'RANGO') ...[
            const SizedBox(height: 8),
            CustomDate(
              height: 31,
              dateType: DateFieldType.dateRange,
              label: 'Rango de fechas',
              hintText: 'Desde — Hasta',
              borderColor: AppColors.blue1,
              initialDateRange: _rango,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              onDateRangeSelected: (r) {
                if (r == null) return;
                setState(() => _rango = r);
                _consultar();
              },
            ),
          ],
          const SizedBox(height: 8),
          CustomProveedorSelector(
            empresaId: widget.empresaId,
            proveedorId: _proveedorId,
            proveedorNombre: _proveedorNombre,
            label: 'Proveedor (todos)',
            onSelected: (p) {
              setState(() {
                _proveedorId = p.proveedorId;
                _proveedorNombre = p.nombre;
              });
              _consultar();
            },
            onCleared: () {
              setState(() {
                _proveedorId = null;
                _proveedorNombre = null;
              });
              _consultar();
            },
          ),
          const SizedBox(height: 8),
          CustomDropdown<String>(
            height: 31,
            label: 'Agrupar por',
            value: _periodo,
            borderColor: AppColors.blue1,
            items: const [
              DropdownItem(value: 'mensual', label: 'Mes'),
              DropdownItem(value: 'anual', label: 'Año'),
              DropdownItem(value: 'semanal', label: 'Semana'),
              DropdownItem(value: 'diario', label: 'Día'),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _periodo = v);
              _consultar();
            },
          ),
        ],
      ),
    );
  }

  /// Qué se está mirando exactamente. Sin esto, un total sin contexto invita a
  /// leerlo como "el total de siempre" cuando en realidad está filtrado.
  Widget _buildResumenFiltro() {
    final partes = <String>[
      _atajos[_atajo] ?? '',
      if (_proveedorNombre != null) _proveedorNombre!,
    ];
    return Row(
      children: [
        Icon(Icons.filter_alt_outlined, size: 12, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Expanded(
          child: AppSubtitle(
            partes.join(' · '),
            font: AppFont.amazonEmberMedium,
            fontSize: 9.5,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildError(String mensaje) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.red.shade300),
            const SizedBox(height: 10),
            AppSubtitle(
              mensaje,
              fontSize: 11,
              maxLines: 4,
              color: Colors.grey.shade700,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _consultar,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.texto,
    required this.activo,
    required this.onTap,
  });

  final String texto;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: activo
              ? AppColors.blue1.withValues(alpha: 0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: activo
                ? AppColors.blue1.withValues(alpha: 0.5)
                : Colors.grey.shade300,
            width: 0.8,
          ),
        ),
        child: AppSubtitle(
          texto,
          font: AppFont.amazonEmberMedium,
          fontSize: 10,
          fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
          color: activo ? AppColors.blue1 : Colors.grey.shade700,
        ),
      ),
    );
  }
}
