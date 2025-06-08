// lib/screens/courses_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_aula/core/theme/app_theme.dart';
import 'package:pro_aula/models/course_model.dart';
import 'package:pro_aula/providers/supabase_providers.dart';
import 'package:pro_aula/screens/home_screen.dart';
import 'package:pro_aula/widgets/main_bottom_navigation.dart';
import 'package:pro_aula/widgets/course_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Providers para la pantalla de cursos
final coursesSearchProvider = StateProvider<String>((ref) => '');
final selectedDifficultyProvider = StateProvider<String?>((ref) => null);
final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final coursesViewModeProvider = StateProvider<bool>(
  (ref) => true,
); // true = grid, false = list

// Provider para cursos filtrados
final filteredCoursesProvider = Provider<AsyncValue<List<Course>>>((ref) {
  final coursesAsync = ref.watch(coursesProvider);
  final searchQuery = ref.watch(coursesSearchProvider);
  final selectedDifficulty = ref.watch(selectedDifficultyProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);

  return coursesAsync.whenData((courses) {
    var filteredCourses = courses;

    // Filtro por búsqueda
    if (searchQuery.isNotEmpty) {
      filteredCourses = filteredCourses.where((course) {
        return course.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
            (course.description?.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ??
                false);
      }).toList();
    }

    // Filtro por dificultad
    if (selectedDifficulty != null) {
      filteredCourses = filteredCourses.where((course) {
        return course.difficulty.toLowerCase() ==
            selectedDifficulty.toLowerCase();
      }).toList();
    }

    // Filtro por categoría (basado en el título o contenido)
    if (selectedCategory != null) {
      filteredCourses = filteredCourses.where((course) {
        return course.title.toLowerCase().contains(
              selectedCategory!.toLowerCase(),
            ) ||
            (course.description?.toLowerCase().contains(
                  selectedCategory!.toLowerCase(),
                ) ??
                false);
      }).toList();
    }

    return filteredCourses;
  });
});

class CoursesScreen extends ConsumerStatefulWidget {
  const CoursesScreen({super.key});

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Categorías disponibles
  final List<Map<String, dynamic>> _categories = [
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(coursesSearchProvider.notifier).state = _searchController.text;
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
  }

  void _clearFilters() {
    _searchController.clear();
    ref.read(coursesSearchProvider.notifier).state = '';
    ref.read(selectedDifficultyProvider.notifier).state = null;
    ref.read(selectedCategoryProvider.notifier).state = null;
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGridView = ref.watch(coursesViewModeProvider);
    final filteredCoursesAsync = ref.watch(filteredCoursesProvider);
    final searchQuery = ref.watch(coursesSearchProvider);
    final selectedDifficulty = ref.watch(selectedDifficultyProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    final hasActiveFilters =
        searchQuery.isNotEmpty ||
        selectedDifficulty != null ||
        selectedCategory != null;

    return Scaffold(
      appBar: _buildAppBar(context, hasActiveFilters),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.vibrantRed,
        child: Column(
          children: [
            // Header con estadísticas y búsqueda
            _buildHeader(context),

            // Chips de filtros activos
            if (hasActiveFilters) _buildActiveFiltersChips(),

            // Lista/Grid de cursos
            Expanded(
              child: filteredCoursesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorWidget(error),
                data: (courses) => _buildCoursesContent(courses, isGridView),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 1),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool hasActiveFilters,
  ) {
    return AppBar(
      title: const Text('Cursos de Física'),
      automaticallyImplyLeading: false,
      actions: [
        // Alternar vista
        Consumer(
          builder: (context, ref, child) {
            final isGridView = ref.watch(coursesViewModeProvider);
            return IconButton(
              icon: Icon(isGridView ? Icons.view_list : Icons.grid_view),
              onPressed: () {
                ref.read(coursesViewModeProvider.notifier).state = !isGridView;
              },
            );
          },
        ),
        // Filtros
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.filter_list),
              if (hasActiveFilters)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.vibrantRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: _showFilterBottomSheet,
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Buscar cursos',
              hintText: 'Mecánica cuántica, ondas, etc...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(coursesSearchProvider.notifier).state = '';
                      },
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 16),

          // Estadísticas rápidas
          Consumer(
            builder: (context, ref, child) {
              final coursesAsync = ref.watch(coursesProvider);

              return coursesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (error, stack) => const SizedBox.shrink(),
                data: (courses) => Row(
                  children: [
                    _buildStatChip(
                      icon: Icons.school_outlined,
                      label: '${courses.length} cursos',
                      color: AppColors.vibrantRed,
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      icon: Icons.person_outline,
                      label: user != null ? 'Inscrito' : 'Invitado',
                      color: user != null
                          ? AppColors.progressGreen
                          : AppColors.golden,
                    ),
                    const Spacer(),
                    if (user == null)
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/auth'),
                        icon: const Icon(Icons.login, size: 16),
                        label: const Text('Iniciar Sesión'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersChips() {
    return Consumer(
      builder: (context, ref, child) {
        final searchQuery = ref.watch(coursesSearchProvider);
        final selectedDifficulty = ref.watch(selectedDifficultyProvider);
        final selectedCategory = ref.watch(selectedCategoryProvider);

        final activeFilters = <Widget>[];

        if (searchQuery.isNotEmpty) {
          activeFilters.add(
            _buildFilterChip(
              label: 'Búsqueda: "$searchQuery"',
              onRemove: () {
                _searchController.clear();
                ref.read(coursesSearchProvider.notifier).state = '';
              },
            ),
          );
        }

        if (selectedDifficulty != null) {
          activeFilters.add(
            _buildFilterChip(
              label: 'Dificultad: $selectedDifficulty',
              onRemove: () {
                ref.read(selectedDifficultyProvider.notifier).state = null;
              },
            ),
          );
        }

        if (selectedCategory != null) {
          activeFilters.add(
            _buildFilterChip(
              label: 'Categoría: $selectedCategory',
              onRemove: () {
                ref.read(selectedCategoryProvider.notifier).state = null;
              },
            ),
          );
        }

        if (activeFilters.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtros activos:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text(
                      'Limpiar todo',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              Wrap(spacing: 8, runSpacing: 4, children: activeFilters),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: AppColors.vibrantRed.withOpacity(0.1),
      deleteIconColor: AppColors.vibrantRed,
      side: BorderSide(color: AppColors.vibrantRed.withOpacity(0.3)),
    );
  }

  Widget _buildCoursesContent(List<Course> courses, bool isGridView) {
    if (courses.isEmpty) {
      return _buildEmptyState();
    }

    if (isGridView) {
      return _buildGridView(courses);
    } else {
      return _buildListView(courses);
    }
  }

  Widget _buildGridView(List<Course> courses) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.70, // Reducido de 0.72 a 0.70 para más altura
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          return CourseCard(course: courses[index]);
        },
      ),
    );
  }

  Widget _buildListView(List<Course> courses) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildCourseListTile(courses[index]),
        );
      },
    );
  }

  Widget _buildCourseListTile(Course course) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.peachy,
            borderRadius: BorderRadius.circular(8),
          ),
          child: course.thumbnailUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    course.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.science_outlined,
                      color: AppColors.vibrantRed,
                    ),
                  ),
                )
              : const Icon(Icons.science_outlined, color: AppColors.vibrantRed),
        ),
        title: Text(
          course.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (course.description?.isNotEmpty == true)
              Text(
                course.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(
                      course.difficulty,
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    course.difficulty,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _getDifficultyColor(course.difficulty),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${course.themes?.length ?? 0} temas',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/course-detail',
            arguments: {'courseId': course.id},
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final searchQuery = ref.watch(coursesSearchProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.peachy,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off,
                size: 64,
                color: AppColors.vibrantRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              searchQuery.isNotEmpty
                  ? 'No se encontraron cursos'
                  : 'No hay cursos disponibles',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isNotEmpty
                  ? 'Intenta con otros términos de búsqueda o ajusta los filtros'
                  : 'Los cursos se agregarán pronto',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (searchQuery.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text('Limpiar filtros'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 24),
            Text(
              'Error al cargar cursos',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBottomSheet() {
    return Consumer(
      builder: (context, ref, child) {
        final selectedDifficulty = ref.watch(selectedDifficultyProvider);
        final selectedCategory = ref.watch(selectedCategoryProvider);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filtros',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _clearFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('Limpiar todo'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Filtro por dificultad
              Text(
                'Dificultad',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ['Beginner', 'Intermediate', 'Advanced'].map((
                  difficulty,
                ) {
                  final isSelected = selectedDifficulty == difficulty;
                  return FilterChip(
                    label: Text(difficulty),
                    selected: isSelected,
                    onSelected: (selected) {
                      ref.read(selectedDifficultyProvider.notifier).state =
                          selected ? difficulty : null;
                    },
                    backgroundColor: _getDifficultyColor(
                      difficulty,
                    ).withOpacity(0.1),
                    selectedColor: _getDifficultyColor(
                      difficulty,
                    ).withOpacity(0.3),
                    checkmarkColor: _getDifficultyColor(difficulty),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Filtro por categoría
              Text(
                'Categorías',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((category) {
                  final isSelected = selectedCategory == category['name'];
                  return FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category['icon'] as IconData,
                          size: 16,
                          color: category['color'] as Color,
                        ),
                        const SizedBox(width: 4),
                        Text(category['name'] as String),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      ref.read(selectedCategoryProvider.notifier).state =
                          selected ? category['name'] as String : null;
                    },
                    backgroundColor: (category['color'] as Color).withOpacity(
                      0.1,
                    ),
                    selectedColor: (category['color'] as Color).withOpacity(
                      0.3,
                    ),
                    checkmarkColor: category['color'] as Color,
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // Botón aplicar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Aplicar filtros'),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => Navigator.pushNamed(context, '/ai-assistant'),
      child: const Icon(Icons.psychology_rounded),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return AppColors.progressGreen;
      case 'intermediate':
        return AppColors.golden;
      case 'advanced':
        return AppColors.vibrantRed;
      default:
        return AppColors.textTertiary;
    }
  }
}
