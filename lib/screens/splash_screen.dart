// lib/screens/splash_screen.dart

// Importar dart:math para el efecto flotante
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;
  late AnimationController _backgroundController;

  late Animation<double> _logoAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _backgroundAnimation;

  String _loadingText = 'Iniciando Física AI...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startInitialization();
  }

  void _initializeAnimations() {
    // Animación del logo (escala y fade)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Animación del progreso
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Animación del fondo
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    // Iniciar animaciones
    _logoController.forward();
    _backgroundController.repeat(reverse: true);

    // Escuchar cambios en la animación del progreso
    _progressAnimation.addListener(() {
      setState(() {
        _progress = _progressAnimation.value;
      });
    });
  }

  Future<void> _startInitialization() async {
    try {
      // Esperar un poco para que se vean las animaciones
      await Future.delayed(const Duration(milliseconds: 800));

      // Paso 1: Verificar conexión a Supabase
      await _updateProgress('Conectando a Supabase...', 0.15);
      await Future.delayed(const Duration(milliseconds: 600));

      // Verificar si Supabase está inicializado
      final supabase = Supabase.instance.client;

      // Paso 2: Verificar autenticación
      await _updateProgress('Verificando sesión de usuario...', 0.35);
      await Future.delayed(const Duration(milliseconds: 600));

      final session = supabase.auth.currentSession;

      // Paso 3: Cargar configuraciones
      await _updateProgress('Cargando configuraciones...', 0.55);
      await Future.delayed(const Duration(milliseconds: 600));

      // Paso 4: Preparar interfaz
      await _updateProgress('Preparando interfaz...', 0.75);
      await Future.delayed(const Duration(milliseconds: 600));

      // Paso 5: Sincronizar datos
      await _updateProgress('Sincronizando datos...', 0.90);
      await Future.delayed(const Duration(milliseconds: 600));

      // Paso 6: Finalizar
      await _updateProgress('¡Todo listo!', 1.0);
      await Future.delayed(const Duration(milliseconds: 800));

      // Navegar a la pantalla apropiada
      if (mounted) {
        if (session != null) {
          // Usuario autenticado - ir al Dashboard
          _navigateToHome();
        } else {
          // Usuario no autenticado - ir a Auth
          _navigateToAuth();
        }
      }
    } catch (error) {
      // Manejar errores
      if (mounted) {
        await _updateProgress('Error de conexión', 1.0);
        await Future.delayed(const Duration(milliseconds: 1000));
        _showErrorDialog(error.toString());
      }
    }
  }

  Future<void> _updateProgress(String text, double progress) async {
    if (mounted) {
      setState(() {
        _loadingText = text;
      });

      // Animar el progreso
      await _progressController.animateTo(progress);
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _navigateToAuth() {
    Navigator.of(context).pushReplacementNamed('/auth');
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Error de Conexión'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text('No se pudo inicializar la aplicación:\n$error'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startInitialization(); // Reintentar
            },
            child: const Text('Reintentar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToAuth(); // Continuar sin conexión
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.vibrantRed,
                  Color.lerp(
                    AppColors.vibrantRed,
                    AppColors.golden,
                    _backgroundAnimation.value * 0.3,
                  )!,
                  AppColors.golden,
                  Color.lerp(
                    AppColors.golden,
                    AppColors.peachy,
                    _backgroundAnimation.value * 0.2,
                  )!,
                ],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo y título principal con animaciones
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoAnimation.value,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              // Logo principal con efectos visuales
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppColors.surface,
                                      AppColors.peachy,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 24,
                                      offset: const Offset(0, 12),
                                    ),
                                    BoxShadow(
                                      color: AppColors.golden.withOpacity(0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.science_outlined,
                                  size: 70,
                                  color: AppColors.vibrantRed,
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Título de la app con sombra
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: AppColors.surface.withOpacity(0.1),
                                  border: Border.all(
                                    color: AppColors.surface.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  'Física AI',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.surface,
                                    letterSpacing: 3,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(2, 2),
                                        blurRadius: 4,
                                        color: Colors.black26,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Subtítulo con efecto
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: AppColors.surface.withOpacity(0.1),
                                ),
                                child: Text(
                                  'Aprende Física con Inteligencia Artificial',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.surface.withOpacity(0.95),
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const Spacer(flex: 2),

                  // Sección de carga con diseño mejorado
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Column(
                      children: [
                        // Barra de progreso con gradiente
                        Container(
                          width: double.infinity,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              return FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _progress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.surface,
                                        AppColors.peachy,
                                        AppColors.golden,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.surface.withOpacity(
                                          0.6,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Texto de carga con animación
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Container(
                            key: ValueKey(_loadingText),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: AppColors.surface.withOpacity(0.1),
                            ),
                            child: Text(
                              _loadingText,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.surface.withOpacity(0.95),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Porcentaje con estilo
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.surface.withOpacity(0.1),
                          ),
                          child: Text(
                            '${(_progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.surface.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Indicadores de física flotantes
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFloatingIcon(Icons.motion_photos_on, 'Mecánica'),
                        _buildFloatingIcon(Icons.lightbulb_outline, 'Óptica'),
                        _buildFloatingIcon(Icons.flash_on, 'Electricidad'),
                        _buildFloatingIcon(Icons.thermostat, 'Térmica'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Footer con versión
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.surface.withOpacity(0.1),
                    ),
                    child: Text(
                      'v1.0.0 • © 2024 Física AI',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.surface.withOpacity(0.7),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingIcon(IconData icon, String label) {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            math.sin(_backgroundAnimation.value * 2 * math.pi) * 3,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.surface.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: AppColors.surface.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.surface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
