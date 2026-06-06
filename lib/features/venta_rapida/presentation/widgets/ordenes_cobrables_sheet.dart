import 'dart:async';

import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/resource.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../../servicio/presentation/widgets/estado_badge_widget.dart';
import '../../domain/entities/orden_cobrable.dart';
import '../../domain/usecases/get_ordenes_cobrables_usecase.dart';

/// Sheet de selección de órdenes de servicio cobrables (REPARADO /
/// LISTO_ENTREGA con saldo pendiente y sin venta vinculada).
///
/// Devuelve la [OrdenCobrable] elegida (o null si se cerró sin elegir).
/// El caller la agrega al carrito vía `VentaRapidaCubit.agregarOrdenServicio`.
Future<OrdenCobrable?> showOrdenesCobrablesSheet(BuildContext context) {
  return showModalBottomSheet<OrdenCobrable>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(
      minHeight: MediaQuery.of(context).size.height * 0.70,
      maxHeight: MediaQuery.of(context).size.height * 0.70,
    ),
    builder: (_) => const _OrdenesCobrablesSheet(),
  );
}

class _OrdenesCobrablesSheet extends StatefulWidget {
  const _OrdenesCobrablesSheet();

  @override
  State<_OrdenesCobrablesSheet> createState() => _OrdenesCobrablesSheetState();
}

class _OrdenesCobrablesSheetState extends State<_OrdenesCobrablesSheet> {
  final _searchController = TextEditingController();
  final _usecase = locator<GetOrdenesCobrablesUseCase>();

  Timer? _debounce;
  bool _loading = true;
  String? _error;
  List<OrdenCobrable> _ordenes = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargar({String? search}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _usecase(search: search);
    if (!mounted) return;
    if (result is Success<List<OrdenCobrable>>) {
      setState(() {
        _ordenes = result.data;
        _loading = false;
      });
    } else if (result is Error<List<OrdenCobrable>>) {
      setState(() {
        _error = result.message;
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _cargar(search: value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 30,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.home_repair_service_outlined,
                    size: 18, color: AppColors.blue1),
                const SizedBox(width: 8),
                const Expanded(
                  child: AppSubtitle(
                    'COBRAR SERVICIO',
                    fontSize: 12,
                    font: AppFont.oxygenBold,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomText(
              controller: _searchController,
              hintText: 'Buscar por código, cliente o equipo',
              borderColor: AppColors.blue1,
              prefixIcon: const Icon(Icons.search, size: 18),
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Flexible(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _cargar(search: _searchController.text),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_ordenes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _searchController.text.trim().isEmpty
                ? 'No hay órdenes listas para cobrar.\nDeben estar en REPARADO o LISTO PARA ENTREGA con saldo pendiente.'
                : 'Sin resultados para "${_searchController.text.trim()}"',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _ordenes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _OrdenCobrableCard(
        orden: _ordenes[index],
        onTap: () => Navigator.of(context).pop(_ordenes[index]),
      ),
    );
  }
}

class _OrdenCobrableCard extends StatelessWidget {
  final OrdenCobrable orden;
  final VoidCallback onTap;

  const _OrdenCobrableCard({required this.orden, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final equipo = orden.equipoDescripcion;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.blue1.withValues(alpha: 0.25), width: 0.8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppSubtitle(
                        orden.codigo,
                        fontSize: 11,
                        font: AppFont.oxygenBold,
                        color: AppColors.blue1,
                      ),
                      const SizedBox(width: 8),
                      EstadoBadgeWidget(estado: orden.estado),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    orden.clienteNombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  if (equipo.isNotEmpty)
                    Text(
                      equipo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'S/ ${orden.saldoPendiente.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blue1,
                  ),
                ),
                if (orden.adelanto > 0)
                  Text(
                    'Adelanto S/ ${orden.adelanto.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 9, color: Colors.green.shade700),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
