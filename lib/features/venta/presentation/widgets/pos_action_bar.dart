import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/custom_button.dart';

import '../bloc/venta_form/venta_form_cubit.dart';
import '../bloc/venta_form/venta_form_state.dart';

/// Barra de acciones inferior del POS (Borrador + Cobrar)
class PosActionBar extends StatelessWidget {
  final VoidCallback onBorrador;
  final VoidCallback onCobrar;

  const PosActionBar({
    super.key,
    required this.onBorrador,
    required this.onCobrar,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VentaFormCubit, VentaFormState>(
      builder: (context, state) {
        final isLoading = state is VentaFormLoading;
        return Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 10,
            bottom: MediaQuery.of(context).padding.bottom + 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Borrador',
                  isLoading: isLoading,
                  backgroundColor: AppColors.blue1,
                  onPressed: isLoading ? null : onBorrador,
                  icon: const Icon(Icons.save_outlined, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: CustomButton(
                  text: 'Cobrar',
                  isLoading: isLoading,
                  onPressed: isLoading ? null : onCobrar,
                  backgroundColor: Colors.green.shade600,
                  icon: const Icon(Icons.point_of_sale, size: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
