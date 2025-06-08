import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_theme.dart';
import '../services/auth_service.dart';
// Para el icono de Google, si quieres uno más estilizado (opcional)
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false; // Para el formulario de email/contraseña
  bool _isLoadingGoogle = false; // Para el botón de Google
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
      _isLoading = false;
      _isLoadingGoogle = false;
    });
    _clearForm();
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
    _confirmPasswordController.clear();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu correo';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Correo inválido';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu nombre';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Confirma tu contraseña';
    if (value != _passwordController.text)
      return 'Las contraseñas no coinciden';
    return null;
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await _authService.signIn(
        _emailController.text,
        _passwordController.text,
      );
      if (user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
      // Si user es null y no hay error, podría ser que el inicio de sesión no fue exitoso
      // pero signIn en AuthService no lanza error. Ajustar si es necesario.
    } on AuthException catch (error) {
      if (mounted)
        setState(() {
          _errorMessage = _authService.getErrorMessage(error.message);
        });
    } catch (error) {
      if (mounted)
        setState(() {
          _errorMessage = _authService.getErrorMessage(error.toString());
        });
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  Future<void> _signUpWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await _authService.signUp(
        _emailController.text,
        _passwordController.text,
        _nameController.text,
      );
      if (user != null && mounted) {
        _showSuccessDialog();
      }
    } on AuthException catch (error) {
      if (mounted)
        setState(() {
          _errorMessage = _authService.getErrorMessage(error.message);
        });
    } catch (error) {
      if (mounted)
        setState(() {
          _errorMessage = _authService.getErrorMessage(error.toString());
        });
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  // --- Inicio de sesión NATIVO con Google ---
  Future<void> _handleNativeGoogleSignIn() async {
    setState(() {
      _isLoadingGoogle = true;
      _errorMessage = null;
    });
    try {
      final user = await _authService.signInWithGoogleNative();
      if (user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
      // Si el user es null y no hubo excepción, el flujo podría haber sido cancelado
      // y AuthService.signInWithGoogleNative debería haber lanzado una excepción.
    } on AuthException catch (error) {
      // Errores específicos de Supabase
      if (mounted) {
        setState(() {
          _errorMessage = _authService.getErrorMessage(error.message);
        });
      }
    } catch (error) {
      // Otros errores (incluyendo los que lanzaste desde signInWithGoogleNative)
      if (mounted) {
        setState(() {
          _errorMessage = _authService.getErrorMessage(error.toString());
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingGoogle = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: isDark
            ? AppColors.darkSurfaceLight
            : AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 28),
            const SizedBox(width: 12),
            Text(
              '¡Éxito!',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Revisa tu email para confirmar tu cuenta.',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _toggleAuthMode();
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final TextEditingController emailResetController = TextEditingController(
      text: _emailController.text.trim(),
    );
    String? resetErrorMessage;
    bool isResetLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext contextInDialog, setStateInDialog) {
            return AlertDialog(
              backgroundColor:
                  Theme.of(contextInDialog).brightness == Brightness.dark
                  ? AppColors.darkSurfaceLight
                  : AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Restablecer Contraseña',
                style: TextStyle(
                  color: Theme.of(contextInDialog).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ingresa tu correo electrónico para recibir un enlace de restablecimiento.',
                    style: TextStyle(
                      color:
                          Theme.of(contextInDialog).brightness ==
                              Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailResetController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(
                      color:
                          Theme.of(contextInDialog).brightness ==
                              Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      hintText: 'tu@email.com',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color:
                            Theme.of(contextInDialog).brightness ==
                                Brightness.dark
                            ? AppColors.textLight
                            : AppColors.textTertiary,
                      ),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color:
                              Theme.of(contextInDialog).brightness ==
                                  Brightness.dark
                              ? AppColors.golden.withOpacity(0.3)
                              : AppColors.border.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color:
                              Theme.of(contextInDialog).brightness ==
                                  Brightness.dark
                              ? AppColors.golden
                              : AppColors.vibrantRed,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.error,
                          width: 1,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.error,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  if (resetErrorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        resetErrorMessage!,
                        style: const TextStyle(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    emailResetController.dispose();
                    Navigator.of(contextInDialog).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isResetLoading
                      ? null
                      : () async {
                          if (emailResetController.text.trim().isEmpty ||
                              !RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(emailResetController.text.trim())) {
                            setStateInDialog(() {
                              resetErrorMessage =
                                  'Por favor, ingresa un correo electrónico válido.';
                            });
                            return;
                          }
                          setStateInDialog(() {
                            isResetLoading = true;
                            resetErrorMessage = null;
                          });
                          try {
                            await _authService.resetPasswordForEmail(
                              emailResetController.text.trim(),
                              // TODO: Reemplaza esto con tu deep link real
                              redirectTo: 'proaula://reset-password-callback/',
                            );
                            if (contextInDialog.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Enlace de restablecimiento enviado. Revisa tu email.',
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              Navigator.of(dialogContext).pop();
                            }
                          } on AuthException catch (error) {
                            setStateInDialog(() {
                              resetErrorMessage = _authService.getErrorMessage(
                                error.message,
                              );
                            });
                          } catch (error) {
                            setStateInDialog(() {
                              resetErrorMessage = _authService.getErrorMessage(
                                error.toString(),
                              );
                            });
                          } finally {
                            if (mounted) {
                              setStateInDialog(() {
                                isResetLoading = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vibrantRed,
                    foregroundColor: AppColors.surface,
                  ),
                  child: isResetLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.surface,
                            ),
                          ),
                        )
                      : const Text('Enviar Enlace'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                const SizedBox(height: 60),
                _buildCleanHeader(),
                const SizedBox(height: 48),
                _buildModernForm(),
                const SizedBox(height: 24),
                _buildSocialLogins(),
                const SizedBox(height: 24),
                _buildGuestOption(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCleanHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceLight : AppColors.peachy,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.vibrantRed.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.science_outlined,
            size: 50,
            color: isDark ? AppColors.golden : AppColors.vibrantRed,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          _isLogin ? '¡Hola de nuevo!' : '¡Únete a nosotros!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin
              ? 'Te extrañamos por aquí'
              : 'Comienza tu aventura en física',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? AppColors.textLight : AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildModernForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceLight : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.golden.withOpacity(0.3) : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (!_isLogin) ...[
              _buildCleanTextField(
                controller: _nameController,
                label: 'Nombre',
                hint: 'Tu nombre completo',
                icon: Icons.person_outline,
                validator: _validateName,
              ),
              const SizedBox(height: 20),
            ],
            _buildCleanTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'tu@email.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            const SizedBox(height: 20),
            _buildCleanTextField(
              controller: _passwordController,
              label: 'Contraseña',
              hint: 'Mínimo 6 caracteres',
              icon: Icons.lock_outline,
              isPassword: true,
              isPasswordVisible: _isPasswordVisible,
              onTogglePassword: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
              validator: _validatePassword,
            ),
            if (!_isLogin) ...[
              const SizedBox(height: 20),
              _buildCleanTextField(
                controller: _confirmPasswordController,
                label: 'Confirmar contraseña',
                hint: 'Repite tu contraseña',
                icon: Icons.lock_outline,
                isPassword: true,
                isPasswordVisible: _isConfirmPasswordVisible,
                onTogglePassword: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
                validator: _validateConfirmPassword,
              ),
            ],
            if (_isLogin) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading || _isLoadingGoogle
                      ? null
                      : _showForgotPasswordDialog,
                  child: Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.golden : AppColors.vibrantRed,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading || _isLoadingGoogle
                    ? null
                    : (_isLogin ? _signInWithEmail : _signUpWithEmail),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.vibrantRed,
                  foregroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.surface,
                          ),
                        ),
                      )
                    : Text(
                        _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isLogin ? '¿No tienes cuenta?' : '¿Ya tienes cuenta?',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textLight
                        : AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                TextButton(
                  onPressed: _isLoading || _isLoadingGoogle
                      ? null
                      : _toggleAuthMode,
                  child: Text(
                    _isLogin ? 'Regístrate' : 'Inicia sesión',
                    style: TextStyle(
                      color: isDark ? AppColors.golden : AppColors.vibrantRed,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLogins() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: isDark
                    ? AppColors.golden.withOpacity(0.3)
                    : AppColors.border,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'o continúa con',
                style: TextStyle(
                  color: isDark ? AppColors.textLight : AppColors.textTertiary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: isDark
                    ? AppColors.golden.withOpacity(0.3)
                    : AppColors.border,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            icon: _isLoadingGoogle
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark
                          ? AppColors.textLight
                          : AppColors.textPrimary,
                    ),
                  )
                // Puedes usar una imagen/logo de Google si lo prefieres
                // : FaIcon(FontAwesomeIcons.google, color: Colors.redAccent), // Ejemplo con FontAwesome
                : Icon(
                    Icons.g_mobiledata_rounded,
                    color: Colors.redAccent,
                    size: 28,
                  ), // Icono simple de G
            label: Text(
              'Iniciar sesión con Google',
              style: TextStyle(
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: _isLoading || _isLoadingGoogle
                ? null
                : _handleNativeGoogleSignIn,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isDark
                    ? AppColors.golden.withOpacity(0.5)
                    : AppColors.border,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: isDark
                  ? AppColors.darkSurfaceLight.withOpacity(0.5)
                  : AppColors.surface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCleanTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool? isPasswordVisible,
    VoidCallback? onTogglePassword,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: isPassword && !(isPasswordVisible ?? false),
          style: TextStyle(
            fontSize: 16,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? AppColors.textLight : AppColors.textTertiary,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: isDark ? AppColors.textLight : AppColors.textTertiary,
              size: 20,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isPasswordVisible!
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: isDark
                          ? AppColors.textLight
                          : AppColors.textTertiary,
                      size: 20,
                    ),
                    onPressed: onTogglePassword,
                  )
                : null,
            filled: true,
            fillColor: isDark
                ? AppColors.darkSurface.withOpacity(0.5)
                : AppColors.peachy.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark
                    ? AppColors.golden.withOpacity(0.3)
                    : AppColors.border.withOpacity(0.5),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.golden : AppColors.vibrantRed,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestOption() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed: _isLoading || _isLoadingGoogle
                ? null
                : () {
                    Navigator.pushReplacementNamed(context, '/home');
                  },
            icon: const Icon(Icons.explore_outlined, color: AppColors.golden),
            label: const Text(
              'Explorar como invitado',
              style: TextStyle(
                color: AppColors.golden,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.golden, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: isDark
                  ? AppColors.golden.withOpacity(0.05)
                  : Colors.transparent,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Podrás crear una cuenta más tarde',
          style: TextStyle(
            color: isDark ? AppColors.textLight : AppColors.textTertiary,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
