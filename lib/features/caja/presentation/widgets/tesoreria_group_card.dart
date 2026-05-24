import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
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
    // reversos vinculados (necesitamos espacio para el banner).
    final renderAsCard = group.isGrouped || group.tieneReversosVinculados;
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Retiro de Tesorería',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Retiro para apertura: $cajaCodigo',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              if (cajero != null)
                Text(
                  'Cajero: $cajero',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              Text(
                '$metodoLabel · $fechaStr',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '-${_money(retiro.monto)}',
          style: TextStyle(
            fontSize: 15,
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

    // Si hay múltiples métodos, mostramos chips inline después de la info.
    final multiMetodo = depositos.length > 1;

    final cajeroEsCerro =
        cajero != null && cierra != null && _sameName(cajero, cierra);

    return Padding(
      padding: EdgeInsets.only(left: indent ? 20 : 0),
      child: Row(
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
                Text(
                  'Depósito de $cajaCodigo',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (cajero != null)
                  Text(
                    'Cajero: $cajero',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (cierra != null && !cajeroEsCerro)
                  Text(
                    'Cerró: $cierra',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (!multiMetodo)
                  Text(
                    '${depositos.first.metodoPago.label} · $fechaStr',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  )
                else ...[
                  Text(
                    fechaStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
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
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+${_money(montoTotal)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.greendark,
            ),
          ),
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
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  bool _sameName(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

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
      title: Text(
        group.titulo,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          decoration: mov.anulado ? TextDecoration.lineThrough : null,
          fontSize: 11,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (group.subtitulo != null && group.subtitulo!.isNotEmpty)
            Text(
              group.subtitulo!,
              style: const TextStyle(fontSize: 10),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(mov.metodoPago.icon,
                  size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                mov.metodoPago.label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  DateFormatter.formatDateTime(mov.fechaMovimiento),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
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
                        Text(
                          group.titulo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        if (group.subtitulo != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${group.subtitulo!} · ${DateFormatter.formatDateTime(group.items.first.fechaMovimiento)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    '$_signo${_money(group.montoTotal)}',
                    style: TextStyle(
                      color: _color,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Desglose por método (chips inline)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: group.items.map((m) => _MetodoChip(
                  metodo: m.metodoPago,
                  monto: m.monto,
                  signo: _signo,
                  color: _color,
                )).toList(),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.undo_rounded, size: 14, color: AppColors.orange),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
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
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
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
