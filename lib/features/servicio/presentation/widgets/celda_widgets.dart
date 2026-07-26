import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/resource.dart';
import '../../../consultas_externas/domain/entities/consulta_dni.dart';
import '../../../consultas_externas/domain/entities/consulta_licencia.dart';
import '../../../consultas_externas/domain/entities/consulta_placa.dart';
import '../../../consultas_externas/domain/entities/consulta_ruc.dart';
import '../../../consultas_externas/domain/repositories/consultas_repository.dart';
import '../constants/tipos_campo_servicio.dart';
import 'buscar_producto_sheet.dart';

/// Widgets para celdas de TABLA.
///
/// 🔴 GOTCHA: `Checkbox` y `DropdownButton` de Material imponen un tamaño
/// mínimo de interacción de 48px. Ni `visualDensity.compact` ni
/// `materialTapTargetSize.shrinkWrap` los bajan lo suficiente, así que
/// deformaban la celda de 34px de alto. Estos los reemplazan con control
/// total del tamaño; el área tocable es TODA la celda, que además es más
/// cómoda que un cuadradito de 18px.

/// Booleano de celda: toda la celda alterna el valor.
class CeldaBooleana extends StatelessWidget {
  final bool valor;
  final ValueChanged<bool> onChanged;

  const CeldaBooleana({
    super.key,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!valor),
      child: Center(
        child: Icon(
          valor ? Icons.check_box : Icons.check_box_outline_blank,
          size: 18,
          color: valor ? AppColors.blue1 : Colors.grey.shade400,
        ),
      ),
    );
  }
}

/// Celda con lupa que resuelve datos en una fuente externa: DNI/CE/RUC
/// (RENIEC, Migraciones, SUNAT), placa (SUNARP) o licencia de conducir.
///
/// La celda guarda SOLO lo tecleado. Los datos resueltos se entregan por
/// [onResuelto] como un mapa `{clave: valor}` con las claves de
/// [kDatosDeConsulta], y la tabla decide en qué columnas ponerlos — así este
/// widget no necesita saber nada de columnas.
class CeldaConsulta extends StatefulWidget {
  final String tipo;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<Map<String, String>> onResuelto;

  const CeldaConsulta({
    super.key,
    required this.tipo,
    required this.controller,
    required this.onChanged,
    required this.onResuelto,
  });

  @override
  State<CeldaConsulta> createState() => _CeldaConsultaState();
}

class _CeldaConsultaState extends State<CeldaConsulta> {
  bool _consultando = false;

  bool get _esNumerico => widget.tipo != 'PLACA_VEHICULO';

  Future<void> _consultar() async {
    final texto = widget.controller.text.trim();
    if (texto.isEmpty) return;

    // Los largos se validan ANTES de encender el indicador: si no, queda
    // girando en los casos que ni llegan a consultar.
    if (widget.tipo == 'LICENCIA_CONDUCIR' && texto.length != 8) {
      _aviso('La licencia se busca por el DNI del conductor (8 dígitos)');
      return;
    }
    if (widget.tipo == 'DOCUMENTO_IDENTIDAD' &&
        ![8, 9, 11].contains(texto.length)) {
      _aviso('Ingresa un DNI (8), CE (9) o RUC (11 dígitos)');
      return;
    }

    setState(() => _consultando = true);
    final repo = locator<ConsultasRepository>();
    dynamic result;

    switch (widget.tipo) {
      case 'PLACA_VEHICULO':
        result = await repo.consultarPlaca(texto);
        break;
      case 'LICENCIA_CONDUCIR':
        result = await repo.consultarLicencia(texto);
        break;
      default:
        // 8 = DNI (RENIEC), 9 = carné de extranjería, 11 = RUC (SUNAT).
        result = texto.length == 11
            ? await repo.consultarRuc(texto)
            : texto.length == 9
                ? await repo.consultarCee(texto)
                : await repo.consultarDni(texto);
    }

    if (!mounted) return;
    setState(() => _consultando = false);

    if (result is Success) {
      widget.onResuelto(_aMapa(result.data));
    } else if (result is Error) {
      _aviso(result.message);
    }
  }

  /// Traduce la respuesta a las claves de `kDatosDeConsulta`.
  Map<String, String> _aMapa(dynamic d) {
    if (d is ConsultaPlaca) {
      return {
        'marca': d.marca,
        'modelo': d.modelo,
        'color': d.color,
        'serie': d.serie,
        'motor': d.motor,
        'vin': d.vin,
      }..removeWhere((_, v) => v.trim().isEmpty);
    }
    if (d is ConsultaLicencia) {
      return {
        'nombre': d.nombreCompleto,
        'categoria': d.licenciaCategoria,
        'vencimiento': d.licenciaFechaVencimiento,
        'estado': d.licenciaEstado,
      }..removeWhere((_, v) => v.trim().isEmpty);
    }
    if (d is ConsultaRuc) return {'nombre': d.razonSocial};
    if (d is ConsultaDni) return {'nombre': d.nombreCompleto};
    return const {};
  }

  void _aviso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      style: const TextStyle(fontSize: 11),
      textAlignVertical: TextAlignVertical.center,
      textCapitalization: _esNumerico
          ? TextCapitalization.none
          : TextCapitalization.characters,
      keyboardType: _esNumerico ? TextInputType.number : TextInputType.text,
      decoration: kDecoracionCelda.copyWith(
        suffixIcon: _consultando
            ? const Padding(
                padding: EdgeInsets.all(4),
                child: SizedBox(
                  width: 11,
                  height: 11,
                  child: CircularProgressIndicator(strokeWidth: 1.6),
                ),
              )
            : GestureDetector(
                onTap: _consultar,
                child: const Icon(Icons.search, size: 14, color: AppColors.blue1),
              ),
        suffixIconConstraints:
            const BoxConstraints(minWidth: 20, minHeight: 20),
      ),
      onChanged: widget.onChanged,
    );
  }
}

/// Celda con FOTO: muestra la miniatura dentro de la celda y al tocarla
/// ofrece verla, reemplazarla o quitarla.
///
/// Igual que la firma, sube el archivo al storage y guarda **solo la URL**:
/// meter la imagen en `datosPersonalizados` inflaría el JSON de la orden.
class CeldaFoto extends StatefulWidget {
  final String? url;
  final String empresaId;
  final ValueChanged<String?> onCambio;

  /// Solo muestra: la miniatura se puede ampliar pero no reemplazar. Es el
  /// modo del detalle cuando no se está editando la tabla.
  final bool soloLectura;

  const CeldaFoto({
    super.key,
    required this.url,
    required this.empresaId,
    required this.onCambio,
    this.soloLectura = false,
  });

  @override
  State<CeldaFoto> createState() => _CeldaFotoState();
}

class _CeldaFotoState extends State<CeldaFoto> {
  bool _subiendo = false;

  Future<void> _capturar(ImageSource origen) async {
    final picked = await ImagePicker().pickImage(
      source: origen,
      // La foto es evidencia, no material de catálogo: comprimir baja mucho
      // el peso sin perder lo que importa (un IMEI, un rayón).
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (picked == null || !mounted) return;

    setState(() => _subiendo = true);
    try {
      final res = await locator<StorageService>().uploadFile(
        file: File(picked.path),
        empresaId: widget.empresaId,
        // `categoria` es un enum CERRADO del backend, no texto libre:
        // PRINCIPAL, GALERIA, THUMBNAIL, DOCUMENTO, FACTURA, COTIZACION,
        // LOGO, BANNER, SPLASH, CERTIFICADO, CONTRATO, EVIDENCIA, FIRMA,
        // QR_COBRO. Una foto de orden de servicio ES evidencia.
        categoria: 'EVIDENCIA',
      );
      if (!mounted) return;
      widget.onCambio(res.url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo subir la foto: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  void _verGrande() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(child: Image.network(widget.url!)),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_subiendo) {
      return const Center(
        child: SizedBox(
          width: 13,
          height: 13,
          child: CircularProgressIndicator(strokeWidth: 1.8),
        ),
      );
    }

    final vacia = widget.url == null || widget.url!.isEmpty;

    if (widget.soloLectura) {
      if (vacia) return const SizedBox.shrink();
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _verGrande,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Image.network(
              widget.url!,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Icon(Icons.broken_image_outlined,
                  size: 14, color: Colors.grey.shade400),
            ),
          ),
        ),
      );
    }

    if (vacia) {
      // Menú explícito en vez de "toque = cámara, mantener = galería": ese
      // atajo no lo descubre nadie y dejaba la galería inalcanzable.
      return PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        tooltip: '',
        position: PopupMenuPosition.under,
        onSelected: (v) => _capturar(
          v == 'camara' ? ImageSource.camera : ImageSource.gallery,
        ),
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: 'camara',
            height: 38,
            child: Row(children: [
              Icon(Icons.photo_camera_outlined, size: 16),
              SizedBox(width: 8),
              Text('Tomar foto', style: TextStyle(fontSize: 12)),
            ]),
          ),
          PopupMenuItem(
            value: 'galeria',
            height: 38,
            child: Row(children: [
              Icon(Icons.photo_library_outlined, size: 16),
              SizedBox(width: 8),
              Text('Elegir de galería', style: TextStyle(fontSize: 12)),
            ]),
          ),
        ],
        child: Center(
          child: Icon(Icons.add_a_photo_outlined,
              size: 15, color: Colors.grey.shade400),
        ),
      );
    }

    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      tooltip: '',
      position: PopupMenuPosition.under,
      onSelected: (v) {
        if (v == 'ver') _verGrande();
        if (v == 'camara') _capturar(ImageSource.camera);
        if (v == 'galeria') _capturar(ImageSource.gallery);
        if (v == 'quitar') widget.onCambio(null);
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'ver', height: 34, child: Text('Ver', style: TextStyle(fontSize: 12))),
        PopupMenuItem(value: 'camara', height: 34, child: Text('Tomar otra', style: TextStyle(fontSize: 12))),
        PopupMenuItem(value: 'galeria', height: 34, child: Text('Elegir de galería', style: TextStyle(fontSize: 12))),
        PopupMenuItem(
          value: 'quitar',
          height: 34,
          child: Text('Quitar', style: TextStyle(fontSize: 12, color: Colors.red)),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Image.network(
            widget.url!,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.broken_image_outlined, size: 14, color: Colors.grey.shade400),
          ),
        ),
      ),
    );
  }
}

/// Celda que elige un producto del catálogo. Guarda el NOMBRE; el precio y
/// el código viajan por [onResuelto] a las columnas que los declaren.
class CeldaProducto extends StatelessWidget {
  final String? valor;
  final String empresaId;
  final String? sedeId;
  final ValueChanged<Map<String, String>> onResuelto;

  const CeldaProducto({
    super.key,
    required this.valor,
    required this.empresaId,
    required this.sedeId,
    required this.onResuelto,
  });

  @override
  Widget build(BuildContext context) {
    final vacia = valor == null || valor!.trim().isEmpty;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final elegido = await BuscarProductoSheet.show(
          context,
          empresaId: empresaId,
          sedeId: sedeId,
        );
        if (elegido != null) onResuelto(elegido);
      },
      child: Row(
        children: [
          Expanded(
            child: Text(
              vacia ? 'Buscar…' : valor!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: vacia ? Colors.grey.shade400 : Colors.black87,
              ),
            ),
          ),
          Icon(Icons.search, size: 13, color: AppColors.blue1),
        ],
      ),
    );
  }
}

/// Selección de celda: abre el menú al tocar cualquier parte de la celda.
class CeldaSeleccion extends StatelessWidget {
  final String? valor;
  final List<String> opciones;
  final ValueChanged<String?> onChanged;

  const CeldaSeleccion({
    super.key,
    required this.valor,
    required this.opciones,
    required this.onChanged,
  });

  static const _limpiar = '__limpiar__';

  @override
  Widget build(BuildContext context) {
    final actual = valor != null && opciones.contains(valor) ? valor : null;

    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      tooltip: '',
      position: PopupMenuPosition.under,
      onSelected: (v) => onChanged(v == _limpiar ? null : v),
      itemBuilder: (_) => [
        for (final o in opciones)
          PopupMenuItem(
            value: o,
            height: 34,
            child: Text(o, style: const TextStyle(fontSize: 12)),
          ),
        if (actual != null)
          const PopupMenuItem(
            value: _limpiar,
            height: 34,
            child: Text('Vaciar',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
      ],
      child: Row(
        children: [
          Expanded(
            child: Text(
              actual ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: actual == null ? Colors.grey.shade400 : Colors.black87,
              ),
            ),
          ),
          Icon(Icons.arrow_drop_down, size: 14, color: Colors.grey.shade500),
        ],
      ),
    );
  }
}
