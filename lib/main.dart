// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_aula/models/form_model.dart';
import 'package:pro_aula/screens/ProfileScreen.dart';
import 'package:pro_aula/screens/ai_physics_assistant_screen.dart';
import 'package:pro_aula/screens/auth_screen.dart';
import 'package:pro_aula/screens/courses_screen.dart';
import 'package:pro_aula/screens/evaluation_screen.dart';
import 'package:pro_aula/screens/exercise_screen.dart';
import 'package:pro_aula/screens/reset_password_screen.dart';
import 'package:pro_aula/screens/home_screen.dart';
import 'package:pro_aula/screens/physics_nearby_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importar el tema personalizado
import 'core/theme/app_theme.dart';

// Importar pantallas
import 'screens/splash_screen.dart';

Future<void> main() async {
  // Asegurar que los widgets estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar orientación de la app (solo vertical)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configurar barra de estado con tonos cálidos
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Inicializar Supabase
  await Supabase.initialize(
    url: 'https://hhhtrxaukmgiseubygky.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhoaHRyeGF1a21naXNldWJ5Z2t5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkwMDk0MDYsImV4cCI6MjA2NDU4NTQwNn0.KLRKuD8iKBWxRXtapl5W7t2JFJshRn4f3UyGbtG59-0',
  );

  // Ejecutar la aplicación
  runApp(ProviderScope(child: const PhysicsAIApp()));
}

// Cliente de Supabase global
final supabase = Supabase.instance.client;

class PhysicsAIApp extends StatefulWidget {
  const PhysicsAIApp({super.key});

  @override
  State<PhysicsAIApp> createState() => _PhysicsAIAppState();
}

class _PhysicsAIAppState extends State<PhysicsAIApp> {
  // GlobalKey para acceder al Navigator desde cualquier lugar
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    // Escuchar cambios en el estado de autenticación
    supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final User? user = data.session?.user;

      debugPrint('🔐 Auth Event: $event');

      switch (event) {
        case AuthChangeEvent.passwordRecovery:
          debugPrint('🔑 Password recovery event detected');
          _handlePasswordRecovery();
          break;

        case AuthChangeEvent.signedIn:
          debugPrint('✅ User signed in: ${user?.email}');
          _handleSignedIn();
          break;

        case AuthChangeEvent.signedOut:
          debugPrint('❌ User signed out');
          _handleSignedOut();
          break;

        case AuthChangeEvent.tokenRefreshed:
          debugPrint('🔄 Token refreshed for: ${user?.email}');
          break;

        default:
          debugPrint('📡 Other auth event: $event');
      }
    });
  }

  void _handlePasswordRecovery() {
    // Pequeño delay para asegurar que el contexto esté listo
    Future.delayed(const Duration(milliseconds: 500), () {
      final context = _navigatorKey.currentContext;
      if (context != null && mounted) {
        // Navegar a la pantalla de reset password
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/reset-password',
          (route) => false, // Limpiar el stack de navegación
        );

        // Mostrar mensaje informativo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔑 Ahora puedes cambiar tu contraseña'),
            backgroundColor: AppColors.vibrantRed,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _handleSignedIn() {
    // Cuando el usuario se autentica exitosamente
    Future.delayed(const Duration(milliseconds: 500), () {
      final context = _navigatorKey.currentContext;
      if (context != null && mounted) {
        // Verificar la ruta actual antes de navegar
        final currentRoute = ModalRoute.of(context)?.settings.name;
        if (currentRoute != '/home') {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/home', (route) => false);
        }
      }
    });
  }

  void _handleSignedOut() {
    // Cuando el usuario cierra sesión
    Future.delayed(const Duration(milliseconds: 500), () {
      final context = _navigatorKey.currentContext;
      if (context != null && mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/auth', (route) => false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Configuración básica de la app
      title: 'Física AI',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey, // ¡IMPORTANTE! Agregar esta línea
      // Aplicar tema personalizado con tu paleta
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Se adapta al sistema
      // Configuración de localización (español)
      locale: const Locale('es', 'ES'),

      // Ruta inicial
      initialRoute: '/',

      // Configurar todas las rutas
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/courses': (context) => const CoursesScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/ai-assistant': (context) => const AIPhysicsAssistantScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/physics-nearby': (context) => const PhysicsNearbyScreen(),
      },

      // Configurar generación de rutas para parámetros
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/course-detail':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) =>
                  CourseDetailScreen(courseId: args?['courseId'] ?? ''),
            );
          case '/theme-content':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => ThemeContentScreen(
                themeId: args?['themeId'] ?? '',
                courseId: args?['courseId'] ?? '',
              ),
            );
          case '/exercise':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => ExerciseScreen(
                themeId: args?['themeId'] ?? '',
                courseId: args?['courseId'] ?? '',
                exerciseId: args?['exerciseId'], // Opcional, puede ser null
              ),
            );
          case '/form':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => EvaluationScreen(
                themeId: args?['themeId'] ?? '',
                evaluation: args?['evaluation'],
              ),
            );
          default:
            return null;
        }
      },

      // Configurar página de error 404
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (context) => const NotFoundScreen());
      },

      // Builder para configuraciones globales
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler:
                TextScaler.noScaling, // Evitar escalado excesivo de texto
          ),
          child: child!,
        );
      },
    );
  }

  @override
  void dispose() {
    // Limpiar listeners si es necesario
    super.dispose();
  }
}

// Resto de tus clases existentes...
class CourseDetailScreen extends StatelessWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Curso')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.golden.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.book_rounded,
                size: 80,
                color: AppColors.vibrantRed,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Detalle del Curso',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Course ID: $courseId',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class ThemeContentScreen extends StatelessWidget {
  final String themeId;
  final String courseId;

  const ThemeContentScreen({
    super.key,
    required this.themeId,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contenido del Tema')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.peachy, AppColors.golden.withOpacity(0.3)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.article_rounded,
                size: 80,
                color: AppColors.vibrantRed,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Contenido del Tema',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Theme ID: $themeId',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Página no encontrada')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 80,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '404',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppColors.vibrantRed,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Página no encontrada',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              },
              icon: const Icon(Icons.home_rounded),
              label: const Text('Volver al Inicio'),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget de navegación inferior con tu paleta
class MainBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const MainBottomNavigation({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            if (currentIndex != 0) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
            }
            break;
          case 1:
            if (currentIndex != 1) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/courses',
                (route) => false,
              );
            }
            break;
          case 2:
            if (currentIndex != 2) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/ai-assistant',
                (route) => false,
              );
            }
            break;
          case 3:
            if (currentIndex != 3) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/profile',
                (route) => false,
              );
            }
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school_rounded),
          label: 'Cursos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.psychology_rounded),
          label: 'AI',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Perfil',
        ),
      ],
    );
  }
}
