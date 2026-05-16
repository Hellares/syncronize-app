import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/utils/resource.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';
import '../../domain/entities/gasto_recurrente.dart';
import '../../domain/entities/pago_gasto_recurrente.dart';
import '../../domain/repositories/gastos_recurrentes_repository.dart';
import 'gasto_recurrente_form_page.dart';

class GastoRecurrenteDetailPage extends StatefulWidget {
  final String gastoId;
  const GastoRecurrenteDetailPage({super.key, required this.gastoId});

  @override
  State<GastoRecurrenteDetailPage> createState() => _GastoRecurrenteDetailPageState();
}

class _GastoRecurrenteDetailPageState extends State<GastoRecurrenteDetailPage> {
  final _repo = locator<GastosRecurrentesRepository>();
  static final _money = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');

  GastoRecurrente? _gasto;
  List<PagoGastoRecurrente> _pagos = [];
  bool _cargando = true;
  String? _error;
  bool _togglingActivo = false;
  bool _verAnulados = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    final results = await Future.wait([
      _repo.obtener(widget.gastoId),
      _repo.listarPagos(widget.gastoId, take: 50, incluirAnulados: _verAnulados),
    ]);
    if (!mounted) return;

    final gastoRes = results[0] as Resource<GastoRecurrente>;
    final pagosRes = results[1] as Resource<List<PagoGastoRecurrente>>;

    if (gastoRes is Success<GastoRecurrente>) {
      setState(() {
        _gasto = gastoRes.data;
        if (pagosRes is Success<List<PagoGastoRecurrente>>) {
          _pagos = pagosRes.data;
        }
        _cargando = false;
      });
    } else if (gastoRes is Error<GastoRecurrente>) {
      setState(() {
        _error = gastoRes.message;
        _cargando = false;
      });
    }
  }

  Future<void> _toggleActivo() async {
    if (_gasto == null) return;
    setState(() => _togglingActivo = true);
    final r = await _repo.toggleActivo(_gasto!.id);
    if (!mounted) return;
    setState(() => _togglingActivo = false);
    if (r is Success<GastoRecurrente>) {
      setState(() => _gasto = r.data);
      SnackBarHelper.showSuccess(
        context,
        _gasto!.activo ? 'Gasto activado' : 'Gasto desactivado',
      );
    } else if (r is Error<GastoRecurrente>) {
      SnackBarHelper.showError(context, r.message);
    }
  }

  Future<void> _editar() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => GastoRecurrenteFormPage(gastoId: widget.gastoId),
      ),
    );
    if (ok == true && mounted) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: _gasto?.nombre ?? 'Gasto recurrente',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
        actions: [
          if (_gasto != null) ...[
            IconButton(
              icon: Icon(
                _verAnulados ? Icons.history_toggle_off : Icons.history,
              ),
              tooltip: _verAnulados ? 'Ocultar anulados' : 'Ver anulados',
              onPressed: () {
                setState(() => _verAnulados = !_verAnulados);
                _cargar();
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editar,
              tooltip: 'Editar',
            ),
          ],
        ],
      ),
      body: GradientContainer(
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    final g = _gasto!;
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(g),
          const SizedBox(height: 16),
          const Text(
            'Historial de pagos',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (_pagos.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Sin pagos registrados todavía',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            ..._pagos.map(_pagoTile),
        ],
      ),
    );
  }

  Widget _header(GastoRecurrente g) {
    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event_repeat, color: AppColors.blue1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.nombre,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      g.categoriaGastoNombre,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: g.activo,
                onChanged: _togglingActivo ? null : (_) => _toggleActivo(),
              ),
            ],
          ),
          const Divider(height: 24),
          _kv('Frecuencia', g.frecuencia.label),
          _kv('Día de vencimiento', g.diaVencimiento.toString()),
          _kv('Monto estimado', _money.format(g.montoEstimado)),
          if (g.sedeNombre != null) _kv('Sede', g.sedeNombre!),
          if (g.proveedorNombre != null) _kv('Proveedor', g.proveedorNombre!),
          if (g.ultimoPagoEn != null)
            _kv('Último pago registrado', DateFormatter.formatDateTime(g.ultimoPagoEn!)),
          if (g.notas != null && g.notas!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Notas',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(g.notas!, style: const TextStyle(fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              k,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(v, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _pagoTile(PagoGastoRecurrente p) {
    final fuenteIcon = p.fuente == FuentePagoGasto.caja
        ? Icons.point_of_sale
        : Icons.account_balance;
    final isAnulado = p.anulado;
    final dimColor = isAnulado ? AppColors.textSecondary : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAnulado
            ? AppColors.red.withValues(alpha: 0.04)
            : AppColors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAnulado
              ? AppColors.red.withValues(alpha: 0.25)
              : AppColors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                fuenteIcon,
                size: 18,
                color: isAnulado ? AppColors.textSecondary : AppColors.blue1,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          p.periodo,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: dimColor,
                            decoration: isAnulado ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '· ${p.fuente.label} · ${p.metodoPago.label}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAnulado)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.red.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'ANULADO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.red,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      DateFormatter.formatDateTime(p.fechaPago),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    if (p.bancoNombre != null)
                      Text(
                        '${p.bancoNombre} · ${p.bancoNumeroCuenta ?? ''}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _money.format(p.montoReal),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: dimColor,
                      decoration: isAnulado ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (p.comprobanteUrl != null)
                    const Icon(Icons.attach_file, size: 14, color: AppColors.textSecondary),
                ],
              ),
              if (!isAnulado)
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  color: AppColors.red,
                  tooltip: 'Anular pago',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _confirmarAnularPago(p),
                ),
            ],
          ),
          if (isAnulado && p.motivoAnulacion != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Motivo: ${p.motivoAnulacion}',
                    style: const TextStyle(fontSize: 11, color: AppColors.red),
                  ),
                  if (p.fechaAnulacion != null || p.anuladoPorNombre != null)
                    Text(
                      [
                        if (p.fechaAnulacion != null)
                          DateFormatter.formatDateTime(p.fechaAnulacion!),
                        if (p.anuladoPorNombre != null) 'por ${p.anuladoPorNombre}',
                      ].join(' · '),
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmarAnularPago(PagoGastoRecurrente p) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => _AnularPagoMotivoDialog(pago: p, money: _money),
    );

    if (motivo == null || !mounted) return;

    final r = await _repo.anularPago(pagoId: p.id, motivo: motivo);
    if (!mounted) return;
    if (r is Success<PagoGastoRecurrente>) {
      SnackBarHelper.showSuccess(context, 'Pago anulado');
      _cargar();
    } else if (r is Error<PagoGastoRecurrente>) {
      SnackBarHelper.showError(context, r.message);
    }
  }
}

/// Dialog separado con StatefulWidget para que el TextEditingController viva
/// dentro del state y se libere correctamente cuando el dialog se cierra
/// (evita el crash `TextEditingController was used after being disposed` que
/// ocurría cuando el dialog seguía animándose tras el pop).
class _AnularPagoMotivoDialog extends StatefulWidget {
  final PagoGastoRecurrente pago;
  final NumberFormat money;
  const _AnularPagoMotivoDialog({required this.pago, required this.money});

  @override
  State<_AnularPagoMotivoDialog> createState() => _AnularPagoMotivoDialogState();
}

class _AnularPagoMotivoDialogState extends State<_AnularPagoMotivoDialog> {
  final _motivoCtrl = TextEditingController();

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (_motivoCtrl.text.trim().length < 3) {
      SnackBarHelper.showError(context, 'Motivo de al menos 3 caracteres');
      return;
    }
    Navigator.of(context).pop(_motivoCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pago;
    return AlertDialog(
      title: const Text('Anular pago'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vas a anular el pago de ${widget.money.format(p.montoReal)} del período ${p.periodo}. '
              'Se ${p.fuente == FuentePagoGasto.caja ? "anulará el movimiento de caja" : "devolverá el monto al saldo del banco"}. '
              'Después podrás registrar uno nuevo.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _motivoCtrl,
              decoration: const InputDecoration(
                labelText: 'Motivo *',
                hintText: 'Ej: monto incorrecto',
                border: OutlineInputBorder(),
              ),
              maxLength: 500,
              maxLines: 2,
              autofocus: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _confirmar,
          style: TextButton.styleFrom(foregroundColor: AppColors.red),
          child: const Text('Anular'),
        ),
      ],
    );
  }
}
