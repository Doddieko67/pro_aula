// lib/extensions/riverpod_extensions.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_aula/services/user_service.dart';
import 'package:pro_aula/models/course_model.dart';

/// =====================================================
/// EXTENSIÓN PARA WIDGETREF - MÉTODOS DE CONVENIENCIA
/// =====================================================

/// Extensión para WidgetRef que agrega métodos de conveniencia para operaciones de usuario
extension UserOperationsExtension on WidgetRef {
  /// Inscribe al usuario en un curso de forma segura
  Future<bool> enrollUserInCourse(String courseId) async {
    final success = await UserService.enrollUserInCourse(courseId);

    if (success) {
      // Invalidar providers relevantes para refrescar la UI
      invalidate(isEnrolledProvider(courseId));
      invalidate(courseProgressProvider(courseId));
      invalidate(userProgressProvider);
      invalidate(userProfileProvider);
    }

    return success;
  }

  /// Actualiza el progreso de un tema
  Future<bool> updateThemeProgress({
    required String courseId,
    required String themeId,
    required double progressPercentage,
    bool? isCompleted,
  }) async {
    final success = await UserService.updateThemeProgress(
      courseId: courseId,
      themeId: themeId,
      progressPercentage: progressPercentage,
      isCompleted: isCompleted,
    );

    if (success) {
      // Invalidar providers relevantes
      invalidate(
        userProgressThemeProvider((courseId: courseId, themeId: themeId)),
      );
      invalidate(courseProgressProvider(courseId));
      invalidate(userProgressProvider);
      invalidate(lastViewedThemeProvider(courseId));
      invalidate(userProfileProvider);
    }

    return success;
  }

  /// Guarda la respuesta de un usuario
  Future<bool> saveUserAnswer({
    required String exerciseId,
    required String userAnswer,
    required bool isCorrect,
  }) async {
    final success = await UserService.saveUserAnswer(
      exerciseId: exerciseId,
      userAnswer: userAnswer,
      isCorrect: isCorrect,
    );

    if (success) {
      // Invalidar estadísticas del usuario
      invalidate(userStatsProvider);
    }

    return success;
  }

  /// Guarda un formulario
  Future<bool> saveFormSubmission({
    required String formId,
    required Map<String, dynamic> answers,
    double? score,
  }) async {
    final success = await UserService.saveFormSubmission(
      formId: formId,
      answers: answers,
      score: score,
    );

    if (success) {
      // Invalidar estadísticas del usuario
      invalidate(userStatsProvider);
    }

    return success;
  }

  /// Actualiza el último curso visto
  Future<bool> updateLastViewedCourse(String courseId) async {
    final success = await UserService.updateLastViewedCourse(courseId);

    if (success) {
      invalidate(userProfileProvider);
    }

    return success;
  }

  /// Actualiza el perfil del usuario
  Future<bool> updateUserProfile({String? name, String? avatarUrl}) async {
    final success = await UserService.updateUserProfile(
      name: name,
      avatarUrl: avatarUrl,
    );

    if (success) {
      invalidate(userProfileProvider);
    }

    return success;
  }

  /// Marca un tema como completado
  Future<bool> markThemeAsCompleted({
    required String courseId,
    required String themeId,
  }) async {
    final success = await UserService.markThemeAsCompleted(
      courseId: courseId,
      themeId: themeId,
    );

    if (success) {
      // Invalidar múltiples providers
      invalidate(
        userProgressThemeProvider((courseId: courseId, themeId: themeId)),
      );
      invalidate(courseProgressProvider(courseId));
      invalidate(userProgressProvider);
      invalidate(userStatsProvider);
    }

    return success;
  }

  /// Refresca todos los datos del usuario
  Future<void> refreshAllUserData() async {
    // Invalidar todos los providers relacionados con el usuario
    invalidate(userProfileProvider);
    invalidate(userProgressProvider);
    invalidate(userStatsProvider);
    invalidate(coursesProvider);

    // Re-verificar que el usuario existe
    await UserService.ensureUserExists();
  }

  /// Limpia los datos del usuario (para logout o testing)
  Future<void> clearUserData() async {
    await UserService.clearUserData();

    // Invalidar todos los providers
    invalidate(userProfileProvider);
    invalidate(userProgressProvider);
    invalidate(userStatsProvider);
    invalidate(coursesProvider);
  }
}

/// =====================================================
/// PROVIDERS PRINCIPALES
/// =====================================================

/// Provider para manejar estado de carga global
final isLoadingProvider = StateProvider<bool>((ref) => false);

/// Provider para el perfil del usuario
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return null;

    // Asegurar que el usuario existe antes de consultar
    await UserService.ensureUserExists();

    final profile = await UserService.getUserProfile();
    return profile;
  } catch (e) {
    print('Error en userProfileProvider: $e');
    return null;
  }
});

/// Provider para las estadísticas del usuario
final userStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  try {
    return await UserService.getUserStats();
  } catch (e) {
    print('Error en userStatsProvider: $e');
    return {
      'totalCoursesEnrolled': 0,
      'totalCoursesCompleted': 0,
      'totalThemesCompleted': 0,
      'totalExercisesAnswered': 0,
      'totalCorrectAnswers': 0,
    };
  }
});

/// Provider para el progreso del usuario
final userProgressProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  try {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return [];

    // Asegurar que el usuario existe antes de consultar
    await UserService.ensureUserExists();

    final response = await Supabase.instance.client
        .from('user_progress')
        .select('''
          *,
          courses:course_id (
            id,
            title,
            difficulty,
            thumbnail_url
          ),
          themes:theme_id (
            id,
            title
          )
        ''')
        .eq('user_id', currentUser.id)
        .order('last_viewed_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    print('Error en userProgressProvider: $e');
    return [];
  }
});

/// Provider para los cursos con mejor manejo de errores
final coursesProvider = FutureProvider<List<Course>>((ref) async {
  try {
    final response = await Supabase.instance.client
        .from('courses')
        .select('''
          *,
          themes (
            id,
            title,
            order_index,
            course_id
          )
        ''')
        .eq('is_published', true)
        .order('created_at', ascending: false);

    return response.map((json) => Course.fromJson(json)).toList();
  } catch (e) {
    print('Error en coursesProvider: $e');
    rethrow;
  }
});

/// Provider para detalles del curso
final courseDetailProvider = FutureProvider.family<Course, String>((
  ref,
  courseId,
) async {
  try {
    final response = await Supabase.instance.client
        .from('courses')
        .select('''
          *,
          themes (
            id,
            title,
            content,
            order_index,
            course_id,
            created_at,
            updated_at
          )
        ''')
        .eq('id', courseId)
        .single();

    return Course.fromJson(response);
  } catch (e) {
    print('Error en courseDetailProvider: $e');
    rethrow;
  }
});

/// =====================================================
/// PROVIDERS ESPECÍFICOS POR CURSO/TEMA
/// =====================================================

/// Provider para verificar si el usuario está inscrito en un curso
final isEnrolledProvider = FutureProvider.family<bool, String>((
  ref,
  courseId,
) async {
  try {
    return await UserService.isUserEnrolled(courseId);
  } catch (e) {
    print('Error en isEnrolledProvider: $e');
    return false;
  }
});

/// Provider para obtener el progreso de un curso
final courseProgressProvider = FutureProvider.family<double, String>((
  ref,
  courseId,
) async {
  try {
    return await UserService.getCourseProgress(courseId);
  } catch (e) {
    print('Error en courseProgressProvider: $e');
    return 0.0;
  }
});

/// Provider para el último tema visto de un curso
final lastViewedThemeProvider = FutureProvider.family<String?, String>((
  ref,
  courseId,
) async {
  try {
    return await UserService.getLastViewedTheme(courseId);
  } catch (e) {
    print('Error en lastViewedThemeProvider: $e');
    return null;
  }
});

/// Provider para el progreso de un tema específico
final userProgressThemeProvider =
    FutureProvider.family<
      Map<String, dynamic>?,
      ({String courseId, String themeId})
    >((ref, params) async {
      try {
        return await UserService.getThemeProgress(
          courseId: params.courseId,
          themeId: params.themeId,
        );
      } catch (e) {
        print('Error en userProgressThemeProvider: $e');
        return null;
      }
    });

/// =====================================================
/// PROVIDERS PARA TEMAS Y EJERCICIOS
/// =====================================================

/// Provider para obtener los temas de un curso
final courseThemesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      courseId,
    ) async {
      try {
        final response = await Supabase.instance.client
            .from('themes')
            .select('*')
            .eq('course_id', courseId)
            .order('order_index');

        return List<Map<String, dynamic>>.from(response);
      } catch (e) {
        print('Error en courseThemesProvider: $e');
        return [];
      }
    });

/// Provider para obtener un tema específico
final themeDetailProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, themeId) async {
      try {
        final response = await Supabase.instance.client
            .from('themes')
            .select('''
          *,
          courses:course_id (
            id,
            title,
            difficulty
          )
        ''')
            .eq('id', themeId)
            .single();

        return response;
      } catch (e) {
        print('Error en themeDetailProvider: $e');
        return null;
      }
    });

/// Provider para obtener ejercicios de un tema
final themeExercisesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      themeId,
    ) async {
      try {
        final response = await Supabase.instance.client
            .from('exercises')
            .select('*')
            .eq('theme_id', themeId)
            .order('order_index');

        return List<Map<String, dynamic>>.from(response);
      } catch (e) {
        print('Error en themeExercisesProvider: $e');
        return [];
      }
    });

/// Provider para obtener formularios de un tema
final themeFormsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      themeId,
    ) async {
      try {
        final response = await Supabase.instance.client
            .from('forms')
            .select('*')
            .eq('theme_id', themeId);

        return List<Map<String, dynamic>>.from(response);
      } catch (e) {
        print('Error en themeFormsProvider: $e');
        return [];
      }
    });

/// =====================================================
/// PROVIDERS PARA RESPUESTAS DEL USUARIO
/// =====================================================

/// Provider para obtener las respuestas del usuario a un ejercicio
final userExerciseAnswersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      exerciseId,
    ) async {
      try {
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser == null) return [];

        final response = await Supabase.instance.client
            .from('user_answers')
            .select('*')
            .eq('user_id', currentUser.id)
            .eq('exercise_id', exerciseId)
            .order('answered_at', ascending: false);

        return List<Map<String, dynamic>>.from(response);
      } catch (e) {
        print('Error en userExerciseAnswersProvider: $e');
        return [];
      }
    });

/// Provider para obtener envíos de formularios del usuario
final userFormSubmissionsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      formId,
    ) async {
      try {
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser == null) return [];

        final response = await Supabase.instance.client
            .from('user_form_submissions')
            .select('*')
            .eq('user_id', currentUser.id)
            .eq('form_id', formId)
            .order('submitted_at', ascending: false);

        return List<Map<String, dynamic>>.from(response);
      } catch (e) {
        print('Error en userFormSubmissionsProvider: $e');
        return [];
      }
    });

/// =====================================================
/// PROVIDERS PARA AUTENTICACIÓN
/// =====================================================

/// =====================================================
/// PROVIDERS DE CONFIGURACIÓN Y UTILIDADES
/// =====================================================

/// Provider para configuración de la aplicación
final appConfigProvider = Provider<Map<String, dynamic>>((ref) {
  return {
    'app_name': 'Pro Aula',
    'version': '1.0.0',
    'max_upload_size': 10 * 1024 * 1024, // 10MB
    'supported_image_formats': ['jpg', 'jpeg', 'png', 'webp'],
    'items_per_page': 20,
  };
});

/// Provider para el cliente de Supabase
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// =====================================================
/// PROVIDERS PARA BÚSQUEDA Y FILTROS
/// =====================================================

/// Provider para la búsqueda de cursos
final courseSearchProvider = StateProvider<String>((ref) => '');

/// Provider para el filtro de dificultad
final difficultyFilterProvider = StateProvider<String?>((ref) => null);

/// Provider para el filtro de categoría
final categoryFilterProvider = StateProvider<String?>((ref) => null);

/// Provider para cursos filtrados
final filteredCoursesProvider = Provider<AsyncValue<List<Course>>>((ref) {
  final coursesAsync = ref.watch(coursesProvider);
  final searchQuery = ref.watch(courseSearchProvider);
  final selectedDifficulty = ref.watch(difficultyFilterProvider);
  final selectedCategory = ref.watch(categoryFilterProvider);

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

/// =====================================================
/// PROVIDERS PARA ESTADÍSTICAS GLOBALES
/// =====================================================

/// Provider para estadísticas de la plataforma
final platformStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final response = await Supabase.instance.client
        .from('platform_stats')
        .select('*')
        .single();

    return response;
  } catch (e) {
    print('Error en platformStatsProvider: $e');
    return {
      'total_users': 0,
      'total_courses': 0,
      'total_themes': 0,
      'total_exercises': 0,
      'active_users': 0,
      'total_answers_submitted': 0,
      'total_correct_answers': 0,
    };
  }
});

/// =====================================================
/// PROVIDERS PARA NOTIFICACIONES Y ALERTAS
/// =====================================================

/// Provider para notificaciones del usuario
final notificationsProvider = StateProvider<List<Map<String, dynamic>>>(
  (ref) => [],
);

/// Provider para mostrar/ocultar notificaciones
final showNotificationsProvider = StateProvider<bool>((ref) => false);

/// =====================================================
/// EXTENSIÓN ADICIONAL PARA CONSULREF
/// =====================================================

/// Extensión adicional para ConsumerRef (usado en ConsumerWidget)
