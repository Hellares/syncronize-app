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

  /// El nombre y el teléfono con los que la empresa se presenta.
  final String empresaNombre;
  final String? empresaTelefono;
  final String? empresaLogo;

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
    this.fotoUrl,
    this.atributosValores = const [],
    this.plantillasIds = const [],
    this.precioAnterior,
    this.simboloMoneda = 'S/',
    this.empresaTelefono,
    this.empresaLogo,
    this.incluirPrecio = true,
    this.incluirCaracteristicas = true,
    this.incluirCodigo = true,
  });

  String get _foto => fotoUrl ?? '';

  String _money(double v) => '$simboloMoneda ${v.toStringAsFixed(2)}';

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
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                    height: 1.2,
                  ),
                ),
                if (incluirCodigo && (codigo ?? '').isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Código $codigo',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
                if (incluirPrecio) ...[
                  const SizedBox(height: 10),
                  _precio(),
                ],
                if (secciones.isNotEmpty || sueltos.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'CARACTERÍSTICAS',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .6,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final (titulo, vals) in secciones) ...[
                    TituloSeccionAtributos(titulo),
                    const SizedBox(height: 4),
                    TablaAtributos(vals),
                    const SizedBox(height: 8),
                  ],
                  ...seccionesDeAtributosSueltos(sueltos),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: AppColors.blue1,
      child: Row(
        children: [
          if ((empresaLogo ?? '').isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                empresaLogo!,
                width: 26,
                height: 26,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                // Un logo que no carga NO puede romper la ficha entera.
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          if ((empresaLogo ?? '').isNotEmpty) const SizedBox(width: 8),
          Expanded(
            child: Text(
              empresaNombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
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

  Widget _precio() {
    final hayRebaja = precioAnterior != null && precioAnterior! > precio;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _money(precio),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: hayRebaja ? const Color(0xFFDC2626) : AppColors.blue1,
            height: 1,
          ),
        ),
        if (hayRebaja) ...[
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              _money(precioAnterior!),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _pie() {
    final tel = (empresaTelefono ?? '').trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (tel.isNotEmpty) ...[
            Icon(Icons.phone_outlined, size: 12, color: Colors.grey.shade600),
            const SizedBox(width: 5),
            Text(tel, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
            const Spacer(),
          ],
          Text(
            'Consultá disponibilidad',
            style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
