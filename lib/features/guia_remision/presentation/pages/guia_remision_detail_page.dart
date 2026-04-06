import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../domain/entities/guia_remision.dart';
import '../../domain/repositories/guia_remision_repository.dart';
import '../bloc/guia_remision_detail_cubit.dart';

class GuiaRemisionDetailPage extends StatelessWidget {
  final String guiaId;

  const GuiaRemisionDetailPage({super.key, required this.guiaId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GuiaRemisionDetailCubit(locator<GuiaRemisionRepository>())..cargar(guiaId),
      child: _DetailView(guiaId: guiaId),
    );
  }
}

class _DetailView extends StatelessWidget {
  final String guiaId;

  const _DetailView({required this.guiaId});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(title: 'Detalle Guia'),
        body: BlocBuilder<GuiaRemisionDetailCubit, GuiaRemisionDetailState>(
          builder: (context, state) {
            if (state is GuiaRemisionDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is GuiaRemisionDetailError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message, style: TextStyle(color: Colors.red.shade400)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.read<GuiaRemisionDetailCubit>().cargar(guiaId),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }
            if (state is GuiaRemisionDetailLoaded) {
              return _buildContent(context, state.guia);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, GuiaRemision guia) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(guia),
          const SizedBox(height: 12),
          _buildSeccionTraslado(guia),
          const SizedBox(height: 12),
          _buildSeccionDestinatario(guia),
          const SizedBox(height: 12),
          _buildSeccionOrigen(guia),
          const SizedBox(height: 12),
          _buildSeccionDestino(guia),
          const SizedBox(height: 12),
          _buildSeccionTransporte(guia),
          const SizedBox(height: 12),
          if (guia.detalles.isNotEmpty) ...[
            _buildSeccionItems(guia),
            const SizedBox(height: 12),
          ],
          if (guia.documentosRelacionados.isNotEmpty) ...[
            _buildSeccionDocsRelacionados(guia),
            const SizedBox(height: 12),
          ],
          if (guia.documentoOrigenCodigo != null) ...[
            _buildSeccionDocumentoOrigen(guia),
            const SizedBox(height: 12),
          ],
          _buildSeccionSunat(guia),
          const SizedBox(height: 16),
          _buildAcciones(context, guia),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(GuiaRemision guia) {
    return GradientContainer(
      borderColor: _estadoBorderColor(guia.estado),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _tipoChip(guia),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    guia.codigoGenerado,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _estadoChip(guia),
                const SizedBox(width: 6),
                _sunatStatusChip(guia),
                const Spacer(),
                Text(
                  DateFormatter.formatDateTime(guia.fechaEmision),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
            if (guia.nombreSede.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.store, size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    'Sede: ${guia.nombreSede}',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionTraslado(GuiaRemision guia) {
    return _seccion(
      'Traslado',
      Icons.local_shipping,
      [
        _infoRow('Motivo', guia.motivoTrasladoEnum?.label ?? guia.motivoTraslado),
        if (guia.motivoTrasladoOtrosDescripcion != null)
          _infoRow('Descripcion', guia.motivoTrasladoOtrosDescripcion!),
        _infoRow('Fecha inicio traslado', DateFormatter.formatDate(guia.fechaInicioTraslado)),
        _infoRow('Peso bruto', '${guia.pesoBrutoTotal} ${guia.pesoBrutoUnidadMedida}'),
        if (guia.numeroBultos != null) _infoRow('Bultos', '${guia.numeroBultos}'),
        if (guia.observaciones != null && guia.observaciones!.isNotEmpty)
          _infoRow('Observaciones', guia.observaciones!),
      ],
    );
  }

  Widget _buildSeccionDestinatario(GuiaRemision guia) {
    return _seccion(
      'Destinatario',
      Icons.person,
      [
        _infoRow('Tipo doc', _tipoDocLabel(guia.clienteTipoDocumento)),
        _infoRow('Numero', guia.clienteNumeroDocumento),
        _infoRow('Denominacion', guia.clienteDenominacion),
        if (guia.clienteDireccion != null && guia.clienteDireccion!.isNotEmpty)
          _infoRow('Direccion', guia.clienteDireccion!),
        if (guia.clienteEmail != null && guia.clienteEmail!.isNotEmpty)
          _infoRow('Email', guia.clienteEmail!),
      ],
    );
  }

  Widget _buildSeccionOrigen(GuiaRemision guia) {
    return _seccion(
      'Punto de Partida',
      Icons.trip_origin,
      [
        _infoRow('Ubigeo', guia.puntoPartidaUbigeo),
        _infoRow('Direccion', guia.puntoPartidaDireccion),
        if (guia.puntoPartidaCodigoEstablecimientoSunat != null)
          _infoRow('Cod. establecimiento', guia.puntoPartidaCodigoEstablecimientoSunat!),
      ],
    );
  }

  Widget _buildSeccionDestino(GuiaRemision guia) {
    return _seccion(
      'Punto de Llegada',
      Icons.flag,
      [
        _infoRow('Ubigeo', guia.puntoLlegadaUbigeo),
        _infoRow('Direccion', guia.puntoLlegadaDireccion),
        if (guia.puntoLlegadaCodigoEstablecimientoSunat != null)
          _infoRow('Cod. establecimiento', guia.puntoLlegadaCodigoEstablecimientoSunat!),
      ],
    );
  }

  Widget _buildSeccionTransporte(GuiaRemision guia) {
    final esPublico = guia.tipoTransporte == 'PUBLICO';
    return _seccion(
      'Transporte',
      Icons.directions_bus,
      [
        _infoRow('Tipo', esPublico ? 'Publico' : 'Privado'),
        if (guia.transportistaPlacaNumero != null)
          _infoRow('Placa', guia.transportistaPlacaNumero!),
        if (esPublico && guia.transportistaDenominacion != null)
          _infoRow('Transportista', guia.transportistaDenominacion!),
        if (!esPublico) ...[
          if (guia.conductorNombre != null)
            _infoRow('Conductor', '${guia.conductorNombre ?? ''} ${guia.conductorApellidos ?? ''}'.trim()),
          if (guia.conductorNumeroLicencia != null)
            _infoRow('Licencia', guia.conductorNumeroLicencia!),
        ],
      ],
    );
  }

  Widget _buildSeccionItems(GuiaRemision guia) {
    return _seccion(
      'Items (${guia.detalles.length})',
      Icons.inventory_2,
      guia.detalles.map((d) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 5, right: 8),
                decoration: BoxDecoration(color: AppColors.blue1, shape: BoxShape.circle),
              ),
              Expanded(
                child: Text(
                  d.nombreProducto,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${d.cantidad} ${d.unidadMedida}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSeccionDocsRelacionados(GuiaRemision guia) {
    return _seccion(
      'Documentos Relacionados',
      Icons.description,
      guia.documentosRelacionados.map((doc) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(Icons.insert_drive_file, size: 12, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                '${doc.tipoLabel}: ${doc.codigoCompleto}',
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSeccionDocumentoOrigen(GuiaRemision guia) {
    String tipo = '';
    if (guia.ventaId != null) tipo = 'Venta';
    if (guia.compraId != null) tipo = 'Compra';
    if (guia.transferenciaId != null) tipo = 'Transferencia';
    if (guia.devolucionId != null) tipo = 'Devolucion';

    return _seccion(
      'Documento Origen',
      Icons.link,
      [
        _infoRow('Tipo', tipo),
        _infoRow('Codigo', guia.documentoOrigenCodigo ?? '-'),
      ],
    );
  }

  Widget _buildSeccionSunat(GuiaRemision guia) {
    return _seccion(
      'SUNAT',
      Icons.cloud_done,
      [
        if (guia.sunatHash != null) _infoRow('Hash', guia.sunatHash!),
        if (guia.sunatPdfUrl != null)
          _linkRow('PDF', guia.sunatPdfUrl!),
        if (guia.sunatXmlUrl != null)
          _linkRow('XML', guia.sunatXmlUrl!),
        if (guia.sunatCdrUrl != null)
          _linkRow('CDR', guia.sunatCdrUrl!),
        if (guia.cadenaQR != null && guia.cadenaQR!.isNotEmpty)
          _infoRow('QR', guia.cadenaQR!.length > 60 ? '${guia.cadenaQR!.substring(0, 60)}...' : guia.cadenaQR!),
        _infoRow('Intentos envio', '${guia.intentosEnvio}'),
        if (guia.errorProveedor != null && guia.errorProveedor!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                guia.errorProveedor!,
                style: TextStyle(fontSize: 10, color: Colors.red.shade700),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAcciones(BuildContext context, GuiaRemision guia) {
    final acciones = <Widget>[];

    if (guia.estado == 'RECHAZADO' || guia.estado == 'BORRADOR' || guia.sunatStatus == 'ERROR_COMUNICACION' || (guia.errorProveedor != null && guia.errorProveedor!.isNotEmpty)) {
      acciones.add(
        _accionButton(
          context,
          'Editar y Reenviar',
          Icons.edit,
          Colors.orange,
          () => context.push('/empresa/guias-remision/editar/${guia.id}'),
        ),
      );
    }

    if (guia.estadoEnum.puedeEnviar) {
      acciones.add(
        _accionButton(
          context,
          'Enviar a SUNAT',
          Icons.send,
          AppColors.blue1,
          () async {
            await context.read<GuiaRemisionDetailCubit>().enviar(guia.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Guia enviada')),
              );
            }
          },
        ),
      );
    }

    if (guia.estado == 'ENVIADO' || guia.sunatStatus == 'PROCESANDO' || guia.sunatStatus == 'PENDIENTE') {
      acciones.add(
        _accionButton(
          context,
          'Consultar Estado',
          Icons.refresh,
          Colors.orange,
          () async {
            await context.read<GuiaRemisionDetailCubit>().consultar(guia.id);
          },
        ),
      );
    }

    // Siempre mostrar botón de PDF propio
    acciones.add(
      _accionButton(
        context,
        'Imprimir PDF',
        Icons.print,
        Colors.indigo,
        () => context.push('/empresa/guias-remision/${guia.id}/pdf'),
      ),
    );

    if (guia.sunatPdfUrl != null) {
      acciones.add(
        _accionButton(
          context,
          'PDF SUNAT',
          Icons.picture_as_pdf,
          Colors.red,
          () => _abrirUrl(guia.sunatPdfUrl!),
        ),
      );
    }

    if (guia.enlaceProveedor != null) {
      acciones.add(
        _accionButton(
          context,
          'Ver en Nubefact',
          Icons.open_in_new,
          Colors.teal,
          () => _abrirUrl(guia.enlaceProveedor!),
        ),
      );
    }

    if (acciones.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Acciones',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: acciones,
        ),
      ],
    );
  }

  // ── Helpers ──

  Widget _seccion(String titulo, IconData icon, List<Widget> children) {
    return GradientContainer(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: AppColors.blue1),
                const SizedBox(width: 6),
                Text(
                  titulo,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkRow(String label, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _abrirUrl(url),
              child: Text(
                'Descargar',
                style: TextStyle(fontSize: 11, color: AppColors.blue1, decoration: TextDecoration.underline),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _tipoChip(GuiaRemision guia) {
    final isRemitente = guia.tipo == 'REMITENTE';
    final color = isRemitente ? Colors.indigo : Colors.teal;
    final label = isRemitente ? 'Remitente' : 'Transportista';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _estadoChip(GuiaRemision guia) {
    final color = _estadoColor(guia.estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        guia.estadoEnum.label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _sunatStatusChip(GuiaRemision guia) {
    Color color;
    String label;
    switch (guia.sunatStatus) {
      case 'ACEPTADO':
        color = Colors.green;
        label = 'SUNAT: Aceptado';
        break;
      case 'RECHAZADO':
        color = Colors.red;
        label = 'SUNAT: Rechazado';
        break;
      case 'PROCESANDO':
        color = Colors.blue;
        label = 'SUNAT: Procesando';
        break;
      case 'ERROR_COMUNICACION':
        color = Colors.red.shade300;
        label = 'SUNAT: Error';
        break;
      default:
        color = Colors.orange;
        label = 'SUNAT: Pendiente';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'BORRADOR':
        return Colors.grey;
      case 'REGISTRADO':
        return Colors.blueGrey;
      case 'ENVIADO':
        return Colors.blue;
      case 'ACEPTADO':
        return Colors.green;
      case 'RECHAZADO':
        return Colors.red;
      case 'ANULADO':
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }

  Color _estadoBorderColor(String estado) {
    switch (estado) {
      case 'ACEPTADO':
        return Colors.green.shade200;
      case 'RECHAZADO':
        return Colors.red.shade200;
      case 'ANULADO':
        return Colors.red.shade300;
      case 'ENVIADO':
        return Colors.blue.shade200;
      default:
        return AppColors.blueborder;
    }
  }

  String _tipoDocLabel(String tipo) {
    switch (tipo) {
      case '1':
        return 'DNI';
      case '6':
        return 'RUC';
      case '4':
        return 'Carnet de Extranjeria';
      case '7':
        return 'Pasaporte';
      case '0':
        return 'Sin documento';
      default:
        return tipo;
    }
  }

  Future<void> _abrirUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
