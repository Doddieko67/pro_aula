// lib/services/database_service.dart - VERSIÓN MEJORADA
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ NUEVA CLASE - NO MÁS MÉTODOS ESTÁTICOS
class DatabaseService {
  final SupabaseClient _supabase;

  DatabaseService(this._supabase);

  // =============================================================================
  // GESTIÓN DE INSCRIPCIÓN Y PROGRESO
  // =============================================================================

  /// Inscribe al usuario en un curso creando progreso para el primer tema
  Future<bool> enrollUserInCourse(String courseId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar si ya está inscrito
      final existingProgress = await _supabase
          .from('user_progress')
          .select('id')
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .limit(1)
          .maybeSingle();

      if (existingProgress != null) {
        print('Usuario ya está inscrito en el curso');
        return true; // Ya está inscrito
      }

      // Obtener el primer tema del curso
      final firstThemeResponse = await _supabase
          .from('themes')
          .select('id')
          .eq('course_id', courseId)
          .order('order_index', ascending: true)
          .limit(1)
          .maybeSingle();

      if (firstThemeResponse == null) {
        throw Exception('El curso no tiene temas disponibles');
      }

      // Crear registro de progreso para el primer tema
      await _supabase.from('user_progress').insert({
        'user_id': userId,
        'course_id': courseId,
        'theme_id': firstThemeResponse['id'],
        'progress_percentage': 0.0,
        'is_completed': false,
        'last_viewed_at': DateTime.now().toIso8601String(),
      });

      print('Usuario inscrito exitosamente en el curso');
      return true;
    } catch (e) {
      print('Error enrolling user in course: $e');
      return false;
    }
  }

  /// Verifica si el usuario está inscrito en un curso
  Future<bool> isUserEnrolledInCourse(String courseId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('user_progress')
          .select('id')
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .limit(1)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking enrollment: $e');
      return false;
    }
  }

  /// Obtiene el progreso del curso completo del usuario
  Future<double> getCourseProgress(String courseId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0.0;

      // Obtener todos los temas del curso
      final themesResponse = await _supabase
          .from('themes')
          .select('id')
          .eq('course_id', courseId)
          .order('order_index', ascending: true);

      if (themesResponse.isEmpty) return 0.0;

      // Obtener progreso del usuario en todos los temas del curso
      final progressResponse = await _supabase
          .from('user_progress')
          .select('theme_id, is_completed')
          .eq('user_id', userId)
          .eq('course_id', courseId);

      final totalThemes = themesResponse.length;
      final completedThemes = progressResponse
          .where((progress) => progress['is_completed'] == true)
          .length;

      return totalThemes > 0 ? (completedThemes / totalThemes) * 100 : 0.0;
    } catch (e) {
      print('Error getting course progress: $e');
      return 0.0;
    }
  }

  /// Obtiene el último tema visto del curso
  Future<String?> getLastViewedTheme(String courseId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('user_progress')
          .select('theme_id, last_viewed_at')
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .order('last_viewed_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response?['theme_id'];
    } catch (e) {
      print('Error getting last viewed theme: $e');
      return null;
    }
  }

  /// Actualiza el progreso de un tema
  Future<bool> updateThemeProgress({
    required String courseId,
    required String themeId,
    required double progressPercentage,
    bool? isCompleted,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final updateData = {
        'progress_percentage': progressPercentage.clamp(0.0, 100.0),
        'last_viewed_at': DateTime.now().toIso8601String(),
      };

      if (isCompleted != null) {
        updateData['is_completed'] = isCompleted;
      }

      // Verificar si ya existe un registro de progreso para este tema
      final existingProgress = await _supabase
          .from('user_progress')
          .select('id')
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .eq('theme_id', themeId)
          .maybeSingle();

      if (existingProgress != null) {
        // Actualizar registro existente
        await _supabase
            .from('user_progress')
            .update(updateData)
            .eq('user_id', userId)
            .eq('course_id', courseId)
            .eq('theme_id', themeId);
      } else {
        // Crear nuevo registro
        await _supabase.from('user_progress').insert({
          'user_id': userId,
          'course_id': courseId,
          'theme_id': themeId,
          ...updateData,
        });
      }

      // Actualizar último tema visto en la tabla users
      await _supabase
          .from('users')
          .update({
            'last_viewed_course_id': courseId,
            'last_viewed_theme_id': themeId,
          })
          .eq('id', userId);

      return true;
    } catch (e) {
      print('Error updating theme progress: $e');
      return false;
    }
  }

  // =============================================================================
  // GESTIÓN DE CURSOS
  // =============================================================================

  /// Obtiene todos los cursos publicados
  Future<List<Map<String, dynamic>>> getPublishedCourses() async {
    try {
      final response = await _supabase
          .from('courses')
          .select('*')
          .eq('is_published', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting courses: $e');
      return [];
    }
  }

  /// Obtiene un curso específico por ID
  Future<Map<String, dynamic>?> getCourseById(String courseId) async {
    try {
      final response = await _supabase
          .from('courses')
          .select('*')
          .eq('id', courseId)
          .single();

      return response;
    } catch (e) {
      print('Error getting course by ID: $e');
      return null;
    }
  }

  // =============================================================================
  // GESTIÓN DE TEMAS
  // =============================================================================

  /// Obtiene todos los temas de un curso
  Future<List<Map<String, dynamic>>> getCourseThemes(String courseId) async {
    try {
      final response = await _supabase
          .from('themes')
          .select('*')
          .eq('course_id', courseId)
          .order('order_index', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting course themes: $e');
      return [];
    }
  }

  /// Obtiene un tema específico por ID
  Future<Map<String, dynamic>?> getThemeById(String themeId) async {
    try {
      final response = await _supabase
          .from('themes')
          .select('*')
          .eq('id', themeId)
          .single();

      return response;
    } catch (e) {
      print('Error getting theme by ID: $e');
      return null;
    }
  }

  /// Obtiene todos los ejercicios de un tema
  Future<List<Map<String, dynamic>>> getThemeExercises(String themeId) async {
    try {
      final response = await _supabase
          .from('exercises')
          .select('*')
          .eq('theme_id', themeId)
          .order('order_index', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting theme exercises: $e');
      return [];
    }
  }

  /// Obtiene todos los formularios de un tema
  Future<List<Map<String, dynamic>>> getThemeForms(String themeId) async {
    try {
      final response = await _supabase
          .from('forms')
          .select('*')
          .eq('theme_id', themeId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting theme forms: $e');
      return [];
    }
  }

  // =============================================================================
  // GESTIÓN DE EJERCICIOS Y RESPUESTAS
  // =============================================================================

  /// Guarda una respuesta del usuario a un ejercicio
  Future<bool> saveUserAnswer({
    required String exerciseId,
    required String userAnswer,
    required bool isCorrect,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Generar un ID único para la respuesta
      final answerId =
          '${userId}_${exerciseId}_${DateTime.now().millisecondsSinceEpoch}';

      await _supabase.from('user_answers').insert({
        'id': answerId,
        'user_id': userId,
        'exercise_id': exerciseId,
        'user_answer': userAnswer,
        'is_correct': isCorrect,
        'answered_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error saving user answer: $e');
      return false;
    }
  }

  // =============================================================================
  // GESTIÓN DE FORMULARIOS Y ENVÍOS
  // =============================================================================

  /// Guarda un envío de formulario del usuario
  Future<bool> saveFormSubmission({
    required String formId,
    required Map<String, dynamic> answers,
    required double score,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Generar un ID único para el envío
      final submissionId =
          '${userId}_${formId}_${DateTime.now().millisecondsSinceEpoch}';

      await _supabase.from('user_form_submissions').insert({
        'id': submissionId,
        'user_id': userId,
        'form_id': formId,
        'answers': answers,
        'score': score,
        'submitted_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error saving form submission: $e');
      return false;
    }
  }

  /// Obtiene los envíos de formulario del usuario
  Future<List<Map<String, dynamic>>> getUserFormSubmissions(
    String formId,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('user_form_submissions')
          .select('*')
          .eq('user_id', userId)
          .eq('form_id', formId)
          .order('submitted_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting user form submissions: $e');
      return [];
    }
  }

  // =============================================================================
  // GESTIÓN DE PERFIL DE USUARIO
  // =============================================================================

  /// Actualiza el último curso visto
  Future<bool> updateLastViewedCourse(String courseId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('users')
          .update({'last_viewed_course_id': courseId})
          .eq('id', userId);

      return true;
    } catch (e) {
      print('Error updating last viewed course: $e');
      return false;
    }
  }

  /// Obtiene estadísticas del usuario
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {
          'enrolledCourses': 0,
          'completedThemes': 0,
          'correctAnswers': 0,
          'totalAnswers': 0,
          'accuracy': 0.0,
        };
      }

      // Cursos inscritos (cursos únicos en user_progress)
      final enrolledCoursesResponse = await _supabase
          .from('user_progress')
          .select('course_id')
          .eq('user_id', userId);

      final enrolledCourses = enrolledCoursesResponse
          .map((e) => e['course_id'])
          .toSet()
          .length;

      // Temas completados
      final completedThemesResponse = await _supabase
          .from('user_progress')
          .select('id')
          .eq('user_id', userId)
          .eq('is_completed', true);

      final completedThemes = completedThemesResponse.length;

      // Respuestas correctas e incorrectas
      final answersResponse = await _supabase
          .from('user_answers')
          .select('is_correct')
          .eq('user_id', userId);

      final totalAnswers = answersResponse.length;
      final correctAnswers = answersResponse
          .where((answer) => answer['is_correct'] == true)
          .length;

      return {
        'enrolledCourses': enrolledCourses,
        'completedThemes': completedThemes,
        'correctAnswers': correctAnswers,
        'totalAnswers': totalAnswers,
        'accuracy': totalAnswers > 0
            ? (correctAnswers / totalAnswers) * 100
            : 0.0,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {
        'enrolledCourses': 0,
        'completedThemes': 0,
        'correctAnswers': 0,
        'totalAnswers': 0,
        'accuracy': 0.0,
      };
    }
  }

  /// Obtiene el perfil del usuario
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  /// Actualiza el perfil del usuario
  Future<bool> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase.from('users').update(updates).eq('id', userId);

      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // =============================================================================
  // GESTIÓN DE INTERACCIONES AI
  // =============================================================================

  /// Guarda una interacción con IA
  Future<bool> saveAIInteraction({
    required String prompt,
    required Map<String, dynamic> response,
    String interactionType = 'chat',
    String? relatedCourseId,
    String? relatedThemeId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Generar un ID único para la interacción
      final interactionId =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}';

      await _supabase.from('ai_interactions').insert({
        'id': interactionId,
        'user_id': userId,
        'prompt': prompt,
        'response': response,
        'interaction_type': interactionType,
        'related_course_id': relatedCourseId,
        'related_theme_id': relatedThemeId,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error saving AI interaction: $e');
      return false;
    }
  }

  /// Obtiene historial de interacciones con IA
  Future<List<Map<String, dynamic>>> getAIInteractions({
    String? courseId,
    String? themeId,
    int limit = 10,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Query base
      var query = _supabase
          .from('ai_interactions')
          .select('*')
          .eq('user_id', userId);

      // Agregar filtros opcionales
      if (courseId != null) {
        query = query.eq('related_course_id', courseId);
      }

      if (themeId != null) {
        query = query.eq('related_theme_id', themeId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting AI interactions: $e');
      return [];
    }
  }

  // =============================================================================
  // UTILIDADES
  // =============================================================================

  /// Verifica la conexión con la base de datos
  Future<bool> checkConnection() async {
    try {
      await _supabase.from('courses').select('id').limit(1);
      return true;
    } catch (e) {
      print('Database connection error: $e');
      return false;
    }
  }

  /// Obtiene información de debugging de la base de datos
  Future<Map<String, dynamic>> getDebugInfo() async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      return {
        'isAuthenticated': userId != null,
        'userId': userId,
        'connectionHealthy': await checkConnection(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'isAuthenticated': false,
        'userId': null,
        'connectionHealthy': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}

// ✅ PROVIDER PARA DatabaseService
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService(Supabase.instance.client);
});

// ✅ PROVIDER PARA VERIFICAR CONEXIÓN
final databaseConnectionProvider = FutureProvider<bool>((ref) async {
  final db = ref.read(databaseServiceProvider);
  return await db.checkConnection();
});

// ✅ PROVIDER PARA ESTADÍSTICAS DEL USUARIO
final userStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final db = ref.read(databaseServiceProvider);
  return await db.getUserStats();
});

// ✅ PROVIDER PARA PERFIL DEL USUARIO
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final db = ref.read(databaseServiceProvider);
  return await db.getUserProfile();
});
