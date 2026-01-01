import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_background.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_logo_widget.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/constants/storage_constants.dart';

import '../../domain/entities/auth_response.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/login/login_cubit.dart';

import '../widgets/widgets.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';

class LoginPage extends StatelessWidget {
  final String? returnTo;

  const LoginPage({super.key, this.returnTo});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<LoginCubit>(),
      child: _LoginView(returnTo: returnTo),
    );
  }
}

class _LoginView extends StatefulWidget {
  final String? returnTo;
  const _LoginView({this.returnTo});

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final ValueNotifier<bool> _submitSignal = ValueNotifier(false);

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _passwordCardKey = GlobalKey();

  bool _showPasswordCard = false;

  //!Variable para cambiar el estilo del gradient fácilmente
  final GradientStyle _gradientStyle = GradientStyle.professional; //!Cambia aquí el estilo

  final LogoStyle _logoStyle = LogoStyle.glowEffect;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _submitSignal.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _fireSubmitSignal() {
    _submitSignal.value = true;
    _submitSignal.value = false;
  }

  void _scrollToPasswordCard() {
    if (!mounted) return;

    final ctx = _passwordCardKey.currentContext;
    if (ctx == null) return;

    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 380),
      alignment: 0.15,
    );
  }

  void _openPasswordCard() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _showPasswordCard = true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToPasswordCard();
    });
  }

  void _closePasswordCard() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _showPasswordCard = false);

    _emailController.clear();
    _passwordController.clear();
    context.read<LoginCubit>().emailChanged('');
    context.read<LoginCubit>().passwordChanged('');
  }

  Widget _fadeSlideTransition(Widget child, Animation<double> animation) {
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      // ✅ Usar el widget GradientBackground en lugar de Container manual
      body: GradientBackground(
        style: _gradientStyle, // 👈 Usa el estilo seleccionado
        child: SafeArea(
          child: BlocConsumer<LoginCubit, LoginState>(
            listener: (context, state) async {
              if (state.submitAttempt) _fireSubmitSignal();

              final response = state.response;

              if (response is Success) {
                final authResponse = response.data as AuthResponse;
                final user = authResponse.user;

                // Verificar si el usuario debe cambiar su contraseña
                if (user.requiereCambioPassword == true) {
                  SnackBarHelper.showInfo(
                    context,
                    'Debes cambiar tu contraseña temporal antes de continuar',
                  );
                  context.go('/change-password', extra: {
                    'userId': user.id,
                    'credencial': state.email.value.trim(),
                  });
                  return;
                }

                if (!user.emailVerificado) {
                  SnackBarHelper.showWarning(
                    context,
                    'Debes verificar tu email antes de continuar',
                  );
                  context.go('/verify-email', extra: user.email);
                  return;
                }

                // Verificar si requiere selección de modo
                if (authResponse.requiresSelection == true && authResponse.options != null) {
                  // Mostrar selector de modo (Marketplace vs Management)
                  ModeSelectionBottomSheet.show(
                    context: context,
                    modeOptions: authResponse.options!,
                    onModeSelected: (modeType, subdominioEmpresa) {
                      // Cerrar el bottom sheet
                      Navigator.pop(context);

                      // Hacer segundo login con el modo seleccionado
                      if (modeType == 'marketplace') {
                        context.read<LoginCubit>().loginWithMode(
                          email: state.email.value.trim(),
                          password: state.password.value,
                          loginMode: 'marketplace',
                        );
                      } else {
                        // Modo management
                        context.read<LoginCubit>().loginWithMode(
                          email: state.email.value.trim(),
                          password: state.password.value,
                          loginMode: 'management',
                          subdominioEmpresa: subdominioEmpresa,
                        );
                      }
                    },
                  );
                  return;
                }

                // Login directo sin selección (ya tiene modo definido)
                SnackBarHelper.showSuccess(context, 'Inicio de sesión exitoso');

                // Guardar loginMode según la respuesta del backend
                final localStorage = locator<LocalStorageService>();
                final loginMode = authResponse.mode ?? 'marketplace';
                await localStorage.setString(StorageConstants.loginMode, loginMode);

                if (!context.mounted) return;

                context.read<AuthBloc>().add(UserLoggedInEvent(user: user));

                if (widget.returnTo != null && widget.returnTo!.isNotEmpty) {
                  context.go(widget.returnTo!);
                } else {
                  // Navegar según el modo de login
                  if (loginMode == 'management') {
                    context.go('/empresa/dashboard');
                  } else {
                    context.go('/marketplace');
                  }
                }
              } else if (response is Error) {
                final msg = response.message.toLowerCase();
                if (msg.contains('verif') || msg.contains('email')) {
                  _showEmailNotVerifiedDialog(context, state.email.value);
                } else {
                  SnackBarHelper.showError(context, response.message);
                }
              }
            },
            builder: (context, state) {
              final isLoading = state.response is Loading;
              final isCheckingMethods = state.isCheckingMethods;

              final canUseGoogle = state.shouldShowGoogleButton;
              final canUsePassword =
                  state.availableMethods?.hasPassword ?? true;

              final showGoogle = canUseGoogle && !_showPasswordCard;

              return Center(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppLogo(
                        logoPath: 'assets/img/logo.svg',
                        logoSize: 110,
                        style: _logoStyle,
                        appName: 'Syncronize',
                        subtitle: 'Red de Emprendedores',
                        // primaryColor: const Color.fromARGB(255, 11, 116, 202),
                        primaryColor: AppColors.blue2
                      ),
                      
                     
                      const SizedBox(height: 28),

                      // --- SECCIÓN GOOGLE ---
                      AnimatedSize(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOutCubicEmphasized,
                        alignment: Alignment.topCenter,
                        child: showGoogle
                            ? _fadeSlideTransition(
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 0,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CustomButton(
                                        text: 'Continuar con Google',
                                        iconPath: 'assets/img/google.svg',
                                        backgroundColor: Colors.white,
                                        textColor: Colors.black87,
                                        enableShadow: true,
                                        enableGlow: false,
                                        isLoading: isLoading,
                                        onPressed:
                                            isLoading || isCheckingMethods
                                            ? null
                                            : () {
                                                FocusManager
                                                    .instance
                                                    .primaryFocus
                                                    ?.unfocus();
                                                context
                                                    .read<LoginCubit>()
                                                    .signInWithGoogle();
                                              },
                                      ),
                                      const SizedBox(height: 15),
                                      const Divider(
                                        indent: 40,
                                        endIndent: 40,
                                        height: 20,
                                        thickness: 1.2,
                                      ),
                                      const SizedBox(height: 15),
                                    ],
                                  ),
                                ),
                                kAlwaysCompleteAnimation,
                              )
                            : const SizedBox.shrink(),
                      ),

                      // --- Email Check/Password Card ---
                      AnimatedSize(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOutCubicEmphasized,
                        alignment: Alignment.topCenter,
                        child: Column(
                          children: [
                            // Botón "Continuar con correo"
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 340),
                              transitionBuilder: (child, animation) =>
                                  _fadeSlideTransition(child, animation),
                              child: !_showPasswordCard
                                  ? Padding(
                                      key: const ValueKey('email_check_button'),
                                      padding: const EdgeInsets.only(bottom: 0),
                                      child: CustomButton(
                                        text: 'Continuar con email o DNI',
                                        backgroundColor: AppColors.blue2,
                                        onPressed:
                                            isLoading || isCheckingMethods
                                            ? null
                                            : _openPasswordCard,
                                        isLoading: false,
                                      ),
                                    )
                                  : const SizedBox(
                                      key: ValueKey('email_check_hidden'),
                                    ),
                            ),

                            // Password Card
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 380),
                              transitionBuilder: (child, animation) =>
                                  _fadeSlideTransition(child, animation),
                              child: _showPasswordCard && canUsePassword
                                  ? Padding(
                                      key: _passwordCardKey,
                                      padding: const EdgeInsets.only(bottom: 0),
                                      child: Card(
                                        color: AppColors.cardBackground,
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              const Icon(
                                                Icons.lock_outline,
                                                size: 35,
                                                color: AppColors.blue,
                                              ),
                                              const SizedBox(height: 8),

                                              AppSubtitle(
                                                'Ingresa tu email o DNI y contraseña',
                                                fontSize: 13,
                                                textAlign: TextAlign.center,
                                                // font: AppFont.pirulentBold,
                                                color: AppColors.blue2
                                              ),

                                              const SizedBox(height: 15),

                                              // Email o DNI
                                              CustomText(
                                                label: 'Email o DNI',
                                                controller: _emailController,
                                                fieldType: FieldType.text,
                                                enabled: !isLoading,
                                                hintText: 'email@ejemplo.com o 12345678',
                                                helperText: 'DNI: 8 dígitos',
                                                borderColor: AppColors.blue2,
                                                borderWidth: 0.6,
                                                required: true,
                                                autovalidateMode:
                                                    AutovalidateModeX
                                                        .afterSubmit,
                                                submitSignal: _submitSignal,
                                                externalError:
                                                    state.email.error,
                                                showValidationIndicator: false,
                                                suffixIcon: isCheckingMethods
                                                    ? const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                            ),
                                                      )
                                                    : null,
                                                onChanged: (v) => context
                                                    .read<LoginCubit>()
                                                    .emailChanged(v),
                                                onSubmitted: (_) =>
                                                    FocusScope.of(
                                                      context,
                                                    ).nextFocus(),
                                              ),

                                              const SizedBox(height: 16),

                                              CustomText(
                                                label: 'Contraseña',
                                                controller: _passwordController,
                                                fieldType: FieldType.password,
                                                enabled: !isLoading,
                                                hintText: '••••••••',
                                                borderColor: AppColors.blue2,
                                                borderWidth: 0.6,
                                                required: true,
                                                autovalidateMode:
                                                    AutovalidateModeX
                                                        .afterSubmit,
                                                submitSignal: _submitSignal,
                                                externalError:
                                                    state.password.error,
                                                showValidationIndicator: false,
                                                onChanged: (v) => context
                                                    .read<LoginCubit>()
                                                    .passwordChanged(v),
                                                onSubmitted: (_) {
                                                  if (!isLoading) {
                                                    FocusManager
                                                        .instance
                                                        .primaryFocus
                                                        ?.unfocus();
                                                    context
                                                        .read<LoginCubit>()
                                                        .login();
                                                  }
                                                },
                                              ),

                                              const SizedBox(height: 15),

                                              CustomButton(
                                                text: 'Iniciar Sesión',
                                                borderWidth: 1,
                                                // enableGlow: true,
                                                height: 35,
                                                backgroundColor: AppColors.blue2,
                                                isLoading: isLoading,
                                                // glowIntensity: 0.5,
                                                onPressed: isLoading
                                                    ? null
                                                    : () {
                                                        FocusManager
                                                            .instance
                                                            .primaryFocus
                                                            ?.unfocus();
                                                        context
                                                            .read<LoginCubit>()
                                                            .login();
                                                      },
                                              ),

                                              const SizedBox(height: 8),

                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  TextButton(
                                                    onPressed: isLoading
                                                        ? null
                                                        : _closePasswordCard,
                                                    child: const Text('Cerrar', style: TextStyle(color: AppColors.blue3, fontSize: 12),),
                                                  ),
                                                  TextButton(
                                                    onPressed: isLoading
                                                        ? null
                                                        : () => context.push(
                                                            '/forgot-password',
                                                          ),
                                                    child: const Text(
                                                      '¿Olvidaste tu contraseña?', style: TextStyle(color: AppColors.blue3, fontSize: 12)
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  : const SizedBox(
                                      key: ValueKey('password_card_hidden'),
                                    ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      CustomButton(
                        text: 'Crear Cuenta',
                        isOutlined: true,
                        enableShadow: true,
                        onPressed: isLoading
                            ? null
                            : () => context.push('/register'),
                        borderWidth: 0.6,
                        enableGlow: true,
                        borderColor: AppColors.blue2,
                        backgroundColor: Colors.white,
                        textColor: AppColors.blue2,
                        glowIntensity: 0.3,
                      ),
                      SizedBox(height: 100)
                    ],

                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showEmailNotVerifiedDialog(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.mark_email_unread_outlined,
          color: Colors.orange,
          size: 48,
        ),
        title: const Text('Email no verificado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Debes verificar tu correo electrónico antes de iniciar sesión.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              email,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/verify-email', extra: email);
            },
            child: const Text('Ir a verificar'),
          ),
        ],
      ),
    );
  }
}
