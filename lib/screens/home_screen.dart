// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pro_aula/core/theme/app_theme.dart';
import 'package:pro_aula/models/course_model.dart';
import 'package:pro_aula/models/user_progress.dart';
import 'package:pro_aula/providers/supabase_providers.dart';
import 'package:pro_aula/widgets/main_bottom_navigation.dart';
import 'package:pro_aula/widgets/course_card.dart';
import 'package:pro_aula/widgets/last_viewed_course_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Providers adicionales para HomeScreen
final lastViewedCourseProvider = FutureProvider<Course?>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) return null;

  // Obtener el usuario con su último curso visto
  final userResponse = await supabase
      .from('users')
      .select('last_viewed_course_id')
      .eq('id', userId)
      .maybeSingle();

  if (userResponse == null || userResponse['last_viewed_course_id'] == null) {
    return null;
  }

  // Obtener el curso completo
  final courseResponse = await supabase
      .from('courses')
      .select('*, themes(*)')
      .eq('id', userResponse['last_viewed_course_id'])
      .maybeSingle();

  return courseResponse != null ? Course.fromJson(courseResponse) : null;
});

final userOverallProgressProvider = FutureProvider<double>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) return 0.0;

  // Calcular progreso general del usuario
  final progressResponse = await supabase
      .from('user_progress')
      .select('progress_percentage, is_completed')
      .eq('user_id', userId);

  if (progressResponse.isEmpty) return 0.0;

  double totalProgress = 0.0;
  int completedThemes = 0;

  for (final progress in progressResponse) {
    if (progress['is_completed'] == true) {
      completedThemes++;
    }
    totalProgress += (progress['progress_percentage'] as num).toDouble();
  }

  return progressResponse.length > 0
      ? totalProgress / progressResponse.length
      : 0.0;
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredCoursesProvider = Provider<AsyncValue<List<Course>>>((ref) {
  final coursesAsync = ref.watch(coursesProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  return coursesAsync.whenData((courses) {
    if (searchQuery.isEmpty) return courses;

    return courses.where((course) {
      return course.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (course.description?.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ??
              false);
    }).toList();
  });
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(searchQueryProvider.notifier).state = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    ref.invalidate(coursesProvider);
    ref.invalidate(lastViewedCourseProvider);
    ref.invalidate(userOverallProgressProvider);
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final isGuest = user == null;

    return Scaffold(
      appBar: _buildAppBar(context, isGuest),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.vibrantRed,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarjeta de bienvenida
              _buildWelcomeCard(context, isGuest),

              const SizedBox(height: 32),

              // Acciones rápidas
              _buildQuickActions(context),

              const SizedBox(height: 32),

              // Campo de búsqueda
              _buildSearchField(),

              const SizedBox(height: 32),

              // Continúa donde lo dejaste (solo si no es invitado)
              if (!isGuest) ...[
                _buildContinueLearningSection(),
                const SizedBox(height: 32),
              ],

              // Cursos disponibles
              _buildCoursesSection(),

              const SizedBox(height: 32),

              // Categorías
              _buildCategoriesSection(),

              const SizedBox(height: 100), // Espacio para el FAB
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 0),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isGuest) {
    return AppBar(
      title: const Text('Física AI'),
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // TODO: Implementar notificaciones
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notificaciones próximamente'),
                backgroundColor: AppColors.vibrantRed,
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(isGuest ? Icons.login : Icons.account_circle_outlined),
          onPressed: () {
            if (isGuest) {
              Navigator.pushNamed(context, '/auth');
            } else {
              Navigator.pushNamed(context, '/profile');
            }
          },
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(BuildContext context, bool isGuest) {
    if (isGuest) {
      return _buildGuestWelcomeCard(context);
    }

    return Consumer(
      builder: (context, ref, child) {
        final progressAsync = ref.watch(userOverallProgressProvider);

        return Card(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.vibrantRed, AppColors.golden],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.science_outlined,
                  color: AppColors.surface,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  '¡Hola! Continuemos aprendiendo',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu progreso semanal ha sido excelente',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.surface.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 20),

                // Barra de progreso
                progressAsync.when(
                  loading: () => const LinearProgressIndicator(
                    backgroundColor: AppColors.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.peachy),
                  ),
                  error: (error, stack) => Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: AppColors.surface.withOpacity(0.3),
                    ),
                  ),
                  data: (progress) => Column(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: AppColors.surface.withOpacity(0.3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: AppColors.surface,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Progreso general: ${progress.toInt()}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.surface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuestWelcomeCard(BuildContext context) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.golden.withOpacity(0.8), AppColors.peachy],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.explore_outlined,
              color: AppColors.textPrimary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              '¡Bienvenido, explorador!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Descubre el fascinante mundo de la física',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/auth'),
              icon: const Icon(Icons.person_add, size: 20),
              label: const Text('Crear cuenta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vibrantRed,
                foregroundColor: AppColors.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Acciones rápidas', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/courses'),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Continuar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/courses'),
                icon: const Icon(Icons.explore_outlined),
                label: const Text('Explorar'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/ai-assistant'),
            icon: const Icon(Icons.psychology_outlined),
            label: const Text('Asistente AI'),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Consumer(
      builder: (context, ref, child) {
        return TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Buscar cursos de física',
            hintText: 'Mecánica, Óptica, Termodinámica...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  )
                : IconButton(
                    icon: const Icon(Icons.tune_rounded),
                    onPressed: () {
                      // TODO: Implementar filtros
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Filtros próximamente'),
                          backgroundColor: AppColors.vibrantRed,
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _buildContinueLearningSection() {
    return Consumer(
      builder: (context, ref, child) {
        final lastViewedAsync = ref.watch(lastViewedCourseProvider);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Continúa donde lo dejaste',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            lastViewedAsync.when(
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, stack) => const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Error al cargar el último curso'),
                ),
              ),
              data: (course) {
                if (course == null) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.start,
                            size: 48,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Aún no has comenzado ningún curso',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          FilledButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/courses'),
                            child: const Text('Explorar cursos'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return LastViewedCourseCard(course: course);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCoursesSection() {
    return Consumer(
      builder: (context, ref, child) {
        final coursesAsync = ref.watch(filteredCoursesProvider);
        final searchQuery = ref.watch(searchQueryProvider);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  searchQuery.isEmpty
                      ? 'Cursos destacados'
                      : 'Resultados de búsqueda',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (searchQuery.isEmpty)
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/courses'),
                    child: const Text('Ver todos'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            coursesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 8),
                      Text('Error al cargar cursos: $error'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(coursesProvider),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (courses) {
                if (courses.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 48,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            searchQuery.isEmpty
                                ? 'No hay cursos disponibles'
                                : 'No se encontraron cursos para "$searchQuery"',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final displayCourses = searchQuery.isEmpty
                    ? courses.take(6).toList()
                    : courses;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: displayCourses.length,
                  itemBuilder: (context, index) {
                    return CourseCard(course: displayCourses[index]);
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoriesSection() {
    final categories = [
      {
        'name': 'Mecánica',
        'icon': Icons.motion_photos_on,
        'color': AppColors.vibrantRed,
      },
      {
        'name': 'Óptica',
        'icon': Icons.lightbulb_outline,
        'color': AppColors.golden,
      },
      {
        'name': 'Termodinámica',
        'icon': Icons.thermostat,
        'color': AppColors.peachy,
      },
      {
        'name': 'Electricidad',
        'icon': Icons.flash_on,
        'color': AppColors.aiAccent,
      },
      {
        'name': 'Ondas',
        'icon': Icons.graphic_eq,
        'color': AppColors.progressGreen,
      },
      {
        'name': 'Física Moderna',
        'icon': Icons.science,
        'color': AppColors.physicsAccent,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explora por categorías',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((category) {
            return ActionChip(
              label: Text(category['name'] as String),
              avatar: Icon(
                category['icon'] as IconData,
                size: 18,
                color: category['color'] as Color,
              ),
              onPressed: () {
                // Filtrar por categoría
                _searchController.text = category['name'] as String;
                ref.read(searchQueryProvider.notifier).state =
                    category['name'] as String;
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.pushNamed(context, '/ai-assistant'),
      icon: const Icon(Icons.psychology_rounded),
      label: const Text('Pregunta a la IA'),
      backgroundColor: AppColors.golden,
      foregroundColor: AppColors.textPrimary,
    );
  }
}
