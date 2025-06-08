import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_aula/models/course_model.dart';
import 'package:pro_aula/models/exercise_model.dart';
import 'package:pro_aula/models/form_model.dart';
import 'package:pro_aula/models/theme_model.dart';
import 'package:pro_aula/models/user_progress.dart';
import 'package:pro_aula/services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ✅ Reemplaza tu courseProgressProvider existente con esta versión mejorada:
final courseProgressProvider = FutureProvider.family<double, String>((
  ref,
  courseId,
) async {
  return await DatabaseService.getCourseProgress(courseId);
});

// ✅ Reemplaza tu lastViewedThemeProvider existente con esta versión mejorada:
final lastViewedThemeProvider = FutureProvider.family<String?, String>((
  ref,
  courseId,
) async {
  return await DatabaseService.getLastViewedTheme(courseId);
});

// ✅ Reemplaza tu isEnrolledProvider existente con esta versión mejorada:
final isEnrolledProvider = FutureProvider.family<bool, String>((
  ref,
  courseId,
) async {
  return await DatabaseService.isUserEnrolledInCourse(courseId);
});

// =============================================================================
// NUEVOS PROVIDERS REQUERIDOS
// =============================================================================

/// Provider para el estado de carga global
final isLoadingProvider = StateProvider<bool>((ref) => false);

/// Provider para actualizar último curso visto
final updateLastViewedCourseProvider = FutureProvider.family<bool, String>((
  ref,
  courseId,
) async {
  return await DatabaseService.updateLastViewedCourse(courseId);
});

/// Provider para estadísticas del usuario
final userStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await DatabaseService.getUserStats();
});

/// Provider para el perfil del usuario
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return await DatabaseService.getUserProfile();
});

/// Provider para cursos del usuario (inscritos)
final userCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) return [];

  try {
    // Obtener cursos únicos en los que el usuario tiene progreso
    final response = await supabase
        .from('user_progress')
        .select('''
          course_id,
          courses!inner(*)
        ''')
        .eq('user_id', userId);

    // Extraer los cursos únicos
    final coursesMap = <String, Course>{};
    for (final item in response) {
      final courseData = item['courses'];
      if (courseData != null) {
        final course = Course.fromJson(courseData);
        coursesMap[course.id] = course;
      }
    }

    return coursesMap.values.toList();
  } catch (e) {
    print('Error getting user courses: $e');
    return [];
  }
});

/// Provider para cursos recientes del usuario
final recentCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) return [];

  try {
    final response = await supabase
        .from('user_progress')
        .select('''
          course_id,
          last_viewed_at,
          courses!inner(*)
        ''')
        .eq('user_id', userId)
        .order('last_viewed_at', ascending: false)
        .limit(5);

    final coursesMap = <String, Course>{};
    for (final item in response) {
      final courseData = item['courses'];
      if (courseData != null) {
        final course = Course.fromJson(courseData);
        coursesMap[course.id] = course;
      }
    }

    return coursesMap.values.toList();
  } catch (e) {
    print('Error getting recent courses: $e');
    return [];
  }
});

// =============================================================================
// EXTENSIONES PARA OPERACIONES (¡LA PARTE MÁS IMPORTANTE!)
// =============================================================================

extension CourseProviderExtensions on WidgetRef {
  /// Inscribir usuario en curso e invalidar providers relevantes
  Future<bool> enrollUserInCourse(String courseId) async {
    final success = await DatabaseService.enrollUserInCourse(courseId);

    if (success) {
      invalidate(isEnrolledProvider(courseId));
      invalidate(courseProgressProvider(courseId));
      invalidate(userCoursesProvider);
      invalidate(userStatsProvider);
      invalidate(recentCoursesProvider);
    }

    return success;
  }

  /// Actualizar progreso de tema e invalidar providers relevantes
  Future<bool> updateThemeProgress({
    required String courseId,
    required String themeId,
    required double progressPercentage,
    bool? isCompleted,
  }) async {
    final success = await DatabaseService.updateThemeProgress(
      courseId: courseId,
      themeId: themeId,
      progressPercentage: progressPercentage,
      isCompleted: isCompleted,
    );

    if (success) {
      invalidate(
        userProgressThemeProvider((courseId: courseId, themeId: themeId)),
      );
      invalidate(courseProgressProvider(courseId));
      invalidate(userStatsProvider);
      invalidate(lastViewedThemeProvider(courseId));
    }

    return success;
  }

  /// Guardar respuesta de usuario e invalidar providers relevantes
  Future<bool> saveUserAnswer({
    required String exerciseId,
    required String userAnswer,
    required bool isCorrect,
  }) async {
    final success = await DatabaseService.saveUserAnswer(
      exerciseId: exerciseId,
      userAnswer: userAnswer,
      isCorrect: isCorrect,
    );

    if (success) {
      invalidate(userAnswersProvider(exerciseId));
      invalidate(userStatsProvider);
    }

    return success;
  }

  /// Refrescar todos los datos del usuario
  Future<void> refreshAllUserData() async {
    invalidate(userStatsProvider);
    invalidate(userProfileProvider);
    invalidate(userCoursesProvider);
    invalidate(recentCoursesProvider);

    // Esperar a que se recarguen los datos principales
    await Future.wait([
      read(userStatsProvider.future),
      read(userProfileProvider.future),
    ]);
  }
}

final courseDetailProvider = FutureProvider.family<Course, String>((
  ref,
  courseId,
) async {
  final supabase = ref.watch(supabaseClientProvider);
  final response = await supabase
      .from('courses')
      .select('*, themes(*)')
      .eq('id', courseId)
      .single();
  return Course.fromJson(response);
});

final themeDetailProvider = FutureProvider.family<CourseTheme, String>((
  ref,
  themeId,
) async {
  final supabase = ref.watch(supabaseClientProvider);
  final response = await supabase
      .from('themes')
      .select()
      .eq('id', themeId)
      .single();
  return CourseTheme.fromJson(response);
});

final exerciseDetailProvider = FutureProvider.family<Exercise, String>((
  ref,
  exerciseId,
) async {
  final supabase = ref.watch(supabaseClientProvider);
  final response = await supabase
      .from('exercises')
      .select()
      .eq('id', exerciseId)
      .single();
  return Exercise.fromJson(response);
});

final formDetailProvider = FutureProvider.family<FormModel, String>((
  ref,
  formId,
) async {
  final supabase = ref.watch(supabaseClientProvider);
  final response = await supabase
      .from('forms')
      .select()
      .eq('id', formId)
      .single();
  return FormModel.fromJson(response);
});

final userProgressThemeProvider =
    FutureProvider.family<UserProgress?, ({String courseId, String themeId})>((
      ref,
      args,
    ) async {
      final supabase = ref.watch(supabaseClientProvider);
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('user_progress')
          .select()
          .eq('user_id', userId)
          .eq('course_id', args.courseId)
          .eq('theme_id', args.themeId)
          .maybeSingle();
      if (response == null) {
        return null;
      }
      return UserProgress.fromJson(response);
    });

final userAnswersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      exerciseId,
    ) async {
      final supabase = ref.watch(supabaseClientProvider);
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('user_answers')
          .select('*')
          .eq('user_id', userId)
          .eq('exercise_id', exerciseId)
          .order('answered_at', ascending: false);
      return response;
    });

// =============================================================================
// NUEVOS PROVIDERS PARA COMPLETAR FUNCIONALIDAD
// =============================================================================

/// Provider para obtener todos los cursos publicados
final coursesProvider = FutureProvider<List<Course>>((ref) async {
  final coursesData = await DatabaseService.getPublishedCourses();
  return coursesData.map((json) => Course.fromJson(json)).toList();
});

/// Provider para el usuario actual
final currentUserProvider = StateProvider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

/// Provider para obtener ejercicios de un tema
final themeExercisesProvider = FutureProvider.family<List<Exercise>, String>((
  ref,
  themeId,
) async {
  final supabase = ref.watch(supabaseClientProvider);

  try {
    final response = await supabase
        .from('exercises')
        .select('*')
        .eq('theme_id', themeId)
        .order('order_index', ascending: true);

    return response.map((json) => Exercise.fromJson(json)).toList();
  } catch (e) {
    print('Error getting theme exercises: $e');
    return [];
  }
});

/// Provider para obtener formularios de un tema
final themeFormsProvider = FutureProvider.family<List<FormModel>, String>((
  ref,
  themeId,
) async {
  final supabase = ref.watch(supabaseClientProvider);

  try {
    final response = await supabase
        .from('forms')
        .select('*')
        .eq('theme_id', themeId);

    return response.map((json) => FormModel.fromJson(json)).toList();
  } catch (e) {
    print('Error getting theme forms: $e');
    return [];
  }
});

/// Provider para el último curso visto
final lastViewedCourseProvider = FutureProvider<Course?>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) return null;

  try {
    final userProfile = await DatabaseService.getUserProfile();
    final lastCourseId = userProfile?['last_viewed_course_id'];

    if (lastCourseId == null) return null;

    final courseResponse = await supabase
        .from('courses')
        .select('*, themes(*)')
        .eq('id', lastCourseId)
        .single();

    return Course.fromJson(courseResponse);
  } catch (e) {
    print('Error getting last viewed course: $e');
    return null;
  }
});

/// Provider para interacciones AI del usuario
final userAIInteractionsProvider =
    FutureProvider.family<
      List<Map<String, dynamic>>,
      ({String? courseId, String? themeId, int limit})
    >((ref, params) async {
      return await DatabaseService.getAIInteractions(
        courseId: params.courseId,
        themeId: params.themeId,
        limit: params.limit,
      );
    });

// =============================================================================
// PROVIDERS DE ESTADO PARA UI
// =============================================================================

/// Provider para el estado de carga global

/// Provider para mensajes de error
final errorMessageProvider = StateProvider<String?>((ref) => null);

/// Provider para el estado de autenticación
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// Provider para verificar la conexión a la base de datos
final databaseConnectionProvider = FutureProvider<bool>((ref) async {
  return await DatabaseService.checkConnection();
});

// =============================================================================
// EXTENSIONES ÚTILES PARA OPERACIONES
// =============================================================================
