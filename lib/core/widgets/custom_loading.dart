import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CustomLoading extends StatelessWidget {
  final String? message;
  final double? width;
  final double? height;
  final double? animationSize;
  final Color? backgroundColor;
  final Color? textColor;
  final double? borderRadius;
  final String? animationPath;
  final bool showOverlay;

  const CustomLoading({
    super.key,
    this.message,
    this.width = 150,
    this.height = 150,
    this.animationSize = 80,
    this.backgroundColor = Colors.white,
    this.textColor,
    this.borderRadius = 20,
    this.animationPath = 'assets/animations/Loading.json',
    this.showOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Center(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              animationPath!,
              width: animationSize,
              height: animationSize,
              fit: BoxFit.contain,
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor ?? Colors.grey[700],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return widget;
  }

  // Factory constructors para casos específicos
  factory CustomLoading.login() {
    return const CustomLoading(
      message: 'Iniciando sesión...',
      animationPath: 'assets/animations/Loading.json',
    );
  }

  factory CustomLoading.registering() {
    return const CustomLoading(
      message: 'Creando cuenta...',
      animationPath: 'assets/animations/Loading.json',
    );
  }

  factory CustomLoading.uploading() {
    return const CustomLoading(
      message: 'Subiendo archivos...',
      animationPath: 'assets/animations/Loading.json',
    );
  }

  factory CustomLoading.processing() {
    return const CustomLoading(
      message: 'Procesando...',
      animationPath: 'assets/animations/Loading.json',
    );
  }

  factory CustomLoading.small({String? message}) {
    return CustomLoading(
      message: message,
      width: 150,
      height: 150,
      animationSize: 60,
      animationPath: 'assets/animations/Loading.json',
    );
  }

  
}