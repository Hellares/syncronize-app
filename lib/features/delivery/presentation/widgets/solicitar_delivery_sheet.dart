import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_switch_tile.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../pages/ubicacion_picker_page.dart';

/// Datos del delivery recolectados por el sheet (el caller arma el payload
/// con empresaId/ventaId y hace el POST).
class SolicitarDeliveryFormData {
  final String direccion;
  final String? referencia;
  final String? distrito;

  /// null = el backend aplica la tarifa default de la sede.
  final double? costoDelivery;

  /// Pin del mapa (ubicación exacta): NAVEGAR del repartidor va al punto
  /// y el cliente ve el 📍 en su tracking.
  final double? destinoLat;
  final double? destinoLon;

  /// Delivery INTERNO: lo lleva un empleado — NO se publica al pool.
  final bool esInterno;
  final String? encargadoInterno;

  const SolicitarDeliveryFormData({
    required this.direccion,
    this.referencia,
    this.distrito,
    this.costoDelivery,
    this.destinoLat,
    this.destinoLon,
    this.esInterno = false,
    this.encargadoInterno,
  });

  Map<String, dynamic> toJson() => {
        'direccion': direccion,
        if (referencia != null && referencia!.isNotEmpty)
          'referencia': referencia,
        if (distrito != null && distrito!.isNotEmpty) 'distrito': distrito,
        if (costoDelivery != null) 'costoDelivery': costoDelivery,
        if (destinoLat != null && destinoLon != null) ...{
          'destinoLat': destinoLat,
          'destinoLon': destinoLon,
        },
        if (esInterno) ...{
          'esInterno': true,
          if (encargadoInterno != null && encargadoInterno!.isNotEmpty)
            'encargadoInterno': encargadoInterno,
        },
      };
}

/// Sheet para publicar el DELIVERY LOCAL de una venta ya pagada al 100%:
/// dirección de entrega + tarifa (vacía = la default de la sede). Al
/// confirmar, el backend lo publica al pool y notifica a los repartidores.
Future<SolicitarDeliveryFormData?> showSolicitarDeliverySheet({
  required BuildContext context,
  required String ventaCodigo,
  // Geocoder propio: habilitan búsqueda local + recientes del cliente.
  String? empresaId,
  String? telefonoCliente,
  // Modo EDICIÓN: corregir la dirección de un delivery ya solicitado
  // (dirección equivocada o el cliente pidió otro punto). Prellena los
  // campos y oculta la tarifa (no cambia al editar).
  bool esEdicion = false,
  String? initDireccion,
  String? initReferencia,
  String? initDistrito,
  LatLng? initDestino,
}) {
  return showModalBottomSheet<SolicitarDeliveryFormData>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SolicitarDeliverySheet(
      ventaCodigo: ventaCodigo,
      empresaId: empresaId,
      telefonoCliente: telefonoCliente,
      esEdicion: esEdicion,
      initDireccion: initDireccion,
      initReferencia: initReferencia,
      initDistrito: initDistrito,
      initDestino: initDestino,
    ),
  );
}

class _SolicitarDeliverySheet extends StatefulWidget {
  final String ventaCodigo;
  final String? empresaId;
  final String? telefonoCliente;
  final bool esEdicion;
  final String? initDireccion;
  final String? initReferencia;
  final String? initDistrito;
  final LatLng? initDestino;
  const _SolicitarDeliverySheet({
    required this.ventaCodigo,
    this.empresaId,
    this.telefonoCliente,
    this.esEdicion = false,
    this.initDireccion,
    this.initReferencia,
    this.initDistrito,
    this.initDestino,
  });

  @override
  State<_SolicitarDeliverySheet> createState() =>
      _SolicitarDeliverySheetState();
}

class _SolicitarDeliverySheetState extends State<_SolicitarDeliverySheet> {
  final _direccionCtrl = TextEditingController();
  final _referenciaCtrl = TextEditingController();
  final _distritoCtrl = TextEditingController();
  final _costoCtrl = TextEditingController();
  final _encargadoCtrl = TextEditingController();
  LatLng? _destino;

  /// Delivery interno: lo lleva un empleado — no se publica al pool.
  bool _esInterno = false;

  @override
  void initState() {
    super.initState();
    // Modo edición: prellenar con lo actual del delivery.
    _direccionCtrl.text = widget.initDireccion ?? '';
    _referenciaCtrl.text = widget.initReferencia ?? '';
    _distritoCtrl.text = widget.initDistrito ?? '';
    _destino = widget.initDestino;
  }

  @override
  void dispose() {
    _direccionCtrl.dispose();
    _referenciaCtrl.dispose();
    _distritoCtrl.dispose();
    _costoCtrl.dispose();
    _encargadoCtrl.dispose();
    super.dispose();
  }

  void _confirmar() {
    final direccion = _direccionCtrl.text.trim();
    if (direccion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Ingresa la dirección de entrega',
            style: TextStyle(fontSize: 12)),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final costoTexto = _costoCtrl.text.trim();
    double? costo;
    if (costoTexto.isNotEmpty) {
      costo = double.tryParse(costoTexto.replaceAll(',', '.'));
      if (costo == null || costo < 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('La tarifa no es un monto válido',
              style: TextStyle(fontSize: 12)),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
    }
    Navigator.of(context).pop(SolicitarDeliveryFormData(
      direccion: direccion,
      referencia: _referenciaCtrl.text.trim(),
      distrito: _distritoCtrl.text.trim(),
      costoDelivery: costo,
      destinoLat: _destino?.latitude,
      destinoLon: _destino?.longitude,
      esInterno: _esInterno,
      encargadoInterno: _encargadoCtrl.text.trim(),
    ));
  }

  Future<void> _fijarEnMapa() async {
    final elegido = await UbicacionPickerPage.show(
      context,
      inicial: _destino,
      empresaId: widget.empresaId,
      telefonoCliente: widget.telefonoCliente,
    );
    if (elegido == null || !mounted) return;
    setState(() {
      _destino = elegido.punto;
      // Dirección y zona del pin se autollenan (editables después).
      if (elegido.direccion != null && elegido.direccion!.isNotEmpty) {
        _direccionCtrl.text = elegido.direccion!.toUpperCase();
      }
      if (elegido.zona != null && elegido.zona!.isNotEmpty) {
        _distritoCtrl.text = elegido.zona!.toUpperCase();
      }
      // Referencia guardada de una dirección frecuente: solo si la caja
      // sigue vacía (no pisar lo que el cajero ya escribió).
      if ((elegido.referencia ?? '').isNotEmpty &&
          _referenciaCtrl.text.trim().isEmpty) {
        _referenciaCtrl.text = elegido.referencia!.toUpperCase();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.delivery_dining,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.esEdicion
                          ? 'Editar dirección — ${widget.ventaCodigo}'
                          : 'Delivery local — ${widget.ventaCodigo}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.esEdicion
                    ? 'Si el repartidor ya tomó el pedido, recibirá un aviso '
                        'con la dirección nueva.'
                    : 'El producto ya está pagado: el repartidor cobra SOLO la '
                        'tarifa del delivery al entregar.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              // PRIMERO el mapa (autollena la dirección): buscar/pinear el
              // punto exacto → NAVEGAR va al punto y el cliente ve el 📍.
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor:
                      _destino == null ? AppColors.blue1 : Colors.green[700],
                  side: BorderSide(
                    color: _destino == null
                        ? AppColors.blue1
                        : Colors.green[700]!,
                        width: 0.6,
                  ),
                  minimumSize: const Size(double.infinity, 38),
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                onPressed: _fijarEnMapa,
                icon: Icon(
                  _destino == null
                      ? Icons.map_outlined
                      : Icons.check_circle_outline,
                  size: 17,
                ),
                label: Text(_destino == null
                    ? 'Buscar y fijar ubicación en el mapa'
                    : '📍 Ubicación fijada — tocar para cambiar'),
              ),
              const SizedBox(height: 8),
              CustomText(
                controller: _direccionCtrl,
                label: 'Dirección de entrega',
                hintText: 'Se llena sola al fijar el pin (editable)',
                borderColor: AppColors.blue1,
                textCase: TextCase.upper,
              ),
              const SizedBox(height: 8),
              CustomText(
                controller: _referenciaCtrl,
                label: 'Referencia',
                hintText: 'ej. Casa de rejas verdes, frente al parque',
                borderColor: AppColors.blue1,
                textCase: TextCase.upper,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomText(
                      controller: _distritoCtrl,
                      label: 'Distrito / zona',
                      borderColor: AppColors.blue1,
                      textCase: TextCase.upper,
                    ),
                  ),
                  // La tarifa no cambia al editar la dirección.
                  if (!widget.esEdicion) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomText(
                        controller: _costoCtrl,
                        label: 'Tarifa S/',
                        hintText: 'de la sede',
                        borderColor: AppColors.blue1,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              if (!widget.esEdicion)
                Text(
                  'Tarifa vacía = se usa la tarifa configurada de la sede.',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              // Delivery INTERNO: lo lleva un empleado — se cobra la tarifa
              // igual, pero NO se publica al pool de repartidores.
              if (!widget.esEdicion) ...[
                const SizedBox(height: 6),
                CustomSwitchTile(
                  title: 'Delivery interno',
                  subtitle: _esInterno
                      ? 'Lo lleva un empleado — NO se publica a repartidores'
                      : 'Se publica al pool de repartidores',
                  subtitleStyle: TextStyle(
                    color: _esInterno
                        ? Colors.teal
                        : Colors.grey.shade600,
                        fontSize: 10,
                  ),
                  value: _esInterno,
                  onChanged: (v) => setState(() => _esInterno = v),
                  activeColor: Colors.teal,
                ),
                if (_esInterno) ...[
                  const SizedBox(height: 6),
                  CustomText(
                    controller: _encargadoCtrl,
                    label: 'Encargado (opcional)',
                    hintText: 'ej. Nombre del empleado que lo lleva',
                    borderColor: Colors.teal,
                    textCase: TextCase.upper,
                  ),
                ],
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  CustomButton(
                    width: 120,
                    borderWidth: 0.6,
                    icon: const Icon(Icons.close_outlined, size: 16, color: AppColors.red),
                    text: 'Cancelar',
                    isOutlined: true,
                    borderColor: AppColors.red,
                    textColor: AppColors.red,
                    enableShadows: false,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomButton(
                      text: widget.esEdicion
                          ? 'Actualizar dirección'
                          : _esInterno
                              ? 'Crear delivery interno'
                              : 'Publicar para repartidores',
                      backgroundColor: AppColors.blue1,
                      textColor: Colors.white,
                      icon: Icon(
                          widget.esEdicion
                              ? Icons.edit_location_alt_outlined
                              : Icons.delivery_dining,
                          size: 16,
                          color: Colors.white),
                      onPressed: _confirmar,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
