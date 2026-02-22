import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/combo_config_historial.dart';
import '../bloc/combo_cubit.dart';
import '../bloc/combo_state.dart';

class ComboHistorialPreciosPage extends StatelessWidget {
  final String comboId;
  final String empresaId;

  const ComboHistorialPreciosPage({
    super.key,
    required this.comboId,
    required this.empresaId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          locator<ComboCubit>()..loadHistorialPrecios(comboId: comboId),
      child: _HistorialView(comboId: comboId),
    );
  }
}

class _HistorialView extends StatelessWidget {
  final String comboId;

  const _HistorialView({required this.comboId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'HISTORIAL DE PRECIOS',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context
                  .read<ComboCubit>()
                  .loadHistorialPrecios(comboId: comboId);
            },
          ),
        ],
      ),
      body: BlocBuilder<ComboCubit, ComboState>(
        builder: (context, state) {
          if (state is ComboLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ComboHistorialLoaded) {
            if (state.historial.isEmpty) {
              return _buildEmptyState();
            }
            return _buildHistorialList(state.historial);
          }

          if (state is ComboError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar el historial',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('No se pudo cargar el historial'));
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Sin historial de cambios',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Los cambios de precio se registran aqui',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorialList(List<ComboConfigHistorialEntry> historial) {
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: historial.length,
      itemBuilder: (context, index) {
        return _buildHistorialTile(historial[index]);
      },
    );
  }

  Widget _buildHistorialTile(ComboConfigHistorialEntry entry) {
    final iconData = _getIconForTipoCambio(entry.tipoCambio);
    final color = _getColorForTipoCambio(entry.tipoCambio);

    return GradientContainer(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(iconData, size: 16, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSubtitle(
                        _getLabelForTipoCambio(entry.tipoCambio),
                        fontSize: 12,
                      ),
                      AppSubtitle(
                        DateFormatter.formatDateTime(entry.creadoEn),
                        fontSize: 10,
                        color: AppColors.blueGrey,
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: AppSubtitle(
                    entry.usuarioNombre,
                    fontSize: 9,
                    color: AppColors.blue1,
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Valores anterior y nuevo
            if (entry.valorAnterior != null) ...[
              _buildValorRow('Anterior', entry.valorAnterior!, Colors.red),
            ],
            _buildValorRow('Nuevo', entry.valorNuevo, Colors.green),

            if (entry.razon != null && entry.razon!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.notes, size: 14, color: AppColors.blueGrey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: AppSubtitle(
                      entry.razon!,
                      fontSize: 10,
                      color: AppColors.blueGrey,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildValorRow(
    String label,
    Map<String, dynamic> valores,
    Color color,
  ) {
    final text = valores.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');

    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 2),
      child: Row(
        children: [
          Icon(
            label == 'Anterior' ? Icons.arrow_back : Icons.arrow_forward,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: AppSubtitle(
              text,
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForTipoCambio(String tipoCambio) {
    switch (tipoCambio) {
      case 'TIPO_PRECIO':
        return Icons.swap_horiz;
      case 'DESCUENTO':
        return Icons.percent;
      case 'COMPONENTE_PRECIO':
        return Icons.view_list;
      case 'PRECIO_FIJO_SEDE':
        return Icons.store;
      case 'OFERTA_COMBO':
        return Icons.local_offer;
      default:
        return Icons.history;
    }
  }

  Color _getColorForTipoCambio(String tipoCambio) {
    switch (tipoCambio) {
      case 'TIPO_PRECIO':
        return Colors.blue;
      case 'DESCUENTO':
        return Colors.orange;
      case 'COMPONENTE_PRECIO':
        return Colors.purple;
      case 'PRECIO_FIJO_SEDE':
        return Colors.teal;
      case 'OFERTA_COMBO':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getLabelForTipoCambio(String tipoCambio) {
    switch (tipoCambio) {
      case 'TIPO_PRECIO':
        return 'Cambio de tipo de precio';
      case 'DESCUENTO':
        return 'Cambio de descuento';
      case 'COMPONENTE_PRECIO':
        return 'Cambio de precio de componente';
      case 'PRECIO_FIJO_SEDE':
        return 'Cambio de precio fijo por sede';
      case 'OFERTA_COMBO':
        return 'Cambio de oferta';
      default:
        return tipoCambio;
    }
  }
}
