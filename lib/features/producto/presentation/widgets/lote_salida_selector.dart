import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/fecha_calendario.dart';
import '../../../../core/widgets/custom_dropdown.dart';

/// Un lote del que puede salir un ajuste manual
/// (`GET producto-stock/:id/lotes-salida`).
class LoteSalida {
  final String id;
  final String codigo;
  final int cantidadActual;
  final DateTime? fechaVencimiento;

  const LoteSalida({
    required this.id,
    required this.codigo,
    required this.cantidadActual,
    this.fechaVencimiento,
  });

  factory LoteSalida.fromJson(Map<String, dynamic> json) => LoteSalida(
        id: json['id'] as String,
        codigo: json['codigo'] as String,
        cantidadActual: (json['cantidadActual'] as num).toInt(),
        fechaVencimiento: json['fechaVencimiento'] != null
            ? DateTime.parse(json['fechaVencimiento'] as String)
            : null,
      );
}

/// De que lote sale un ajuste de salida (merma, perdida, baja, donacion...).
///
/// 🔑 Sin esto la salida siempre tomaba el lote que FEFO pone primero, y quien
/// va al estante agarra una caja concreta: la merma de la caja rota tiene que
/// descontarse de ESE lote, no del mas viejo.
///
/// Si se elige un lote sale entero de ese lote (el backend rechaza si no
/// alcanza). En automatico igual se muestra de que lotes van a salir.
///
/// Con el motor de lotes apagado el backend devuelve la lista vacia y esto no
/// se dibuja: sin conciliar, las cantidades de los lotes estan infladas.
class LoteSalidaSelector extends StatefulWidget {
  final String productoStockId;

  /// Unidades que salen, en positivo.
  final int cantidad;

  /// El lote elegido, o null = automatico.
  final String? loteId;
  final ValueChanged<String?> onChanged;
  final Color? borderColor;

  const LoteSalidaSelector({
    super.key,
    required this.productoStockId,
    required this.cantidad,
    required this.loteId,
    required this.onChanged,
    this.borderColor,
  });

  @override
  State<LoteSalidaSelector> createState() => _LoteSalidaSelectorState();
}

class _LoteSalidaSelectorState extends State<LoteSalidaSelector> {
  /// `CustomDropdown` usa null como "sin elegir", asi que automatico va con ''.
  static const _automatico = '';

  List<LoteSalida> _lotes = const [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void didUpdateWidget(covariant LoteSalidaSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productoStockId != widget.productoStockId) {
      _lotes = const [];
      _cargar();
    }
  }

  Future<void> _cargar() async {
    final pedido = widget.productoStockId;
    List<LoteSalida> lotes = const [];
    try {
      final res = await locator<DioClient>()
          .get('/producto-stock/$pedido/lotes-salida');
      final data = res.data as Map<String, dynamic>;
      if (data['motorActivo'] == true) {
        lotes = (data['lotes'] as List)
            .map((j) => LoteSalida.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Sin lotes no hay selector: el ajuste sigue funcionando en automatico.
    }
    // Llego tarde: ya se esta mirando otro producto.
    if (!mounted || pedido != widget.productoStockId) return;
    setState(() => _lotes = lotes);
  }

  static String _etiqueta(LoteSalida l, bool salePrimero) {
    final dias = diasParaVencer(l.fechaVencimiento);
    return [
      l.codigo,
      'quedan ${l.cantidadActual}',
      if (dias != null && dias < 0)
        'VENCIDO'
      else if (l.fechaVencimiento != null)
        'vence ${formatearDiaEnvase(l.fechaVencimiento)}',
      if (salePrimero) 'sale primero',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    if (_lotes.isEmpty) return const SizedBox.shrink();

    LoteSalida? elegido;
    for (final l in _lotes) {
      if (l.id == widget.loteId) elegido = l;
    }

    // El mismo reparto que hace el backend: el elegido SOLO, o los lotes en
    // orden FEFO.
    final tramos = <String>[];
    var resto = widget.cantidad;
    for (final l in elegido != null ? [elegido] : _lotes) {
      if (resto <= 0) break;
      final toma = l.cantidadActual < resto ? l.cantidadActual : resto;
      tramos.add('${l.codigo} ($toma)');
      resto -= toma;
    }
    final errorLote = elegido != null && elegido.cantidadActual < widget.cantidad
        ? 'El lote ${elegido.codigo} tiene ${elegido.cantidadActual}: no alcanza para ${widget.cantidad}'
        : null;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomDropdown<String>(
            label: 'Lote',
            value: elegido?.id ?? _automatico,
            borderColor: widget.borderColor,
            items: [
              const DropdownItem(
                value: _automatico,
                label: 'Automatico: sale primero el que vence antes',
              ),
              for (var i = 0; i < _lotes.length; i++)
                DropdownItem(
                  value: _lotes[i].id,
                  label: _etiqueta(_lotes[i], i == 0),
                ),
            ],
            // Frena el Form del que lo contiene: un lote que no alcanza no se
            // manda a que el backend lo rechace.
            validator: (_) => errorLote,
            onChanged: (v) =>
                widget.onChanged(v == null || v == _automatico ? null : v),
          ),
          if (widget.cantidad > 0 && tramos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                errorLote ??
                    'Sale de: ${tramos.join(' + ')}${resto > 0 ? ' · $resto sin lote' : ''}',
                style: TextStyle(
                  fontSize: 10,
                  color: errorLote != null ? Colors.red : Colors.grey.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
