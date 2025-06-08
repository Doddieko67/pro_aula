// lib/services/database_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // =============================================================================
  // GESTIÓN DE INSCRIPCIÓN Y PROGRESO
  // =============================================================================

  /// Inscribe al usuario en un curso creando progreso para el primer tema
  static Future<bool> enrollUserInCourse(String courseId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

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
  static Future<bool> isUserEnrolledInCourse(String courseId) async {
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
  static Future<double> getCourseProgress(String courseId) async {
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
  static Future<String?> getLastViewedTheme(String courseId) async {
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
  static Future<bool> updateThemeProgress({
    required String courseId,
    required String themeId,
    required double progressPercentage,
    bool? isCompleted,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

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
  static Future<List<Map<String, dynamic>>> getPublishedCourses() async {
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

  // =============================================================================
  // GESTIÓN DE EJERCICIOS Y RESPUESTAS
  // =============================================================================

  /// Guarda una respuesta del usuario
  static Future<bool> saveUserAnswer({
    required String exerciseId,
    required String userAnswer,
    required bool isCorrect,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      await _supabase.from('user_answers').insert({
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
  // GESTIÓN DE PERFIL DE USUARIO
  // =============================================================================

  /// Actualiza el último curso visto
  static Future<bool> updateLastViewedCourse(String courseId) async {
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
  static Future<Map<String, dynamic>> getUserStats() async {
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
  static Future<Map<String, dynamic>?> getUserProfile() async {
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

  // =============================================================================
  // GESTIÓN DE INTERACCIONES AI (CORREGIDO)
  // =============================================================================

  /// Guarda una interacción con IA
  static Future<bool> saveAIInteraction({
    required String prompt,
    required Map<String, dynamic> response,
    String interactionType = 'chat',
    String? relatedCourseId,
    String? relatedThemeId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      await _supabase.from('ai_interactions').insert({
        'user_id': userId,
        'prompt': prompt,
        'response': response,
        'interaction_type': interactionType,
        'related_course_id': relatedCourseId,
        'related_theme_id': relatedThemeId,
      });

      return true;
    } catch (e) {
      print('Error saving AI interaction: $e');
      return false;
    }
  }

  /// Obtiene historial de interacciones con IA (VERSIÓN SIMPLIFICADA)
  static Future<List<Map<String, dynamic>>> getAIInteractions({
    String? courseId,
    String? themeId,
    int limit = 10,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Query base sin filtros opcionales problemáticos
      final response = await _supabase
          .from('ai_interactions')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      // Filtrar en memoria si es necesario (más seguro)
      var filteredResponse = List<Map<String, dynamic>>.from(response);

      if (courseId != null) {
        filteredResponse = filteredResponse
            .where((item) => item['related_course_id'] == courseId)
            .toList();
      }

      if (themeId != null) {
        filteredResponse = filteredResponse
            .where((item) => item['related_theme_id'] == themeId)
            .toList();
      }

      return filteredResponse;
    } catch (e) {
      print('Error getting AI interactions: $e');
      return [];
    }
  }

  // =============================================================================
  // UTILIDADES
  // =============================================================================

  /// Verifica la conexión con la base de datos
  static Future<bool> checkConnection() async {
    try {
      await _supabase.from('courses').select('id').limit(1);
      return true;
    } catch (e) {
      print('Database connection error: $e');
      return false;
    }
  }
}
