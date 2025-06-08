// lib/screens/theme_content_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_aula/core/theme/app_theme.dart';
import 'package:pro_aula/models/form_model.dart';
import 'package:pro_aula/models/theme_model.dart';
import 'package:pro_aula/models/user_progress.dart';
import 'package:pro_aula/providers/supabase_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider para verificar si el usuario completó este tema
final themeCompletionProvider =
    FutureProvider.family<bool, ({String courseId, String themeId})>((
      ref,
      args,
    ) async {
      final supabase = ref.watch(supabaseClientProvider);
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) return false;

      final response = await supabase
          .from('user_progress')
          .select('is_completed')
          .eq('user_id', userId)
          .eq('course_id', args.courseId)
          .eq('theme_id', args.themeId)
          .maybeSingle();

      return response?['is_completed'] == true;
    });

// Provider para obtener ejercicios del tema
final themeExercisesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      themeId,
    ) async {
      final supabase = ref.watch(supabaseClientProvider);

      final response = await supabase
          .from('exercises')
          .select('*')
          .eq('theme_id', themeId)
          .order('order_index');

      return response;
    });

// Provider para obtener evaluaciones del tema
final themeFormsProvider = FutureProvider.family<List<FormModel>, String>((
  ref,
  themeId,
) async {
  final supabase = ref.watch(supabaseClientProvider);

  final response = await supabase
      .from('forms') // ✅ Cambiado a 'forms'
      .select('*')
      .eq('theme_id', themeId)
      .order('created_at');

  return response.map((json) => FormModel.fromJson(json)).toList();
});

class ThemeContentScreen extends ConsumerStatefulWidget {
  final String themeId;
  final String courseId;

  const ThemeContentScreen({
    super.key,
    required this.themeId,
    required this.courseId,
  });

  @override
  ConsumerState<ThemeContentScreen> createState() => _ThemeContentScreenState();
}

class _ThemeContentScreenState extends ConsumerState<ThemeContentScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasViewedContent = false;

  @override
  void initState() {
    super.initState();
    _updateUserProgress();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Marcar como visto cuando el usuario haga scroll hasta cierto punto
    if (!_hasViewedContent && _scrollController.offset > 200) {
      _hasViewedContent = true;
      _updateProgressPercentage(50.0); // 50% por leer el contenido
    }
  }

  Future<void> _updateUserProgress() async {
    final supabase = ref.read(supabaseClientProvider);
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return;

    try {
      // Crear o actualizar registro de progreso
      await supabase.from('user_progress').upsert({
        'user_id': userId,
        'course_id': widget.courseId,
        'theme_id': widget.themeId,
        'progress_percentage': 0.0,
        'is_completed': false,
        'last_viewed_at': DateTime.now().toIso8601String(),
      });

      // Actualizar último curso visto
      await supabase
          .from('users')
          .update({'last_viewed_course_id': widget.courseId})
          .eq('id', userId);
    } catch (e) {
      debugPrint('Error updating progress: $e');
    }
  }

  Future<void> _updateProgressPercentage(double percentage) async {
    final supabase = ref.read(supabaseClientProvider);
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return;

    try {
      await supabase
          .from('user_progress')
          .update({
            'progress_percentage': percentage,
            'last_viewed_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('course_id', widget.courseId)
          .eq('theme_id', widget.themeId);

      // Invalidar providers para refrescar UI
      ref.invalidate(
        themeCompletionProvider((
          courseId: widget.courseId,
          themeId: widget.themeId,
        )),
      );
    } catch (e) {
      debugPrint('Error updating progress percentage: $e');
    }
  }

  Future<void> _markThemeCompleted() async {
    await _updateProgressPercentage(100.0);

    final supabase = ref.read(supabaseClientProvider);
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return;

    try {
      await supabase
          .from('user_progress')
          .update({
            'progress_percentage': 100.0,
            'is_completed': true,
            'last_viewed_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('course_id', widget.courseId)
          .eq('theme_id', widget.themeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Tema completado! 🎉'),
            backgroundColor: AppColors.progressGreen,
          ),
        );
      }

      // Invalidar providers
      ref.invalidate(
        themeCompletionProvider((
          courseId: widget.courseId,
          themeId: widget.themeId,
        )),
      );
    } catch (e) {
      debugPrint('Error marking theme completed: $e');
    }
  }

  void _navigateToExercises() {
    Navigator.pushNamed(
      context,
      '/exercise',
      arguments: {'themeId': widget.themeId, 'courseId': widget.courseId},
    );
  }

  // ✅ FUNCIÓN CORREGIDA
  void _navigateToSpecificEvaluation(FormModel evaluation) {
    Navigator.pushNamed(
      context,
      '/form',
      arguments: {'themeId': widget.themeId, 'evaluation': evaluation},
    );
  }

  // ✅ FUNCIÓN PARA MANEJAR MÚLTIPLES EVALUACIONES
  void _navigateToForms() {
    final formsAsync = ref.read(themeFormsProvider(widget.themeId));

    formsAsync.whenData((forms) {
      if (forms.length == 1) {
        // Si solo hay una evaluación, ir directo
        _navigateToSpecificEvaluation(forms.first);
      } else if (forms.length > 1) {
        // Si hay múltiples, mostrar diálogo de selección
        _showEvaluationSelectionDialog(forms);
      }
    });
  }

  // ✅ DIÁLOGO DE SELECCIÓN DE EVALUACIONES
  void _showEvaluationSelectionDialog(List<FormModel> evaluations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Evaluación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: evaluations
              .map(
                (evaluation) => ListTile(
                  leading: const Icon(Icons.quiz),
                  title: Text(evaluation.title),
                  subtitle: Text('${evaluation.questions.length} preguntas'),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToSpecificEvaluation(evaluation);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeAsync = ref.watch(themeDetailProvider(widget.themeId));
    final exercisesAsync = ref.watch(themeExercisesProvider(widget.themeId));
    final formsAsync = ref.watch(themeFormsProvider(widget.themeId));
    final isCompletedAsync = ref.watch(
      themeCompletionProvider((
        courseId: widget.courseId,
        themeId: widget.themeId,
      )),
    );

    return Scaffold(
      body: themeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorWidget(error),
        data: (theme) => CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildSliverAppBar(theme),
            SliverToBoxAdapter(
              child: _buildContent(
                theme,
                exercisesAsync,
                formsAsync,
                isCompletedAsync,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(CourseTheme theme) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.vibrantRed,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          theme.title,
          style: const TextStyle(
            color: AppColors.surface,
            fontWeight: FontWeight.w600,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.vibrantRed, AppColors.golden],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    CourseTheme theme,
    AsyncValue<List<Map<String, dynamic>>> exercisesAsync,
    AsyncValue<List<FormModel>> formsAsync,
    AsyncValue<bool> isCompletedAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estado de progreso
          _buildProgressCard(isCompletedAsync),

          const SizedBox(height: 24),

          // Contenido del tema
          _buildThemeContent(theme),

          const SizedBox(height: 24),

          // Actividades disponibles
          _buildActivitiesSection(exercisesAsync, formsAsync),

          const SizedBox(height: 24),

          // Botón de completar tema
          _buildCompleteButton(isCompletedAsync),

          const SizedBox(height: 100), // Espacio para FAB
        ],
      ),
    );
  }

  Widget _buildProgressCard(AsyncValue<bool> isCompletedAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: isCompletedAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const Text('Error al cargar progreso'),
          data: (isCompleted) => Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.progressGreen.withOpacity(0.2)
                      : AppColors.golden.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.play_circle_outline,
                  color: isCompleted
                      ? AppColors.progressGreen
                      : AppColors.golden,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCompleted ? 'Tema Completado' : 'En Progreso',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isCompleted
                            ? AppColors.progressGreen
                            : AppColors.golden,
                      ),
                    ),
                    Text(
                      isCompleted
                          ? '¡Excelente trabajo! Has completado este tema.'
                          : 'Continúa leyendo y completa las actividades.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeContent(CourseTheme theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.article_outlined,
                  color: AppColors.vibrantRed,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Contenido del Tema',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildContentBlocks(theme.content),
          ],
        ),
      ),
    );
  }

  Widget _buildContentBlocks(Map<String, dynamic> content) {
    // Simular contenido estructurado
    // En producción, esto vendría del JSONB content
    final blocks =
        content['blocks'] as List<dynamic>? ??
        [
          {
            'type': 'text',
            'content':
                'Este es el contenido principal del tema. Aquí se explican los conceptos fundamentales de física de manera clara y detallada.',
          },
          {
            'type': 'formula',
            'title': 'Fórmula Principal',
            'content': 'F = ma',
            'description':
                'Donde F es la fuerza, m es la masa y a es la aceleración.',
          },
          {
            'type': 'example',
            'title': 'Ejemplo Práctico',
            'content':
                'Considera un objeto de 5 kg que acelera a 2 m/s². La fuerza aplicada sería F = 5 × 2 = 10 N.',
          },
        ];

    return Column(
      children: blocks.map<Widget>((block) {
        switch (block['type']) {
          case 'text':
            return _buildTextBlock(block['content']);
          case 'formula':
            return _buildFormulaBlock(block);
          case 'example':
            return _buildExampleBlock(block);
          default:
            return _buildTextBlock(block['content'] ?? '');
        }
      }).toList(),
    );
  }

  Widget _buildTextBlock(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
      ),
    );
  }

  Widget _buildFormulaBlock(Map<String, dynamic> block) {
    // Extraer datos de la estructura de tu base de datos
    final formulaName = block['name'] ?? block['title'] ?? 'Fórmula';
    final formula = block['formula'] ?? block['content'] ?? '';
    final variables = block['variables'] as Map<String, dynamic>?;
    final description = block['description'];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.peachy.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.golden.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.golden.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la fórmula con icono
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.golden.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.functions,
                  color: AppColors.golden,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  formulaName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.golden,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Fórmula destacada en el centro
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.golden.withOpacity(0.05),
                  AppColors.golden.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.vibrantRed.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Text(
              formula,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.lightGolden,
                fontFamily: 'monospace',
                fontSize: 32,
              ),
            ),
          ),

          // Variables y sus explicaciones
          if (variables != null && variables.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.golden.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.golden,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Variables:',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.golden,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...variables.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Variable symbol
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.vibrantRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.vibrantRed.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              entry.key,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.vibrantRed,
                                    fontFamily: 'monospace',
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Variable description
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                entry.value.toString(),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      height: 1.4,
                                      color: AppColors.peachy,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],

          // Descripción adicional si existe
          if (description != null && description.toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.progressGreen.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.progressGreen.withOpacity(0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.progressGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nota importante:',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.progressGreen,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description.toString(),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                                height: 1.5,
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
    );
  }

  Widget _buildExampleBlock(Map<String, dynamic> block) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.progressGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.progressGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: AppColors.progressGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                block['title'] ?? 'Ejemplo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.progressGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            block['content'] ?? '',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesSection(
    AsyncValue<List<Map<String, dynamic>>> exercisesAsync,
    AsyncValue<List<FormModel>> formsAsync,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.assignment_outlined,
                  color: AppColors.vibrantRed,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Actividades',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ejercicios
            exercisesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
              data: (exercises) => exercises.isNotEmpty
                  ? _buildActivityButton(
                      icon: Icons.quiz_outlined,
                      title: 'Ejercicios Prácticos',
                      subtitle: '${exercises.length} ejercicios disponibles',
                      color: AppColors.golden,
                      onTap: _navigateToExercises,
                    )
                  : _buildNoActivitiesMessage('ejercicios'),
            ),

            const SizedBox(height: 12),

            // ✅ SECCIÓN DE EVALUACIONES MEJORADA
            formsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
              data: (evaluations) => evaluations.isNotEmpty
                  ? Column(
                      children: evaluations
                          .map(
                            (evaluation) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildEvaluationButton(evaluation),
                            ),
                          )
                          .toList(),
                    )
                  : _buildNoActivitiesMessage('evaluaciones'),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NUEVO WIDGET PARA CADA EVALUACIÓN
  Widget _buildEvaluationButton(FormModel evaluation) {
    return InkWell(
      onTap: () => _navigateToSpecificEvaluation(evaluation),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.vibrantRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.vibrantRed.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.vibrantRed.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.quiz,
                color: AppColors.vibrantRed,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evaluation.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${evaluation.questions.length} preguntas',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.vibrantRed,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNoActivitiesMessage(String activityType) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.border.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.hourglass_empty, color: AppColors.textTertiary, size: 32),
          const SizedBox(height: 8),
          Text(
            'No hay $activityType disponibles',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton(AsyncValue<bool> isCompletedAsync) {
    return isCompletedAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (isCompleted) => isCompleted
          ? Card(
              color: AppColors.progressGreen.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.progressGreen,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Tema Completado!',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.progressGreen,
                                ),
                          ),
                          Text(
                            'Has terminado este tema exitosamente',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _markThemeCompleted,
                icon: const Icon(Icons.check),
                label: const Text('Marcar como Completado'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.progressGreen,
                  foregroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
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
            const SizedBox(height: 16),
            Text(
              'Error al cargar el tema',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}
