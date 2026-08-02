import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/repositories/delivery_repository.dart';

/// La empresa ve las ofertas de los repartidores y elige una.
///
/// Se muestra el precio JUNTO con el nombre y las entregas completadas: con
/// el precio solo no se puede decidir, y la más barata no siempre es la
/// mejor. Es la misma idea de inDrive, donde el pasajero ve la calificación
/// del chofer y no solo el monto.
///
/// Devuelve `true` si se aceptó alguna (el caller debe recargar).
Future<bool?> showOfertasDeliverySheet({
  required BuildContext context,
  required String deliveryId,
  required String empresaId,
  required String ventaCodigo,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OfertasSheet(
      deliveryId: deliveryId,
      empresaId: empresaId,
      ventaCodigo: ventaCodigo,
    ),
  );
}

class _OfertasSheet extends StatefulWidget {
  final String deliveryId;
  final String empresaId;
  final String ventaCodigo;

  const _OfertasSheet({
    required this.deliveryId,
    required this.empresaId,
    required this.ventaCodigo,
  });

  @override
  State<_OfertasSheet> createState() => _OfertasSheetState();
}

class _OfertasSheetState extends State<_OfertasSheet> {
  final _repo = locator<DeliveryRepository>();

  List<Map<String, dynamic>> _ofertas = const [];
  bool _cargando = true;
  bool _aceptando = false;
  String? _error;

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
    final r = await _repo.ofertasDe(widget.deliveryId, widget.empresaId);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (r is Success<List<Map<String, dynamic>>>) {
        _ofertas = r.data;
      } else if (r is Error<List<Map<String, dynamic>>>) {
        _error = r.message;
      }
    });
  }

  Future<void> _aceptar(Map<String, dynamic> oferta) async {
    setState(() => _aceptando = true);
    final r = await _repo.aceptarOferta(
      oferta['id'] as String,
      widget.empresaId,
    );
    if (!mounted) return;
    setState(() => _aceptando = false);

    if (r is Success) {
      Navigator.pop(context, true);
      return;
    }
    // Puede haber vencido o alguien más quedarse con el pedido mientras se
    // decidía: se recarga para mostrar el estado real.
    setState(() => _error = (r as Error).message);
    _cargar();
  }

  double _monto(Map<String, dynamic> o) {
    final v = o['monto'];
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  /// Minutos que le quedan a la oferta (vencen a los 10 min).
  int _minutosRestantes(Map<String, dynamic> o) {
    final expira = DateTime.tryParse(o['expiraEn']?.toString() ?? '');
    if (expira == null) return 0;
    return expira.difference(DateTime.now()).inMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ofertas para ${widget.ventaCodigo}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar',
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: _cargando ? null : _cargar,
                ),
              ],
            ),
            Text(
              'Al aceptar una, el pedido queda asignado a ese repartidor con '
              'ese precio.',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _error!,
                  style:
                      TextStyle(fontSize: 11.5, color: Colors.orange.shade900),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (_cargando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 26),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_ofertas.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 22),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.hourglass_empty,
                          size: 34, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      const Text(
                        'Todavía nadie ofertó',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Las ofertas vencen a los 10 minutos. Si nadie oferta, '
                        'puedes enviarlo con personal propio.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _ofertas.length,
                  separatorBuilder: (_, __) => const Divider(height: 14),
                  itemBuilder: (_, i) => _fila(_ofertas[i], esMasBarata: i == 0),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fila(Map<String, dynamic> o, {required bool esMasBarata}) {
    final minutos = _minutosRestantes(o);
    final entregas = (o['entregasCompletadas'] as num?)?.toInt() ?? 0;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'S/ ${_monto(o).toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  if (esMasBarata) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'más baja',
                        style: TextStyle(
                            fontSize: 9.5, color: Colors.green.shade800),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                '${o['repartidorNombre'] ?? 'Repartidor'} · $entregas entregas',
                style: const TextStyle(fontSize: 11.5),
              ),
              if ((o['comentario'] as String?)?.trim().isNotEmpty ?? false)
                Text(
                  '"${o['comentario']}"',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                  ),
                ),
              Text(
                minutos <= 0 ? 'por vencer' : 'vence en $minutos min',
                style: TextStyle(
                  fontSize: 10.5,
                  color: minutos <= 2 ? Colors.orange.shade800 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.blue1,
            visualDensity: VisualDensity.compact,
            textStyle: const TextStyle(fontSize: 11.5),
          ),
          onPressed: _aceptando ? null : () => _aceptar(o),
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}
