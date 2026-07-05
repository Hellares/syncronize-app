import 'package:flutter/material.dart';

import '../../../../core/constants/storage_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/repositories/carrito_repository.dart';
import '../../domain/usecases/get_contador_usecase.dart';

/// Contador global del carrito (total de unidades). Vive fuera del árbol de
/// widgets para que cualquier página (detalle marketplace, home, carrito) lo
/// lea y actualice sin necesitar un cubit compartido entre rutas.
class CarritoBadgeController {
  CarritoBadgeController._();

  static final ValueNotifier<int> cantidad = ValueNotifier<int>(0);

  /// Refresca desde el server. Silencioso: sin sesión o con error no hace nada
  /// (conserva el último valor conocido).
  static Future<void> sync() async {
    try {
      final token =
          locator<LocalStorageService>().getString(StorageConstants.accessToken);
      if (token == null || token.isEmpty) return;
      final result = await locator<GetContadorUseCase>()();
      if (result is Success<CarritoContador>) {
        cantidad.value = result.data.totalCantidad;
      }
    } catch (_) {}
  }

  static void set(int value) => cantidad.value = value < 0 ? 0 : value;

  static void add(int n) => set(cantidad.value + n);
}

/// Badge rojo con la cantidad del carrito montado sobre [child] (el ícono del
/// carrito). Hace "pop" (escala con rebote) cada vez que la cantidad cambia.
class CarritoBadge extends StatelessWidget {
  final Widget child;

  const CarritoBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: CarritoBadgeController.cantidad,
      builder: (context, count, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (count > 0)
              Positioned(
                top: -3,
                right: -3,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey<int>(count),
                  tween: Tween(begin: 1.5, end: 1.0),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutBack,
                  builder: (_, scale, badge) =>
                      Transform.scale(scale: scale, child: badge),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                    constraints: const BoxConstraints(minWidth: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.white, width: 1.2),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
