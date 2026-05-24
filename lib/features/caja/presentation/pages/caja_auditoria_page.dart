import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/utils/resource.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../impresoras/domain/services/impresoras_manager.dart';
import '../../domain/entities/arqueo_caja.dart';
import '../../domain/entities/caja.dart';
import '../../domain/entities/caja_auditoria.dart';
import '../../domain/entities/cierre_caja.dart';
import '../../domain/entities/movimiento_caja.dart';
import '../../domain/entities/resumen_caja.dart';
import '../../domain/usecases/get_auditoria_usecase.dart';
import '../services/caja_ticket_data.dart';
import '../services/cierre_caja_esc_pos_generator.dart';
import '../widgets/resumen_caja_card.dart';

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
        actions: [
          // Botón siempre visible. Si la caja sigue ABIERTA, imprime un
          // snapshot "ESTADO DE CAJA" usando el resumen en vivo; si está
          // CERRADA, imprime el ticket de cierre definitivo.
          FutureBuilder<Resource<CajaAuditoria>>(
            future: _future,
            builder: (context, snap) {
              if (snap.data is! Success<CajaAuditoria>) {
                return const SizedBox.shrink();
              }
              final auditoria =
                  (snap.data as Success<CajaAuditoria>).data;
              return PopupMenuButton<String>(
                icon: const Icon(Icons.print_rounded),
                tooltip: 'Imprimir',
                onSelected: (value) {
                  if (value == 'resumen') {
                    _imprimir(auditoria, conDetalle: false);
                  } else if (value == 'detalle') {
                    _imprimir(auditoria, conDetalle: true);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'resumen',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.receipt_rounded, size: 20),
                      title: Text('Solo resumen',
                          style: TextStyle(fontSize: 13)),
                      subtitle: Text('Totales + métodos de pago',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'detalle',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.list_alt_rounded, size: 20),
                      title: Text('Resumen + detalle',
                          style: TextStyle(fontSize: 13)),
                      subtitle: Text('Incluye todas las ventas y egresos',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
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
                      padding: const EdgeInsets.all(10),
                      children: [
                        _buildHeader(auditoria.caja),
                        const SizedBox(height: 10),
                        // Mismo ResumenCajaCard que usa CajaPage en la
                        // pantalla principal — datos mapeados desde el
                        // resumen actual de la auditoría.
                        ResumenCajaCard(
                          resumen: _toResumenCaja(auditoria.resumenActual),
                          montoApertura: auditoria.caja.montoApertura,
                        ),
                        if (auditoria.cierre != null) ...[
                          const SizedBox(height: 10),
                          _buildResultadoCierreCard(
                              auditoria.cierre!, auditoria.resumenActual),
                        ],
                        if (auditoria.arqueos.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _buildArqueosCard(auditoria.arqueos),
                        ],
                        const SizedBox(height: 10),
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
  // Mismo diseño que CajaPage cuando hay caja abierta (icono punto venta +
  // código + sede + badge estado + grid de info), con campos extra propios
  // de auditoría: cierre y duración.

  Widget _buildHeader(Caja caja) {
    final cerrada = caja.estado == EstadoCaja.cerrada;
    final iconColor = cerrada ? AppColors.textSecondary : AppColors.green;
    final duracion = (caja.fechaCierre ?? DateTime.now())
        .difference(caja.fechaApertura);
    final dur = '${duracion.inHours}h ${duracion.inMinutes.remainder(60)}min';

    return GradientContainer(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.point_of_sale_rounded,
                  color: iconColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSubtitle(
                      caja.codigo,
                      fontSize: 12,
                      color: AppColors.blue3,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      caja.sedeNombre ?? 'Sede',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
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
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Cajero',
                  caja.usuarioNombre ?? '-',
                  Icons.person_rounded,
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _buildInfoItemEnd(
                    'Apertura',
                    DateFormatter.formatDateTime(caja.fechaApertura),
                    Icons.access_time_rounded,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  cerrada ? 'Cierre' : 'En curso',
                  caja.fechaCierre != null
                      ? DateFormatter.formatDateTime(caja.fechaCierre!)
                      : '—',
                  Icons.stop_rounded,
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _buildInfoItemEnd(
                    'Duración',
                    dur,
                    Icons.timelapse_rounded,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Monto Apertura',
                  _currencyFormat.format(caja.montoApertura),
                  Icons.attach_money_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Helpers de info item (mismo estilo que CajaPage) ────────────────

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItemEnd(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(width: 6),
        Icon(icon, size: 16, color: AppColors.textSecondary),
      ],
    );
  }

  // ─── Mapper: ResumenActualCaja → ResumenCaja (entity compartida) ─────
  //
  // ResumenCajaCard recibe ResumenCaja con ResumenMetodoPago[]. La
  // auditoría tiene ResumenActualCaja con DetalleMetodoCaja[] (que también
  // incluye `apertura`, que ResumenCajaCard ya recibe aparte por param).

  ResumenCaja _toResumenCaja(ResumenActualCaja r) {
    return ResumenCaja(
      totalIngresos: r.totalIngresos,
      totalEgresos: r.totalEgresos,
      saldo: r.saldoActual,
      saldoEfectivo: r.saldoEfectivo,
      detalles: r.detallesPorMetodo
          .map((d) => ResumenMetodoPago(
                metodoPago: d.metodoPago,
                totalIngresos: d.ingresos,
                totalEgresos: d.egresos,
                saldo: d.saldo,
              ))
          .toList(),
      egresoAnulacionVenta: r.egresoAnulacionVenta,
      cantidadAnulaciones: r.cantidadAnulaciones,
      egresosPorCategoria: r.egresosPorCategoria,
    );
  }

  // ─── Resultado del cierre (mini-card extra cuando caja cerrada) ──────
  //
  // El ResumenCajaCard arriba ya muestra los totales recalculados. Acá
  // sumamos lo específico del cierre: conteo físico vs esperado, diferencia
  // y un banner naranja si el snapshot ya no coincide con el resumen
  // recalculado (anulación posterior al cierre).

  Widget _buildResultadoCierreCard(
      CierreCaja cierre, ResumenActualCaja actual) {
    final drift =
        (actual.totalIngresos - cierre.totalIngresos).abs() > 0.01 ||
            (actual.totalEgresos - cierre.totalEgresos).abs() > 0.01;

    return GradientContainer(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSubtitle('RESULTADO DEL CIERRE',
              fontSize: 11, color: AppColors.blue3),
          const SizedBox(height: 12),
          _kvRow('Esperado',
              _currencyFormat.format(cierre.totalEsperado), bold: true),
          const SizedBox(height: 6),
          _kvRow('Conteo físico',
              _currencyFormat.format(cierre.totalConteoFisico)),
          const SizedBox(height: 6),
          _kvRow(
            'Diferencia',
            _currencyFormat.format(cierre.diferencia),
            color: cierre.diferencia.abs() < 0.01
                ? AppColors.green
                : (cierre.diferencia < 0 ? AppColors.red : AppColors.orange),
            bold: true,
          ),
          if (drift) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '⚠ El cierre snapshot difiere del recálculo actual. Posible '
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
            const Divider(height: 20),
            const Text(
              'Conteo por método',
              style: TextStyle(
                  fontSize: 11,
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
            const Divider(height: 20),
            Text(
              cierre.observaciones!,
              style: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Fila compacta de detalle de cierre por método, con desglose
  /// Ingresos / Egresos (si aplican) + tabla Esperado / Conteo / Dif.
  Widget _buildMetodoCierreRow(DetalleCierreMetodo d) {
    final hasIngresos = d.ingresos.abs() > 0.01;
    final hasEgresos = d.egresos.abs() > 0.01;
    final hasApertura = d.apertura.abs() > 0.01;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            d.metodoPago.label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.blue3,
            ),
          ),
          const SizedBox(height: 2),
          // Apertura / Ingresos / Egresos en una fila (solo los que aplican).
          if (hasApertura || hasIngresos || hasEgresos)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                children: [
                  if (hasApertura)
                    Expanded(
                      child: Text(
                        'Aper: ${_currencyFormat.format(d.apertura)}',
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ),
                  if (hasIngresos)
                    Expanded(
                      child: Text(
                        'Ing: +${_currencyFormat.format(d.ingresos)}',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.green),
                      ),
                    ),
                  if (hasEgresos)
                    Expanded(
                      child: Text(
                        'Egr: -${_currencyFormat.format(d.egresos)}',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.red),
                      ),
                    ),
                ],
              ),
            ),
          // Tabla Esperado / Conteo / Dif. (lo que se compara al cerrar).
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: Row(
              children: [
                Expanded(
                  child: _miniKv('Esperado',
                      _currencyFormat.format(d.esperado), null),
                ),
                Expanded(
                  child: _miniKv('Conteo',
                      _currencyFormat.format(d.conteoFisico), null),
                ),
                Expanded(
                  child: _miniKv(
                    'Dif.',
                    _currencyFormat.format(d.diferencia),
                    d.diferencia.abs() < 0.01
                        ? AppColors.green
                        : (d.diferencia < 0
                            ? AppColors.red
                            : AppColors.orange),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniKv(String label, String value, Color? color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
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
      // Excluir transferencias auto del cierre (DEPOSITO/RETIRO_TESORERIA):
      // son barridos hacia/desde la Caja Central, no movimientos operativos.
      // El listado de arriba SI los muestra para trazabilidad visual; estos
      // totales reflejan solo actividad operativa de la caja.
      if (m.categoria == CategoriaMovimientoCaja.depositoTesoreria ||
          m.categoria == CategoriaMovimientoCaja.retiroTesoreria) {
        continue;
      }
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
                    // Adelanto de cotización cuya cotización quedó RECHAZADA
                    // → su devolución ya se generó (en esta caja o en tesorería).
                    if (m.categoria ==
                            CategoriaMovimientoCaja.adelantoCotizacion &&
                        m.cotizacionFueAnulada) ...[
                      const SizedBox(width: 6),
                      _badge('DEVUELTO', AppColors.orange),
                    ],
                    // MANUAL solo aplica a movs que el cajero registra
                    // explícitamente desde el form de Nuevo Movimiento.
                    // Excluimos categorías auto-generadas por flujos
                    // (cotización, etc.) aunque la fila en BD venga con
                    // esManual=true por bug histórico.
                    if (m.esManual &&
                        m.categoria !=
                            CategoriaMovimientoCaja.adelantoCotizacion &&
                        m.categoria !=
                            CategoriaMovimientoCaja
                                .devolucionAdelantoCotizacion) ...[
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

  // ─── Impresión ESC-POS ───────────────────────────────────────────────

  Future<void> _imprimir(CajaAuditoria auditoria,
      {required bool conDetalle}) async {
    try {
      final ticketData = await resolverCajaTicketData(context, auditoria.caja);
      final manager = locator<ImpresorasManager>();
      final principal = await manager.getPrincipal();
      if (!mounted) return;
      if (principal == null) {
        _toast('No hay impresora principal configurada', Colors.orange);
        return;
      }

      // Mapeo de detalles "vivo" para el caso caja ABIERTA (sin cierre).
      // El generator solo los usa cuando cierre==null.
      final resumen = _toResumenCaja(auditoria.resumenActual);
      final detallesVivo = resumen.detalles
          .where((d) => d.totalIngresos > 0 || d.totalEgresos > 0)
          .toList();

      final bytes = await CierreCajaEscPosGenerator.generate(
        caja: auditoria.caja,
        cierre: auditoria.cierre,
        empresaNombre: ticketData.empresaNombre,
        empresaRazonSocial: ticketData.razonSocial,
        empresaRuc: ticketData.ruc,
        empresaDireccion: ticketData.direccion,
        empresaTelefono: ticketData.telefono,
        sedeNombre: auditoria.caja.sedeNombre,
        logoEmpresa: ticketData.logoBytes,
        paperWidth: principal.anchoPapel.mm,
        movimientos: conDetalle ? auditoria.movimientos : null,
        totalIngresosVivo: resumen.totalIngresos,
        totalEgresosVivo: resumen.totalEgresos,
        detallesVivo: detallesVivo,
        egresoAnulacionVenta: resumen.egresoAnulacionVenta,
        cantidadAnulaciones: resumen.cantidadAnulaciones,
        egresosPorCategoria: resumen.egresosPorCategoria,
      );

      final ok = await manager.imprimirEnPrincipal(bytes);
      if (!mounted) return;
      _toast(
        ok
            ? (conDetalle ? 'Cierre + detalle impreso' : 'Resumen impreso')
            : 'No se pudo imprimir',
        ok ? Colors.green : Colors.orange,
      );
    } catch (e) {
      if (!mounted) return;
      _toast('Error al imprimir: $e', Colors.red);
    }
  }

  void _toast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
