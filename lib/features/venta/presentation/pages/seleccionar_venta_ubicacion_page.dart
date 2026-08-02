import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../auth/presentation/widgets/custom_text.dart'
    show CustomText, TextCase;
import '../../../empresa/presentation/bloc/sede_activa/sede_activa_cubit.dart';
import '../../domain/entities/venta.dart';
import '../../domain/repositories/venta_repository.dart';
import '../widgets/venta_estado_chip.dart';

/// Elige a qué venta pegarle una ubicación que llegó compartida desde otra
/// app (el cliente mandó su punto por WhatsApp).
///
/// La dirección de delivery se edita DENTRO de la venta, así que este paso
/// intermedio existe para saber en cuál. Al elegir, navega al detalle con el
/// punto y ahí se abre solo el sheet de delivery.
class SeleccionarVentaUbicacionPage extends StatefulWidget {
  final LatLng punto;

  const SeleccionarVentaUbicacionPage({super.key, required this.punto});

  @override
  State<SeleccionarVentaUbicacionPage> createState() =>
      _SeleccionarVentaUbicacionPageState();
}

class _SeleccionarVentaUbicacionPageState
    extends State<SeleccionarVentaUbicacionPage> {
  final TextEditingController _buscarCtrl = TextEditingController();

  List<Venta> _ventas = const [];
  bool _cargando = true;
  String? _error;
  Timer? _debounce;

  /// Arranca en HOY: la ubicación que manda el cliente es casi siempre de un
  /// pedido recién hecho, y traer el histórico completo llena la lista de
  /// ruido. Se puede apagar porque el cliente bien puede mandar su punto al
  /// día siguiente de haber comprado.
  bool _soloHoy = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _buscarCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    final sedeId = context.read<SedeActivaCubit>().state.activa?.id;
    final texto = _buscarCtrl.text.trim();

    // El rango va en UTC pero recortado sobre el día LOCAL, si no "hoy"
    // arranca a las 19:00 de ayer.
    final hoy = DateTime.now();
    final res = await locator<VentaRepository>().getVentas(
      sedeId: sedeId,
      search: texto.isEmpty ? null : texto,
      fechaDesde: _soloHoy
          ? DateFormatter.toUtcIso(DateFormatter.startOfDay(hoy))
          : null,
      fechaHasta: _soloHoy
          ? DateFormatter.toUtcIso(DateFormatter.endOfDay(hoy))
          : null,
    );
    if (!mounted) return;

    if (res is Success<List<Venta>>) {
      setState(() {
        _ventas = res.data;
        _cargando = false;
      });
    } else if (res is Error<List<Venta>>) {
      setState(() {
        _error = res.message;
        _cargando = false;
      });
    }
  }

  void _onBuscarCambio(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _cargar);
  }

  /// `pushReplacement`: una vez elegida la venta este paso ya no sirve, y
  /// volver atrás desde el detalle debe llevar a donde estaba el usuario.
  void _elegir(Venta venta) {
    context.pushReplacement('/empresa/ventas/${venta.id}', extra: widget.punto);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Ubicación recibida',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
      ),
      body: Column(
        children: [
          _cabecera(),
          Expanded(child: _cuerpo()),
        ],
      ),
    );
  }

  Widget _cabecera() {
    return Container(
      color: AppColors.blue1.withValues(alpha: 0.06),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.place, size: 18, color: AppColors.blue1),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '¿A qué venta le corresponde esta ubicación?',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blue1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CustomText(
            controller: _buscarCtrl,
            label: 'Buscar',
            hintText: 'Código de venta o nombre del cliente',
            borderColor: AppColors.blue1,
            textCase: TextCase.upper,
            onChanged: _onBuscarCambio,
          ),
          const SizedBox(height: 8),
          // Alto fijo: el chip solo mide ~32 px y queda por debajo del
          // mínimo tocable de 48.
          SizedBox(
            height: 40,
            child: Row(
              children: [
                FilterChip(
                  selected: _soloHoy,
                  onSelected: (v) {
                    setState(() => _soloHoy = v);
                    _cargar();
                  },
                  label: const Text('Solo hoy'),
                  labelStyle: const TextStyle(fontSize: 11.5),
                  selectedColor: AppColors.blue1.withValues(alpha: 0.18),
                  checkmarkColor: AppColors.blue1,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _soloHoy
                        ? 'Mostrando las ventas de hoy'
                        : 'Mostrando todo el historial',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cuerpo() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _mensaje(
        icono: Icons.cloud_off,
        titulo: 'No se pudieron cargar las ventas',
        detalle: _error!,
        accion: TextButton.icon(
          onPressed: _cargar,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Reintentar'),
        ),
      );
    }
    if (_ventas.isEmpty) {
      final buscando = _buscarCtrl.text.trim().isNotEmpty;
      return _mensaje(
        icono: Icons.receipt_long_outlined,
        titulo: 'Sin ventas para mostrar',
        detalle: buscando
            ? (_soloHoy
                ? 'Ninguna venta de hoy coincide con la búsqueda.'
                : 'Ninguna venta coincide con la búsqueda.')
            : (_soloHoy
                ? 'Esta sede todavía no registró ventas hoy.'
                : 'Esta sede todavía no tiene ventas registradas.'),
        // Sin esta salida, una venta de ayer sería inalcanzable.
        accion: _soloHoy
            ? TextButton.icon(
                onPressed: () {
                  setState(() => _soloHoy = false);
                  _cargar();
                },
                icon: const Icon(Icons.history, size: 18),
                label: const Text('Buscar en días anteriores'),
              )
            : null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: _ventas.length,
      itemExtent: 76,
      itemBuilder: (_, i) => _fila(_ventas[i]),
    );
  }

  Widget _fila(Venta venta) {
    return InkWell(
      onTap: () => _elegir(venta),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        venta.codigo,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      VentaEstadoChip(
                        estado: venta.estado,
                        esCredito: venta.esCredito,
                      ),
                      if (venta.tieneDelivery) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.delivery_dining,
                          size: 15,
                          color: Colors.green.shade700,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    venta.nombreCliente,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  Text(
                    DateFormatter.formatSmart(venta.fechaVenta),
                    style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Text(
              'S/ ${venta.total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _mensaje({
    required IconData icono,
    required String titulo,
    required String detalle,
    Widget? accion,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              detalle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            ),
            if (accion != null) ...[const SizedBox(height: 8), accion],
          ],
        ),
      ),
    );
  }
}
