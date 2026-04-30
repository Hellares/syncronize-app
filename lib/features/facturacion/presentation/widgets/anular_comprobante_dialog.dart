import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/comunicacion_baja.dart';
import '../../domain/entities/crear_comunicacion_baja_request.dart';
import '../../domain/entities/crear_resumen_diario_request.dart';
import '../../domain/entities/resumen_diario.dart';
import '../../domain/usecases/crear_comunicacion_baja_usecase.dart';
import '../../domain/usecases/crear_resumen_diario_usecase.dart';

/// Dialog para anular UN comprobante. Bifurca según tipo:
///  - **FACTURA / NC-FC* / ND-FD*** → Comunicación de Baja (RA), plazo 7 días.
///  - **BOLETA** → Resumen Diario (RC), plazo 3 días.
///
/// Notas con prefijo BC*/BD* aún no se soportan (endpoint distinto en Syncrofact).
class AnularComprobanteDialog extends StatefulWidget {
  final String comprobanteId;
  final String comprobanteCodigo;
  final String tipoComprobante;
  final DateTime fechaEmision;
  final String sedeId;
  final double total;
  final String moneda;

  const AnularComprobanteDialog({
    super.key,
    required this.comprobanteId,
    required this.comprobanteCodigo,
    required this.tipoComprobante,
    required this.fechaEmision,
    required this.sedeId,
    required this.total,
    this.moneda = 'PEN',
  });

  /// Muestra el dialog. Devuelve el documento de anulación (CDB o RC) si fue
  /// exitoso, null si se canceló.
  static Future<Object?> show(
    BuildContext context, {
    required String comprobanteId,
    required String comprobanteCodigo,
    required String tipoComprobante,
    required DateTime fechaEmision,
    required String sedeId,
    required double total,
    String moneda = 'PEN',
  }) {
    return showDialog<Object>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AnularComprobanteDialog(
        comprobanteId: comprobanteId,
        comprobanteCodigo: comprobanteCodigo,
        tipoComprobante: tipoComprobante,
        fechaEmision: fechaEmision,
        sedeId: sedeId,
        total: total,
        moneda: moneda,
      ),
    );
  }

  @override
  State<AnularComprobanteDialog> createState() =>
      _AnularComprobanteDialogState();
}

class _AnularComprobanteDialogState extends State<AnularComprobanteDialog> {
  final _motivoGeneralController = TextEditingController();
  final _motivoEspecificoController = TextEditingController();
  bool _submitting = false;
  String? _error;

  String get _simboloMoneda => widget.moneda == 'USD' ? '\$' : 'S/';

  /// Boletas se anulan vía Resumen Diario (plazo 3 días). El resto vía CDB (7 días).
  bool get _esBoleta => widget.tipoComprobante == 'BOLETA';

  int get _plazoDias => _esBoleta ? 3 : 7;

  String get _tituloDialog =>
      _esBoleta ? 'Anular Boleta (Resumen Diario)' : 'Comunicación de Baja';

  String get _mecanismoNombre => _esBoleta ? 'RC' : 'CDB';

  /// Fecha de emisión en zona horaria local del dispositivo.
  /// `widget.fechaEmision` puede venir parseada como UTC (cuando el JSON trae "Z"),
  /// y al extraer .year/.month/.day devuelve componentes UTC — lo que provoca un
  /// desfase de 1 día con la fecha real local del usuario.
  DateTime get _fechaEmisionLocal => widget.fechaEmision.toLocal();

  int get _diasTranscurridos {
    final hoy = DateTime.now();
    final h = DateTime(hoy.year, hoy.month, hoy.day);
    final f = DateTime(_fechaEmisionLocal.year, _fechaEmisionLocal.month,
        _fechaEmisionLocal.day);
    return h.difference(f).inDays;
  }

  bool get _fueraDePlazo => _diasTranscurridos > _plazoDias;

  bool get _formValido =>
      !_fueraDePlazo &&
      _motivoGeneralController.text.trim().length >= 3 &&
      _motivoEspecificoController.text.trim().length >= 3 &&
      !_submitting;

  Future<void> _emitir() async {
    if (!_formValido) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    if (_esBoleta) {
      await _emitirRC();
    } else {
      await _emitirCDB();
    }
  }

  Future<void> _emitirCDB() async {
    final fLocal = _fechaEmisionLocal;
    final fechaRef =
        '${fLocal.year.toString().padLeft(4, '0')}-${fLocal.month.toString().padLeft(2, '0')}-${fLocal.day.toString().padLeft(2, '0')}';

    final request = CrearComunicacionBajaRequest(
      sedeId: widget.sedeId,
      fechaReferencia: fechaRef,
      motivoBaja: _motivoGeneralController.text.trim(),
      detalles: [
        CrearComunicacionBajaDetalleRequest(
          comprobanteId: widget.comprobanteId,
          motivoEspecifico: _motivoEspecificoController.text.trim(),
        ),
      ],
    );

    final usecase = locator<CrearComunicacionBajaUseCase>();
    final result = await usecase(request);

    if (!mounted) return;

    if (result is Success<ComunicacionBaja>) {
      Navigator.of(context).pop(result.data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'CDB ${result.data.numeroCompleto} emitida (${result.data.estadoSunat})'),
          backgroundColor: result.data.esAceptado ? Colors.green : Colors.orange,
        ),
      );
    } else if (result is Error<ComunicacionBaja>) {
      setState(() {
        _submitting = false;
        _error = result.message;
      });
    }
  }

  Future<void> _emitirRC() async {
    final request = CrearResumenDiarioRequest(
      sedeId: widget.sedeId,
      motivoAnulacion: _motivoGeneralController.text.trim(),
      detalles: [
        CrearResumenDiarioDetalleRequest(
          comprobanteId: widget.comprobanteId,
          motivoEspecifico: _motivoEspecificoController.text.trim(),
        ),
      ],
    );

    final usecase = locator<CrearResumenDiarioUseCase>();
    final result = await usecase(request);

    if (!mounted) return;

    if (result is Success<ResumenDiario>) {
      Navigator.of(context).pop(result.data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'RC ${result.data.numeroCompleto} emitido (${result.data.estadoSunat})'),
          backgroundColor: result.data.esAceptado ? Colors.green : Colors.orange,
        ),
      );
    } else if (result is Error<ResumenDiario>) {
      setState(() {
        _submitting = false;
        _error = result.message;
      });
    }
  }

  @override
  void dispose() {
    _motivoGeneralController.dispose();
    _motivoEspecificoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.cancel_outlined, color: Colors.red.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_tituloDialog,
                style: const TextStyle(fontSize: 16, color: Colors.red)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con info del comprobante
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${_tipoLabel(widget.tipoComprobante)} ${widget.comprobanteCodigo}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    Text(
                        'Total: $_simboloMoneda ${widget.total.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade700)),
                    Text(
                      'Emitido: ${_fechaEmisionLocal.day}/${_fechaEmisionLocal.month}/${_fechaEmisionLocal.year}'
                      ' ($_diasTranscurridos días)',
                      style: TextStyle(
                        fontSize: 11,
                        color: _fueraDePlazo
                            ? Colors.red
                            : Colors.grey.shade700,
                        fontWeight: _fueraDePlazo ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_fueraDePlazo) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _esBoleta
                        ? 'Fuera del plazo SUNAT ($_plazoDias días). Pasado este plazo no se puede anular oficialmente.'
                        : 'Fuera del plazo SUNAT ($_plazoDias días). Para revertir este comprobante usa Nota de Crédito.',
                    style: TextStyle(
                        fontSize: 11, color: Colors.orange.shade900),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                _esBoleta
                    ? 'El Resumen Diario anula oficialmente la boleta ante SUNAT. Plazo: $_plazoDias días desde la emisión. Esta acción NO se puede revertir.'
                    : 'La Comunicación de Baja anula oficialmente el comprobante ante SUNAT. Plazo: $_plazoDias días desde la emisión. Esta acción NO se puede revertir.',
                style: const TextStyle(fontSize: 11, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _motivoGeneralController,
                enabled: !_fueraDePlazo && !_submitting,
                maxLines: 2,
                maxLength: 500,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: _esBoleta
                      ? 'Motivo general de la anulación'
                      : 'Motivo general de la baja',
                  hintText: 'Ej: Anulación por error administrativo',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _motivoEspecificoController,
                enabled: !_fueraDePlazo && !_submitting,
                maxLines: 2,
                maxLength: 250,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Motivo específico del documento',
                  hintText: 'Ej: Cliente canceló la operación antes de la entrega',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(_error!,
                      style: TextStyle(
                          fontSize: 11, color: Colors.red.shade800)),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _formValido ? _emitir : null,
          child: _submitting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text('Emitir $_mecanismoNombre',
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ],
    );
  }

  String _tipoLabel(String tipo) {
    switch (tipo) {
      case 'FACTURA':
        return 'Factura';
      case 'BOLETA':
        return 'Boleta';
      case 'NOTA_CREDITO':
        return 'N. Crédito';
      case 'NOTA_DEBITO':
        return 'N. Débito';
      default:
        return tipo;
    }
  }
}
