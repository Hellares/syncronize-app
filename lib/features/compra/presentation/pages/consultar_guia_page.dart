import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../data/datasources/compra_remote_datasource.dart';
import '../../data/models/guia_remision_consulta_model.dart';

/// Consulta de Guía de Remisión (GRE) del proveedor en SUNAT.
class ConsultarGuiaPage extends StatefulWidget {
  /// Pre-llena el número (ej. desde una recepción). Opcional.
  final String? numeroInicial;
  const ConsultarGuiaPage({super.key, this.numeroInicial});

  @override
  State<ConsultarGuiaPage> createState() => _ConsultarGuiaPageState();
}

class _ConsultarGuiaPageState extends State<ConsultarGuiaPage> {
  final _ds = locator<CompraRemoteDataSource>();
  late final TextEditingController _ctrl;
  bool _loading = false;
  String? _error;
  GuiaRemisionConsulta? _guia;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.numeroInicial ?? '');
    if ((widget.numeroInicial ?? '').isNotEmpty) _consultar();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _consultar() async {
    final n = _ctrl.text.trim().toUpperCase();
    if (!RegExp(r'^\d{11}-\d{1,2}-[A-Z0-9]+-\d+$').hasMatch(n)) {
      setState(() => _error = 'Formato: RUC-tipo-serie-número (ej. 20132373958-09-T290-120)');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _guia = null;
    });
    try {
      final g = await _ds.consultarGuiaRemision(n);
      if (!mounted) return;
      setState(() {
        _guia = g;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'No se pudo consultar la guía. Verificá el número.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Consultar guía SUNAT',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
      ),
      body: GradientBackground(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            GradientContainer(
              borderColor: AppColors.blueborder,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      label: 'Número de guía',
                      controller: _ctrl,
                      hintText: '20132373958-09-T290-120',
                      borderColor: AppColors.blueborder,
                    ),
                    const SizedBox(height: 4),
                    const AppSubtitle('Formato: RUC-tipo-serie-número',
                        fontSize: 10, color: AppColors.blueGrey),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Consultar',
                        backgroundColor: AppColors.blue1,
                        textColor: Colors.white,
                        isLoading: _loading,
                        onPressed: _loading ? null : _consultar,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            if (_guia != null) ...[
              const SizedBox(height: 12),
              _GuiaView(guia: _guia!),
            ],
          ],
        ),
      ),
    );
  }
}

class _GuiaView extends StatelessWidget {
  final GuiaRemisionConsulta guia;
  const _GuiaView({required this.guia});

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping, size: 18, color: AppColors.blue1),
                const SizedBox(width: 8),
                Expanded(
                  child: AppSubtitle('${guia.tipoDesc}  ${guia.numeroCompleto}',
                      fontSize: 14, color: AppColors.blue1),
                ),
              ],
            ),
            if (guia.fechaEmision != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('Emitida: ${DateFormatter.formatDate(guia.fechaEmision!)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ),
            const Divider(height: 18),
            _seccion('Emisor', [
              _row('RUC', guia.emisorRuc),
              _row('Nombre', guia.emisorNombre),
            ]),
            _seccion('Destinatario', [
              _row('Doc', guia.receptorDoc),
              _row('Nombre', guia.receptorNombre),
            ]),
            _seccion('Traslado', [
              _row('Motivo', guia.motivoDesc ?? guia.motivoCod),
              _row('Inicio', guia.fechaInicio != null ? DateFormatter.formatDate(guia.fechaInicio!) : null),
              _row('Peso bruto', guia.pesoBruto != null ? '${guia.pesoBruto} kg' : null),
              _row('Modalidad', guia.modalidad),
            ]),
            _seccion('Ruta', [
              _row('Origen', guia.origenDireccion),
              _row('Destino', guia.destinoDireccion),
            ]),
            if (guia.vehiculoPlaca != null || guia.conductorNombre != null)
              _seccion('Transporte', [
                _row('Placa', guia.vehiculoPlaca),
                _row('Conductor', guia.conductorNombre),
                _row('Lic./DNI', [guia.conductorLicencia, guia.conductorDoc].where((e) => e != null).join(' · ').trim().isEmpty ? null : [guia.conductorLicencia, guia.conductorDoc].where((e) => e != null).join(' · ')),
              ]),
            if (guia.bienes.isNotEmpty) ...[
              const SizedBox(height: 8),
              const AppSubtitle('Bienes', fontSize: 11, color: AppColors.blue1),
              const SizedBox(height: 4),
              ...guia.bienes.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(b.descripcion ?? '—',
                              style: const TextStyle(fontSize: 11)),
                        ),
                        Text(
                          '${b.cantidad ?? ''} ${b.unidad ?? ''}'.trim(),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _seccion(String titulo, List<Widget> filas) {
    final visibles = filas.whereType<_Fila>().where((f) => f.value != null).toList();
    if (visibles.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSubtitle(titulo, fontSize: 11, color: AppColors.blue1),
          const SizedBox(height: 2),
          ...visibles,
        ],
      ),
    );
  }

  _Fila _row(String label, String? value) => _Fila(label: label, value: value);
}

class _Fila extends StatelessWidget {
  final String label;
  final String? value;
  const _Fila({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
