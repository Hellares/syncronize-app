import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../mis_pedidos/presentation/pages/mis_pedidos_page.dart';
// import '../../../marketplace/presentation/pages/marketplace_page.dart';

class CheckoutConfirmacionPage extends StatelessWidget {
  final List<String> codigos;

  const CheckoutConfirmacionPage({super.key, required this.codigos});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      style: GradientStyle.minimal,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const SmartAppBar(title: 'Confirmacion'),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono de exito
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppColors.green,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),

                const AppTitle(
                  'Pedido(s) creado(s) exitosamente',
                  fontSize: 20,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                const AppText(
                  'Tu pedido ha sido registrado. Recuerda subir tu comprobante de pago para que el vendedor pueda procesarlo.',
                  textAlign: TextAlign.center,
                  color: AppColors.textSecondary,
                  size: 14,
                ),
                const SizedBox(height: 24),

                // Codigos de pedido
                if (codigos.isNotEmpty) ...[
                  GradientContainer(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    child: Column(
                      children: [
                        const AppText(
                          'Codigo(s) de pedido:',
                          fontWeight: FontWeight.w600,
                          size: 13,
                        ),
                        const SizedBox(height: 8),
                        ...codigos.map(
                          (codigo) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.blue1.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: AppText(
                                codigo,
                                fontWeight: FontWeight.bold,
                                size: 16,
                                color: AppColors.blue1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Boton subir comprobante
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    borderColor: AppColors.blue1,
                    backgroundColor: AppColors.blue1,
                    text: 'Subir comprobante de pago',
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const MisPedidosPage(),
                        ),
                      );
                    },
                    //height: 48,
                    //borderRadius: 14,
                    icon: const Icon(Icons.upload_file, color: AppColors.white, size: 20),
                  ),
                ),
                const SizedBox(height: 12),

                // Boton ver mis pedidos
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    backgroundColor: AppColors.green,
                    borderColor: AppColors.green,
                    text: 'Ver mis pedidos',
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const MisPedidosPage(),
                        ),
                      );
                    },
                    //isOutlined: true,
                    //height: 48,
                    //borderRadius: 14,
                    icon: const Icon(Icons.list_alt, color: AppColors.blue1, size: 20),
                  ),
                ),
                const SizedBox(height: 12),

                // Boton seguir comprando
                // SizedBox(
                //   width: double.infinity,
                //   child: CustomButton(
                //     borderColor: AppColors.blue1,
                //     backgroundColor: AppColors.blue1,
                //     text: 'Seguir comprando',
                //     onPressed: () {
                //       Navigator.of(context).pushAndRemoveUntil(
                //         MaterialPageRoute(
                //           builder: (_) => const MarketplacePage(),
                //         ),
                //         (route) => route.isFirst,
                //       );
                //     },
                //     //isOutlined: true,
                //     //height: 48,
                //     //borderRadius: 14,
                //     icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.blue1, size: 20),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
