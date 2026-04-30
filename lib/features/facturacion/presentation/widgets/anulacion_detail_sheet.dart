import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/anulacion.dart';
import '../bloc/anulaciones_cubit.dart';

/// Sheet con detalle completo de una anulación (CDB o RC).
/// Botón "Re-consultar SUNAT" disponible solo si el estado es no-terminal.
class AnulacionDetailSheet extends StatefulWidget {
  final Anulacion anulacion;

  const AnulacionDetailSheet({super.key, required this.anulacion});

  static Future<void> show(BuildContext context, Anulacion anulacion) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => BlocProvider.value(
        // Pasamos el cubit padre para poder llamar reConsultar() desde acá.
        value: BlocProvider.of<AnulacionesCubit>(context),
        child: AnulacionDetailSheet(anulacion: anulacion),
      ),
    );
  }

  @override
  State<AnulacionDetailSheet> createState() => _AnulacionDetailSheetState();
}

class _AnulacionDetailSheetState extends State<AnulacionDetailSheet> {
  bool _consultando = false;
  String? _consultaError;

  Anulacion get a => widget.anulacion;

  @override
  Widget build(BuildContext context) {
    final estadoColor = _colorEstado(a.estadoSunat);
    final tipoColor =
        a.tipo == TipoAnulacion.cdb ? Colors.blue : Colors.teal;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tipoColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    a.tipoLabel,
                    style: TextStyle(
                        fontSize: 11,
                        color: tipoColor,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    a.numeroCompleto,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    a.estadoSunat,
                    style: TextStyle(
                        fontSize: 11,
                        color: estadoColor,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(a.tipoDescripcion,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 16),

            // Bloque info
            _section('Información'),
            _kv('Fecha emisión', _fmtDate(a.fechaEmision.toLocal())),
            _kv('Fecha referencia', _fmtDate(a.fechaReferencia.toLocal())),
            if (a.ticket != null && a.ticket!.isNotEmpty)
              _kv('Ticket SUNAT', a.ticket!, mono: true),
            _kv('Documentos', '${a.cantidadDocumentos}'),

            const SizedBox(height: 12),
            _section('Motivo'),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(a.motivo,
                  style: const TextStyle(fontSize: 12)),
            ),

            if (a.errorProveedor != null && a.errorProveedor!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _section('Error del proveedor'),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(a.errorProveedor!,
                    style: TextStyle(
                        fontSize: 11, color: Colors.red.shade800)),
              ),
            ],

            const SizedBox(height: 16),
            _section(
                'Comprobantes anulados (${a.cantidadDocumentos})'),
            ...a.documentos.map((d) => _DocCard(doc: d)),

            if (_consultaError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(_consultaError!,
                    style: TextStyle(
                        fontSize: 11, color: Colors.red.shade800)),
              ),
            ],
            const SizedBox(height: 16),
            // Acciones
            if (a.esProcesando)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _consultando
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cloud_sync),
                  label: const Text('Re-consultar SUNAT'),
                  onPressed: _consultando ? null : _reConsultar,
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _reConsultar() async {
    setState(() {
      _consultando = true;
      _consultaError = null;
    });
    final cubit = context.read<AnulacionesCubit>();
    final err = await cubit.reConsultar(a);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _consultando = false;
        _consultaError = err;
      });
    } else {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estado actualizado desde SUNAT'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
            letterSpacing: 0.5),
      ),
    );
  }

  Widget _kv(String k, String v, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(k,
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(v,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: mono ? 'monospace' : null,
                )),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static Color _colorEstado(String estado) {
    switch (estado) {
      case 'ACEPTADO':
        return Colors.green.shade700;
      case 'RECHAZADO':
        return Colors.red.shade700;
      case 'PROCESANDO':
      case 'ENVIADO':
        return Colors.orange.shade700;
      case 'PENDIENTE':
      default:
        return Colors.grey.shade700;
    }
  }
}

class _DocCard extends StatelessWidget {
  final DocumentoAnulado doc;
  const _DocCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final tipoLabel = _tipoLabel(doc.tipoComprobante);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$tipoLabel ${doc.comprobanteCodigo}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          if (doc.motivoEspecifico.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(doc.motivoEspecifico,
                style: const TextStyle(fontSize: 11)),
          ],
        ],
      ),
    );
  }

  static String _tipoLabel(String tipo) {
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
