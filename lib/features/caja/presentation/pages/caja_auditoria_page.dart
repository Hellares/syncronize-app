import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/utils/resource.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../domain/entities/arqueo_caja.dart';
import '../../domain/entities/caja.dart';
import '../../domain/entities/caja_auditoria.dart';
import '../../domain/entities/cierre_caja.dart';
import '../../domain/entities/movimiento_caja.dart';
import '../../domain/usecases/get_auditoria_usecase.dart';

/// Pantalla de auditoría completa de una caja (apertura → cierre).
///
/// Diferencias clave vs movimientos_caja_page:
///  - Muestra TODOS los movimientos, incluso contrapartidas auto-generadas
///    (las marca con badge "REVERSO" para trazabilidad de anulaciones).
///  - Funciona tanto para caja ABIERTA (resumen en vivo) como CERRADA (con
///    snapshot del cierre + drift contra resumen actual).
///  - Header compacto con apertura/cierre/cajero/sede + duración.
///  - Filtros locales por tipo, método, búsqueda.
class CajaAuditoriaPage extends StatefulWidget {
  final String cajaId;

  const CajaAuditoriaPage({super.key, required this.cajaId});

  @override
  State<CajaAuditoriaPage> createState() => _CajaAuditoriaPageState();
}

class _CajaAuditoriaPageState extends State<CajaAuditoriaPage> {
  late Future<Resource<CajaAuditoria>> _future;
  TipoMovimientoCaja? _filtroTipo;
  MetodoPago? _filtroMetodo;
  String _busqueda = '';
  bool _mostrarAnulados = true;
  bool _mostrarContrapartidas = false;

  static final _currencyFormat = NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/ ',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _future = locator<GetAuditoriaUseCase>().call(cajaId: widget.cajaId);
  }

  Future<void> _reload() async {
    setState(() {
      _future = locator<GetAuditoriaUseCase>().call(cajaId: widget.cajaId);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Auditoría de Caja',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
      ),
      body: GradientContainer(
        child: FutureBuilder<Resource<CajaAuditoria>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final resource = snap.data;
            if (resource == null || resource is Error<CajaAuditoria>) {
              final msg = resource is Error<CajaAuditoria>
                  ? resource.message
                  : 'Error desconocido';
              return _buildError(msg);
            }
            final auditoria = (resource as Success<CajaAuditoria>).data;
            // Filtrado calculado una vez para que el footer fijo de totales
            // y la card de movimientos compartan el mismo subset.
            final filtrados = _filtrarMovimientos(auditoria.movimientos);
            return Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildHeader(auditoria.caja),
                        const SizedBox(height: 12),
                        if (auditoria.cierre != null)
                          _buildCierreCard(
                              auditoria.cierre!, auditoria.resumenActual)
                        else
                          _buildResumenActualCard(auditoria.resumenActual),
                        const SizedBox(height: 12),
                        if (auditoria.arqueos.isNotEmpty) ...[
                          _buildArqueosCard(auditoria.arqueos),
                          const SizedBox(height: 12),
                        ],
                        _buildMovimientosCard(
                            auditoria.movimientos, filtrados),
                      ],
                    ),
                  ),
                ),
                _buildTotalesFijos(filtrados),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.red),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────

  Widget _buildHeader(Caja caja) {
    final duracion = (caja.fechaCierre ?? DateTime.now())
        .difference(caja.fechaApertura);
    final dur =
        '${duracion.inHours}h ${duracion.inMinutes.remainder(60)}min';

    return GradientContainer(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppSubtitle(
                  caja.codigo,
                  fontSize: 12,
                  color: AppColors.blue3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: caja.estado.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  caja.estado.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: caja.estado.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${caja.sedeNombre ?? 'Sede'} · ${caja.usuarioNombre ?? 'Cajero'}',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: _infoRow(
                  Icons.play_arrow_rounded,
                  'Apertura',
                  DateFormatter.formatDateTime(caja.fechaApertura),
                ),
              ),
              Expanded(
                child: _infoRow(
                  Icons.stop_rounded,
                  caja.estado == EstadoCaja.cerrada ? 'Cierre' : 'En curso',
                  caja.fechaCierre != null
                      ? DateFormatter.formatDateTime(caja.fechaCierre!)
                      : '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _infoRow(
                  Icons.attach_money_rounded,
                  'Apertura',
                  _currencyFormat.format(caja.montoApertura),
                ),
              ),
              Expanded(
                child: _infoRow(
                  Icons.timelapse_rounded,
                  'Duración',
                  dur,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Cierre (caja cerrada) ───────────────────────────────────────────

  Widget _buildCierreCard(CierreCaja cierre, ResumenActualCaja actual) {
    // Drift: si alguien anuló un movimiento DESPUÉS de cerrar, el snapshot
    // del cierre ya no coincide con el resumen actual recalculado.
    final drift =
        (actual.totalIngresos - cierre.totalIngresos).abs() > 0.01 ||
            (actual.totalEgresos - cierre.totalEgresos).abs() > 0.01;

    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSubtitle('Resultado del Cierre',
              fontSize: 14, color: AppColors.blue3),
          const SizedBox(height: 10),
          _kvRow('Esperado',
              _currencyFormat.format(cierre.totalEsperado), bold: true),
          _kvRow('Conteo físico',
              _currencyFormat.format(cierre.totalConteoFisico)),
          _kvRow(
            'Diferencia',
            _currencyFormat.format(cierre.diferencia),
            color: cierre.diferencia.abs() < 0.01
                ? AppColors.green
                : (cierre.diferencia < 0 ? AppColors.red : AppColors.orange),
            bold: true,
          ),
          if (drift) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '⚠ El cierre snapshot difiere del recalculo actual. Posible '
                'anulación posterior al cierre. Cierre I/E: '
                'S/${cierre.totalIngresos.toStringAsFixed(2)} / '
                'S/${cierre.totalEgresos.toStringAsFixed(2)}. '
                'Actual I/E: '
                'S/${actual.totalIngresos.toStringAsFixed(2)} / '
                'S/${actual.totalEgresos.toStringAsFixed(2)}.',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ],
          if (cierre.detalles.isNotEmpty) ...[
            const Divider(height: 24),
            const Text(
              'Por método de pago',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            ...cierre.detalles
                .where((d) =>
                    d.ingresos > 0 ||
                    d.egresos > 0 ||
                    d.conteoFisico > 0 ||
                    d.apertura > 0)
                .map(_buildMetodoCierreRow),
          ],
          if (cierre.observaciones != null &&
              cierre.observaciones!.isNotEmpty) ...[
            const Divider(height: 24),
            Text(
              cierre.observaciones!,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetodoCierreRow(DetalleCierreMetodo d) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              d.metodoPago.label,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              _currencyFormat.format(d.esperado),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              _currencyFormat.format(d.conteoFisico),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              _currencyFormat.format(d.diferencia),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: d.diferencia.abs() < 0.01
                    ? AppColors.green
                    : (d.diferencia < 0 ? AppColors.red : AppColors.orange),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Resumen actual (caja abierta) ───────────────────────────────────

  Widget _buildResumenActualCard(ResumenActualCaja r) {
    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSubtitle('Saldo en Curso',
              fontSize: 14, color: AppColors.blue3),
          const SizedBox(height: 10),
          _kvRow('Ingresos', _currencyFormat.format(r.totalIngresos),
              color: AppColors.green),
          _kvRow('Egresos', _currencyFormat.format(r.totalEgresos),
              color: AppColors.red),
          _kvRow('Apertura', _currencyFormat.format(r.montoApertura)),
          const Divider(height: 20),
          _kvRow('Saldo total operado',
              _currencyFormat.format(r.saldoActual),
              bold: true, color: AppColors.blue1),
          _kvRow('Saldo efectivo (en gaveta)',
              _currencyFormat.format(r.saldoEfectivo),
              bold: true, color: AppColors.green),
          if (r.detallesPorMetodo.any((d) => d.saldo > 0)) ...[
            const Divider(height: 24),
            const Text(
              'Por método de pago',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            ...r.detallesPorMetodo
                .where((d) => d.ingresos > 0 || d.egresos > 0 || d.apertura > 0)
                .map((d) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(d.metodoPago.label,
                                style: const TextStyle(fontSize: 12)),
                          ),
                          Expanded(
                            child: Text(
                              '+${_currencyFormat.format(d.ingresos)}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.green),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '-${_currencyFormat.format(d.egresos)}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.red),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _currencyFormat.format(d.saldo),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
          ],
        ],
      ),
    );
  }

  // ─── Arqueos intermedios ─────────────────────────────────────────────

  Widget _buildArqueosCard(List<ArqueoCaja> arqueos) {
    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSubtitle('Arqueos intermedios (${arqueos.length})',
              fontSize: 14, color: AppColors.blue3),
          const SizedBox(height: 10),
          ...arqueos.map((a) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_note_rounded,
                      size: 16,
                      color: a.diferencia.abs() < 0.01
                          ? AppColors.green
                          : AppColors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${a.tipo.label} · ${DateFormatter.formatDateTime(a.fechaArqueo)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Por ${a.realizadoPorNombre ?? '?'}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _currencyFormat.format(a.diferencia),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: a.diferencia.abs() < 0.01
                            ? AppColors.green
                            : (a.diferencia < 0
                                ? AppColors.red
                                : AppColors.orange),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ─── Movimientos ─────────────────────────────────────────────────────

  /// Aplica los filtros activos (tipo/método/búsqueda/anulados/contrapartidas)
  /// a la lista completa de movimientos. Se calcula desde el `build` para que
  /// el footer fijo de totales y la card de movimientos compartan el mismo
  /// subset sin recomputar.
  List<MovimientoAuditoria> _filtrarMovimientos(
      List<MovimientoAuditoria> todos) {
    return todos.where((m) {
      if (!_mostrarAnulados && m.anulado) return false;
      if (!_mostrarContrapartidas && m.esContrapartida) return false;
      if (_filtroTipo != null && m.tipo != _filtroTipo) return false;
      if (_filtroMetodo != null && m.metodoPago != _filtroMetodo) return false;
      if (_busqueda.isNotEmpty) {
        final q = _busqueda.toLowerCase();
        final d = (m.descripcion ?? '').toLowerCase();
        final v = (m.ventaCodigo ?? '').toLowerCase();
        if (!d.contains(q) &&
            !v.contains(q) &&
            !m.categoria.label.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Widget _buildMovimientosCard(
    List<MovimientoAuditoria> todos,
    List<MovimientoAuditoria> filtrados,
  ) {
    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppSubtitle(
                  'Movimientos (${filtrados.length} de ${todos.length})',
                  fontSize: 14,
                  color: AppColors.blue3,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded, size: 20),
                color: AppColors.blue1,
                onPressed: _showFiltrosSheet,
              ),
            ],
          ),
          if (_filtroTipo != null ||
              _filtroMetodo != null ||
              _busqueda.isNotEmpty ||
              !_mostrarAnulados ||
              _mostrarContrapartidas)
            Wrap(
              spacing: 6,
              children: [
                if (_filtroTipo != null)
                  _chipFiltro(_filtroTipo!.label,
                      () => setState(() => _filtroTipo = null)),
                if (_filtroMetodo != null)
                  _chipFiltro(_filtroMetodo!.label,
                      () => setState(() => _filtroMetodo = null)),
                if (_busqueda.isNotEmpty)
                  _chipFiltro('Buscar: $_busqueda',
                      () => setState(() => _busqueda = '')),
                if (!_mostrarAnulados)
                  _chipFiltro('Sin anulados',
                      () => setState(() => _mostrarAnulados = true)),
                if (_mostrarContrapartidas)
                  _chipFiltro('Con contrapartidas',
                      () => setState(() => _mostrarContrapartidas = false)),
              ],
            ),
          const SizedBox(height: 8),
          if (filtrados.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Sin movimientos en este filtro',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            )
          else
            Column(
              children: filtrados.map(_buildMovimientoRow).toList(),
            ),
        ],
      ),
    );
  }

  /// Footer fijo al pie de la pantalla con totales de la lista filtrada.
  /// Excluye anulados (no cuentan al neto real). Aislado del scroll del
  /// ListView para que el cajero siempre vea cuánto cierra mientras revisa.
  Widget _buildTotalesFijos(List<MovimientoAuditoria> filtrados) {
    double inOk = 0, outOk = 0;
    for (final m in filtrados) {
      if (m.anulado) continue;
      if (m.tipo == TipoMovimientoCaja.ingreso) {
        inOk += m.monto;
      } else {
        outOk += m.monto;
      }
    }
    final neto = inOk - outOk;

    return Material(
      elevation: 8,
      color: AppColors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: _buildTotalColumn(
                  'Ingresos',
                  _currencyFormat.format(inOk),
                  AppColors.green,
                ),
              ),
              Expanded(
                child: _buildTotalColumn(
                  'Egresos',
                  _currencyFormat.format(outOk),
                  AppColors.red,
                ),
              ),
              Expanded(
                child: _buildTotalColumn(
                  'Neto',
                  _currencyFormat.format(neto),
                  neto >= 0 ? AppColors.green : AppColors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMovimientoRow(MovimientoAuditoria m) {
    final esIngreso = m.tipo == TipoMovimientoCaja.ingreso;
    final color = esIngreso ? AppColors.green : AppColors.red;
    final sign = esIngreso ? '+' : '-';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.greyLight, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(m.categoria.icon,
              size: 18,
              color: m.anulado
                  ? AppColors.textSecondary.withValues(alpha: 0.4)
                  : color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        m.descripcion?.isNotEmpty == true
                            ? m.descripcion!
                            : m.categoria.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          decoration:
                              m.anulado ? TextDecoration.lineThrough : null,
                          color: m.anulado
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (m.anulado) ...[
                      const SizedBox(width: 6),
                      _badge('ANULADO', AppColors.red),
                    ],
                    if (m.esContrapartida) ...[
                      const SizedBox(width: 6),
                      _badge('REVERSO', AppColors.orange),
                    ],
                    if (m.esManual) ...[
                      const SizedBox(width: 6),
                      _badge('MANUAL', AppColors.blue3),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${m.metodoPago.label} · '
                  '${DateFormatter.formatDateTime(m.fechaMovimiento)}'
                  '${m.ventaCodigo != null ? ' · ${m.ventaCodigo}' : ''}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                if (m.motivoAnulacion != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    m.motivoAnulacion!,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.red.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$sign${_currencyFormat.format(m.monto)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: m.anulado
                  ? AppColors.textSecondary.withValues(alpha: 0.4)
                  : color,
              decoration: m.anulado ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Filtros sheet ───────────────────────────────────────────────────

  void _showFiltrosSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(builder: (ctx, setSt) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSubtitle('Filtros',
                      fontSize: 16, color: AppColors.blue3),
                  const SizedBox(height: 16),
                  // Tipo
                  const Text('Tipo',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      _toggleChip(
                          'Todos',
                          _filtroTipo == null,
                          () => setSt(() => _filtroTipo = null)),
                      ...TipoMovimientoCaja.values.map((t) => _toggleChip(
                            t.label,
                            _filtroTipo == t,
                            () => setSt(() => _filtroTipo = t),
                          )),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Método
                  const Text('Método de pago',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      _toggleChip(
                          'Todos',
                          _filtroMetodo == null,
                          () => setSt(() => _filtroMetodo = null)),
                      ...MetodoPago.values
                          .where((m) => m != MetodoPago.credito)
                          .map((m) => _toggleChip(
                                m.label,
                                _filtroMetodo == m,
                                () => setSt(() => _filtroMetodo = m),
                              )),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Toggles
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: const Text('Mostrar anulados',
                              style: TextStyle(fontSize: 13)),
                          value: _mostrarAnulados,
                          onChanged: (v) =>
                              setSt(() => _mostrarAnulados = v ?? true),
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: const Text('Ver contrapartidas',
                              style: TextStyle(fontSize: 13)),
                          value: _mostrarContrapartidas,
                          onChanged: (v) =>
                              setSt(() => _mostrarContrapartidas = v ?? false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Buscar (descripción, venta, categoría)',
                      prefixIcon: Icon(Icons.search_rounded, size: 18),
                      isDense: true,
                    ),
                    controller: TextEditingController(text: _busqueda),
                    onChanged: (v) => _busqueda = v,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {}); // refrescar lista
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kvRow(String k, String v,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Text(
            v,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _chipFiltro(String label, VoidCallback onRemove) {
    return InputChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onDeleted: onRemove,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _toggleChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
