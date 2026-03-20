import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../direccion/domain/entities/direccion_persona.dart';
import '../../../direccion/domain/repositories/direccion_repository.dart';
import 'checkout_confirmacion_page.dart';

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> carritoData;

  const CheckoutPage({super.key, required this.carritoData});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _notasController = TextEditingController();
  String _metodoPago = 'YAPE';
  bool _isLoading = false;

  // Direcciones
  List<DireccionPersona> _direcciones = [];
  DireccionPersona? _direccionSeleccionada;
  bool _isLoadingDirecciones = true;

  // Opciones de envío por empresa: empresaId -> config
  Map<String, Map<String, dynamic>> _opcionesEnvio = {};
  // Selección de entrega por empresa: empresaId -> {tipo, sedeId?}
  Map<String, Map<String, dynamic>> _entregaSeleccionada = {};
  bool _isLoadingEnvio = true;

  double get _subtotal {
    double total = 0;
    for (final grupo in widget.carritoData) {
      final items = grupo['items'] as List<dynamic>? ?? [];
      for (final item in items) {
        total += (item['subtotal'] as num?)?.toDouble() ?? 0;
      }
    }
    return total;
  }

  double get _total => _subtotal;

  double _subtotalEmpresa(Map<String, dynamic> grupo) {
    final items = grupo['items'] as List<dynamic>? ?? [];
    return items.fold<double>(0, (sum, item) => sum + ((item['subtotal'] as num?)?.toDouble() ?? 0));
  }

  /// Determina si el envío es gratis para esta empresa
  bool _esEnvioGratis(String empresaId) {
    final entrega = _entregaSeleccionada[empresaId];
    if (entrega?['tipo'] == 'RETIRO_TIENDA') return true;

    final opciones = _opcionesEnvio[empresaId];
    final gratisDesde = (opciones?['envio']?['gratisDesde'] as num?)?.toDouble();
    if (gratisDesde != null && _subtotal >= gratisDesde) return true;

    // Verificar si todos los items del grupo tienen envioGratis
    final grupo = widget.carritoData.firstWhere((g) => g['empresaId'] == empresaId, orElse: () => {});
    final items = grupo['items'] as List<dynamic>? ?? [];
    if (items.isNotEmpty && items.every((i) => i['envioGratis'] == true)) return true;

    return false;
  }

  String _mensajeEnvio(String empresaId) {
    if (_esEnvioGratis(empresaId)) return 'Envío gratis';

    final opciones = _opcionesEnvio[empresaId];
    final mensajeLocal = opciones?['envio']?['mensajeLocal'] as String?;
    return mensajeLocal ?? 'Costo de envío lo asume el cliente al recibir';
  }

  @override
  void initState() {
    super.initState();
    _loadDirecciones();
    _loadOpcionesEnvio();
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _loadDirecciones() async {
    setState(() => _isLoadingDirecciones = true);
    final result = await locator<DireccionRepository>().listar();
    if (mounted) {
      setState(() {
        _isLoadingDirecciones = false;
        if (result is Success<List<DireccionPersona>>) {
          _direcciones = result.data.where((d) => d.tipo == 'ENVIO').toList();
          _direccionSeleccionada = _direcciones.where((d) => d.esPredeterminada).firstOrNull
              ?? _direcciones.firstOrNull;
        }
      });
    }
  }

  Future<void> _loadOpcionesEnvio() async {
    setState(() => _isLoadingEnvio = true);
    final dio = locator<DioClient>();

    for (final grupo in widget.carritoData) {
      final empresaId = grupo['empresaId'] as String;
      try {
        final response = await dio.get('/marketplace/carrito/opciones-envio/$empresaId');
        _opcionesEnvio[empresaId] = response.data as Map<String, dynamic>;
        // Default: envío a domicilio
        _entregaSeleccionada[empresaId] = {'tipo': 'ENVIO_DOMICILIO'};
      } catch (_) {
        _entregaSeleccionada[empresaId] = {'tipo': 'ENVIO_DOMICILIO'};
      }
    }

    if (mounted) setState(() => _isLoadingEnvio = false);
  }

  Future<void> _irAMisDirecciones() async {
    await context.push('/mis-direcciones');
    _loadDirecciones();
  }

  Future<void> _confirmarPedido() async {
    // Validar dirección si hay envío a domicilio
    final tieneEnvioDomicilio = _entregaSeleccionada.values.any((e) => e['tipo'] == 'ENVIO_DOMICILIO');
    if (tieneEnvioDomicilio && _direccionSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una direccion de envio'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final entregaPorEmpresa = _entregaSeleccionada.entries.map((e) {
        final data = <String, dynamic>{
          'empresaId': e.key,
          'tipoEntrega': e.value['tipo'],
        };
        if (e.value['sedeId'] != null) data['sedeRetiroId'] = e.value['sedeId'];
        return data;
      }).toList();

      final dioClient = locator<DioClient>();
      final response = await dioClient.post('/marketplace/checkout', data: {
        'metodoPago': _metodoPago,
        if (_direccionSeleccionada != null) 'direccionEnvioId': _direccionSeleccionada!.id,
        if (_notasController.text.trim().isNotEmpty) 'notasComprador': _notasController.text.trim(),
        'entregaPorEmpresa': entregaPorEmpresa,
      });

      if (!mounted) return;

      List<String> codigos = [];
      final responseData = response.data;
      if (responseData is Map && responseData['pedidos'] is List) {
        for (final pedido in responseData['pedidos']) {
          if (pedido is Map && pedido['codigo'] != null) codigos.add(pedido['codigo'] as String);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido(s) creado(s) exitosamente'), backgroundColor: AppColors.green),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => CheckoutConfirmacionPage(codigos: codigos)),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final message = (e.response?.data is Map ? e.response?.data['message'] : null) ?? 'Error al procesar el pedido';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message is List ? message.first.toString() : message.toString()), backgroundColor: AppColors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      style: GradientStyle.minimal,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const SmartAppBar(title: 'Checkout'),
        body: _isLoadingEnvio
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === RESUMEN + ENTREGA POR EMPRESA ===
                    const AppSubtitle('Resumen del Pedido'),
                    const SizedBox(height: 12),
                    ...widget.carritoData.map(_buildGrupoEmpresa),

                    // Total
                    const SizedBox(height: 8),
                    GradientContainer(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppSubtitle('Total a pagar', fontSize: 16),
                          AppSubtitle('S/ ${_total.toStringAsFixed(2)}', fontSize: 18, color: AppColors.green),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // === DIRECCIÓN (solo si hay envío a domicilio) ===
                    if (_entregaSeleccionada.values.any((e) => e['tipo'] == 'ENVIO_DOMICILIO')) ...[
                      Row(
                        children: [
                          const AppSubtitle('Direccion de Envio'),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _irAMisDirecciones,
                            icon: const Icon(Icons.edit_location_alt, size: 16),
                            label: const Text('Gestionar', style: TextStyle(fontSize: 11)),
                            style: TextButton.styleFrom(foregroundColor: AppColors.blue1, padding: const EdgeInsets.symmetric(horizontal: 8)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildDireccionSelector(),
                      const SizedBox(height: 24),
                    ],

                    // === MÉTODO DE PAGO ===
                    const AppSubtitle('Metodo de Pago'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildMetodoPagoChip('YAPE', Icons.phone_android, const Color(0xFF6C2C91)),
                        const SizedBox(width: 12),
                        _buildMetodoPagoChip('PLIN', Icons.phone_android, const Color(0xFF00BCD4)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // === NOTAS ===
                    const AppSubtitle('Notas (opcional)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notasController,
                      decoration: InputDecoration(
                        hintText: 'Instrucciones especiales, referencias, etc.',
                        prefixIcon: const Icon(Icons.note_outlined, color: AppColors.blue1),
                        filled: true, fillColor: AppColors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.greyLight)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.greyLight)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.blue1, width: 1.5)),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        borderColor: AppColors.blue1,
                        backgroundColor: AppColors.blue1,
                        text: 'Confirmar Pedido',
                        onPressed: _isLoading ? null : _confirmarPedido,
                        isLoading: _isLoading,
                        height: 50,
                        borderRadius: 14,
                        icon: const Icon(Icons.check_circle_outline, color: AppColors.white, size: 20),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildGrupoEmpresa(Map<String, dynamic> grupo) {
    final empresaId = grupo['empresaId'] as String;
    final empresaNombre = grupo['empresaNombre'] as String? ?? 'Empresa';
    final items = grupo['items'] as List<dynamic>? ?? [];
    final subtotalGrupo = _subtotalEmpresa(grupo);
    final opciones = _opcionesEnvio[empresaId];
    final entrega = _entregaSeleccionada[empresaId] ?? {'tipo': 'ENVIO_DOMICILIO'};
    final envioGratis = _esEnvioGratis(empresaId);
    final mensaje = _mensajeEnvio(empresaId);

    final retiroDisponible = opciones?['retiroTienda']?['disponible'] == true;
    final sedes = (opciones?['retiroTienda']?['sedes'] as List<dynamic>?) ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GradientContainer(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header empresa
            Row(
              children: [
                const Icon(Icons.store, size: 18, color: AppColors.blue1),
                const SizedBox(width: 8),
                Expanded(child: AppSubtitle(empresaNombre, fontSize: 14)),
                AppSubtitle('S/ ${subtotalGrupo.toStringAsFixed(2)}', fontSize: 14, color: AppColors.blue1),
              ],
            ),
            const Divider(height: 16),

            // Items
            ...items.map((item) {
              final nombre = (item['productoNombre'] ?? item['nombre']) as String? ?? '';
              final cantidad = item['cantidad'] as int? ?? 1;
              final precioUnitario = (item['precioUnitario'] as num?)?.toDouble() ?? 0;
              final imagenUrl = item['imagenUrl'] as String?;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: imagenUrl != null
                          ? Image.network(imagenUrl, width: 36, height: 36, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(width: 36, height: 36, color: Colors.grey.shade200,
                                child: const Icon(Icons.image, size: 16, color: Colors.grey)))
                          : Container(width: 36, height: 36, color: Colors.grey.shade200,
                              child: const Icon(Icons.image, size: 16, color: Colors.grey)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nombre, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('x$cantidad  •  S/ ${precioUnitario.toStringAsFixed(2)} c/u', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                      ],
                    )),
                    Text('S/ ${(precioUnitario * cantidad).toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }),

            const Divider(height: 16),

            // Opciones de entrega
            const AppSubtitle('Entrega', fontSize: 12),
            const SizedBox(height: 8),

            // Envío a domicilio
            _buildEntregaOption(
              empresaId: empresaId,
              tipo: 'ENVIO_DOMICILIO',
              icon: Icons.local_shipping,
              label: 'Envío a domicilio',
              sublabel: envioGratis ? 'Envío gratis' : 'Cliente asume costo',
              sublabelColor: envioGratis ? Colors.green : Colors.orange,
              isSelected: entrega['tipo'] == 'ENVIO_DOMICILIO',
            ),
            if (!envioGratis && entrega['tipo'] == 'ENVIO_DOMICILIO')
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 4),
                child: Text(mensaje, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              ),
            const SizedBox(height: 6),

            // Retiro en tienda
            if (retiroDisponible)
              _buildEntregaOption(
                empresaId: empresaId,
                tipo: 'RETIRO_TIENDA',
                icon: Icons.store,
                label: 'Retiro en tienda',
                sublabel: 'Gratis',
                sublabelColor: Colors.green,
                isSelected: entrega['tipo'] == 'RETIRO_TIENDA',
              ),

            // Selector de sede (si retiro seleccionado)
            if (entrega['tipo'] == 'RETIRO_TIENDA' && sedes.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...sedes.map((sede) {
                final sedeMap = sede as Map<String, dynamic>;
                final sedeId = sedeMap['id'] as String;
                final isSelectedSede = entrega['sedeId'] == sedeId;
                return GestureDetector(
                  onTap: () => setState(() {
                    _entregaSeleccionada[empresaId] = {'tipo': 'RETIRO_TIENDA', 'sedeId': sedeId};
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4, left: 32),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelectedSede ? AppColors.blue1.withValues(alpha: 0.05) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelectedSede ? AppColors.blue1 : Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(isSelectedSede ? Icons.radio_button_checked : Icons.radio_button_off,
                          size: 16, color: isSelectedSede ? AppColors.blue1 : Colors.grey.shade400),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sedeMap['nombre'] as String? ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              if (sedeMap['direccion'] != null)
                                Text(
                                  [sedeMap['direccion'], sedeMap['distrito']].where((e) => e != null).join(', '),
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEntregaOption({
    required String empresaId,
    required String tipo,
    required IconData icon,
    required String label,
    required String sublabel,
    required Color sublabelColor,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() {
        _entregaSeleccionada[empresaId] = {'tipo': tipo};
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue1.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.blue1 : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18, color: isSelected ? AppColors.blue1 : Colors.grey.shade400),
            const SizedBox(width: 8),
            Icon(icon, size: 18, color: isSelected ? AppColors.blue1 : Colors.grey.shade500),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal))),
            Text(sublabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sublabelColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildDireccionSelector() {
    if (_isLoadingDirecciones) {
      return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }

    if (_direcciones.isEmpty) {
      return GradientContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.location_off, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text('No tienes direcciones de envio guardadas', style: TextStyle(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            CustomButton(text: 'Agregar direccion', onPressed: _irAMisDirecciones, backgroundColor: AppColors.blue1, height: 40, borderRadius: 8,
              icon: const Icon(Icons.add_location, color: Colors.white, size: 18)),
          ],
        ),
      );
    }

    return Column(
      children: _direcciones.map((dir) {
        final isSelected = _direccionSeleccionada?.id == dir.id;
        return GestureDetector(
          onTap: () => setState(() => _direccionSeleccionada = dir),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.blue1.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppColors.blue1 : Colors.grey.shade300, width: isSelected ? 2 : 1),
            ),
            child: Row(
              children: [
                Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? AppColors.blue1 : Colors.grey.shade400, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        AppSubtitle(dir.displayName, fontSize: 13),
                        if (dir.esPredeterminada) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: AppColors.blue1.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                            child: const Text('Principal', style: TextStyle(fontSize: 9, color: AppColors.blue1, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 2),
                      Text(dir.direccionCompleta, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (dir.tieneCoordenadas) Icon(Icons.gps_fixed, size: 16, color: Colors.green.shade600),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetodoPagoChip(String metodo, IconData icon, Color color) {
    final isSelected = _metodoPago == metodo;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _metodoPago = metodo),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : AppColors.greyLight, width: isSelected ? 2 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? color : AppColors.grey, size: 20),
              const SizedBox(width: 8),
              Text(metodo, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
