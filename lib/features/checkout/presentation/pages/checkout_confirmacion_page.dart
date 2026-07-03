import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../mis_pedidos/presentation/pages/mis_pedidos_page.dart';
import '../../../mis_pedidos/presentation/pages/pedido_detail_page.dart';
// import '../../../marketplace/presentation/pages/marketplace_page.dart';

class CheckoutConfirmacionPage extends StatelessWidget {
  final List<String> codigos;

  /// Ids de los pedidos creados (paralelo a [codigos]). Con UN solo pedido se
  /// navega directo a su detalle para pagar.
  final List<String> pedidoIds;

  const CheckoutConfirmacionPage({
    super.key,
    required this.codigos,
    this.pedidoIds = const [],
  });

  /// Con un solo pedido → directo a su detalle (ahí están "Pagar con Yape" y
  /// el upload del comprobante); con varios → a la lista de pedidos.
  void _irAPagar(BuildContext context) {
    if (pedidoIds.length == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PedidoDetailPage(pedidoId: pedidoIds.first),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MisPedidosPage()),
      );
    }
  }

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
                    color: AppColors.green.withValues(alpha: 0.1),
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
                  'Tu pedido ha sido registrado. Para completarlo, realiza el pago:',
                  textAlign: TextAlign.center,
                  color: AppColors.textSecondary,
                  size: 14,
                ),
                const SizedBox(height: 16),

                // ¿Cómo pagar? — las dos opciones disponibles.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.greyLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF742284).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.qr_code_2_rounded,
                                size: 18, color: Color(0xFF742284)),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: AppText(
                              'Paga con Yape: confirmación automática al instante',
                              size: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.blue1.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.upload_file,
                                size: 18, color: AppColors.blue1),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: AppText(
                              'O sube tu comprobante de pago y el vendedor lo validará',
                              size: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

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
                                color: AppColors.blue1.withValues(alpha: 0.08),
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

                // Pagar ahora (Yape automático o subir comprobante — ambas
                // opciones viven en el detalle del pedido).
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    borderColor: const Color(0xFF742284),
                    backgroundColor: const Color(0xFF742284),
                    text: 'Pagar ahora',
                    onPressed: () => _irAPagar(context),
                    icon: const Icon(Icons.qr_code_2_rounded, color: AppColors.white, size: 20),
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
