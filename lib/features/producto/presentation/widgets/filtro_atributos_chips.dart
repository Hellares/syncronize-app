import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/producto_atributo.dart';

/// Fila de chips para filtrar productos por valor de atributo.
///
/// La comparten el listado de productos, Venta Rápida y el marketplace: las
/// tres mandan lo mismo al backend (`atributos=clave:valor`), así que no tiene
/// sentido que cada una arme su propia UI.
///
/// 🔑 **Las cadenas dependientes se filtran, pero NO se bloquean.** Al cargar
/// un producto, PROCESADOR está bloqueado hasta elegir FABRICANTE, porque hay
/// que guardar un dato coherente. Acá es al revés: si no elegiste marca,
/// PROCESADOR ofrece TODOS los procesadores — buscar "Snapdragon 8 Gen" sin
/// saber de qué marca es, es justamente el caso de uso. Si sí elegiste marca,
/// se recorta a esa rama para no ofrecer combinaciones que no existen.
class FiltroAtributosChips extends StatelessWidget {
  /// Atributos filtrables, tal como los devuelve `/producto-atributos/filtros`.
  final List<ProductoAtributo> atributos;

  /// Lo elegido hoy: clave del atributo → valores.
  final Map<String, List<String>> seleccion;

  /// Se llama con el mapa ya actualizado.
  final ValueChanged<Map<String, List<String>>> onChanged;

  const FiltroAtributosChips({
    super.key,
    required this.atributos,
    required this.seleccion,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (atributos.isEmpty) return const SizedBox.shrink();

    final hayAlgo = seleccion.values.any((v) => v.isNotEmpty);

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          if (hayAlgo) ...[
            _ChipLimpiar(onTap: () => onChanged(const {})),
            const SizedBox(width: 6),
          ],
          for (final atributo in atributos) ...[
            _ChipAtributo(
              atributo: atributo,
              elegidos: seleccion[atributo.clave] ?? const [],
              onTap: () => _abrirSelector(context, atributo),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  /// Las opciones que tiene sentido ofrecer para [atributo].
  ///
  /// Si depende de otro y ese otro TIENE valores elegidos, se recorta a esas
  /// ramas. Si el padre está sin elegir, se ofrecen todas.
  List<String> _opcionesVisibles(ProductoAtributo atributo) {
    if (atributo.dependeDeAtributoId == null || atributo.opciones.isEmpty) {
      return atributo.valores;
    }

    ProductoAtributo? padre;
    for (final a in atributos) {
      if (a.id == atributo.dependeDeAtributoId) padre = a;
    }
    final elegidosDelPadre = padre == null
        ? const <String>[]
        : (seleccion[padre.clave] ?? const <String>[]);
    if (elegidosDelPadre.isEmpty) return atributo.valores;

    return atributo.opciones
        .where((o) => o.padreValor != null && elegidosDelPadre.contains(o.padreValor))
        .map((o) => o.valor)
        .toList(growable: false);
  }

  Future<void> _abrirSelector(
    BuildContext context,
    ProductoAtributo atributo,
  ) async {
    final opciones = _opcionesVisibles(atributo);
    var actual = seleccion;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final elegidos = actual[atributo.clave] ?? const <String>[];
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        atributo.nombre,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue1,
                        ),
                      ),
                    ),
                    if (elegidos.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          final copia = {
                            for (final e in actual.entries)
                              e.key: List<String>.from(e.value),
                          }..remove(atributo.clave);
                          actual = copia;
                          setSheetState(() {});
                          onChanged(copia);
                        },
                        child: const Text('Quitar',
                            style: TextStyle(fontSize: 11)),
                      ),
                  ],
                ),
                if (opciones.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No hay opciones para este filtro.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  )
                else
                  Flexible(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: opciones.map((valor) {
                          final activo = elegidos.contains(valor);
                          return FilterChip(
                            label: Text(valor,
                                style: const TextStyle(fontSize: 11)),
                            selected: activo,
                            showCheckmark: false,
                            selectedColor: AppColors.blue1.withValues(alpha: 0.15),
                            onSelected: (_) {
                              final copia = {
                                for (final e in actual.entries)
                                  e.key: List<String>.from(e.value),
                              };
                              final lista =
                                  copia.putIfAbsent(atributo.clave, () => []);
                              if (lista.contains(valor)) {
                                lista.remove(valor);
                              } else {
                                lista.add(valor);
                              }
                              if (lista.isEmpty) copia.remove(atributo.clave);
                              actual = copia;
                              setSheetState(() {});
                              onChanged(copia);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChipAtributo extends StatelessWidget {
  final ProductoAtributo atributo;
  final List<String> elegidos;
  final VoidCallback onTap;

  const _ChipAtributo({
    required this.atributo,
    required this.elegidos,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activo = elegidos.isNotEmpty;
    // Con un solo valor se muestra el valor, que dice más que el nombre del
    // atributo: "Snapdragon 8 Gen" en vez de "PROCESADOR · 1".
    final texto = switch (elegidos.length) {
      0 => atributo.nombre,
      1 => elegidos.first,
      _ => '${atributo.nombre} · ${elegidos.length}',
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: activo ? AppColors.blue1 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: activo ? AppColors.blue1 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              texto,
              style: TextStyle(
                fontSize: 11,
                fontWeight: activo ? FontWeight.w600 : FontWeight.w500,
                color: activo ? Colors.white : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.expand_more,
              size: 14,
              color: activo ? Colors.white : Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipLimpiar extends StatelessWidget {
  final VoidCallback onTap;

  const _ChipLimpiar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close, size: 13, color: Colors.red.shade600),
            const SizedBox(width: 3),
            Text(
              'Limpiar',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
