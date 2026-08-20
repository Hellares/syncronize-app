import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/custom_search_field.dart';
import '../../../../core/widgets/custom_sede_selector.dart';
import '../../../../core/utils/busqueda_texto.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/grupo_mayoreo.dart';
import '../../domain/repositories/precio_nivel_repository.dart';

/// MONITOR DE MAYOREO COMBINADO — qué variantes suman entre sí para llegar al
/// mínimo de un nivel.
///
/// Desde que el mayoreo se acumula por grupo, tres edredones de tres diseños
/// distintos que comparten el mismo "Por Mayor ≥ 3" se cobran por mayor. Eso es
/// lo que se quería, pero el grupo es IMPLÍCITO: sale de que las dos variantes
/// tengan cargado el mismo nivel, no de una lista que alguien mantiene. Nadie
/// puede saber, mirando la pantalla de variantes, cuáles combinan.
///
/// Peor: cambiarle un sol al precio por mayor de una variante la saca del grupo
/// EN SILENCIO. Esta pantalla es la que lo hace visible — y por eso muestra tan
/// fuerte los dos casos que duelen: la variante que quedó sola en su grupo y la
/// que no tiene nivel y nunca va a hacer mayoreo.
///
/// 🔴 Los grupos los arma el backend con la MISMA llave con la que cobra. El
/// app no los recalcula: un monitor que agrupara por su cuenta podría mostrar
/// algo distinto de lo que el POS termina cobrando.
class GruposMayoreoPage extends StatefulWidget {
  final String productoId;
  final String productoNombre;
  final String? sedeIdInicial;

  const GruposMayoreoPage({
    super.key,
    required this.productoId,
    required this.productoNombre,
    this.sedeIdInicial,
  });

  @override
  State<GruposMayoreoPage> createState() => _GruposMayoreoPageState();
}

class _GruposMayoreoPageState extends State<GruposMayoreoPage> {
  final PrecioNivelRepository _repo = locator<PrecioNivelRepository>();
  final TextEditingController _buscador = TextEditingController();

  List<dynamic> _sedes = [];
  String? _sedeId;

  GruposMayoreoResumen? _resumen;
  bool _cargando = true;
  String? _error;
  String _filtro = '';

  /// Grupos abiertos. Arranca vacío: con 7 grupos y 91 variantes, abrir todo
  /// de entrada es una pared de texto.
  final Set<String> _abiertos = {};

  @override
  void initState() {
    super.initState();
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _sedes = List<dynamic>.from(
        empresaState.context.sedes.where((s) => s.isActive),
      );
      if (widget.sedeIdInicial != null &&
          _sedes.any((s) => s.id == widget.sedeIdInicial)) {
        _sedeId = widget.sedeIdInicial;
      } else if (_sedes.isNotEmpty) {
        _sedeId = _sedes
            .firstWhere((s) => s.esPrincipal, orElse: () => _sedes.first)
            .id;
      }
    }
    _cargar();
  }

  @override
  void dispose() {
    _buscador.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final result = await _repo.getGruposMayoreo(
      productoId: widget.productoId,
      sedeId: _sedeId,
    );
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (result is Success<GruposMayoreoResumen>) {
        _resumen = result.data;
      } else if (result is Error<GruposMayoreoResumen>) {
        _error = result.message;
      }
    });
  }

  bool _coincide(VarianteMayoreo v) {
    final terminos = terminosBusqueda(_filtro);
    if (terminos.isEmpty) return true;
    // Nombre + SKU juntos: "frozen 3 pzs" y "VAR-000044" filtran igual de bien.
    return coincideTodosLosTerminos('${v.nombre} ${v.sku}', terminos);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        title: Column(
          children: [
            const Text(
              'Grupos de Mayoreo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
            Text(
              widget.productoNombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: _cargar,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildMensaje(
        icono: Icons.cloud_off,
        titulo: 'No se pudieron cargar los grupos',
        detalle: _error!,
        accion: TextButton(onPressed: _cargar, child: const Text('Reintentar')),
      );
    }
    final r = _resumen;
    if (r == null) return const SizedBox.shrink();

    if (r.vacio && r.sinNivel.isEmpty) {
      return _buildMensaje(
        icono: Icons.sell_outlined,
        titulo: 'Este producto no tiene variantes',
        detalle: 'El mayoreo combinado se calcula entre variantes.',
      );
    }

    if (r.vacio) {
      return _buildMensaje(
        icono: Icons.price_change_outlined,
        titulo: 'Ninguna variante tiene precio por mayor',
        detalle:
            'Las ${r.totalVariantes} variantes se venden siempre a precio de '
            'lista. Cargá un nivel "Por Mayor" en al menos dos para que '
            'empiecen a combinar entre sí.',
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          if (_sedes.isNotEmpty) ...[
            _buildSelectorSede(),
            const SizedBox(height: 10),
          ],
          _buildResumen(r),
          const SizedBox(height: 10),
          CustomSearchField(
            controller: _buscador,
            hintText: 'Buscar variante en los grupos...',
            onChanged: (v) => setState(() => _filtro = v),
            onClear: () => setState(() => _filtro = ''),
          ),
          const SizedBox(height: 12),
          ...r.grupos.map(_buildGrupo),
          if (r.sinNivel.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSinNivel(r.sinNivel),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectorSede() {
    return Row(
      children: [
        Icon(Icons.store, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        const Text(
          'Sede:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        CustomSedeSelector(
          sedes: _sedes,
          currentSede: _sedes.firstWhere(
            (s) => s.id == _sedeId,
            orElse: () => _sedes.first,
          ),
          onSelected: (id) {
            // Los grupos no cambian por sede, pero el precio de lista y el
            // stock sí — y son los que dicen cuánto se ahorra realmente.
            setState(() => _sedeId = id);
            _cargar();
          },
        ),
      ],
    );
  }

  /// La foto de arriba: cuántos grupos hay, cuántas variantes combinan y —lo
  /// importante— cuántas quedaron afuera.
  Widget _buildResumen(GruposMayoreoResumen r) {
    final afuera = r.totalVariantes - r.variantesEnGrupo;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspaces_outline,
                  size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 6),
              Text(
                '${r.grupos.length} '
                '${r.grupos.length == 1 ? 'grupo' : 'grupos'} de mayoreo',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Las variantes de un mismo grupo SUMAN entre sí para llegar al '
            'mínimo. Llevar una de cada una ya es mayoreo.',
            style: TextStyle(fontSize: 10, color: Colors.blue.shade900),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _pill(
                '${r.variantesEnGrupo} de ${r.totalVariantes} combinan',
                Colors.green,
              ),
              if (afuera > 0)
                _pill(
                  '$afuera sin precio por mayor',
                  Colors.orange,
                ),
              if (r.gruposSolitarios > 0)
                _pill(
                  '${r.gruposSolitarios} ${r.gruposSolitarios == 1 ? 'grupo' : 'grupos'} de una sola',
                  Colors.orange,
                ),
              if (r.gruposConAviso > 0)
                _pill('${r.gruposConAviso} con avisos', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String texto, MaterialColor color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.shade300, width: 0.6),
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color.shade800,
          ),
        ),
      );

  Widget _buildGrupo(GrupoMayoreo g) {
    final visibles = g.variantes.where(_coincide).toList();
    // Con el buscador activo, un grupo sin coincidencias se esconde entero.
    if (_filtro.trim().isNotEmpty && visibles.isEmpty) {
      return const SizedBox.shrink();
    }
    // Buscando, se abre solo: el usuario ya dijo qué quiere ver.
    final abierto =
        _abiertos.contains(g.clave) || _filtro.trim().isNotEmpty;

    final precioTexto = g.esPorcentaje
        ? '−${(g.porcentajeDesc ?? 0).toStringAsFixed(0)}%'
        : 'S/ ${(g.precio ?? 0).toStringAsFixed(2)}';
    final rango = g.cantidadMaxima != null
        ? '${g.cantidadMinima} a ${g.cantidadMaxima} u'
        : 'desde ${g.cantidadMinima} u';

    final solitario = !g.combinaConAlguien;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: solitario ? Colors.orange.shade300 : Colors.grey.shade300,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() {
              if (!_abiertos.remove(g.clave)) _abiertos.add(g.clave);
            }),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: Colors.green.shade300, width: 0.6),
                    ),
                    child: Text(
                      precioTexto,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${g.nombreNivel} · $rango',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          solitario
                              ? 'Sola en su grupo: no combina con ninguna otra'
                              : '${g.variantes.length} variantes combinan · '
                                  '${g.stockDelGrupo} u en stock',
                          style: TextStyle(
                            fontSize: 10,
                            color: solitario
                                ? Colors.orange.shade800
                                : Colors.grey[600],
                            fontWeight:
                                solitario ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    abierto ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (g.preciosVentaDispares)
            _aviso(
              'Las variantes de este grupo NO tienen el mismo precio de lista, '
              'así que la misma rebaja les deja descuentos distintos.',
            ),
          if (g.nivelSinEfecto)
            _aviso(
              'En al menos una variante el precio por mayor no baja del precio '
              'de lista: ahí el nivel nunca se va a aplicar.',
            ),
          if (abierto) ...[
            const Divider(height: 1),
            ...visibles.map((v) => _buildVariante(v, g)),
          ],
        ],
      ),
    );
  }

  Widget _aviso(String texto) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        color: Colors.red.shade50,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 13, color: Colors.red.shade700),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                texto,
                style: TextStyle(fontSize: 10, color: Colors.red.shade900),
              ),
            ),
          ],
        ),
      );

  Widget _buildVariante(VarianteMayoreo v, GrupoMayoreo g) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.nombre,
                  style: TextStyle(
                    fontSize: 10,
                    color: v.isActive ? Colors.black87 : Colors.grey,
                    decoration:
                        v.isActive ? null : TextDecoration.lineThrough,
                  ),
                ),
                Text(
                  '${v.sku}'
                  '${v.stockActual != null ? ' · ${v.stockActual} u' : ''}'
                  '${v.isActive ? '' : ' · desactivada'}',
                  style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (v.precioVenta != null) ...[
            Text(
              'S/ ${v.precioVenta!.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            v.precioConNivel != null
                ? 'S/ ${v.precioConNivel!.toStringAsFixed(2)}'
                : '—',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// Las que nunca van a hacer mayoreo. Va al final y en naranja porque casi
  /// siempre es un olvido, no una decisión.
  Widget _buildSinNivel(List<VarianteMayoreo> sinNivel) {
    final visibles = sinNivel.where(_coincide).toList();
    if (_filtro.trim().isNotEmpty && visibles.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300, width: 0.8),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.block, size: 14, color: Colors.orange.shade800),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Nunca harán mayoreo (${sinNivel.length})',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'No tienen ningún nivel de precio cargado, así que se venden '
            'siempre a precio de lista por más que el cliente lleve muchas.',
            style: TextStyle(fontSize: 10, color: Colors.orange.shade900),
          ),
          const SizedBox(height: 8),
          ...visibles.map(
            (v) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      v.nombre,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  Text(
                    '${v.sku}'
                    '${v.precioVenta != null ? ' · S/ ${v.precioVenta!.toStringAsFixed(2)}' : ''}',
                    style: TextStyle(fontSize: 9, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMensaje({
    required IconData icono,
    required String titulo,
    required String detalle,
    Widget? accion,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              detalle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            if (accion != null) ...[const SizedBox(height: 10), accion],
          ],
        ),
      ),
    );
  }
}
