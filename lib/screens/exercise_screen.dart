// lib/screens/exercise_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_aula/core/theme/app_theme.dart';
import 'package:pro_aula/models/exercise_model.dart';
import 'package:pro_aula/providers/supabase_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider para obtener ejercicios del tema
final themeExercisesListProvider =
    FutureProvider.family<List<Exercise>, String>((ref, themeId) async {
      final supabase = ref.watch(supabaseClientProvider);

      final response = await supabase
          .from('exercises')
          .select('*')
          .eq('theme_id', themeId)
          .order('order_index');

      return response.map((json) => Exercise.fromJson(json)).toList();
    });

// Provider para obtener respuestas del usuario a ejercicios del tema
final userExerciseAnswersProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, themeId) async {
      final supabase = ref.watch(supabaseClientProvider);
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) return {};

      final response = await supabase
          .from('user_answers')
          .select('exercise_id, is_correct, user_answer')
          .eq('user_id', userId)
          .order('answered_at', ascending: false);

      // Agrupar por exercise_id y tomar la respuesta más reciente
      final answersMap = <String, dynamic>{};
      for (final answer in response) {
        final exerciseId = answer['exercise_id'] as String;
        if (!answersMap.containsKey(exerciseId)) {
          answersMap[exerciseId] = answer;
        }
      }

      return answersMap;
    });

// Provider para el progreso de ejercicios
final exerciseProgressProvider =
    StateProvider<({int current, int total, int correct})>((ref) {
      return (current: 0, total: 0, correct: 0);
    });

class ExerciseScreen extends ConsumerStatefulWidget {
  final String themeId;
  final String courseId;
  final String? exerciseId;

  const ExerciseScreen({
    super.key,
    required this.themeId,
    required this.courseId,
    this.exerciseId,
  });

  @override
  ConsumerState<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends ConsumerState<ExerciseScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentExerciseIndex = 0;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextExercise(List<Exercise> exercises) {
    if (_currentExerciseIndex < exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _showResults = false;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _showFinalResults();
    }
  }

  void _previousExercise() {
    if (_currentExerciseIndex > 0) {
      setState(() {
        _currentExerciseIndex--;
        _showResults = false;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showFinalResults() {
    final progress = ref.read(exerciseProgressProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode
            ? AppColors.darkSurfaceLight
            : AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: double.maxFinite,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [
                      AppColors.darkSurface.withOpacity(0.8),
                      AppColors.golden.withOpacity(0.1),
                    ]
                  : [
                      AppColors.golden.withOpacity(0.1),
                      AppColors.peachy.withOpacity(0.2),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header con icono
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.golden, AppColors.vibrantRed],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.golden.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: AppColors.surface,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '¡Ejercicios Completados!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Resultado
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppColors.darkSurface
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkMode
                          ? const Color(0xFF5D4E40)
                          : AppColors.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.3)
                            : AppColors.border.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${progress.correct}',
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.progressGreen,
                                ),
                          ),
                          Text(
                            '/${progress.total}',
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode
                                      ? AppColors.textLight
                                      : AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                      Text(
                        'Respuestas correctas',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDarkMode
                              ? AppColors.textLight
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF5D4E40)
                                  : AppColors.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Container(
                            height: 8,
                            width:
                                (MediaQuery.of(context).size.width - 120) *
                                (progress.total > 0
                                    ? progress.correct / progress.total
                                    : 0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.progressGreen,
                                  AppColors.golden,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.peachy.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getPerformanceMessage(progress.correct, progress.total),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _currentExerciseIndex = 0;
                            _showResults = false;
                          });
                          _pageController.animateToPage(
                            0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: AppColors.golden),
                          foregroundColor: AppColors.golden,
                          backgroundColor: isDarkMode
                              ? AppColors.darkSurface
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Volver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.vibrantRed,
                          foregroundColor: AppColors.surface,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getPerformanceMessage(int correct, int total) {
    if (total == 0) return 'No hay ejercicios disponibles.';

    final percentage = (correct / total) * 100;

    if (percentage >= 90) {
      return '¡Excelente! 🎉 Dominas muy bien este tema.';
    } else if (percentage >= 70) {
      return '¡Muy bien! 👍 Tienes un buen entendimiento.';
    } else if (percentage >= 50) {
      return 'Bien hecho 👌 Puedes mejorar con más práctica.';
    } else {
      return 'Sigue practicando 💪 La práctica hace al maestro.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(
      themeExercisesListProvider(widget.themeId),
    );
    final answersAsync = ref.watch(userExerciseAnswersProvider(widget.themeId));
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [AppColors.darkSurfaceLight, AppColors.darkSurface]
                : [AppColors.vibrantRed, AppColors.vibrantRed.withOpacity(0.8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              _buildCustomAppBar(),

              // Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppColors.darkSurface
                        : AppColors.surfaceLight,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: exercisesAsync.when(
                      loading: () => _buildLoadingWidget(),
                      error: (error, stack) => _buildErrorWidget(error),
                      data: (exercises) {
                        if (exercises.isEmpty) {
                          return _buildEmptyState();
                        }

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final currentProgress = ref.read(
                            exerciseProgressProvider,
                          );
                          if (currentProgress.total != exercises.length) {
                            ref
                                .read(exerciseProgressProvider.notifier)
                                .state = (
                              current: _currentExerciseIndex + 1,
                              total: exercises.length,
                              correct: currentProgress.correct,
                            );
                          }
                        });

                        return answersAsync.when(
                          loading: () => _buildLoadingWidget(),
                          error: (error, stack) => _buildErrorWidget(error),
                          data: (answers) =>
                              _buildExercisesContent(exercises, answers),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.darkTextPrimary.withOpacity(0.2)
                  : AppColors.surface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back,
                color: isDarkMode
                    ? AppColors.darkTextPrimary
                    : AppColors.surface,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ejercicios',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.surface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final progress = ref.watch(exerciseProgressProvider);
                    return Text(
                      'Pregunta ${progress.current} de ${progress.total}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDarkMode
                            ? AppColors.darkTextPrimary.withOpacity(0.8)
                            : AppColors.surface.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Progress badge
          Consumer(
            builder: (context, ref, child) {
              final progress = ref.watch(exerciseProgressProvider);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? AppColors.darkTextPrimary.withOpacity(0.2)
                      : AppColors.surface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.surface,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${progress.correct}',
                      style: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkTextPrimary
                            : AppColors.surface,
                        fontWeight: FontWeight.w600,
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

  Widget _buildLoadingWidget() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.darkSurfaceLight
                  : AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.golden.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.golden),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Cargando ejercicios...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDarkMode ? AppColors.textLight : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesContent(
    List<Exercise> exercises,
    Map<String, dynamic> previousAnswers,
  ) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(exercises.length),

          // Exercises content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentExerciseIndex = index;
                  _showResults = false;
                });

                final currentProgress = ref.read(exerciseProgressProvider);
                ref.read(exerciseProgressProvider.notifier).state = (
                  current: index + 1,
                  total: exercises.length,
                  correct: currentProgress.correct,
                );
              },
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                final previousAnswer = previousAnswers[exercise.id];

                return ExerciseCard(
                  exercise: exercise,
                  exerciseNumber: index + 1,
                  totalExercises: exercises.length,
                  previousAnswer: previousAnswer,
                  showResults: _showResults,
                  onAnswerSubmitted: (isCorrect) {
                    setState(() {
                      _showResults = true;
                    });

                    if (isCorrect) {
                      final currentProgress = ref.read(
                        exerciseProgressProvider,
                      );
                      ref.read(exerciseProgressProvider.notifier).state = (
                        current: currentProgress.current,
                        total: currentProgress.total,
                        correct: currentProgress.correct + 1,
                      );
                    }
                  },
                  onNext: () => _nextExercise(exercises),
                  onPrevious: _currentExerciseIndex > 0
                      ? _previousExercise
                      : null,
                  isLast: index == exercises.length - 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(int totalExercises) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurfaceLight : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : AppColors.border.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progreso',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDarkMode
                            ? AppColors.textLight
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ejercicio ${_currentExerciseIndex + 1} de $totalExercises',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDarkMode
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Consumer(
                builder: (context, ref, child) {
                  final progress = ref.watch(exerciseProgressProvider);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.progressGreen, AppColors.golden],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${progress.correct} correctas',
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF5D4E40)
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 8,
                width:
                    (MediaQuery.of(context).size.width - 80) *
                    ((_currentExerciseIndex + 1) / totalExercises),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.vibrantRed, AppColors.golden],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.peachy.withOpacity(0.3),
                    AppColors.golden.withOpacity(0.3),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.quiz_outlined,
                size: 60,
                color: AppColors.golden,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No hay ejercicios disponibles',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDarkMode
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Este tema aún no tiene ejercicios.\nLos ejercicios se agregarán pronto.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDarkMode
                    ? AppColors.textLight
                    : AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver al Tema'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vibrantRed,
                foregroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 60,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Error al cargar ejercicios',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDarkMode
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Ocurrió un problema al cargar los ejercicios.\nPor favor, inténtalo de nuevo.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDarkMode
                    ? AppColors.textLight
                    : AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vibrantRed,
                foregroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para cada ejercicio individual - DISEÑO COMPLETAMENTE NUEVO
class ExerciseCard extends ConsumerStatefulWidget {
  final Exercise exercise;
  final int exerciseNumber;
  final int totalExercises;
  final Map<String, dynamic>? previousAnswer;
  final bool showResults;
  final Function(bool isCorrect) onAnswerSubmitted;
  final VoidCallback onNext;
  final VoidCallback? onPrevious;
  final bool isLast;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.exerciseNumber,
    required this.totalExercises,
    this.previousAnswer,
    required this.showResults,
    required this.onAnswerSubmitted,
    required this.onNext,
    this.onPrevious,
    required this.isLast,
  });

  @override
  ConsumerState<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends ConsumerState<ExerciseCard>
    with TickerProviderStateMixin {
  final TextEditingController _answerController = TextEditingController();
  String? _selectedAnswer;
  bool _hasAnswered = false;
  bool _isCorrect = false;
  late AnimationController _submitAnimationController;
  late Animation<double> _submitAnimation;

  @override
  void initState() {
    super.initState();
    _submitAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _submitAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _submitAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    if (widget.previousAnswer != null) {
      _answerController.text = widget.previousAnswer!['user_answer'] ?? '';
      _selectedAnswer = widget.previousAnswer!['user_answer'];
      _hasAnswered = true;
      _isCorrect = widget.previousAnswer!['is_correct'] == true;
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    _submitAnimationController.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer() async {
    if (_hasAnswered) return;

    final userAnswer = widget.exercise.exerciseType == 'text_input'
        ? _answerController.text.trim()
        : _selectedAnswer;

    if (userAnswer == null || userAnswer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor, ingresa una respuesta'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final isCorrect = _checkAnswer(userAnswer, widget.exercise.correctAnswer);

    setState(() {
      _hasAnswered = true;
      _isCorrect = isCorrect;
    });

    _submitAnimationController.forward();
    await _saveUserAnswer(userAnswer, isCorrect);
    widget.onAnswerSubmitted(isCorrect);
  }

  bool _checkAnswer(String userAnswer, String correctAnswer) {
    final normalizedUser = userAnswer.toLowerCase().trim();
    final normalizedCorrect = correctAnswer.toLowerCase().trim();
    return normalizedUser == normalizedCorrect;
  }

  Future<void> _saveUserAnswer(String userAnswer, bool isCorrect) async {
    final supabase = ref.read(supabaseClientProvider);
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return;

    try {
      await supabase.from('user_answers').insert({
        'id':
            '${userId}_${widget.exercise.id}_${DateTime.now().millisecondsSinceEpoch}',
        'user_id': userId,
        'exercise_id': widget.exercise.id,
        'user_answer': userAnswer,
        'is_correct': isCorrect,
        'answered_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving user answer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? AppColors.darkSurfaceLight
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : AppColors.golden.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header con número de pregunta y estado
                      _buildQuestionHeader(),

                      const SizedBox(height: 24),

                      // Pregunta
                      _buildQuestionSection(),

                      const SizedBox(height: 32),

                      // Área de respuesta
                      _buildAnswerSection(),

                      // Explicación (solo si ya respondió)
                      if (_hasAnswered && widget.showResults) ...[
                        const SizedBox(height: 24),
                        _buildExplanationSection(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Botones de navegación
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildQuestionHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.golden, AppColors.vibrantRed],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Pregunta ${widget.exerciseNumber}',
            style: const TextStyle(
              color: AppColors.surface,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        const Spacer(),
        if (_hasAnswered && widget.showResults)
          ScaleTransition(
            scale: _submitAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isCorrect ? AppColors.progressGreen : AppColors.error,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color:
                        (_isCorrect ? AppColors.progressGreen : AppColors.error)
                            .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isCorrect ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: AppColors.surface,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isCorrect ? 'Correcta' : 'Incorrecta',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.surface,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuestionSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  AppColors.darkSurface.withOpacity(0.5),
                  AppColors.golden.withOpacity(0.1),
                ]
              : [
                  AppColors.peachy.withOpacity(0.3),
                  AppColors.golden.withOpacity(0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF5D4E40) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.golden,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.help_outline,
                  color: AppColors.surface,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Pregunta',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? AppColors.textLight
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.exercise.question,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: isDarkMode
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.vibrantRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.edit,
                  color: AppColors.surface,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Tu respuesta',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? AppColors.textLight
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: _hasAnswered
                  ? (isDarkMode
                        ? AppColors.darkSurface
                        : AppColors.border.withOpacity(0.3))
                  : (isDarkMode ? AppColors.darkSurface : AppColors.surface),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hasAnswered
                    ? (isDarkMode ? const Color(0xFF5D4E40) : AppColors.border)
                    : AppColors.golden,
                width: 2,
              ),
              boxShadow: _hasAnswered
                  ? []
                  : [
                      BoxShadow(
                        color: AppColors.golden.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: TextField(
              controller: _answerController,
              enabled: !_hasAnswered,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: isDarkMode
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Escribe tu respuesta aquí...',
                hintStyle: TextStyle(
                  color: isDarkMode
                      ? AppColors.textTertiary
                      : AppColors.textTertiary,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
                suffixIcon: !_hasAnswered
                    ? Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.golden, AppColors.vibrantRed],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: _submitAnswer,
                          icon: const Icon(
                            Icons.send,
                            color: AppColors.surface,
                          ),
                        ),
                      )
                    : null,
              ),
              maxLines: 3,
              minLines: 1,
            ),
          ),
          if (!_hasAnswered) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitAnswer,
                icon: const Icon(Icons.check_circle),
                label: const Text('Responder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.golden,
                  foregroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExplanationSection() {
    if (widget.exercise.explanation?.isNotEmpty != true) {
      return const SizedBox.shrink();
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ScaleTransition(
      scale: _submitAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    AppColors.darkSurface.withOpacity(0.5),
                    AppColors.golden.withOpacity(0.1),
                  ]
                : [
                    AppColors.golden.withOpacity(0.1),
                    AppColors.peachy.withOpacity(0.2),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.golden.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.golden,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lightbulb,
                    color: AppColors.surface,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Explicación',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.golden,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.exercise.explanation!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
                fontWeight: FontWeight.w500,
                color: isDarkMode
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            if (!_isCorrect) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.progressGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.progressGreen.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.progressGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: AppColors.surface,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Respuesta correcta:',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.progressGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          Text(
                            widget.exercise.correctAnswer,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.progressGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (widget.onPrevious != null) ...[
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.golden),
                  color: isDarkMode ? AppColors.darkSurfaceLight : null,
                ),
                child: TextButton.icon(
                  onPressed: widget.onPrevious,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Anterior'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.golden,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],

          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: _hasAnswered && widget.showResults
                    ? LinearGradient(
                        colors: [AppColors.progressGreen, AppColors.golden],
                      )
                    : null,
                color: _hasAnswered && widget.showResults
                    ? null
                    : (isDarkMode ? const Color(0xFF5D4E40) : AppColors.border),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _hasAnswered && widget.showResults
                    ? [
                        BoxShadow(
                          color: AppColors.progressGreen.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [],
              ),
              child: ElevatedButton.icon(
                onPressed: (_hasAnswered && widget.showResults)
                    ? widget.onNext
                    : null,
                icon: Icon(
                  widget.isLast ? Icons.emoji_events : Icons.arrow_forward,
                ),
                label: Text(widget.isLast ? 'Finalizar' : 'Siguiente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: _hasAnswered && widget.showResults
                      ? AppColors.surface
                      : (isDarkMode
                            ? AppColors.textLight
                            : AppColors.textSecondary),
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
