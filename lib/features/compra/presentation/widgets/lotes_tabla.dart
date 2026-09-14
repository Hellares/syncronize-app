import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/fecha_calendario.dart';
import '../../domain/entities/lote.dart';

/// Los lotes en una tabla tipo Excel, con el mismo formato que el kardex:
/// encabezado fijo, scroll horizontal sincronizado entre encabezado y filas,
/// filas cebra de alto fijo y "Cargar más" al final.
///
/// Solo pinta: la página le pasa los lotes y las acciones. Está aparte para
/// poder montarla en un test sin el cubit.
class LotesTabla extends StatefulWidget {
  final List<Lote> lotes;
  final bool hasNext;
  final bool cargandoMas;
  final ValueChanged<Lote> onTap;
  final VoidCallback onCargarMas;

  const LotesTabla({
    super.key,
    required this.lotes,
    required this.hasNext,
    required this.cargandoMas,
    required this.onTap,
    required this.onCargarMas,
  });

  // Anchos fijos: encabezado y filas usan EXACTAMENTE los mismos.
  static const double wCodigo = 150;
  static const double wProducto = 200;
  static const double wEstado = 76;
  static const double wStock = 80;
  static const double wCosto = 76;
  static const double wValor = 84;
  static const double wVence = 120;
  static const double wIngreso = 76;
  static const double wProveedor = 170;
  static const double rowH = 34;

  static const double anchoTotal = wCodigo +
      wProducto +
      wEstado +
      wStock +
      wCosto +
      wValor +
      wVence +
      wIngreso +
      wProveedor;

  @override
  State<LotesTabla> createState() => _LotesTablaState();
}

class _LotesTablaState extends State<LotesTabla> {
  // Scroll horizontal sincronizado entre el encabezado fijo y las filas
  // (mismo patrón que el kardex y Verificación de Precios).
  final ScrollController _headerH = ScrollController();
  final ScrollController _bodyH = ScrollController();
  bool _sincronizando = false;

  // Franjas tipo Excel: el stock en azul, como el saldo del kardex.
  static final Color _bgStock = Colors.blue.shade50;
  static final Color _bgStockH = Colors.blue.shade100;

  @override
  void initState() {
    super.initState();
    _headerH.addListener(() => _sync(_headerH, _bodyH));
    _bodyH.addListener(() => _sync(_bodyH, _headerH));
  }

  void _sync(ScrollController src, ScrollController dst) {
    if (_sincronizando || !dst.hasClients || src.offset == dst.offset) return;
    _sincronizando = true;
    dst.jumpTo(src.offset);
    _sincronizando = false;
  }

  @override
  void dispose() {
    _headerH.dispose();
    _bodyH.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final extra = widget.hasNext ? 1 : 0;
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _headerH,
            physics: const ClampingScrollPhysics(),
            child: _encabezado(),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _bodyH,
              physics: const ClampingScrollPhysics(),
              child: SizedBox(
                width: LotesTabla.anchoTotal,
                child: ListView.builder(
                  itemCount: widget.lotes.length + extra,
                  itemExtent: LotesTabla.rowH,
                  itemBuilder: (_, i) => i >= widget.lotes.length
                      ? _cargarMas()
                      : _fila(widget.lotes[i], i),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _encabezado() {
    const s = TextStyle(
        fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.blue3);
    return Container(
      width: LotesTabla.anchoTotal,
      height: LotesTabla.rowH,
      color: AppColors.blue1.withValues(alpha: 0.08),
      child: Row(
        children: [
          _celdaH('Código', LotesTabla.wCodigo, s),
          _celdaH('Producto', LotesTabla.wProducto, s),
          _celdaH('Estado', LotesTabla.wEstado, s),
          _celdaH('Stock', LotesTabla.wStock, s,
              derecha: true, fondo: _bgStockH),
          _celdaH('Costo', LotesTabla.wCosto, s, derecha: true),
          _celdaH('Valor', LotesTabla.wValor, s, derecha: true),
          _celdaH('Vence', LotesTabla.wVence, s),
          _celdaH('Ingreso', LotesTabla.wIngreso, s),
          _celdaH('Proveedor', LotesTabla.wProveedor, s),
        ],
      ),
    );
  }

  Widget _fila(Lote lote, int index) {
    const ts = TextStyle(fontSize: 10);
    final colorEstado = _colorEstado(lote.estado);
    final (textoVence, colorVence) = _vencimiento(lote);
    final proveedor = lote.nombreProveedor ??
        (lote.proveedor?['nombre'] as String?) ??
        '—';

    return InkWell(
      onTap: () => widget.onTap(lote),
      child: Container(
        width: LotesTabla.anchoTotal,
        height: LotesTabla.rowH,
        decoration: BoxDecoration(
          color: index.isEven ? Colors.white : Colors.grey.shade50,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            _celda(lote.codigo, LotesTabla.wCodigo, ts),
            _celda(
              lote.nombreProducto.isNotEmpty ? lote.nombreProducto : '—',
              LotesTabla.wProducto,
              const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
            _celda(
              lote.estadoTexto,
              LotesTabla.wEstado,
              TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colorEstado),
            ),
            _celda(
              '${lote.cantidadActual}/${lote.cantidadInicial}',
              LotesTabla.wStock,
              const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              derecha: true,
              fondo: _bgStock,
            ),
            _celda('S/ ${lote.precioCosto.toStringAsFixed(2)}',
                LotesTabla.wCosto, ts,
                derecha: true),
            // Lo que vale lo que QUEDA del lote, al costo de ese lote.
            _celda(
              'S/ ${(lote.cantidadActual * lote.precioCosto).toStringAsFixed(2)}',
              LotesTabla.wValor,
              ts,
              derecha: true,
            ),
            _celda(
              textoVence,
              LotesTabla.wVence,
              TextStyle(
                fontSize: 10,
                color: colorVence,
                fontWeight: lote.proximoAVencer
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            // El ingreso es un instante: a hora local.
            _celda(DateFormat('dd/MM/yy').format(lote.fechaIngreso.toLocal()),
                LotesTabla.wIngreso, ts),
            _celda(proveedor, LotesTabla.wProveedor, ts.copyWith(fontSize: 9)),
          ],
        ),
      ),
    );
  }

  /// "Cargar más" pegado a la IZQUIERDA: centrado en una tabla más ancha que
  /// el teléfono quedaría fuera de la pantalla.
  Widget _cargarMas() {
    return InkWell(
      onTap: widget.cargandoMas ? null : widget.onCargarMas,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: widget.cargandoMas
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Cargar más',
                  style: TextStyle(fontSize: 12, color: AppColors.blue1)),
        ),
      ),
    );
  }

  /// El vencimiento es el DÍA del envase, por sus campos UTC (a hora local en
  /// Lima daría el día anterior), y el estado por día de calendario.
  (String, Color) _vencimiento(Lote lote) {
    if (lote.fechaVencimiento == null) return ('—', Colors.grey);
    final fecha = formatearDiaEnvase(lote.fechaVencimiento);
    if (lote.estaVencido) return ('VENCIDO $fecha', Colors.red.shade700);
    if (lote.diasParaVencer == 0) return ('Vence HOY', Colors.orange.shade800);
    if (lote.proximoAVencer) {
      return ('$fecha · ${lote.diasParaVencer} d', Colors.orange.shade800);
    }
    return (fecha, Colors.black87);
  }

  Color _colorEstado(EstadoLote estado) {
    switch (estado) {
      case EstadoLote.ACTIVO:
        return Colors.green.shade700;
      case EstadoLote.AGOTADO:
        return Colors.grey.shade600;
      case EstadoLote.VENCIDO:
        return Colors.red.shade700;
      case EstadoLote.BLOQUEADO:
        return Colors.orange.shade800;
    }
  }

  Widget _celdaH(String texto, double ancho, TextStyle s,
      {bool derecha = false, Color? fondo}) {
    return Container(
      width: ancho,
      color: fondo,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: derecha ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(texto, style: s),
    );
  }

  Widget _celda(String texto, double ancho, TextStyle s,
      {bool derecha = false, Color? fondo}) {
    return Container(
      width: ancho,
      color: fondo,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: derecha ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(texto, style: s, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
