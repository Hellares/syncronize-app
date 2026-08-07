import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/network/dio_client.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/utils/unidad_presentacion.dart';
import '../../../empresa/domain/entities/sede.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../producto/presentation/widgets/abrir_bulto_dialog.dart';

/// Una fila de `GET /apertura-bulto/disponibles`: un bulto cerrado y la
/// variante suelta en la que se convierte, con el stock de los dos lados.
class _BultoAbrible {
  final String productoNombre;
  final String bultoVarianteId;
  final String bultoNombre;
  final int bultoStock;
  final String destinoVarianteId;
  final String destinoNombre;
  final int destinoStock;
  final int? destinoStockMinimo;
  final double? destinoFactor;
  final String? destinoSimbolo;
  final double rendimiento;
  final bool destinoBajoMinimo;

  _BultoAbrible({
    required this.productoNombre,
    required this.bultoVarianteId,
    required this.bultoNombre,
    required this.bultoStock,
    required this.destinoVarianteId,
    required this.destinoNombre,
    required this.destinoStock,
    required this.destinoStockMinimo,
    required this.destinoFactor,
    required this.destinoSimbolo,
    required this.rendimiento,
    required this.destinoBajoMinimo,
  });

  factory _BultoAbrible.fromJson(Map<String, dynamic> j) {
    final bulto = j['bulto'] as Map<String, dynamic>;
    final destino = j['destino'] as Map<String, dynamic>;
    return _BultoAbrible(
      productoNombre:
          (j['producto'] as Map<String, dynamic>?)?['nombre']?.toString() ?? '',
      bultoVarianteId: bulto['varianteId'].toString(),
      bultoNombre: bulto['nombre'].toString(),
      bultoStock: (bulto['stock'] as num?)?.toInt() ?? 0,
      destinoVarianteId: destino['varianteId'].toString(),
      destinoNombre: destino['nombre'].toString(),
      destinoStock: (destino['stock'] as num?)?.toInt() ?? 0,
      destinoStockMinimo: (destino['stockMinimo'] as num?)?.toInt(),
      destinoFactor: (destino['factorPresentacion'] as num?)?.toDouble(),
      destinoSimbolo: destino['simbolo']?.toString(),
      rendimiento: (j['rendimiento'] as num?)?.toDouble() ?? 0,
      destinoBajoMinimo: j['destinoBajoMinimo'] == true,
    );
  }

  /// El stock suelto en la unidad en la que se le habla al usuario: 15000 g
  /// no le dice nada a nadie, 15 kg sí.
  String get sueltoTexto {
    if (destinoFactor != null && destinoFactor! > 1) {
      return UnidadPresentacion(factor: destinoFactor!, simbolo: destinoSimbolo)
          .cantidadTexto(destinoStock);
    }
    return '$destinoStock ${destinoSimbolo ?? ''}'.trim();
  }
}

/// Pantalla "Abrir bultos".
///
/// Vía planificada de la apertura: ver qué hay cerrado y abrir por adelantado.
/// La vía reactiva —la alerta de stock bajo con acción directa— comparte el
/// mismo diálogo, así las dos hacen exactamente lo mismo.
class AbrirBultosPage extends StatefulWidget {
  const AbrirBultosPage({super.key});

  @override
  State<AbrirBultosPage> createState() => _AbrirBultosPageState();
}

class _AbrirBultosPageState extends State<AbrirBultosPage> {
  final DioClient _dio = locator<DioClient>();

  List<Sede> _sedes = const [];
  String? _sedeId;
  List<_BultoAbrible> _items = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // La sede sale del contexto de empresa, como en el resto de inventario.
    // A diferencia de otras pantallas acá NO hay opción "todas": abrir mueve
    // stock físico y siempre ocurre en una sede concreta.
    final state = context.read<EmpresaContextCubit>().state;
    if (state is EmpresaContextLoaded) {
      _sedes = state.context.sedes;
      _sedeId = _sedes.isNotEmpty ? _sedes.first.id : null;
    }
    _cargar();
  }

  Future<void> _cargar() async {
    if (_sedeId == null) {
      setState(() {
        _cargando = false;
        _error = 'No hay sedes disponibles en esta empresa.';
      });
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final resp = await _dio.get(
        '/apertura-bulto/disponibles',
        queryParameters: {'sedeId': _sedeId!},
      );
      final data = resp.data as List<dynamic>? ?? [];
      if (!mounted) return;
      setState(() {
        _items = data
            .map((e) => _BultoAbrible.fromJson(e as Map<String, dynamic>))
            .toList();
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e is DioException
            ? (e.response?.data is Map
                ? (e.response!.data['message']?.toString() ??
                    'No se pudieron cargar los bultos')
                : e.message ?? 'No se pudieron cargar los bultos')
            : e.toString();
      });
    }
  }

  Future<void> _abrir(_BultoAbrible item, {bool cerrar = false}) async {
    final r = await AbrirBultoDialog.show(
      context: context,
      bultoVarianteId: item.bultoVarianteId,
      bultoNombre: item.bultoNombre,
      destinoNombre: item.destinoNombre,
      destinoFactor: item.destinoFactor,
      destinoSimbolo: item.destinoSimbolo,
      rendimiento: item.rendimiento,
      sedeId: _sedeId!,
      stockBultos: item.bultoStock,
      stockDestino: item.destinoStock,
      cerrar: cerrar,
    );
    if (r != null) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abrir bultos'),
        bottom: _sedes.length > 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(46),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: DropdownButtonFormField<String>(
                    initialValue: _sedeId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    items: _sedes
                        .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.nombre,
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v == null || v == _sedeId) return;
                      setState(() => _sedeId = v);
                      _cargar();
                    },
                  ),
                ),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: _buildCuerpo(),
      ),
    );
  }

  Widget _buildCuerpo() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildMensaje(Icons.error_outline, _error!, accion: _cargar);
    }
    if (_items.isEmpty) {
      return _buildMensaje(
        Icons.inventory_2_outlined,
        'No hay bultos configurados para abrirse.\n\n'
        'Se configuran en el formulario de variantes del producto, en la '
        'sección "Al abrir este bulto".',
      );
    }
    // Los que están bajo mínimo van arriba: son los que hay que abrir ya.
    final ordenados = [..._items]..sort((a, b) {
        if (a.destinoBajoMinimo != b.destinoBajoMinimo) {
          return a.destinoBajoMinimo ? -1 : 1;
        }
        return a.productoNombre.compareTo(b.productoNombre);
      });
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: ordenados.length,
      itemBuilder: (_, i) => _buildTile(ordenados[i]),
    );
  }

  Widget _buildTile(_BultoAbrible item) {
    final sinBultos = item.bultoStock <= 0;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: AppSubtitle(item.productoNombre)),
                if (item.destinoBajoMinimo)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      sinBultos ? 'BAJO MÍNIMO' : 'ABRIR YA',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _linea(item.bultoNombre, '${item.bultoStock} cerrado(s)'),
            _linea(item.destinoNombre, item.sueltoTexto),
            if (item.destinoBajoMinimo && sinBultos) ...[
              const SizedBox(height: 6),
              Text(
                'Está bajo mínimo y NO quedan bultos cerrados: acá sí hay que '
                'comprarle al proveedor.',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange.shade900,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: item.destinoStock >= item.rendimiento
                      ? () => _abrir(item, cerrar: true)
                      : null,
                  child: const Text('Rearmar'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: sinBultos ? null : () => _abrir(item),
                  icon: const Icon(Icons.open_in_full, size: 16),
                  label: const Text('Abrir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _linea(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              etiqueta,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.blue1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMensaje(IconData icono, String mensaje, {VoidCallback? accion}) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 60),
        Icon(icono, size: 48, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(
          mensaje,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        if (accion != null) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton(onPressed: accion, child: const Text('Reintentar')),
          ),
        ],
      ],
    );
  }
}
