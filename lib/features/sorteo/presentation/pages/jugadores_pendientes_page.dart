import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/realtime_sync_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../data/datasources/sorteo_remote_datasource.dart';

/// Cola global: jugadores captados por el bot con pago POR VALIDAR, de
/// todos los sorteos/dinámicas abiertos. Al validar (✓) el backend
/// activa (ticket + WhatsApp) y en DINÁMICAS crea el premio automático
/// con los datos del bot — la card queda lista en el detalle.
class JugadoresPendientesPage extends StatefulWidget {
  const JugadoresPendientesPage({super.key});

  @override
  State<JugadoresPendientesPage> createState() =>
      _JugadoresPendientesPageState();
}

class _JugadoresPendientesPageState extends State<JugadoresPendientesPage> {
  final _ds = locator<SorteoRemoteDataSource>();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _pendientes = const [];

  /// Ids con acción en curso (deshabilita sus botones).
  final _procesando = <String>{};
  StreamSubscription? _realtimeSub;

  @override
  void initState() {
    super.initState();
    _cargar();
    // Otro device validó / el bot registró a alguien → recargar la cola.
    _realtimeSub = locator<RealtimeSyncService>().events.listen((e) {
      if (mounted && e is RealtimeSorteoCambiado && !_loading) _cargar();
    });
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _ds.getParticipantesPendientes();
      if (!mounted) return;
      setState(() {
        _pendientes = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _cambiarEstado(Map<String, dynamic> p, String estado) async {
    final id = p['id'] as String;
    final nombre = (p['nombre'] as String?) ?? '';
    final esDinamica =
        ((p['sorteo'] as Map?)?['tipo'] as String?) == 'DINAMICA';
    final activar = estado == 'ACTIVO';

    final ok = await ConfirmDialog.show(
      context: context,
      type: activar ? ConfirmDialogType.info : ConfirmDialogType.destructive,
      title: activar ? 'Validar pago' : 'Rechazar jugador',
      message: activar
          ? '¿Confirmar el pago de $nombre? Se le asignará su ticket y el '
              'bot le confirmará por WhatsApp.'
              '${esDinamica ? ' Como es DINÁMICA, su premio se registrará automáticamente con los datos que dejó.' : ''}'
          : '¿Rechazar a $nombre?',
      confirmText: activar ? 'Validar' : 'Rechazar',
      icon: activar ? Icons.check_circle_outline : Icons.cancel_outlined,
    );
    if (ok != true || !mounted) return;

    setState(() => _procesando.add(id));
    try {
      await _ds.cambiarEstadoParticipante(id, estado);
      if (!mounted) return;
      setState(() {
        _procesando.remove(id);
        _pendientes = [..._pendientes]..removeWhere((x) => x['id'] == id);
      });
      _snack(
        activar
            ? (esDinamica
                ? '🏆 ${nombre.split(' ').first} activado — premio creado automáticamente'
                : '🎟️ ${nombre.split(' ').first} activado — el bot le confirmó su ticket')
            : 'Jugador rechazado',
        ok: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _procesando.remove(id));
      _snack('No se pudo: $e', ok: false);
    }
  }

  /// "12/07 22:53" en hora local del device.
  String _fechaHoraRegistro(String? iso) {
    final d = iso != null ? DateTime.tryParse(iso)?.toLocal() : null;
    if (d == null) return '';
    String p2(int v) => v.toString().padLeft(2, '0');
    return '${p2(d.day)}/${p2(d.month)} ${p2(d.hour)}:${p2(d.minute)}';
  }

  void _snack(String msg, {required bool ok}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 12)),
      backgroundColor: ok ? Colors.green.shade700 : Colors.orange.shade800,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        customHeight: 40,
        title: 'Jugadores por validar',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh, size: 20, color: Colors.white),
            onPressed: _loading ? null : _cargar,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off,
                            size: 40, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey.shade600)),
                        TextButton(
                            onPressed: _cargar,
                            child: const Text('Reintentar')),
                      ],
                    ),
                  ),
                )
              : _pendientes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.task_alt,
                              size: 48, color: Colors.green.shade200),
                          const SizedBox(height: 10),
                          Text('Sin pagos por validar 🎉',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _pendientes.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) => _card(_pendientes[i]),
                      ),
                    ),
    );
  }

  Widget _card(Map<String, dynamic> p) {
    final id = p['id'] as String;
    final sorteo = (p['sorteo'] as Map?) ?? const {};
    final esDinamica = sorteo['tipo'] == 'DINAMICA';
    final agencia = p['agenciaNombre'] as String?;
    final destino = [p['destinoProvincia'], p['destinoDepartamento']]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(', ');
    final direccion = p['agenciaDireccion'] as String?;
    final envio = agencia == null || agencia.isEmpty
        ? null
        : [
            agencia,
            if (destino.isNotEmpty) '→ $destino',
            if (direccion != null && direccion.isNotEmpty) '· $direccion',
          ].join(' ');
    final pagadorNombre = p['pagadorNombre'] as String?;
    final pagadorCelular = p['pagadorCelular'] as String?;
    final pagador = pagadorNombre == null || pagadorNombre.isEmpty
        ? null
        : [
            pagadorNombre,
            if (pagadorCelular != null && pagadorCelular.isNotEmpty)
              '· $pagadorCelular',
          ].join(' ');
    final ocupado = _procesando.contains(id);

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          (p['nombre'] as String?) ?? '',
                          style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.blue1),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: (esDinamica ? Colors.purple : AppColors.blue1)
                              .withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${esDinamica ? '🎯 ' : ''}${sorteo['titulo'] ?? ''}',
                          style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: esDinamica
                                  ? Colors.purple.shade700
                                  : AppColors.blue1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'DNI ${p['dni']} · ${p['celular']}',
                    style:
                        TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                  // Fecha/hora del registro — distingue jugadas repetidas.
                  Row(
                    children: [
                      Icon(Icons.schedule,
                          size: 9, color: Colors.grey.shade500),
                      const SizedBox(width: 3),
                      Text(
                        _fechaHoraRegistro(p['creadoEn'] as String?),
                        style: TextStyle(
                            fontSize: 9, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  // El YAPE lo hace un tercero — cuadrar el pago con esto.
                  if (pagador != null)
                    Row(
                      children: [
                        Icon(Icons.payments_outlined,
                            size: 10, color: Colors.teal.shade700),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            'Yapea: $pagador',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.teal.shade700,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (envio != null)
                    Row(
                      children: [
                        Icon(Icons.local_shipping_outlined,
                            size: 10, color: AppColors.blue1),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            envio,
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.blue1,
                                fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (ocupado)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else ...[
              IconButton(
                tooltip: esDinamica
                    ? 'Validar pago (activa + crea el premio automático)'
                    : 'Validar pago (activa y confirma por WhatsApp)',
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.check_circle_outline,
                    size: 20, color: Colors.green.shade700),
                onPressed: () => _cambiarEstado(p, 'ACTIVO'),
              ),
              IconButton(
                tooltip: 'Rechazar',
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.cancel_outlined,
                    size: 20, color: Colors.red.shade400),
                onPressed: () => _cambiarEstado(p, 'RECHAZADO'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
