import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../domain/entities/movimiento_caja.dart';
import '../utils/tesoreria_grouping.dart';

/// Card que renderiza un [TesoreriaGroup]:
///  - Si es grupo de 1: fila simple igual a un movimiento suelto.
///  - Si es grupo de N: header (titulo + monto total) + chips por metodo
///    con el desglose (ej. "💵 Efectivo +S/150,00", "📱 Yape +S/30,00").
class TesoreriaGroupCard extends StatelessWidget {
  final TesoreriaGroup group;

  /// Callback al tap. Si null, el card no es clicable.
  final VoidCallback? onTap;

  const TesoreriaGroupCard({super.key, required this.group, this.onTap});

  String _money(double v) => 'S/ ${v.toStringAsFixed(2)}';

  Color get _color =>
      group.esIngreso ? AppColors.greendark : AppColors.red;
  String get _signo => group.esIngreso ? '+' : '-';

  @override
  Widget build(BuildContext context) {
    // Ciclo apertura↔cierre tiene su propio layout (bloque retiro + flecha
    // + bloque depósito), independiente del agrupado tradicional.
    if (group.kind == TesoreriaGroupKind.cicloCaja) {
      return _cicloCard();
    }
    // Render como card grupal si hay >1 item, o si es un barrido con
    // reversos vinculados (necesitamos espacio para el banner). También
    // cuando el barrido tiene un solo movimiento en la central (la
    // "Recepción") pero su barridoResumen abarca varios métodos o algún
    // digital→banco: ahí hay que dibujar los chips, no el tile simple.
    final resumen0 = _barridoResumen(group.items.first);
    final tieneResumenRico = resumen0.length > 1 || resumen0.any((r) => r.aBanco);
    final renderAsCard =
        group.isGrouped || group.tieneReversosVinculados || tieneResumenRico;
    if (!renderAsCard) {
      return _singleTile(group.items.first);
    }
    return _groupedCard();
  }

  /// Card del ciclo apertura↔cierre: bloque retiro arriba, flecha ↓
  /// indentada, bloque depósito abajo. Badge "devuelto al cierre" en
  /// pill top-right si el ciclo cerró.
  Widget _cicloCard() {
    final retiro = group.cicloRetiro;
    final depositos = group.cicloDepositos;
    final cajaCodigo = group.cicloCajaCodigo ?? 'CAJA';
    final cajero = group.cicloCajeroNombre;
    final cierra = group.cicloCierraNombre;
    final cierreCompleto = group.cicloCompleto;
    final radius = BorderRadius.circular(10);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: AppColors.white,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: AppColors.blue1.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (retiro != null) _buildBloqueRetiro(retiro, cajero),
                    if (retiro != null && depositos.isNotEmpty)
                      const SizedBox(height: 10),
                    if (depositos.isNotEmpty)
                      _buildBloqueDeposito(
                        depositos: depositos,
                        cajaCodigo: cajaCodigo,
                        cajero: cajero,
                        cierra: cierra,
                        indent: retiro != null,
                      ),
                    if (group.tieneReversosVinculados) ...[
                      const SizedBox(height: 10),
                      _ReversosAfectanBanner(group: group),
                    ],
                  ],
                ),
              ),
              // Badge "devuelto al cierre" en pill top-right.
              if (cierreCompleto)
                Positioned(
                  top: 8,
                  right: 10,
                  child: _badgePillDevueltoAlCierre(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBloqueRetiro(MovimientoCaja retiro, String? cajeroFallback) {
    final cajaCodigo =
        retiro.metadata?['cajaAperturaCodigo'] as String? ?? '';
    final cajero = cajeroFallback ?? retiro.registradoPorNombre;
    final metodoLabel = retiro.metodoPago.label;
    final fechaStr = DateFormatter.formatDateTime(retiro.fechaMovimiento);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSubtitle('Retiro de Tesorería', color: AppColors.red),
              const SizedBox(height: 4),
              AppSubtitle('Retiro para apertura: $cajaCodigo', color: AppColors.black54),
              if (cajero != null)
                AppLabelText('Cajero: $cajero', color: AppColors.black54),
              AppLabelText('$metodoLabel · $fechaStr', color: AppColors.black54),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '-${_money(retiro.monto)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildBloqueDeposito({
    required List<MovimientoCaja> depositos,
    required String cajaCodigo,
    required String? cajero,
    required String? cierra,
    required bool indent,
  }) {
    final montoTotal = depositos.fold<double>(0, (s, m) => s + m.monto);
    final fechaCierre = depositos.first.fechaMovimiento;
    final fechaStr = DateFormatter.formatDateTime(fechaCierre);

    // Desglose completo del barrido (efectivo + digital→banco), informativo.
    // Lo adjunta el backend en la metadata del INGRESO de tesorería.
    final resumen = _barridoResumen(depositos.first);
    final hayDigitalABanco = resumen.any((r) => r.aBanco);
    // Total del barrido = efectivo (bóveda) + medios digitales (bancos).
    final totalBarrido = resumen.isNotEmpty
        ? resumen.fold<double>(0, (s, r) => s + r.monto)
        : montoTotal;

    // Si hay múltiples métodos (en el resumen o en los depósitos), mostramos
    // chips inline después de la info.
    final multiMetodo = depositos.length > 1 || resumen.length > 1;

    final cajeroEsCerro =
        cajero != null && cierra != null && _sameName(cajero, cierra);

    return Padding(
      padding: EdgeInsets.only(left: indent ? 15 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: info (izq) + monto/barrido (der).
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (indent)
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 6),
                  child: Icon(
                    Icons.subdirectory_arrow_right,
                    size: 18,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSubtitle('Depósito de $cajaCodigo', color: AppColors.green),
                    const SizedBox(height: 4),
                    if (cajero != null)
                      AppLabelText('Cajero: $cajero', color: AppColors.black54),
                    if (cierra != null && !cajeroEsCerro)
                      AppLabelText('Cerró: $cierra', color: AppColors.black54),
                    AppLabelText(
                      multiMetodo ? fechaStr : '${depositos.first.metodoPago.label} · $fechaStr',
                      color: AppColors.black54,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+${_money(montoTotal)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.greendark,
                    ),
                  ),
                  if (resumen.isNotEmpty && (totalBarrido - montoTotal).abs() > 0.001)
                    Text(
                      'Barrido: ${_money(totalBarrido)}',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Chips a TODO EL ANCHO (debajo del header).
          if (multiMetodo) ...[
            const SizedBox(height: 6),
            Padding(
              padding: EdgeInsets.only(left: indent ? 24 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  resumen.isNotEmpty
                      ? _chipsResumen(resumen)
                      : Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: depositos
                              .map((m) => _MetodoChip(
                                    metodo: m.metodoPago,
                                    monto: m.monto,
                                    signo: '+',
                                    color: AppColors.greendark,
                                  ))
                              .toList(),
                        ),
                  if (hayDigitalABanco) ...[
                    const SizedBox(height: 3),
                    AppLabelText('Efectivo → bóveda · digital → bancos', color: AppColors.black54),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _badgePillDevueltoAlCierre() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.orange.withValues(alpha: 0.45),
          width: 0.8,
        ),
      ),
      child: const Text(
        'devuelto al cierre',
        style: TextStyle(
          fontSize: 9,
          color: AppColors.orange,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  bool _sameName(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  /// Desglose completo del barrido del cierre, adjuntado por el backend en la
  /// metadata del INGRESO de tesorería (incluye el digital que fue a bancos).
  List<_BarridoItem> _barridoResumen(MovimientoCaja dep) {
    final raw = dep.metadata?['barridoResumen'];
    if (raw is! List) return const [];
    return raw.map((e) {
      final m = e as Map;
      return _BarridoItem(
        (m['metodoPago'] ?? '').toString(),
        (m['monto'] as num?)?.toDouble() ?? 0,
        m['aBanco'] == true,
      );
    }).toList();
  }

  /// Chips del desglose en filas de a TRES (grid de 3 columnas), cada uno
  /// ocupando un tercio de la fila para aprovechar el ancho.
  Widget _chipsResumen(List<_BarridoItem> items) {
    const columnas = 3;
    final filas = <Widget>[];
    for (var i = 0; i < items.length; i += columnas) {
      final celdas = <Widget>[];
      for (var j = 0; j < columnas; j++) {
        final idx = i + j;
        if (j > 0) celdas.add(const SizedBox(width: 4));
        celdas.add(Expanded(
          child: idx < items.length
              ? _BarridoChip(item: items[idx])
              : const SizedBox(),
        ));
      }
      filas.add(Padding(
        padding: EdgeInsets.only(top: i == 0 ? 0 : 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: celdas),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: filas);
  }

  Widget _singleTile(MovimientoCaja mov) {
    final tile = ListTile(
      onTap: onTap,
      trailing: onTap != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_signo${_money(group.montoTotal)}',
                  style: TextStyle(
                    color: _color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right,
                    size: 16, color: AppColors.textSecondary),
              ],
            )
          : Text(
              '$_signo${_money(group.montoTotal)}',
              style: TextStyle(
                color: _color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: _color.withValues(alpha: 0.12),
        child: Icon(mov.categoria.icon, color: _color, size: 16),
      ),
      title: 
      // Text(
      //   group.titulo,
      //   style: TextStyle(
      //     fontWeight: FontWeight.w600,
      //     decoration: mov.anulado ? TextDecoration.lineThrough : null,
      //     fontSize: 11,
      //   ),
      // ),
      AppSubtitle(
        group.titulo,
        color: mov.anulado ? AppColors.textSecondary : null,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (group.subtitulo != null && group.subtitulo!.isNotEmpty)
            // Text(
            //   group.subtitulo!,
            //   style: const TextStyle(fontSize: 10),
            //   maxLines: 2,
            //   overflow: TextOverflow.ellipsis,
            // ),
            AppLabelText(
              group.subtitulo!,
              color: AppColors.textSecondary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(mov.metodoPago.icon,
                  size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              // Text(
              //   mov.metodoPago.label,
              //   style: const TextStyle(
              //     fontSize: 11,
              //     color: AppColors.textSecondary,
              //   ),
              // ),
              AppLabelText(
                mov.metodoPago.label,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: 
                // Text(
                //   DateFormatter.formatDateTime(mov.fechaMovimiento),
                //   style: const TextStyle(
                //     fontSize: 11,
                //     color: AppColors.textSecondary,
                //   ),
                //   overflow: TextOverflow.ellipsis,
                // ),
                AppLabelText(
                  DateFormatter.formatDateTime(mov.fechaMovimiento),
                  color: AppColors.textSecondary,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (mov.anulado) ...[
                const SizedBox(width: 8),
                _badgeAnulado(),
              ],
            ],
          ),
        ],
      ),
    );

    // Badge "DEVUELTO AL CIERRE" se posiciona absoluto arriba derecha
    // para no competir con el subtitle (que ya está apretado por método
    // + fecha + nombre cajero). Solo aplica a RETIRO_TESORERIA de
    // apertura cuya caja ya cerró.
    if (group.retiroAperturaDevuelto) {
      return Stack(
        children: [
          tile,
          Positioned(
            top: 6,
            right: 8,
            child: _badgeDevueltoAlCierre(),
          ),
        ],
      );
    }
    return tile;
  }

  Widget _groupedCard() {
    final iconCategoria = group.items.first.categoria.icon;
    final radius = BorderRadius.circular(10);
    final resumen = _barridoResumen(group.items.first);
    final hayDigital = resumen.any((r) => r.aBanco);
    final totalBarrido = resumen.isNotEmpty
        ? resumen.fold<double>(0, (s, r) => s + r.monto)
        : group.montoTotal;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: _color.withValues(alpha: 0.04),
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: _color.withValues(alpha: 0.20)),
            ),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _color.withValues(alpha: 0.15),
                    child: Icon(iconCategoria, color: _color, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSubtitle(group.titulo, color: _color),
                        if (group.subtitulo != null) ...[
                          const SizedBox(height: 2),
                          // Text(
                          //   '${group.subtitulo!} · ${DateFormatter.formatDateTime(group.items.first.fechaMovimiento)}',
                          //   style: const TextStyle(
                          //     fontSize: 11,
                          //     color: AppColors.textSecondary,
                          //   ),
                          // ),
                          AppLabelText(
                            '${group.subtitulo!} · ${DateFormatter.formatDateTime(group.items.first.fechaMovimiento)}',
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$_signo${_money(group.montoTotal)}',
                        style: TextStyle(
                          color: _color,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      if (resumen.isNotEmpty && (totalBarrido - group.montoTotal).abs() > 0.001)
                        Text(
                          'Barrido: ${_money(totalBarrido)}',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary.withValues(alpha: 0.9),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Desglose por método (chips inline). Si el barrido adjuntó el
            // resumen completo (efectivo + digital→banco), lo usamos.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  resumen.isNotEmpty
                      ? _chipsResumen(resumen)
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: group.items
                              .map((m) => _MetodoChip(
                                    metodo: m.metodoPago,
                                    monto: m.monto,
                                    signo: _signo,
                                    color: _color,
                                  ))
                              .toList(),
                        ),
                  if (hayDigital) ...[
                    const SizedBox(height: 4),
                    AppLabelText('Efectivo → bóveda · digital → bancos', color: AppColors.textSecondary),
                  ],
                ],
              ),
            ),
            // Banner informativo si la caja origen tuvo anulaciones
            // posteriores (reversos vinculados desde tesorería).
            if (group.tieneReversosVinculados)
              _ReversosAfectanBanner(group: group),
          ],
        ),
          ),
        ),
      ),
    );
  }

  Widget _badgeAnulado() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Text(
        'ANULADO',
        style: TextStyle(
          fontSize: 8,
          color: AppColors.red,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// Badge para RETIRO_TESORERIA cuya caja correspondiente ya cerró
  /// (el ciclo apertura → cierre se completó; el dinero ya volvió en
  /// el barrido del cierre como DEPOSITO_TESORERIA).
  Widget _badgeDevueltoAlCierre() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
            color: AppColors.orange.withValues(alpha: 0.40), width: 0.6),
      ),
      child: const Text(
        'DEVUELTO AL CIERRE',
        style: TextStyle(
          fontSize: 8,
          color: AppColors.orange,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReversosAfectanBanner extends StatelessWidget {
  final TesoreriaGroup group;

  const _ReversosAfectanBanner({required this.group});

  String _pluralize(int n, String singular, String plural) {
    return n == 1 ? '1 $singular' : '$n $plural';
  }

  String _buildLabel() {
    final cv = group.cantidadReversosVenta;
    final cc = group.cantidadDevolucionesCotizacion;
    final partes = <String>[];
    if (cv > 0) {
      partes.add(_pluralize(cv, 'anulación de venta',
          'anulaciones de venta'));
    }
    if (cc > 0) {
      partes.add(_pluralize(cc, 'anulación de cotización',
          'anulaciones de cotización'));
    }
    return 'Afectado por ${partes.join(' y ')}';
  }

  @override
  Widget build(BuildContext context) {
    final label = _buildLabel();
    final monto = group.montoAfectadoPorReversos;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.30),width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.undo_rounded, size: 14, color: AppColors.orange),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.orange,
              ),
            ),
          ),
          Text(
            '-S/ ${monto.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarridoItem {
  final String metodo; // 'EFECTIVO' | 'YAPE' | ...
  final double monto;
  final bool aBanco; // fue a una cuenta bancaria (no a la bóveda)
  const _BarridoItem(this.metodo, this.monto, this.aBanco);

  MetodoPago get metodoEnum => MetodoPago.values.firstWhere(
        (e) => e.name.toUpperCase() == metodo.toUpperCase(),
        orElse: () => MetodoPago.efectivo,
      );
}

/// Chip informativo de un método del barrido. Los que fueron a un banco llevan
/// un ícono de banco para dejar claro que no entraron a la bóveda.
class _BarridoChip extends StatelessWidget {
  final _BarridoItem item;
  const _BarridoChip({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.aBanco ? AppColors.blue1 : AppColors.greendark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.metodoEnum.icon, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(item.metodoEnum.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600)),
              ),
              if (item.aBanco)
                Icon(Icons.account_balance_rounded, size: 10, color: color.withValues(alpha: 0.8)),
            ],
          ),
          const SizedBox(height: 2),
          Text('+ S/${item.monto.toStringAsFixed(2)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MetodoChip extends StatelessWidget {
  final MetodoPago metodo;
  final double monto;
  final String signo;
  final Color color;

  const _MetodoChip({
    required this.metodo,
    required this.monto,
    required this.signo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 0.5),
        
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(metodo.icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            metodo.label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 6),
          Text(
            '$signo S/${monto.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
