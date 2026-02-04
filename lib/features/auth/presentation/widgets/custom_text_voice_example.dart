import 'package:flutter/material.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';

/// Ejemplo de uso del CustomText con funcionalidad de voz
class CustomTextVoiceExample extends StatefulWidget {
  const CustomTextVoiceExample({super.key});

  @override
  State<CustomTextVoiceExample> createState() => _CustomTextVoiceExampleState();
}

class _CustomTextVoiceExampleState extends State<CustomTextVoiceExample> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejemplo: Voice Input'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Presiona el ícono del micrófono para dictar texto',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Ejemplo 1: Campo de texto simple con voz
              CustomText(
                label: 'Nombre completo',
                hintText: 'Escribe o dicta tu nombre',
                controller: _textController,
                enableVoiceInput: true, // 👈 Habilitar dictado de voz
                fieldType: FieldType.text,
                required: true,
              ),
              const SizedBox(height: 20),

              // Ejemplo 2: Campo de email con voz
              CustomText(
                label: 'Correo electrónico',
                hintText: 'Escribe o dicta tu email',
                controller: _emailController,
                enableVoiceInput: true, // 👈 Habilitar dictado de voz
                fieldType: FieldType.email,
                required: true,
                validator: FieldValidators.validateEmail,
              ),
              const SizedBox(height: 20),

              // Ejemplo 3: Campo de notas multilinea con voz
              CustomText(
                label: 'Notas',
                hintText: 'Escribe o dicta tus notas',
                controller: _notesController,
                enableVoiceInput: true, // 👈 Habilitar dictado de voz
                fieldType: FieldType.text,
                maxLines: 5,
                required: false,
              ),
              const SizedBox(height: 20),

              // Ejemplo 4: Con locale personalizado (Colombia)
              CustomText(
                label: 'Mensaje en español (Colombia)',
                hintText: 'Dicta tu mensaje',
                controller: TextEditingController(),
                enableVoiceInput: true,
                voiceLocale: 'es_CO', // 👈 Configurar locale específico
                fieldType: FieldType.text,
              ),
              const SizedBox(height: 32),

              // Botón de ejemplo para leer el texto
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Texto capturado'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nombre: ${_textController.text}'),
                          const SizedBox(height: 8),
                          Text('Email: ${_emailController.text}'),
                          const SizedBox(height: 8),
                          Text('Notas: ${_notesController.text}'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Ver texto capturado'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
