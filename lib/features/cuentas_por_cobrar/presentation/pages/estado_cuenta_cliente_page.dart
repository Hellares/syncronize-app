import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../domain/entities/estado_cuenta_cliente.dart';
import '../../domain/repositories/cuentas_cobrar_repository.dart';

/// Estado de cuenta de un cliente: resumen + ventas a crédito + abonos.
class EstadoCuentaClientePage extends StatefulWidget {
  final String? clienteId;
  final String? clienteEmpresaId;
  final String? nombreCliente;

  const EstadoCuentaClientePage({
    super.key,
    this.clienteId,
    this.clienteEmpresaId,
    this.nombreCliente,
  });

  @override
  State<EstadoCuentaClientePage> createState() => _EstadoCuentaClientePageState();
}

class _EstadoCuentaClientePageState extends State<EstadoCuentaClientePage> {
  EstadoCuentaCliente? _data;
  String? _error;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final res = await locator<CuentasCobrarRepository>().getEstadoCuentaCliente(
      clienteId: widget.clienteId,
      clienteEmpresaId: widget.clienteEmpresaId,
    );
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (res is Success<EstadoCuentaCliente>) {
        _data = res.data;
      } else if (res is Error<EstadoCuentaCliente>) {
        _error = res.message;
      }
    });
  }

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
  }

  String _fuenteLabel(String? f) {
    switch (f) {
      case 'TESORERIA':
        return 'Tesorería';
      case 'CAJA':
        return 'Caja';
      case 'BANCO':
        return 'Banco';
      default:
        return f ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const SmartAppBar(title: 'Estado de cuenta'),
        body: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorView(mensaje: _error!, onReintentar: _cargar)
                : _data == null
                    ? const SizedBox.shrink()
                    : RefreshIndicator(
                        onRefresh: _cargar,
                        child: _contenido(_data!),
                      ),
      ),
    );
  }

  Widget _contenido(EstadoCuentaCliente e) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        _HeaderCliente(cliente: e.cliente, nombreFallback: widget.nombreCliente),
        const SizedBox(height: 10),
        _ResumenCard(resumen: e.resumen),
        const SizedBox(height: 14),
        _SeccionHeader('Ventas a crédito', '${e.ventas.length}'),
        const SizedBox(height: 6),
        if (e.ventas.isEmpty)
          _Vacio('Sin ventas a crédito')
        else
          ...e.ventas.map((v) => _VentaTile(v: v, fmt: _fmt)),
        const SizedBox(height: 14),
        _SeccionHeader('Abonos', '${e.abonos.length}'),
        const SizedBox(height: 6),
        if (e.abonos.isEmpty)
          _Vacio('Sin abonos registrados')
        else
          ...e.abonos.map((a) => _AbonoTile(a: a, fmt: _fmt, fuenteLabel: _fuenteLabel)),
      ],
    );
  }
}

class _HeaderCliente extends StatelessWidget {
  final ClienteInfo cliente;
  final String? nombreFallback;
  const _HeaderCliente({required this.cliente, this.nombreFallback});

  @override
  Widget build(BuildContext context) {
    final nombre = cliente.nombre ?? nombreFallback ?? 'Cliente';
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.blue1.withValues(alpha: 0.12),
              child: Icon(
                cliente.tipo == 'EMPRESA' ? Icons.business : Icons.person,
                color: AppColors.blue1,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  if (cliente.documento != null)
                    Text(cliente.documento!,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumenCard extends StatelessWidget {
  final ResumenEstadoCuenta resumen;
  const _ResumenCard({required this.resumen});

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saldo pendiente',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 2),
            Text('S/ ${resumen.saldoPendiente.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: resumen.saldoPendiente > 0 ? Colors.red.shade700 : Colors.green.shade700)),
            if (resumen.totalMora > 0)
              Text('incl. mora S/ ${resumen.totalMora.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 10, color: Colors.orange.shade800)),
            const Divider(height: 18),
            Row(
              children: [
                _mini('Vendido', resumen.totalVendido),
                _mini('Abonado', resumen.totalAbonado),
                _mini('Ventas', resumen.cantidadVentas.toDouble(), entero: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mini(String label, double valor, {bool entero = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          const SizedBox(height: 2),
          Text(entero ? valor.toInt().toString() : 'S/ ${valor.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SeccionHeader extends StatelessWidget {
  final String titulo;
  final String contador;
  const _SeccionHeader(this.titulo, this.contador);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Text(titulo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.blue1.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(contador,
                style: const TextStyle(fontSize: 10, color: AppColors.blue1, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _VentaTile extends StatelessWidget {
  final VentaCreditoItem v;
  final String Function(DateTime?) fmt;
  const _VentaTile({required this.v, required this.fmt});

  Color get _color {
    if (v.saldoPendiente <= 0) return Colors.green.shade700;
    if (v.estado == 'VENCIDA') return Colors.red.shade700;
    return Colors.blue.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.codigo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                Text('${fmt(v.fechaVenta)}  ·  Vence ${fmt(v.fechaVencimiento)}',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('S/ ${v.saldoPendiente.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _color)),
              Text('de S/ ${v.total.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AbonoTile extends StatelessWidget {
  final AbonoItem a;
  final String Function(DateTime?) fmt;
  final String Function(String?) fuenteLabel;
  const _AbonoTile({required this.a, required this.fmt, required this.fuenteLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.south_west, size: 16, color: Colors.green.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${a.metodoPago}${a.fuente != null ? ' · ${fuenteLabel(a.fuente)}' : ''}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text('${fmt(a.fechaPago)}${a.ventaCodigo != null ? '  ·  ${a.ventaCodigo}' : ''}',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Text('+ S/ ${a.monto.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.green.shade700)),
        ],
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  final String texto;
  const _Vacio(this.texto);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text(texto, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;
  const _ErrorView({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 44, color: Colors.red.shade300),
            const SizedBox(height: 10),
            Text(mensaje, textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade400)),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue1, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
