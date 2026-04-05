import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_loading.dart';
import '../../domain/entities/cliente_con_citas.dart';
import '../../domain/repositories/cita_repository.dart';

class ClientesCitasPage extends StatefulWidget {
  const ClientesCitasPage({super.key});

  @override
  State<ClientesCitasPage> createState() => _ClientesCitasPageState();
}

class _ClientesCitasPageState extends State<ClientesCitasPage> {
  List<ClienteConCitas> _clientes = [];
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadClientes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadClientes({String? search}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = locator<CitaRepository>();
    final result = await repo.getClientesConCitas(search: search);

    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result is Success<List<ClienteConCitas>>) {
        _clientes = result.data;
      } else if (result is Error) {
        _error = (result as Error).message;
      }
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _loadClientes(search: value.trim().isEmpty ? null : value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Historial por Cliente',
          backgroundColor: AppColors.blue1,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: () => _loadClientes(
                search: _searchController.text.trim().isEmpty
                    ? null
                    : _searchController.text.trim(),
              ),
              tooltip: 'Actualizar',
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Barra de búsqueda
              Padding(
                padding: const EdgeInsets.all(12),
                child: GradientContainer(
                  gradient: AppGradients.blueWhiteBlue(),
                  borderColor: AppColors.blueborder,
                  borderWidth: 0.6,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Buscar cliente por nombre o teléfono...',
                        hintStyle:
                            TextStyle(fontSize: 12, color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.search,
                            size: 18, color: AppColors.blue1),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear,
                                    size: 16, color: Colors.grey.shade400),
                                onPressed: () {
                                  _searchController.clear();
                                  _loadClientes();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
              // Lista
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return CustomLoading.small(message: 'Cargando clientes...');
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadClientes,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reintentar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blue1,
                  side: const BorderSide(color: AppColors.blue1),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_clientes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                _searchController.text.isNotEmpty
                    ? 'No se encontraron clientes con citas'
                    : 'No hay clientes con citas registradas',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadClientes(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      ),
      color: AppColors.blue1,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _clientes.length,
        itemBuilder: (context, index) {
          final cliente = _clientes[index];
          return _ClienteCitaCard(
            cliente: cliente,
            onTap: () {
              context.push(
                '/empresa/citas/historial-cliente',
                extra: {
                  'clienteId': cliente.isPersona
                      ? cliente.clienteId!
                      : cliente.clienteEmpresaId!,
                  if (!cliente.isPersona)
                    'clienteEmpresaId': cliente.clienteEmpresaId,
                  'clienteNombre': cliente.nombre,
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ClienteCitaCard extends StatelessWidget {
  final ClienteConCitas cliente;
  final VoidCallback onTap;

  const _ClienteCitaCard({required this.cliente, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GradientContainer(
        gradient: AppGradients.blueWhiteBlue(),
        borderColor: AppColors.blueborder,
        borderWidth: 0.6,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    cliente.isPersona ? Icons.person : Icons.business,
                    color: AppColors.blue1,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSubtitle(
                        cliente.nombre,
                        fontSize: 12,
                        color: AppColors.blue2,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (cliente.telefono != null) ...[
                            Icon(Icons.phone,
                                size: 10, color: Colors.grey.shade500),
                            const SizedBox(width: 3),
                            Text(
                              cliente.telefono!,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                                fontFamily: AppFonts.getFontFamily(
                                    AppFont.oxygenRegular),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cliente.isPersona
                                  ? AppColors.blue1.withValues(alpha: 0.08)
                                  : Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              cliente.isPersona ? 'Persona' : 'Empresa',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: cliente.isPersona
                                    ? AppColors.blue1
                                    : Colors.amber.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Badge de total citas
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${cliente.totalCitas}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blue1,
                        ),
                      ),
                      Text(
                        cliente.totalCitas == 1 ? 'cita' : 'citas',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.blue1.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
