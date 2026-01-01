import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_loading.dart';
import '../../../../core/utils/resource.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/politica_descuento.dart';
import '../../domain/usecases/get_politica_by_id.dart';

class PoliticaDescuentoDetailPage extends StatelessWidget {
  final String politicaId;

  const PoliticaDescuentoDetailPage({
    super.key,
    required this.politicaId,
  });

  @override
  Widget build(BuildContext context) {
    return _PoliticaDetailView(politicaId: politicaId);
  }
}

class _PoliticaDetailView extends StatefulWidget {
  final String politicaId;

  const _PoliticaDetailView({required this.politicaId});

  @override
  State<_PoliticaDetailView> createState() => _PoliticaDetailViewState();
}

class _PoliticaDetailViewState extends State<_PoliticaDetailView> {
  bool _isLoading = true;
  PoliticaDescuento? _politica;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPolitica();
  }

  Future<void> _loadPolitica() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final getPoliticaById = locator<GetPoliticaById>();
    final result = await getPoliticaById(widget.politicaId);

    if (result is Success<PoliticaDescuento>) {
      setState(() {
        _politica = result.data;
        _isLoading = false;
      });
    } else if (result is Error<PoliticaDescuento>) {
      setState(() {
        _error = result.message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: SmartAppBar(
        showLogo: false,
        title: 'Detalle de Política',
        actions: [
          if (_politica != null)
            BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
              builder: (context, state) {
                if (state is EmpresaContextLoaded &&
                    state.context.permissions.canManageDiscounts) {
                  return IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () {
                      context.push('/empresa/descuentos/${widget.politicaId}/editar');
                    },
                    tooltip: 'Editar',
                  );
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
      body: GradientBackground(
        style: GradientStyle.professional,
        child: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return CustomLoading.small(message: 'Cargando política...');
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadPolitica,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_politica == null) {
      return const Center(
        child: Text('No se encontró la política'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPolitica,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 16),
          _buildDiscountInfoCard(),
          const SizedBox(height: 16),
          _buildRestrictionsCard(),
          const SizedBox(height: 16),
          _buildDatesCard(),
          const SizedBox(height: 16),
          _buildActionsCard(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _politica!.nombre,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _politica!.isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _politica!.isActive ? 'Activa' : 'Inactiva',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _politica!.isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            if (_politica!.descripcion != null) ...[
              const SizedBox(height: 12),
              Text(
                _politica!.descripcion!,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del Descuento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Tipo', _getTipoDescuentoLabel(_politica!.tipoDescuento)),
            const Divider(),
            _buildInfoRow('Cálculo', _getTipoCalculoLabel(_politica!.tipoCalculo)),
            const Divider(),
            _buildInfoRow('Valor', _getDescuentoValue()),
            if (_politica!.descuentoMaximo != null) ...[
              const Divider(),
              _buildInfoRow(
                'Descuento Máximo',
                'S/. ${_politica!.descuentoMaximo!.toStringAsFixed(2)}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRestrictionsCard() {
    final hasRestrictions = _politica!.montoMinCompra != null ||
        _politica!.cantidadMaxUsos != null ||
        _politica!.maxFamiliaresPorTrabajador != null;

    if (!hasRestrictions) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Restricciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (_politica!.montoMinCompra != null) ...[
              _buildInfoRow(
                'Monto Mínimo de Compra',
                'S/. ${_politica!.montoMinCompra!.toStringAsFixed(2)}',
              ),
              const Divider(),
            ],
            if (_politica!.cantidadMaxUsos != null) ...[
              _buildInfoRow(
                'Cantidad Máxima de Usos',
                _politica!.cantidadMaxUsos.toString(),
              ),
              const Divider(),
            ],
            if (_politica!.maxFamiliaresPorTrabajador != null) ...[
              _buildInfoRow(
                'Máximo Familiares por Trabajador',
                _politica!.maxFamiliaresPorTrabajador.toString(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDatesCard() {
    final hasDates = _politica!.fechaInicio != null || _politica!.fechaFin != null;

    if (!hasDates) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vigencia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (_politica!.fechaInicio != null) ...[
              _buildInfoRow(
                'Fecha de Inicio',
                _formatDate(_politica!.fechaInicio!),
              ),
              const Divider(),
            ],
            if (_politica!.fechaFin != null) ...[
              _buildInfoRow(
                'Fecha de Fin',
                _formatDate(_politica!.fechaFin!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Acciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.push(
                  '/empresa/descuentos/${widget.politicaId}/asignar-usuarios?nombre=${Uri.encodeComponent(_politica!.nombre)}',
                );
              },
              icon: const Icon(Icons.people),
              label: const Text('Asignar Usuarios'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                context.push(
                  '/empresa/descuentos/${widget.politicaId}/asignar-productos?nombre=${Uri.encodeComponent(_politica!.nombre)}',
                );
              },
              icon: const Icon(Icons.inventory_2),
              label: const Text('Asignar Productos'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navegar a historial de uso
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Función por implementar'),
                  ),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text('Ver Historial de Uso'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getTipoDescuentoLabel(TipoDescuento tipo) {
    switch (tipo) {
      case TipoDescuento.trabajador:
        return 'Trabajador';
      case TipoDescuento.familiarTrabajador:
        return 'Familiar de Trabajador';
      case TipoDescuento.vip:
        return 'VIP';
      case TipoDescuento.promocional:
        return 'Promocional';
      case TipoDescuento.lealtad:
        return 'Lealtad';
      case TipoDescuento.cumpleanios:
        return 'Cumpleaños';
    }
  }

  String _getTipoCalculoLabel(TipoCalculoDescuento tipo) {
    switch (tipo) {
      case TipoCalculoDescuento.porcentaje:
        return 'Porcentaje';
      case TipoCalculoDescuento.montoFijo:
        return 'Monto Fijo';
    }
  }

  String _getDescuentoValue() {
    if (_politica!.tipoCalculo == TipoCalculoDescuento.porcentaje) {
      return '${_politica!.valorDescuento.toStringAsFixed(0)}%';
    } else {
      return 'S/. ${_politica!.valorDescuento.toStringAsFixed(2)}';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
