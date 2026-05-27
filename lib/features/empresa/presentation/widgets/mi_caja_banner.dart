import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../caja/presentation/bloc/caja_activa_cubit.dart';
import '../../../caja/presentation/bloc/caja_activa_state.dart';

class MiCajaBanner extends StatefulWidget {
  const MiCajaBanner({super.key});

  @override
  State<MiCajaBanner> createState() => _MiCajaBannerState();
}

class _MiCajaBannerState extends State<MiCajaBanner> {
  late final CajaActivaCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = locator<CajaActivaCubit>()..loadCajaActiva();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<CajaActivaCubit, CajaActivaState>(
        builder: (context, state) {
          if (state is CajaActivaLoading) {
            return const SizedBox.shrink();
          }

          if (state is CajaActivaAbierta) {
            return _buildCajaAbierta(context, state);
          }

          if (state is CajaActivaSinCaja) {
            return _buildSinCaja(context);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCajaAbierta(BuildContext context, CajaActivaAbierta state) {
    final caja = state.caja;
    return GestureDetector(
      onTap: () => context.push('/empresa/caja'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  caja.codigo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue1,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: const Text(
                    'ABIERTA',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right,
                    size: 18, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _infoChip(
                  Icons.store_outlined,
                  caja.sedeNombre ?? 'Sede',
                ),
                const SizedBox(width: 12),
                _infoChip(
                  Icons.access_time_rounded,
                  DateFormatter.formatTime(caja.fechaApertura),
                ),
                const SizedBox(width: 12),
                _infoChip(
                  Icons.account_balance_wallet_outlined,
                  'Apertura: S/ ${caja.montoApertura.toStringAsFixed(2)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSinCaja(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/empresa/caja'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.point_of_sale,
                size: 18, color: Colors.grey.shade500),
            const SizedBox(width: 8),
            Text(
              'Sin caja abierta',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.blue1,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Abrir Caja',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade500),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade700,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
