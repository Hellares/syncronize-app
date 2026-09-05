/// La ficha de un producto pensada para MANDARLA por WhatsApp.
///
/// No es una pantalla: es el lienzo que se captura como imagen. Por eso está
/// pensada para un ancho fijo (`anchoLienzo`) y no para adaptarse — lo que se
/// ve acá es exactamente el PNG que le va a llegar al cliente.
///
/// 🔴 Todo lo que se dibuje tiene que estar RESUELTO antes de capturar: una
/// imagen que todavía no cargó sale en blanco en la captura. Por eso la foto
/// del producto se precarga con `precacheImage` en la pantalla que la muestra
/// y acá se dibuja con `gaplessPlayback`.
///
/// 🔴 El nombre de arriba es el NOMBRE COMERCIAL y el color es el que la
/// empresa configuró para sus documentos: los dos llegan resueltos desde
/// `resolverIdentidadComercial`, no de `Empresa.nombre` (que es la razón
/// social) ni del azul del sistema.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/atributo_plantilla.dart';
import 'ficha_atributos.dart';

/// Ancho del lienzo en píxeles lógicos. Con `pixelRatio: 3` la captura sale de
/// ~1080 px de ancho, que es lo que WhatsApp muestra sin recomprimir feo.
const double anchoFichaCompartible = 360;

class FichaCompartible extends StatelessWidget {
  /// 🔴 Recibe DATOS y no un `Producto`: la misma ficha sirve para el producto
  /// y para una variante, que no comparten tipo.
  final String titulo;
  final String? codigo;

  /// La descripción del producto. Vacía o null = no se dibuja nada.
  final String? descripcion;
  final String? fotoUrl;

  /// Los `AtributoValor` (de producto o de variante) y el orden de secciones
  /// que el producto guardó, si lo tiene.
  final List<dynamic> atributosValores;
  final List<String> plantillasIds;
  final List<AtributoPlantilla> plantillas;

  /// Precio ya resuelto por la pantalla (el efectivo de la sede) y, si hay
  /// rebaja, el de lista para tacharlo.
  final double precio;
  final double? precioAnterior;
  final String simboloMoneda;

  /// El nombre COMERCIAL y el teléfono con los que la empresa se presenta.
  final String empresaNombre;
  final String? empresaTelefono;
  final String? empresaLogo;

  /// El color de la marca. Sale de la configuración de documentos, así que una
  /// empresa con la marca en rojo no manda fichas azules.
  final Color color;

  /// El cierre configurado ("Gracias por su preferencia").
  final String? textoPie;

  final bool incluirPrecio;
  final bool incluirCaracteristicas;
  final bool incluirCodigo;

  const FichaCompartible({
    super.key,
    required this.titulo,
    required this.plantillas,
    required this.precio,
    required this.empresaNombre,
    this.codigo,
    this.descripcion,
    this.fotoUrl,
    this.atributosValores = const [],
    this.plantillasIds = const [],
    this.precioAnterior,
    this.simboloMoneda = 'S/',
    this.empresaTelefono,
    this.empresaLogo,
    this.color = AppColors.blue1,
    this.textoPie,
    this.incluirPrecio = true,
    this.incluirCaracteristicas = true,
    this.incluirCodigo = true,
  });

  String get _foto => fotoUrl ?? '';

  String _money(double v) => '$simboloMoneda ${v.toStringAsFixed(2)}';

  bool get _hayRebaja => precioAnterior != null && precioAnterior! > precio;

  @override
  Widget build(BuildContext context) {
    final (secciones, sueltos) = incluirCaracteristicas && atributosValores.isNotEmpty
        ? agruparAtributosPorSeccion(
            atributosValores: atributosValores,
            plantillasIds: plantillasIds,
            plantillas: plantillas,
          )
        : (const <(String, List<dynamic>)>[], const <dynamic>[]);

    return Container(
      width: anchoFichaCompartible,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecera(),
          _imagen(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    height: 1.2,
                  ),
                ),
                if (incluirCodigo && (codigo ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  // El código en una pastilla y no suelto: al lado del nombre
                  // en gris parecía parte del nombre.
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Cód. $codigo',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ),
                ],
                if (incluirPrecio) ...[
                  const SizedBox(height: 12),
                  _precio(),
                ],
                // Después del precio y antes de las características, que es
                // el orden en el que se lee una ficha: qué es, cuánto sale,
                // de qué se trata, y recién ahí el detalle.
                if ((descripcion ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    descripcion!.trim(),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
                if (secciones.isNotEmpty || sueltos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _rotuloCaracteristicas(),
                  const SizedBox(height: 8),
                  for (final (titulo, vals) in secciones) ...[
                    TituloSeccionAtributos(titulo, color: color),
                    const SizedBox(height: 4),
                    TablaAtributos(vals),
                    const SizedBox(height: 8),
                  ],
                  ...seccionesDeAtributosSueltos(sueltos, color: color),
                ],
              ],
            ),
          ),
          _pie(),
        ],
      ),
    );
  }

  Widget _cabecera() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      color: color,
      child: Row(
        children: [
          if ((empresaLogo ?? '').isNotEmpty) ...[
            // El logo sobre fondo blanco: la mayoría vienen recortados sobre
            // blanco y sobre la franja de color se veían sucios.
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  empresaLogo!,
                  width: 26,
                  height: 26,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  // Un logo que no carga NO puede romper la ficha entera.
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(width: 9),
          ],
          Expanded(
            child: Text(
              empresaNombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: .2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagen() {
    if (_foto.isEmpty) {
      // Sin foto va un bloque neutro y NO un hueco: una ficha con un agujero
      // blanco parece rota.
      return Container(
        width: double.infinity,
        height: 200,
        color: const Color(0xFFF3F4F6),
        child: Icon(Icons.inventory_2_outlined, size: 44, color: Colors.grey.shade400),
      );
    }
    // 🔴 `contain` y centrada, igual que en el PDF del catálogo: recortar una
    // foto de producto le come el borde, que es justo lo que el cliente quiere
    // ver. Donde la proporción no llena queda el fondo neutro.
    return Container(
      width: double.infinity,
      height: 260,
      color: const Color(0xFFF3F4F6),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(6),
      child: Image.network(
        _foto,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.inventory_2_outlined, size: 44, color: Colors.grey.shade400),
      ),
    );
  }

  Widget _rotuloCaracteristicas() {
    return Row(
      children: [
        Container(width: 16, height: 2, color: color),
        const SizedBox(width: 6),
        Text(
          'CARACTERÍSTICAS',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: .6,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _precio() {
    // El descuento en porcentaje: "antes S/ 120" dice poco, "-25%" se entiende
    // de un vistazo y es lo que hace que la ficha se reenvíe.
    final descuento = _hayRebaja
        ? (((precioAnterior! - precio) / precioAnterior!) * 100).round()
        : 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 🔴 `FittedBox` y no un `Text` a secas: un precio de cinco cifras con
        // el anterior tachado al lado desborda la fila, y en una ficha que se
        // CAPTURA el desborde viaja adentro del PNG. Así se achica y entra.
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _money(precio),
              maxLines: 1,
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: _hayRebaja ? const Color(0xFFDC2626) : color,
                height: 1,
              ),
            ),
          ),
        ),
        if (_hayRebaja) ...[
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _money(precioAnterior!),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                if (descuento > 0) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '-$descuento%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _pie() {
    final tel = (empresaTelefono ?? '').trim();
    final cierre = (textoPie ?? '').trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (tel.isNotEmpty) ...[
            Icon(Icons.phone_outlined, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              tel,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(width: 10),
          ],
          // 🔴 Flexible y no un `Text` suelto: el pie lo escribe la empresa y
          // uno largo desbordaba la fila. En una pantalla se ve la franja
          // amarilla; acá se CAPTURA y el cliente recibe la ficha rota.
          Expanded(
            child: Text(
              cierre.isEmpty ? 'Consulte disponibilidad' : cierre,
              textAlign: tel.isEmpty ? TextAlign.left : TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }
}
