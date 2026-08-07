import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/network/dio_client.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/utils/unidad_presentacion.dart';

/// Resultado de una apertura/cierre, para que quien abrió el diálogo pueda
/// refrescar su listado sin volver a consultar.
class AperturaResultado {
  final int bultos;
  final int stockDestinoNuevo;
  final String numeroDocumento;

  const AperturaResultado({
    required this.bultos,
    required this.stockDestinoNuevo,
    required this.numeroDocumento,
  });
}

/// Diálogo de apertura de bultos: descuenta N de la variante cerrada y suma
/// N × rendimiento a la variante suelta.
///
/// Es el ÚNICO lugar donde se dispara la operación — lo usan tanto la pantalla
/// "Abrir bultos" de inventario como (más adelante) la alerta de stock bajo,
/// así que las dos vías se comportan igual y muestran los mismos errores.
///
/// Ojo: requiere rol de gerencia. El backend lo valida y devuelve
/// APERTURA_NO_AUTORIZADA; acá solo se muestra el mensaje, porque un cajero
/// puede llegar hasta el diálogo y hay que decirle por qué no puede.
class AbrirBultoDialog extends StatefulWidget {
  /// Se reciben escalares y no entidades a propósito: los dos llamadores
  /// (la pantalla de inventario y la alerta de stock) trabajan con la
  /// respuesta de `/apertura-bulto/disponibles`, que no trae variantes
  /// completas. Armar una `ProductoVariante` a medias solo para pasarla acá
  /// obligaba a inventar campos.
  final String bultoVarianteId;
  final String bultoNombre;
  final String destinoNombre;

  /// Presentación del destino, para mostrar "15 kg" en vez de "15000".
  /// Null = no tiene y se muestra en su unidad de venta.
  final double? destinoFactor;
  final String? destinoSimbolo;

  final double rendimiento;
  final String sedeId;

  /// Stock actual de cada lado, para validar antes de gastar el viaje.
  final int stockBultos;
  final int stockDestino;

  /// `false` = abrir (por defecto), `true` = rearmar.
  final bool cerrar;

  const AbrirBultoDialog({
    super.key,
    required this.bultoVarianteId,
    required this.bultoNombre,
    required this.destinoNombre,
    required this.destinoFactor,
    required this.destinoSimbolo,
    required this.rendimiento,
    required this.sedeId,
    required this.stockBultos,
    required this.stockDestino,
    this.cerrar = false,
  });

  static Future<AperturaResultado?> show({
    required BuildContext context,
    required String bultoVarianteId,
    required String bultoNombre,
    required String destinoNombre,
    required double? destinoFactor,
    required String? destinoSimbolo,
    required double rendimiento,
    required String sedeId,
    required int stockBultos,
    required int stockDestino,
    bool cerrar = false,
  }) {
    return showDialog<AperturaResultado>(
      context: context,
      builder: (_) => AbrirBultoDialog(
        bultoVarianteId: bultoVarianteId,
        bultoNombre: bultoNombre,
        destinoNombre: destinoNombre,
        destinoFactor: destinoFactor,
        destinoSimbolo: destinoSimbolo,
        rendimiento: rendimiento,
        sedeId: sedeId,
        stockBultos: stockBultos,
        stockDestino: stockDestino,
        cerrar: cerrar,
      ),
    );
  }

  @override
  State<AbrirBultoDialog> createState() => _AbrirBultoDialogState();
}

class _AbrirBultoDialogState extends State<AbrirBultoDialog> {
  final DioClient _dio = locator<DioClient>();
  final _cantidadCtrl = TextEditingController(text: '1');
  final _observacionesCtrl = TextEditingController();

  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  int get _cantidad => int.tryParse(_cantidadCtrl.text.trim()) ?? 0;

  int get _rendimiento => widget.rendimiento.round();

  /// Cuántos bultos se pueden mover como máximo. Al abrir manda el stock de
  /// bultos; al cerrar, cuántos bultos ENTEROS se pueden rearmar con lo suelto.
  int get _maximo => widget.cerrar
      ? (_rendimiento > 0 ? widget.stockDestino ~/ _rendimiento : 0)
      : widget.stockBultos;

  String get _titulo => widget.cerrar ? 'Rearmar bultos' : 'Abrir bultos';

  /// Texto de una cantidad del destino en su presentación, si tiene.
  String _enDestino(num cantidad) {
    if (!(widget.destinoFactor != null && widget.destinoFactor! > 1)) {
      return '$cantidad ${(widget.destinoSimbolo ?? '')}';
    }
    final u = UnidadPresentacion(
      factor: widget.destinoFactor!,
      simbolo: (widget.destinoSimbolo ?? ''),
    );
    return u.cantidadTexto(cantidad);
  }

  Future<void> _confirmar() async {
    if (_cantidad < 1) {
      setState(() => _error = 'Ingresá una cantidad mayor a 0');
      return;
    }
    if (_cantidad > _maximo) {
      setState(() => _error = widget.cerrar
          ? 'Solo alcanza para rearmar $_maximo bulto(s): hacen falta '
              '${_enDestino(_rendimiento)} por cada uno.'
          : 'Solo hay ${widget.stockBultos} bulto(s) en esta sede.');
      return;
    }

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      final resp = await _dio.post(
        '/apertura-bulto/${widget.cerrar ? 'cerrar' : 'abrir'}',
        data: {
          'varianteId': widget.bultoVarianteId,
          'sedeId': widget.sedeId,
          'cantidad': _cantidad,
          if (_observacionesCtrl.text.trim().isNotEmpty)
            'observaciones': _observacionesCtrl.text.trim(),
        },
      );
      final data = resp.data as Map<String, dynamic>?;
      if (!mounted) return;

      final destino = data?['destino'] as Map<String, dynamic>?;
      Navigator.pop(
        context,
        AperturaResultado(
          bultos: _cantidad,
          stockDestinoNuevo: (destino?['stockNuevo'] as num?)?.toInt() ?? 0,
          numeroDocumento: data?['numeroDocumento']?.toString() ?? '—',
        ),
      );

      // El costo del destino cambia por promedio ponderado; mostrarlo evita la
      // sorpresa de ver el margen distinto después.
      final costoNuevo = (destino?['precioCostoNuevo'] as num?)?.toDouble();
      final costoAnterior = (destino?['precioCostoAnterior'] as num?)?.toDouble();
      final hayCosto = data?['costoActualizado'] == true && costoNuevo != null;
      final extra = hayCosto
          ? '\nCosto de ${widget.destinoNombre}: '
              '${costoAnterior != null ? 'S/ ${costoAnterior.toStringAsFixed(6)} → ' : ''}'
              'S/ ${costoNuevo.toStringAsFixed(6)}'
          : (data?['razonCostoNoActualizado'] != null
              ? '\n⚠️ Costo NO actualizado: ${data!['razonCostoNoActualizado']}'
              : '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.cerrar ? 'Rearmados' : 'Abiertos'} $_cantidad bulto(s) · '
            '${widget.destinoNombre}: ${_enDestino((destino?['stockNuevo'] as num?) ?? 0)}'
            '$extra',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _error = _mensajeDeError(e);
      });
    }
  }

  /// El backend devuelve códigos propios; traducirlos acá evita mostrar un
  /// mensaje técnico para casos que tienen una explicación concreta.
  String _mensajeDeError(Object e) {
    if (e is! DioException) return e.toString();
    final body = e.response?.data;
    if (body is! Map<String, dynamic>) {
      return e.message ?? 'No se pudo completar la operación';
    }
    final mensaje = body['message']?.toString() ??
        'No se pudo completar la operación';
    if (body['code'] == 'APERTURA_NO_AUTORIZADA') {
      return 'Solo un gerente o administrador puede abrir o rearmar bultos. '
          'Pedile a alguien con ese rol que lo haga.';
    }
    return mensaje;
  }

  @override
  Widget build(BuildContext context) {
    final total = _cantidad > 0 ? _cantidad * _rendimiento : 0;

    return AlertDialog(
      title: AppSubtitle(_titulo.toUpperCase()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFlujo(),
            const SizedBox(height: 12),
            CustomText(
              controller: _cantidadCtrl,
              borderColor: AppColors.blue1,
              label: widget.cerrar ? 'Bultos a rearmar' : 'Bultos a abrir',
              hintText: '1',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 4),
            Text(
              widget.cerrar
                  ? 'Se pueden rearmar hasta $_maximo con lo que hay suelto.'
                  : 'Hay ${widget.stockBultos} bulto(s) en esta sede.',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
            if (total > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(4),
                  border:
                      Border.all(color: AppColors.blue1.withValues(alpha: 0.25)),
                ),
                child: Text(
                  widget.cerrar
                      ? '−${_enDestino(total)} de ${widget.destinoNombre}\n'
                          '+$_cantidad ${widget.bultoNombre}'
                      : '−$_cantidad ${widget.bultoNombre}\n'
                          '+${_enDestino(total)} de ${widget.destinoNombre}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue1,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            CustomText(
              controller: _observacionesCtrl,
              borderColor: AppColors.blue1,
              label: 'Observaciones (opcional)',
              hintText: 'Queda en el kardex',
            ),
            if (widget.cerrar) ...[
              const SizedBox(height: 8),
              Text(
                'Rearmar solo tiene sentido si el bulto está entero. Si ya se '
                'vendió parte, no alcanza y la operación falla.',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline,
                        size: 14, color: Colors.red.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                            fontSize: 11, color: Colors.red.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _enviando ? null : _confirmar,
          child: _enviando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.cerrar ? 'Rearmar' : 'Abrir'),
        ),
      ],
    );
  }

  Widget _buildFlujo() {
    // Al rearmar, el flujo se lee al revés: sale del granel y entra al bulto.
    final origen = widget.cerrar ? widget.destinoNombre : widget.bultoNombre;
    final destino = widget.cerrar ? widget.bultoNombre : widget.destinoNombre;
    return Row(
      children: [
        Expanded(
          child: Text(
            origen,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        Icon(Icons.arrow_forward, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            destino,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
