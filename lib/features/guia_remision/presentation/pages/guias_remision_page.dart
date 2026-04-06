import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../domain/entities/guia_remision.dart';
import '../../domain/repositories/guia_remision_repository.dart';
import '../bloc/guia_remision_list_cubit.dart';
import '../bloc/guia_remision_list_state.dart';

class GuiasRemisionPage extends StatelessWidget {
  const GuiasRemisionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GuiaRemisionListCubit(locator<GuiaRemisionRepository>())..cargar(),
      child: const _GuiasRemisionView(),
    );
  }
}

class _GuiasRemisionView extends StatefulWidget {
  const _GuiasRemisionView();

  @override
  State<_GuiasRemisionView> createState() => _GuiasRemisionViewState();
}

class _GuiasRemisionViewState extends State<_GuiasRemisionView> {
  final _searchController = TextEditingController();
  String? _filtroTipo;
  String? _filtroEstado;
  String? _filtroSunatStatus;
  String? _filtroMotivo;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(title: 'Guias de Remision'),
        body: Column(
          children: [
            _buildFiltros(),
            Expanded(
              child: BlocBuilder<GuiaRemisionListCubit, GuiaRemisionListState>(
                builder: (context, state) {
                  if (state is GuiaRemisionListLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is GuiaRemisionListError) {
                    return Center(
                      child: Text(state.message, style: TextStyle(color: Colors.red.shade400)),
                    );
                  }
                  if (state is GuiaRemisionListLoaded) {
                    if (state.guias.isEmpty) {
                      return const Center(
                        child: Text('No hay guias de remision', style: TextStyle(color: Colors.grey)),
                      );
                    }
                    return _buildList(state);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFabs(),
      ),
    );
  }

  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          // Barra de busqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por codigo, cliente o documento...',
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        context.read<GuiaRemisionListCubit>().setBusqueda(null);
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(fontSize: 12),
            onChanged: (_) => setState(() {}),
            onSubmitted: (v) =>
                context.read<GuiaRemisionListCubit>().setBusqueda(v.isEmpty ? null : v),
          ),
          const SizedBox(height: 8),
          // Chips de filtro - Tipo
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Todos', null, _filtroTipo, (v) {
                  setState(() => _filtroTipo = v);
                  context.read<GuiaRemisionListCubit>().setFiltroTipo(v);
                }),
                _filterChip('Remitente', 'REMITENTE', _filtroTipo, (v) {
                  setState(() => _filtroTipo = v);
                  context.read<GuiaRemisionListCubit>().setFiltroTipo(v);
                }),
                _filterChip('Transportista', 'TRANSPORTISTA', _filtroTipo, (v) {
                  setState(() => _filtroTipo = v);
                  context.read<GuiaRemisionListCubit>().setFiltroTipo(v);
                }),
                const SizedBox(width: 12),
                // Estado chips
                _statusChip('Borrador', 'BORRADOR', Colors.grey),
                _statusChip('Enviado', 'ENVIADO', Colors.blue),
                _statusChip('Aceptado', 'ACEPTADO', Colors.green),
                _statusChip('Rechazado', 'RECHAZADO', Colors.red),
                _statusChip('Anulado', 'ANULADO', Colors.red.shade900),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Chips de filtro - SUNAT status + Motivo
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _sunatStatusChip('Pendiente', 'PENDIENTE', Colors.orange),
                _sunatStatusChip('Aceptado', 'ACEPTADO', Colors.green),
                _sunatStatusChip('Rechazado', 'RECHAZADO', Colors.red),
                _sunatStatusChip('Error', 'ERROR_COMUNICACION', Colors.red.shade300),
                _sunatStatusChip('Procesando', 'PROCESANDO', Colors.blue),
                const SizedBox(width: 12),
                _motivoChip('Venta', 'VENTA'),
                _motivoChip('Compra', 'COMPRA'),
                _motivoChip('Traslado', 'TRASLADO_ENTRE_ESTABLECIMIENTOS'),
                _motivoChip('Devolucion', 'DEVOLUCION'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? value, String? current, ValueChanged<String?> onTap) {
    final selected = current == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? AppColors.blue1 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? AppColors.blue1 : Colors.grey.shade300),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: selected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String label, String value, Color color) {
    final selected = _filtroEstado == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () {
          setState(() => _filtroEstado = selected ? null : value);
          context.read<GuiaRemisionListCubit>().setFiltroEstado(selected ? null : value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.15) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? color : Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? color : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sunatStatusChip(String label, String value, Color color) {
    final selected = _filtroSunatStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () {
          setState(() => _filtroSunatStatus = selected ? null : value);
          context.read<GuiaRemisionListCubit>().setFiltroSunatStatus(selected ? null : value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.15) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? color : Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_upload, size: 10, color: color),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? color : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _motivoChip(String label, String value) {
    final selected = _filtroMotivo == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () {
          setState(() => _filtroMotivo = selected ? null : value);
          context.read<GuiaRemisionListCubit>().setFiltroMotivo(selected ? null : value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? AppColors.blue1.withValues(alpha: 0.15) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? AppColors.blue1 : Colors.grey.shade300),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: selected ? AppColors.blue1 : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(GuiaRemisionListLoaded state) {
    return RefreshIndicator(
      onRefresh: () => context.read<GuiaRemisionListCubit>().cargar(page: state.currentPage),
      child: Column(
        children: [
          // Resumen
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${state.total} guias',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  'Pag ${state.currentPage}/${state.totalPages}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: state.guias.length,
              itemBuilder: (context, i) => _GuiaRemisionCard(
                guia: state.guias[i],
                onEnviar: () => _enviar(state.guias[i]),
                onTap: () => context.push('/empresa/guias-remision/${state.guias[i].id}'),
              ),
            ),
          ),
          // Paginacion
          if (state.totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: state.currentPage > 1
                        ? () => context.read<GuiaRemisionListCubit>().cargar(page: state.currentPage - 1)
                        : null,
                  ),
                  Text(
                    '${state.currentPage} / ${state.totalPages}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: state.currentPage < state.totalPages
                        ? () => context.read<GuiaRemisionListCubit>().cargar(page: state.currentPage + 1)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFabs() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'enviarPendientes',
          onPressed: _enviarPendientes,
          backgroundColor: Colors.orange,
          child: const Icon(Icons.send, size: 18, color: Colors.white),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.extended(
          heroTag: 'nuevaGuia',
          onPressed: () => context.push('/empresa/guias-remision/nueva'),
          backgroundColor: AppColors.blue1,
          icon: const Icon(Icons.add, size: 18, color: Colors.white),
          label: const Text('Nueva Guia', style: TextStyle(fontSize: 12, color: Colors.white)),
        ),
      ],
    );
  }

  Future<void> _enviar(GuiaRemision guia) async {
    try {
      await context.read<GuiaRemisionListCubit>().enviar(guia.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${guia.codigoGenerado} enviado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _enviarPendientes() async {
    final result = await context.read<GuiaRemisionListCubit>().enviarPendientes();
    if (mounted) {
      final data = result is Success ? (result as Success).data : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data != null
                ? 'Enviados: ${data['enviados']}, Errores: ${data['errores']}'
                : 'Error al enviar pendientes',
          ),
        ),
      );
    }
  }
}

// ── Card individual de guia de remision ──

class _GuiaRemisionCard extends StatelessWidget {
  final GuiaRemision guia;
  final VoidCallback onEnviar;
  final VoidCallback onTap;

  const _GuiaRemisionCard({
    required this.guia,
    required this.onEnviar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: GradientContainer(
          borderColor: _borderColor,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: tipo + codigo + estado + sunat
                Row(
                  children: [
                    _tipoChip(),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        guia.codigoGenerado,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
                    _estadoChip(),
                    const SizedBox(width: 4),
                    _sunatStatusChip(),
                  ],
                ),
                const SizedBox(height: 6),
                // Cliente
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        guia.clienteDenominacion,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      guia.clienteNumeroDocumento,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Motivo traslado
                Row(
                  children: [
                    Icon(Icons.local_shipping, size: 11, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      guia.motivoTrasladoEnum?.label ?? guia.motivoTraslado,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Fecha + ruta
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 11, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      DateFormatter.formatDate(guia.fechaEmision),
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 4),
                // Ruta: partida -> llegada
                Row(
                  children: [
                    Icon(Icons.place, size: 11, color: Colors.green.shade400),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        guia.puntoPartidaDireccion,
                        style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 9, color: Colors.grey.shade400),
                    const SizedBox(width: 5),
                    Icon(Icons.place, size: 11, color: Colors.red.shade400),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        guia.puntoLlegadaDireccion,
                        style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // Documento origen
                if (guia.documentoOrigenCodigo != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.link, size: 11, color: Colors.indigo.shade300),
                      const SizedBox(width: 4),
                      Text(
                        'Origen: ${guia.documentoOrigenCodigo}',
                        style: TextStyle(fontSize: 9, color: Colors.indigo.shade400, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ],
                // Error
                if (guia.errorProveedor != null && guia.sunatStatus == 'PENDIENTE') ...[
                  const SizedBox(height: 4),
                  Text(
                    guia.errorProveedor!.length > 80
                        ? '${guia.errorProveedor!.substring(0, 80)}...'
                        : guia.errorProveedor!,
                    style: TextStyle(fontSize: 9, color: Colors.red.shade400),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Acciones
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (guia.estadoEnum.puedeEnviar)
                      _actionButton(Icons.send, 'Enviar', Colors.blue, onEnviar),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color get _borderColor {
    switch (guia.estado) {
      case 'ACEPTADO':
        return Colors.green.shade200;
      case 'RECHAZADO':
        return Colors.red.shade200;
      case 'ANULADO':
        return Colors.red.shade300;
      case 'ENVIADO':
        return Colors.blue.shade200;
      case 'BORRADOR':
        return Colors.grey.shade300;
      default:
        return AppColors.blueborder;
    }
  }

  Widget _tipoChip() {
    final isRemitente = guia.tipo == 'REMITENTE';
    final color = isRemitente ? Colors.indigo : Colors.teal;
    final label = isRemitente ? 'REM' : 'TRANS';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _estadoChip() {
    Color color;
    switch (guia.estado) {
      case 'BORRADOR':
        color = Colors.grey;
        break;
      case 'REGISTRADO':
        color = Colors.blueGrey;
        break;
      case 'ENVIADO':
        color = Colors.blue;
        break;
      case 'ACEPTADO':
        color = Colors.green;
        break;
      case 'RECHAZADO':
        color = Colors.red;
        break;
      case 'ANULADO':
        color = Colors.red.shade900;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        guia.estadoEnum.label,
        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _sunatStatusChip() {
    Color color;
    String label;
    switch (guia.sunatStatus) {
      case 'ACEPTADO':
        color = Colors.green;
        label = 'ACEPTADO';
        break;
      case 'RECHAZADO':
        color = Colors.red;
        label = 'RECHAZADO';
        break;
      case 'PROCESANDO':
        color = Colors.blue;
        label = 'PROCESANDO';
        break;
      case 'ERROR_COMUNICACION':
        color = Colors.red.shade300;
        label = 'ERROR';
        break;
      default:
        if (guia.intentosEnvio == 0) {
          color = Colors.orange;
          label = 'PENDIENTE';
        } else {
          color = Colors.orange;
          label = 'REINTENTO';
        }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 3),
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
