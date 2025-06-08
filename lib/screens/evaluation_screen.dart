// lib/screens/evaluation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_aula/core/theme/app_theme.dart';
import 'package:pro_aula/models/form_model.dart';
import 'package:pro_aula/providers/supabase_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider para obtener evaluaciones del tema
final themeEvaluationsProvider = FutureProvider.family<List<FormModel>, String>(
  (ref, themeId) async {
    final supabase = ref.watch(supabaseClientProvider);

    final response = await supabase
        .from('forms') // ✅ Usar 'forms' para ser consistente
        .select('*')
        .eq('theme_id', themeId)
        .order('created_at');

    return response.map((json) => FormModel.fromJson(json)).toList();
  },
);

// Provider para obtener respuestas del usuario a evaluaciones
final userEvaluationAnswersProvider =
    FutureProvider.family<Map<String, dynamic>, String>((
      ref,
      evaluationId,
    ) async {
      final supabase = ref.watch(supabaseClientProvider);
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) return {};

      final response = await supabase
          .from('evaluation_answers')
          .select('question_index, selected_option, is_correct')
          .eq('user_id', userId)
          .eq('evaluation_id', evaluationId)
          .order('answered_at', ascending: false);

      // Agrupar por question_index y tomar la respuesta más reciente
      final answersMap = <String, dynamic>{};
      for (final answer in response) {
        final questionIndex = answer['question_index'].toString();
        if (!answersMap.containsKey(questionIndex)) {
          answersMap[questionIndex] = answer;
        }
      }

      return answersMap;
    });

// Provider para el progreso de evaluación
final evaluationProgressProvider =
    StateProvider<({int current, int total, int correct, bool isCompleted})>((
      ref,
    ) {
      return (current: 0, total: 0, correct: 0, isCompleted: false);
    });

class EvaluationScreen extends ConsumerStatefulWidget {
  final String themeId;
  final FormModel evaluation;

  const EvaluationScreen({
    super.key,
    required this.themeId,
    required this.evaluation,
  });

  @override
  ConsumerState<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends ConsumerState<EvaluationScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentQuestionIndex = 0;
  Map<int, String> _selectedAnswers = {};
  Map<int, bool> _answeredQuestions = {};
  bool _isEvaluationCompleted = false;

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

    // Inicializar progreso
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(evaluationProgressProvider.notifier).state = (
        current: 1,
        total: widget.evaluation.questions.length,
        correct: 0,
        isCompleted: false,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.evaluation.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // Actualizar progreso
      final currentProgress = ref.read(evaluationProgressProvider);
      ref.read(evaluationProgressProvider.notifier).state = (
        current: _currentQuestionIndex + 1,
        total: currentProgress.total,
        correct: currentProgress.correct,
        isCompleted: false,
      );
    } else {
      _completeEvaluation();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // Actualizar progreso
      final currentProgress = ref.read(evaluationProgressProvider);
      ref.read(evaluationProgressProvider.notifier).state = (
        current: _currentQuestionIndex + 1,
        total: currentProgress.total,
        correct: currentProgress.correct,
        isCompleted: false,
      );
    }
  }

  void _selectAnswer(String selectedOption) {
    final question = widget.evaluation.questions[_currentQuestionIndex];
    final isCorrect = selectedOption == question['correct_answer'];

    // Verificar si ya había respondido esta pregunta antes
    final hadPreviousAnswer =
        _answeredQuestions[_currentQuestionIndex] ?? false;

    setState(() {
      _selectedAnswers[_currentQuestionIndex] = selectedOption;
      _answeredQuestions[_currentQuestionIndex] = true;
    });

    // Guardar respuesta
    _saveAnswer(_currentQuestionIndex, selectedOption, isCorrect);

    // Actualizar contador de respuestas correctas
    final currentProgress = ref.read(evaluationProgressProvider);
    int correctCount = currentProgress.correct;

    // Solo sumar si es la primera vez que responde esta pregunta y es correcta
    if (!hadPreviousAnswer && isCorrect) {
      correctCount++;
    }

    ref.read(evaluationProgressProvider.notifier).state = (
      current: currentProgress.current,
      total: currentProgress.total,
      correct: correctCount,
      isCompleted: false,
    );
  }

  Future<void> _saveAnswer(
    int questionIndex,
    String selectedOption,
    bool isCorrect,
  ) async {
    final supabase = ref.read(supabaseClientProvider);
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return;

    try {
      await supabase.from('evaluation_answers').insert({
        'id':
            '${userId}_${widget.evaluation.id}_${questionIndex}_${DateTime.now().millisecondsSinceEpoch}',
        'user_id': userId,
        'evaluation_id': widget.evaluation.id,
        'question_index': questionIndex,
        'selected_option': selectedOption,
        'is_correct': isCorrect,
        'answered_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving evaluation answer: $e');
    }
  }

  void _completeEvaluation() {
    setState(() {
      _isEvaluationCompleted = true;
    });

    final progress = ref.read(evaluationProgressProvider);
    ref.read(evaluationProgressProvider.notifier).state = (
      current: progress.current,
      total: progress.total,
      correct: progress.correct,
      isCompleted: true,
    );

    _showFinalResults();
  }

  void _showFinalResults() {
    final progress = ref.read(evaluationProgressProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final percentage = (progress.correct / progress.total) * 100;

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
                      colors: _getGradeColors(percentage),
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getGradeColors(percentage)[0].withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getGradeIcon(percentage),
                    color: AppColors.surface,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '¡Evaluación Completada!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.evaluation.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isDarkMode
                        ? AppColors.textLight
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Calificación
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _getGradeColors(percentage),
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: AppColors.surface,
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildScoreItem(
                            'Correctas',
                            '${progress.correct}',
                            AppColors.progressGreen,
                            Icons.check_circle,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: isDarkMode
                                ? const Color(0xFF5D4E40)
                                : AppColors.border,
                          ),
                          _buildScoreItem(
                            'Total',
                            '${progress.total}',
                            isDarkMode
                                ? AppColors.textLight
                                : AppColors.textSecondary,
                            Icons.quiz,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: isDarkMode
                                ? const Color(0xFF5D4E40)
                                : AppColors.border,
                          ),
                          _buildScoreItem(
                            'Incorrectas',
                            '${progress.total - progress.correct}',
                            AppColors.error,
                            Icons.cancel,
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
                    color: _getGradeColors(percentage)[0].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getGradeIcon(percentage),
                        color: _getGradeColors(percentage)[0],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getGradeMessage(percentage),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: isDarkMode
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ✅ BOTÓN PRINCIPAL: VER RESPUESTAS
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showAnswersReview();
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('Ver mis Respuestas'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.progressGreen,
                      foregroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _resetEvaluation();
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

  Widget _buildScoreItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  List<Color> _getGradeColors(double percentage) {
    if (percentage >= 90) {
      return [AppColors.progressGreen, AppColors.golden];
    } else if (percentage >= 70) {
      return [AppColors.golden, AppColors.vibrantRed];
    } else if (percentage >= 50) {
      return [AppColors.vibrantRed, AppColors.golden];
    } else {
      return [AppColors.error, AppColors.vibrantRed];
    }
  }

  IconData _getGradeIcon(double percentage) {
    if (percentage >= 90) {
      return Icons.emoji_events;
    } else if (percentage >= 70) {
      return Icons.thumb_up;
    } else if (percentage >= 50) {
      return Icons.thumbs_up_down;
    } else {
      return Icons.sentiment_dissatisfied;
    }
  }

  String _getGradeMessage(double percentage) {
    if (percentage >= 90) {
      return '¡Excelente! 🎉 Dominas perfectamente este tema.';
    } else if (percentage >= 70) {
      return '¡Muy bien! 👍 Tienes un buen conocimiento del tema.';
    } else if (percentage >= 50) {
      return 'Bien hecho 👌 Puedes mejorar con más estudio.';
    } else {
      return 'Sigue estudiando 📚 Necesitas repasar más el tema.';
    }
  }

  // ✅ NUEVA FUNCIÓN PARA MOSTRAR REVISIÓN DE RESPUESTAS
  void _showAnswersReview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EvaluationResultsScreen(
          evaluation: widget.evaluation,
          selectedAnswers: _selectedAnswers,
          finalProgress: ref.read(evaluationProgressProvider),
        ),
      ),
    );
  }

  void _resetEvaluation() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedAnswers.clear();
      _answeredQuestions.clear();
      _isEvaluationCompleted = false;
    });

    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    ref.read(evaluationProgressProvider.notifier).state = (
      current: 1,
      total: widget.evaluation.questions.length,
      correct: 0,
      isCompleted: false,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          // Progress indicator
                          _buildProgressIndicator(),

                          // Questions content
                          Expanded(
                            child: PageView.builder(
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentQuestionIndex = index;
                                });

                                final currentProgress = ref.read(
                                  evaluationProgressProvider,
                                );
                                ref
                                    .read(evaluationProgressProvider.notifier)
                                    .state = (
                                  current: index + 1,
                                  total: currentProgress.total,
                                  correct: currentProgress.correct,
                                  isCompleted: false,
                                );
                              },
                              itemCount: widget.evaluation.questions.length,
                              itemBuilder: (context, index) {
                                final question =
                                    widget.evaluation.questions[index];

                                return QuestionCard(
                                  question: question,
                                  questionNumber: index + 1,
                                  totalQuestions:
                                      widget.evaluation.questions.length,
                                  selectedAnswer: _selectedAnswers[index],
                                  onAnswerSelected: (answer) =>
                                      _selectAnswer(answer),
                                  onNext: _nextQuestion,
                                  onPrevious: _currentQuestionIndex > 0
                                      ? _previousQuestion
                                      : null,
                                  isLast:
                                      index ==
                                      widget.evaluation.questions.length - 1,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
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
                  'Evaluación',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.surface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  widget.evaluation.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDarkMode
                        ? AppColors.darkTextPrimary.withOpacity(0.8)
                        : AppColors.surface.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Progress badge
          Consumer(
            builder: (context, ref, child) {
              final progress = ref.watch(evaluationProgressProvider);
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
                child: Text(
                  '${progress.current}/${progress.total}',
                  style: TextStyle(
                    color: isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.surface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
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
                      'Pregunta ${_currentQuestionIndex + 1} de ${widget.evaluation.questions.length}',
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
                  final progress = ref.watch(evaluationProgressProvider);
                  final answered = _answeredQuestions.length;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.golden, AppColors.vibrantRed],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$answered/${progress.total} respondidas',
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
                    ((_currentQuestionIndex + 1) /
                        widget.evaluation.questions.length),
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
}

// Widget para cada pregunta individual
class QuestionCard extends StatefulWidget {
  final Map<String, dynamic> question;
  final int questionNumber;
  final int totalQuestions;
  final String? selectedAnswer;
  final Function(String) onAnswerSelected;
  final VoidCallback onNext;
  final VoidCallback? onPrevious;
  final bool isLast;

  const QuestionCard({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    this.selectedAnswer,
    required this.onAnswerSelected,
    required this.onNext,
    this.onPrevious,
    required this.isLast,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard>
    with TickerProviderStateMixin {
  late AnimationController _selectionAnimationController;
  late Animation<double> _selectionAnimation;

  @override
  void initState() {
    super.initState();
    _selectionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _selectionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _selectionAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _selectionAnimationController.dispose();
    super.dispose();
  }

  void _selectOption(String option) {
    widget.onAnswerSelected(option);
    _selectionAnimationController.forward();
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
                      // Header con número de pregunta
                      _buildQuestionHeader(),

                      const SizedBox(height: 24),

                      // Pregunta
                      _buildQuestionSection(),

                      const SizedBox(height: 32),

                      // Opciones
                      _buildOptionsSection(),
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
            'Pregunta ${widget.questionNumber}',
            style: const TextStyle(
              color: AppColors.surface,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        const Spacer(),
        if (widget.selectedAnswer != null)
          ScaleTransition(
            scale: _selectionAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.progressGreen,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.progressGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 16, color: AppColors.surface),
                  SizedBox(width: 6),
                  Text(
                    'Respondida',
                    style: TextStyle(
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
            widget.question['question'] as String,
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

  Widget _buildOptionsSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final options = widget.question['options'] as List<dynamic>;

    return Column(
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
                Icons.radio_button_checked,
                color: AppColors.surface,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Selecciona una opción',
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
        ...options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value as String;
          final isSelected = widget.selectedAnswer == option;
          final optionLabel = String.fromCharCode(65 + index); // A, B, C, D

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => _selectOption(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.golden.withOpacity(0.1)
                      : (isDarkMode
                            ? AppColors.darkSurface
                            : AppColors.surface),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.golden
                        : (isDarkMode
                              ? const Color(0xFF5D4E40)
                              : AppColors.border),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.golden.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.golden
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.golden
                              : (isDarkMode
                                    ? AppColors.textLight
                                    : AppColors.textSecondary),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          optionLabel,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.surface
                                : (isDarkMode
                                      ? AppColors.textLight
                                      : AppColors.textSecondary),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        option,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColors.golden
                              : (isDarkMode
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary),
                        ),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.golden,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: AppColors.surface,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hasAnswer = widget.selectedAnswer != null;

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
                gradient: hasAnswer
                    ? LinearGradient(
                        colors: [AppColors.progressGreen, AppColors.golden],
                      )
                    : null,
                color: hasAnswer
                    ? null
                    : (isDarkMode ? const Color(0xFF5D4E40) : AppColors.border),
                borderRadius: BorderRadius.circular(16),
                boxShadow: hasAnswer
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
                onPressed: hasAnswer ? widget.onNext : null,
                icon: Icon(
                  widget.isLast ? Icons.emoji_events : Icons.arrow_forward,
                ),
                label: Text(widget.isLast ? 'Finalizar' : 'Siguiente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: hasAnswer
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

// ✅ NUEVA PANTALLA: Revisión de respuestas después de completar la evaluación
class EvaluationResultsScreen extends StatelessWidget {
  final FormModel evaluation;
  final Map<int, String> selectedAnswers;
  final ({int current, int total, int correct, bool isCompleted}) finalProgress;

  const EvaluationResultsScreen({
    super.key,
    required this.evaluation,
    required this.selectedAnswers,
    required this.finalProgress,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final percentage = (finalProgress.correct / finalProgress.total) * 100;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [AppColors.darkSurfaceLight, AppColors.darkSurface]
                : [
                    AppColors.progressGreen,
                    AppColors.progressGreen.withOpacity(0.8),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              _buildCustomAppBar(context, isDarkMode),

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
                    child: Column(
                      children: [
                        // Resumen de resultados
                        _buildResultsSummary(context, isDarkMode, percentage),

                        // Lista de respuestas
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: evaluation.questions.length,
                            itemBuilder: (context, index) {
                              final question = evaluation.questions[index];
                              final userAnswer = selectedAnswers[index];
                              final correctAnswer =
                                  question['correct_answer'] as String;
                              final isCorrect = userAnswer == correctAnswer;

                              return _buildAnswerReviewCard(
                                context,
                                isDarkMode,
                                question,
                                index + 1,
                                userAnswer,
                                correctAnswer,
                                isCorrect,
                              );
                            },
                          ),
                        ),
                      ],
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

  Widget _buildCustomAppBar(BuildContext context, bool isDarkMode) {
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
                  'Revisión de Respuestas',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.surface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  evaluation.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDarkMode
                        ? AppColors.darkTextPrimary.withOpacity(0.8)
                        : AppColors.surface.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Score badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.darkTextPrimary.withOpacity(0.2)
                  : AppColors.surface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${finalProgress.correct}/${finalProgress.total}',
              style: TextStyle(
                color: isDarkMode
                    ? AppColors.darkTextPrimary
                    : AppColors.surface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSummary(
    BuildContext context,
    bool isDarkMode,
    double percentage,
  ) {
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
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: _getGradeColors(percentage)),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getGradeColors(percentage)[0].withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _getGradeIcon(percentage),
                  color: AppColors.surface,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resultado Final',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isDarkMode
                            ? AppColors.textLight
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isDarkMode
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: _getGradeColors(percentage)),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '${finalProgress.correct}/${finalProgress.total}',
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getGradeColors(percentage)[0].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _getGradeIcon(percentage),
                  color: _getGradeColors(percentage)[0],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getGradeMessage(percentage),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerReviewCard(
    BuildContext context,
    bool isDarkMode,
    Map<String, dynamic> question,
    int questionNumber,
    String? userAnswer,
    String correctAnswer,
    bool isCorrect,
  ) {
    final options = question['options'] as List<dynamic>;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurfaceLight : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCorrect
              ? AppColors.progressGreen.withOpacity(0.3)
              : AppColors.error.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCorrect ? AppColors.progressGreen : AppColors.error)
                .withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con número y estado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.golden, AppColors.vibrantRed],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    'Pregunta $questionNumber',
                    style: const TextStyle(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? AppColors.progressGreen
                        : AppColors.error,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: AppColors.surface,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCorrect ? 'Correcta' : 'Incorrecta',
                        style: const TextStyle(
                          color: AppColors.surface,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Pregunta
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppColors.darkSurface.withOpacity(0.5)
                    : AppColors.peachy.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode
                      ? const Color(0xFF5D4E40)
                      : AppColors.border,
                ),
              ),
              child: Text(
                question['question'] as String,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Opciones
            ...options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value as String;
              final optionLabel = String.fromCharCode(65 + index); // A, B, C, D
              final isUserChoice = userAnswer == option;
              final isCorrectChoice = correctAnswer == option;

              Color borderColor;
              Color backgroundColor;
              Color textColor;
              Widget? trailingIcon;

              if (isCorrectChoice) {
                // Opción correcta - siempre verde
                borderColor = AppColors.progressGreen;
                backgroundColor = AppColors.progressGreen.withOpacity(0.1);
                textColor = AppColors.progressGreen;
                trailingIcon = const Icon(
                  Icons.check_circle,
                  color: AppColors.progressGreen,
                  size: 20,
                );
              } else if (isUserChoice && !isCorrect) {
                // Opción del usuario incorrecta - rojo
                borderColor = AppColors.error;
                backgroundColor = AppColors.error.withOpacity(0.1);
                textColor = AppColors.error;
                trailingIcon = const Icon(
                  Icons.cancel,
                  color: AppColors.error,
                  size: 20,
                );
              } else {
                // Otras opciones - neutral
                borderColor = isDarkMode
                    ? const Color(0xFF5D4E40)
                    : AppColors.border;
                backgroundColor = isDarkMode
                    ? AppColors.darkSurface
                    : AppColors.surface;
                textColor = isDarkMode
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: (isCorrectChoice || (isUserChoice && !isCorrect))
                            ? (isCorrectChoice
                                  ? AppColors.progressGreen
                                  : AppColors.error)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: textColor, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          optionLabel,
                          style: TextStyle(
                            color:
                                (isCorrectChoice ||
                                    (isUserChoice && !isCorrect))
                                ? AppColors.surface
                                : textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ),
                    if (trailingIcon != null) trailingIcon,
                  ],
                ),
              );
            }).toList(),

            // Mensaje explicativo si la respuesta fue incorrecta
            if (!isCorrect && userAnswer != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.golden.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.golden.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.golden,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tu respuesta: ${String.fromCharCode(65 + options.indexOf(userAnswer))} • Correcta: ${String.fromCharCode(65 + options.indexOf(correctAnswer))}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.golden,
                          fontWeight: FontWeight.w500,
                        ),
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

  List<Color> _getGradeColors(double percentage) {
    if (percentage >= 90) {
      return [AppColors.progressGreen, AppColors.golden];
    } else if (percentage >= 70) {
      return [AppColors.golden, AppColors.vibrantRed];
    } else if (percentage >= 50) {
      return [AppColors.vibrantRed, AppColors.golden];
    } else {
      return [AppColors.error, AppColors.vibrantRed];
    }
  }

  IconData _getGradeIcon(double percentage) {
    if (percentage >= 90) {
      return Icons.emoji_events;
    } else if (percentage >= 70) {
      return Icons.thumb_up;
    } else if (percentage >= 50) {
      return Icons.thumbs_up_down;
    } else {
      return Icons.sentiment_dissatisfied;
    }
  }

  String _getGradeMessage(double percentage) {
    if (percentage >= 90) {
      return '¡Excelente! 🎉 Dominas perfectamente este tema.';
    } else if (percentage >= 70) {
      return '¡Muy bien! 👍 Tienes un buen conocimiento del tema.';
    } else if (percentage >= 50) {
      return 'Bien hecho 👌 Puedes mejorar con más estudio.';
    } else {
      return 'Sigue estudiando 📚 Necesitas repasar más el tema.';
    }
  }
}
