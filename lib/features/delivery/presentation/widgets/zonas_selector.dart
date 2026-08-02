import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/datasources/repartidor_remote_datasource.dart';

typedef _Opcion = ({String codigo, String nombre});

/// Selector de zonas de reparto en cascada (departamento → provincia →
/// distritos), para que el repartidor ELIJA en vez de tipear.
///
/// Escribir a mano era la causa de que los pedidos no le aparecieran a
/// nadie: alcanzaba con que el repartidor pusiera "TRUJILLO" y el pedido
/// cayera en "SALAVERRY" para que no hubiera match.
///
/// Devuelve NOMBRES de distrito, no códigos, porque es contra el texto de la
/// dirección que el backend hace el match. Elegir una provincia entera suma
/// todos sus distritos: así una zona amplia cubre las direcciones que solo
/// mencionan el distrito.
class ZonasSelector extends StatefulWidget {
  final List<String> zonas;
  final ValueChanged<List<String>> onChanged;

  const ZonasSelector({
    super.key,
    required this.zonas,
    required this.onChanged,
  });

  @override
  State<ZonasSelector> createState() => _ZonasSelectorState();
}

class _ZonasSelectorState extends State<ZonasSelector> {
  final _ds = locator<RepartidorRemoteDataSource>();

  List<_Opcion> _departamentos = const [];
  List<_Opcion> _provincias = const [];
  List<_Opcion> _distritos = const [];

  String? _departamento;
  String? _provincia;

  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDepartamentos();
  }

  Future<void> _cargarDepartamentos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final d = await _ds.ubigeoDepartamentos();
      if (!mounted) return;
      setState(() {
        _departamentos = d;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar la lista de zonas';
        _cargando = false;
      });
    }
  }

  Future<void> _elegirDepartamento(String? codigo) async {
    setState(() {
      _departamento = codigo;
      _provincia = null;
      _provincias = const [];
      _distritos = const [];
    });
    if (codigo == null) return;
    final p = await _ds.ubigeoProvincias(codigo);
    if (!mounted) return;
    setState(() => _provincias = p);
  }

  Future<void> _elegirProvincia(String? codigo) async {
    setState(() {
      _provincia = codigo;
      _distritos = const [];
    });
    if (codigo == null) return;
    final d = await _ds.ubigeoDistritos(codigo);
    if (!mounted) return;
    setState(() => _distritos = d);
  }

  void _agregar(Iterable<String> nombres) {
    // Set para no duplicar cuando se suma un distrito ya cubierto por la
    // provincia que se agregó antes.
    final actuales = {...widget.zonas};
    actuales.addAll(nombres.map((n) => n.toUpperCase()));
    final lista = actuales.toList()..sort();
    widget.onChanged(lista);
  }

  void _quitar(String zona) {
    widget.onChanged(widget.zonas.where((z) => z != zona).toList());
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_error != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(fontSize: 11.5, color: Colors.orange.shade900),
            ),
          ),
          TextButton(onPressed: _cargarDepartamentos, child: const Text('Reintentar')),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zonas donde repartes',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.blue1,
          ),
        ),
        const SizedBox(height: 6),
        _combo(
          etiqueta: 'Departamento',
          valor: _departamento,
          opciones: _departamentos,
          onChanged: _elegirDepartamento,
        ),
        const SizedBox(height: 8),
        _combo(
          etiqueta: 'Provincia',
          valor: _provincia,
          opciones: _provincias,
          onChanged: _provincias.isEmpty ? null : _elegirProvincia,
        ),
        if (_distritos.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Toca los distritos donde repartes',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ),
              TextButton(
                onPressed: () => _agregar(_distritos.map((d) => d.nombre)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 11.5),
                ),
                child: const Text('Toda la provincia'),
              ),
            ],
          ),
          Wrap(
            spacing: 6,
            runSpacing: 2,
            children: _distritos.map((d) {
              final ya = widget.zonas.contains(d.nombre.toUpperCase());
              return FilterChip(
                label: Text(d.nombre, style: const TextStyle(fontSize: 11)),
                selected: ya,
                visualDensity: VisualDensity.compact,
                onSelected: (_) =>
                    ya ? _quitar(d.nombre.toUpperCase()) : _agregar([d.nombre]),
              );
            }).toList(),
          ),
        ],
        if (widget.zonas.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Tus zonas (${widget.zonas.length})',
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 2,
            children: widget.zonas
                .map((z) => Chip(
                      label: Text(z, style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                      onDeleted: () => _quitar(z),
                      deleteIconColor: Colors.grey.shade600,
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _combo({
    required String etiqueta,
    required String? valor,
    required List<_Opcion> opciones,
    required ValueChanged<String?>? onChanged,
  }) {
    // Alto fijo en la FILA: los DropdownButton de M3 no encogen por debajo
    // del tap target de 48px aunque se les recorte el contenido.
    return SizedBox(
      height: 48,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: etiqueta,
          labelStyle: const TextStyle(fontSize: 12),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: valor,
            isExpanded: true,
            isDense: true,
            hint: Text(
              onChanged == null ? 'Elige el departamento primero' : 'Selecciona',
              style: const TextStyle(fontSize: 12),
            ),
            style: const TextStyle(fontSize: 12.5, color: Colors.black87),
            onChanged: onChanged,
            items: opciones
                .map((o) => DropdownMenuItem(
                      value: o.codigo,
                      child: Text(o.nombre, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
