import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa_banco/domain/entities/empresa_banco.dart';
import '../../../empresa_banco/domain/usecases/get_cuentas_bancarias_usecase.dart';
import '../../data/datasources/cuentas_recaudacion_remote_datasource.dart';
import '../../domain/entities/recaudacion_metodo.dart';

/// Config "Cuentas de recaudación": a qué banco entra cada método digital
/// (Yape→BCP, Plin→Interbank…). EFECTIVO no se mapea (va a la bóveda/Tesorería).
class CuentasRecaudacionPage extends StatefulWidget {
  const CuentasRecaudacionPage({super.key});

  @override
  State<CuentasRecaudacionPage> createState() => _CuentasRecaudacionPageState();
}

class _CuentasRecaudacionPageState extends State<CuentasRecaudacionPage> {
  final _ds = locator<CuentasRecaudacionRemoteDataSource>();
  bool _loading = true;
  String? _error;
  List<RecaudacionMetodo> _mapeo = [];
  List<EmpresaBanco> _bancos = [];
  String? _guardando; // metodoPago en curso

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bancosRes = await locator<GetCuentasBancariasUseCase>().call();
      final mapeo = await _ds.listar();
      if (!mounted) return;
      setState(() {
        _bancos = bancosRes is Success<List<EmpresaBanco>>
            ? bancosRes.data.where((b) => b.isActive).toList()
            : [];
        _mapeo = mapeo;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo cargar: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _asignar(RecaudacionMetodo m, String? bancoId) async {
    setState(() => _guardando = m.metodoPago);
    try {
      if (bancoId == null) {
        await _ds.removeCuenta(m.metodoPago);
      } else {
        await _ds.setCuenta(m.metodoPago, bancoId);
      }
      if (!mounted) return;
      final banco = bancoId == null ? null : _bancos.firstWhere((b) => b.id == bancoId);
      setState(() {
        _mapeo = _mapeo
            .map((x) => x.metodoPago == m.metodoPago
                ? x.copyWith(
                    limpiar: bancoId == null,
                    bancoId: bancoId,
                    banco: banco == null
                        ? null
                        : BancoRecaudacion(
                            id: banco.id,
                            nombreBanco: banco.nombreBanco,
                            numeroCuenta: banco.numeroCuenta,
                            moneda: banco.moneda ?? 'PEN',
                          ),
                  )
                : x)
            .toList();
        _guardando = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar: $e'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Cuentas de recaudación',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
      ),
      body: GradientBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _cargar, child: const Text('Reintentar')),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargar,
                    color: AppColors.blue1,
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        _intro(),
                        const SizedBox(height: 8),
                        if (_bancos.isEmpty) _sinBancos() else ..._mapeo.map(_filaMetodo),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _intro() {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: AppColors.blue1),
            SizedBox(width: 8),
            Expanded(
              child: AppSubtitle(
                'Indicá a qué cuenta bancaria entra cada cobro digital. El efectivo va a la Tesorería (bóveda).',
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sinBancos() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.account_balance, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No tienes cuentas bancarias registradas.\nCrea una en "Cuentas bancarias".',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _filaMetodo(RecaudacionMetodo m) {
    final guardando = _guardando == m.metodoPago;
    return GradientContainer(
      margin: const EdgeInsets.only(bottom: 8),
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.smartphone, size: 16, color: AppColors.blue1),
                const SizedBox(width: 6),
                AppSubtitle(m.metodoLabel, fontSize: 14, color: AppColors.blue1),
                const Spacer(),
                if (guardando)
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 8),
            CustomDropdown<String?>(
              label: 'Cuenta de recaudación',
              value: m.bancoId,
              borderColor: AppColors.blueborder,
              items: [
                const DropdownItem(value: null, label: 'Sin asignar'),
                ..._bancos.map((b) => DropdownItem(
                      value: b.id,
                      label: '${b.nombreBanco} ·· ${b.numeroCuenta} (${b.moneda ?? 'PEN'})',
                    )),
              ],
              onChanged: guardando ? null : (v) => _asignar(m, v),
            ),
          ],
        ),
      ),
    );
  }
}
