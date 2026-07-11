import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/codigo_producto_sunat.dart';

/// Selector del código de producto SUNAT (catálogos 25.1/25.2/25.3).
///
/// Lista CURADA — nunca texto libre: desde el 01.08.2026 un código inválido
/// en el comprobante es RECHAZO de SUNAT (ERR-3496).
///
/// Devuelve:
/// - `null`  → canceló (no tocar el valor actual)
/// - `''`    → eligió "Quitar código"
/// - `'nnnnnnnn'` → código elegido
Future<String?> showCodigoProductoSunatSelector(
  BuildContext context, {
  String? codigoActual,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CodigoSunatSelectorSheet(codigoActual: codigoActual),
  );
}

class _CodigoSunatSelectorSheet extends StatefulWidget {
  final String? codigoActual;

  const _CodigoSunatSelectorSheet({this.codigoActual});

  @override
  State<_CodigoSunatSelectorSheet> createState() =>
      _CodigoSunatSelectorSheetState();
}

class _CodigoSunatSelectorSheetState extends State<_CodigoSunatSelectorSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _mostrarLeyenda = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CodigoProductoSunat> get _filtrados {
    if (_query.isEmpty) return kCatalogoCodigosProductoSunat;
    final q = _query.toLowerCase();
    return kCatalogoCodigosProductoSunat
        .where((c) =>
            c.codigo.contains(q) ||
            c.descripcion.toLowerCase().contains(q) ||
            c.grupo.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _filtrados;

    // Agrupar preservando el orden oficial de grupos.
    final porGrupo = <String, List<CodigoProductoSunat>>{};
    for (final c in filtrados) {
      porGrupo.putIfAbsent(c.grupo, () => []).add(c);
    }
    final grupos =
        GruposCodigoSunat.orden.where(porGrupo.containsKey).toList();

    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.qr_code_2, size: 20, color: AppColors.blue1),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Código producto SUNAT',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(
                            () => _mostrarLeyenda = !_mostrarLeyenda),
                        icon: Icon(
                          Icons.help_outline,
                          size: 18,
                          color: _mostrarLeyenda
                              ? AppColors.blue1
                              : Colors.grey.shade500,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: '¿Cuándo usar cada código?',
                      ),
                      const SizedBox(width: 8),
                      if (widget.codigoActual != null &&
                          widget.codigoActual!.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).pop(''),
                          icon: const Icon(Icons.close, size: 14),
                          label: const Text(
                            'Quitar',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade400,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Solo para bienes de los anexos 25.1/25.2/25.3 (detracción, '
                    'percepción, combustibles, minería). Si tu producto no está '
                    'en la lista, déjalo sin código.',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                  if (_mostrarLeyenda) ...[
                    const SizedBox(height: 8),
                    _buildLeyenda(),
                  ],
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v.trim()),
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Buscar por código o descripción…',
                      hintStyle:
                          TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: filtrados.isEmpty
                  ? Center(
                      child: Text(
                        'Sin resultados para "$_query"',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: grupos.fold<int>(
                          0, (s, g) => s + 1 + porGrupo[g]!.length),
                      itemBuilder: (context, index) {
                        var i = index;
                        for (final g in grupos) {
                          if (i == 0) return _buildGrupoHeader(g);
                          i--;
                          final items = porGrupo[g]!;
                          if (i < items.length) return _buildItem(items[i]);
                          i -= items.length;
                        }
                        return const SizedBox.shrink();
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeyenda() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿CUÁNDO USAR CADA CÓDIGO?',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.amber.shade900,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          _leyendaFila(
            '✔',
            'Bienes de los anexos (pollo beneficiado, bebidas, combustibles, '
                'oro…): usa su código ESPECÍFICO de la lista.',
          ),
          _leyendaFila(
            '◦',
            'Empresa en el padrón 12 de SUNAT ("obligado a enviar código") '
                'con productos que NO están en los anexos: usa el genérico '
                '00000000.',
          ),
          _leyendaFila(
            '✕',
            'Empresa que NO está en el padrón 12: deja el producto SIN '
                'código — SUNAT no lo exige y el comprobante sale igual.',
          ),
          const SizedBox(height: 4),
          Text(
            'Desde el 01/08/2026 un código inválido es RECHAZO de SUNAT; por '
            'eso solo se elige de esta lista. Los bienes fiscalizados deben '
            'llevar su código real, no el genérico.',
            style: TextStyle(
              fontSize: 9,
              fontStyle: FontStyle.italic,
              color: Colors.amber.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _leyendaFila(String simbolo, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            simbolo,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.amber.shade900,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrupoHeader(String grupo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        grupo.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildItem(CodigoProductoSunat c) {
    final seleccionado = c.codigo == widget.codigoActual;
    return InkWell(
      onTap: () => Navigator.of(context).pop(c.codigo),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: seleccionado ? Colors.blue.shade50 : null,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: seleccionado
                    ? AppColors.blue1.withValues(alpha: 0.12)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                c.codigo,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  color: seleccionado ? AppColors.blue1 : Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                c.descripcion,
                style: const TextStyle(fontSize: 11.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (seleccionado)
              Icon(Icons.check_circle, size: 16, color: AppColors.blue1),
          ],
        ),
      ),
    );
  }
}
