import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/custom_loading.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/transferencia_stock.dart';
import '../bloc/transferencias_list/transferencias_list_cubit.dart';
import '../bloc/transferencias_list/transferencias_list_state.dart';
import '../widgets/transferencia_card.dart';
import 'crear_transferencia_page.dart';
import 'transferencia_detail_page.dart';

class TransferenciasStockPage extends StatefulWidget {
  final String? sedeId; // Si es null, muestra todas las transferencias
  final EstadoTransferencia? estadoInicial; // Filtro inicial

  const TransferenciasStockPage({
    super.key,
    this.sedeId,
    this.estadoInicial,
  });

  @override
  State<TransferenciasStockPage> createState() =>
      _TransferenciasStockPageState();
}

class _TransferenciasStockPageState extends State<TransferenciasStockPage>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  late TabController _tabController;
  String? _empresaId;
  EstadoTransferencia? _filtroEstado;

  @override
  void initState() {
    super.initState();
    _filtroEstado = widget.estadoInicial;
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: _getTabIndex(_filtroEstado),
    );
    _scrollController.addListener(_onScroll);
    _loadInitialData();

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _onTabChanged(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      context.read<TransferenciasListCubit>().loadMore();
    }
  }

  void _loadInitialData() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _empresaId = empresaState.context.empresa.id;
      _loadTransferencias();
    }
  }

  void _loadTransferencias() {
    if (_empresaId != null) {
      context.read<TransferenciasListCubit>().loadTransferencias(
            empresaId: _empresaId!,
            sedeId: widget.sedeId,
            estado: _filtroEstado,
          );
    }
  }

  void _onTabChanged(int index) {
    final estados = [
      null, // Todas
      EstadoTransferencia.pendiente,
      EstadoTransferencia.aprobada,
      EstadoTransferencia.enTransito,
      EstadoTransferencia.recibida,
    ];

    setState(() {
      _filtroEstado = estados[index];
    });
    _loadTransferencias();
  }

  int _getTabIndex(EstadoTransferencia? estado) {
    if (estado == null) return 0;
    if (estado == EstadoTransferencia.pendiente) return 1;
    if (estado == EstadoTransferencia.aprobada) return 2;
    if (estado == EstadoTransferencia.enTransito) return 3;
    if (estado == EstadoTransferencia.recibida) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Transferencias de Stock',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<TransferenciasListCubit>().reload(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.blue1,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.blue1,
          tabs: const [
            Tab(text: 'Todas'),
            Tab(text: 'Pendientes'),
            Tab(text: 'Aprobadas'),
            Tab(text: 'En Tránsito'),
            Tab(text: 'Recibidas'),
          ],
        ),
      ),
      body: GradientBackground(
        child: BlocBuilder<TransferenciasListCubit, TransferenciasListState>(
          builder: (context, state) {
            if (state is TransferenciasListLoading) {
              return const CustomLoading();
            }

            if (state is TransferenciasListError) {
              return _buildError(state.message);
            }

            if (state is TransferenciasListEmpty) {
              return _buildEmpty();
            }

            if (state is TransferenciasListLoaded) {
              return _buildList(state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCrear(),
        backgroundColor: AppColors.blue1,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nueva Transferencia',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildList(TransferenciasListLoaded state) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.transferencias.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.transferencias.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final transferencia = state.transferencias[index];
        return TransferenciaCard(
          transferencia: transferencia,
          onTap: () => _navigateToDetail(transferencia),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sync_alt,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay transferencias',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea una nueva transferencia entre sedes',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar transferencias',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                context.read<TransferenciasListCubit>().reload(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue1,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCrear() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => locator<TransferenciasListCubit>(),
          child: const CrearTransferenciaPage(),
        ),
      ),
    );

    if (result == true && mounted) {
      context.read<TransferenciasListCubit>().reload();
    }
  }

  void _navigateToDetail(TransferenciaStock transferencia) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransferenciaDetailPage(
          transferenciaId: transferencia.id,
        ),
      ),
    );

    if (result == true && mounted) {
      context.read<TransferenciasListCubit>().reload();
    }
  }
}
