// lib/services/user_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Verifica que el usuario autenticado exista en la tabla users
  /// Si no existe, lo crea automáticamente
  static Future<bool> ensureUserExists() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        print('No hay usuario autenticado');
        return false;
      }

      print('Verificando usuario: ${currentUser.id}');

      // Verificar si el usuario existe en la tabla users
      final existingUser = await _client
          .from('users')
          .select('id')
          .eq('id', currentUser.id)
          .maybeSingle();

      if (existingUser != null) {
        print('Usuario ya existe en la tabla users');
        return true;
      }

      print('Usuario no existe en tabla users, creando...');

      // Crear usuario si no existe
      await _client.from('users').insert({
        'id': currentUser.id,
        'email': currentUser.email,
        'name':
            currentUser.userMetadata?['name'] ??
            currentUser.userMetadata?['full_name'] ??
            currentUser.email?.split('@')[0],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('Usuario creado exitosamente en tabla users');
      return true;
    } catch (error) {
      print('Error en ensureUserExists: $error');
      return false;
    }
  }

  /// Inscribe al usuario en un curso de forma segura
  static Future<bool> enrollUserInCourse(String courseId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        print('No hay usuario autenticado para inscribir en curso');
        return false;
      }

      // Asegurar que el usuario existe primero
      final userExists = await ensureUserExists();
      if (!userExists) {
        print('No se pudo verificar/crear el usuario');
        return false;
      }

      // Verificar si ya está inscrito
      final existingProgress = await _client
          .from('user_progress')
          .select('id')
          .eq('user_id', currentUser.id)
          .eq('course_id', courseId)
          .maybeSingle();

      if (existingProgress != null) {
        print('Usuario ya está inscrito en el curso');
        return true;
      }

      // Obtener el primer tema del curso para crear progreso inicial
      final firstTheme = await _client
          .from('themes')
          .select('id')
          .eq('course_id', courseId)
          .order('order_index')
          .limit(1)
          .maybeSingle();

      if (firstTheme == null) {
        print('No se encontraron temas para el curso');
        return false;
      }

      // Crear progreso inicial
      await _client.from('user_progress').insert({
        'user_id': currentUser.id,
        'course_id': courseId,
        'theme_id': firstTheme['id'],
        'progress_percentage': 0.0,
        'is_completed': false,
        'last_viewed_at': DateTime.now().toIso8601String(),
      });

      // Actualizar last_viewed_course_id del usuario
      await _client
          .from('users')
          .update({
            'last_viewed_course_id': courseId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', currentUser.id);

      print('Usuario inscrito exitosamente en el curso');
      return true;
    } catch (error) {
      print('Error en enrollUserInCourse: $error');
      return false;
    }
  }

  /// Actualiza el progreso de un tema de forma segura
  static Future<bool> updateThemeProgress({
    required String courseId,
    required String themeId,
    required double progressPercentage,
    bool? isCompleted,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        print('No hay usuario autenticado para actualizar progreso');
        return false;
      }

      // Asegurar que el usuario existe
      final userExists = await ensureUserExists();
      if (!userExists) {
        print('No se pudo verificar/crear el usuario');
        return false;
      }

      final now = DateTime.now().toIso8601String();
      final completedStatus = isCompleted ?? (progressPercentage >= 100.0);

      // Buscar progreso existente
      final existingProgress = await _client
          .from('user_progress')
          .select('id, progress_percentage')
          .eq('user_id', currentUser.id)
          .eq('course_id', courseId)
          .eq('theme_id', themeId)
          .maybeSingle();

      if (existingProgress != null) {
        // Actualizar progreso existente (solo si es mayor al actual)
        final currentProgress =
            (existingProgress['progress_percentage'] as num?)?.toDouble() ??
            0.0;
        final newProgress = progressPercentage > currentProgress
            ? progressPercentage
            : currentProgress;

        await _client
            .from('user_progress')
            .update({
              'progress_percentage': newProgress,
              'is_completed': completedStatus,
              'last_viewed_at': now,
            })
            .eq('id', existingProgress['id']);
      } else {
        // Crear nuevo progreso
        await _client.from('user_progress').insert({
          'user_id': currentUser.id,
          'course_id': courseId,
          'theme_id': themeId,
          'progress_percentage': progressPercentage,
          'is_completed': completedStatus,
          'last_viewed_at': now,
        });
      }

      // Actualizar usuario con último tema visto
      await _client
          .from('users')
          .update({
            'last_viewed_course_id': courseId,
            'last_viewed_theme_id': themeId,
            'updated_at': now,
          })
          .eq('id', currentUser.id);

      print('Progreso de tema actualizado exitosamente');
      return true;
    } catch (error) {
      print('Error en updateThemeProgress: $error');
      return false;
    }
  }

  /// Guarda la respuesta de un usuario a un ejercicio
  static Future<bool> saveUserAnswer({
    required String exerciseId,
    required String userAnswer,
    required bool isCorrect,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        print('No hay usuario autenticado para guardar respuesta');
        return false;
      }

      // Asegurar que el usuario existe
      final userExists = await ensureUserExists();
      if (!userExists) {
        print('No se pudo verificar/crear el usuario');
        return false;
      }

      // Generar ID válido (usar gen_random_uuid de la base de datos)
      await _client.from('user_answers').insert({
        'user_id': currentUser.id,
        'exercise_id': exerciseId,
        'user_answer': userAnswer,
        'is_correct': isCorrect,
        'answered_at': DateTime.now().toIso8601String(),
      });

      print('Respuesta del usuario guardada exitosamente');
      return true;
    } catch (error) {
      print('Error en saveUserAnswer: $error');
      return false;
    }
  }

  /// Guarda la respuesta de un formulario
  static Future<bool> saveFormSubmission({
    required String formId,
    required Map<String, dynamic> answers,
    double? score,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        print('No hay usuario autenticado para guardar formulario');
        return false;
      }

      // Asegurar que el usuario existe
      final userExists = await ensureUserExists();
      if (!userExists) {
        print('No se pudo verificar/crear el usuario');
        return false;
      }

      await _client.from('user_form_submissions').insert({
        'user_id': currentUser.id,
        'form_id': formId,
        'answers': answers,
        'score': score,
        'submitted_at': DateTime.now().toIso8601String(),
      });

      print('Formulario guardado exitosamente');
      return true;
    } catch (error) {
      print('Error en saveFormSubmission: $error');
      return false;
    }
  }

  /// Verifica si el usuario está inscrito en un curso
  static Future<bool> isUserEnrolled(String courseId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return false;

      final result = await _client.rpc(
        'is_user_enrolled',
        params: {'p_user_id': currentUser.id, 'p_course_id': courseId},
      );

      return result as bool? ?? false;
    } catch (error) {
      print('Error verificando inscripción: $error');
      // Fallback: verificar directamente en user_progress
      try {
        final currentUser = _client.auth.currentUser;
        if (currentUser == null) return false;

        final progress = await _client
            .from('user_progress')
            .select('id')
            .eq('user_id', currentUser.id)
            .eq('course_id', courseId)
            .maybeSingle();

        return progress != null;
      } catch (fallbackError) {
        print('Error en fallback de isUserEnrolled: $fallbackError');
        return false;
      }
    }
  }

  /// Obtiene el progreso general de un curso
  static Future<double> getCourseProgress(String courseId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return 0.0;

      final result = await _client.rpc(
        'get_course_progress',
        params: {'p_user_id': currentUser.id, 'p_course_id': courseId},
      );

      return (result as num?)?.toDouble() ?? 0.0;
    } catch (error) {
      print('Error obteniendo progreso del curso: $error');
      // Fallback: calcular manualmente
      try {
        final currentUser = _client.auth.currentUser;
        if (currentUser == null) return 0.0;

        // Obtener todos los temas del curso
        final themes = await _client
            .from('themes')
            .select('id')
            .eq('course_id', courseId);

        if (themes.isEmpty) return 0.0;

        // Obtener progreso completado
        final completedThemes = await _client
            .from('user_progress')
            .select('id')
            .eq('user_id', currentUser.id)
            .eq('course_id', courseId)
            .eq('is_completed', true);

        final progress = (completedThemes.length / themes.length) * 100;
        return progress.toDouble();
      } catch (fallbackError) {
        print('Error en fallback de getCourseProgress: $fallbackError');
        return 0.0;
      }
    }
  }

  /// Actualiza el último curso visto
  static Future<bool> updateLastViewedCourse(String courseId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return false;

      // Asegurar que el usuario existe
      final userExists = await ensureUserExists();
      if (!userExists) return false;

      await _client
          .from('users')
          .update({
            'last_viewed_course_id': courseId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', currentUser.id);

      return true;
    } catch (error) {
      print('Error actualizando último curso visto: $error');
      return false;
    }
  }

  /// Obtiene las estadísticas del usuario
  static Future<Map<String, int>> getUserStats() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        return {
          'totalCoursesEnrolled': 0,
          'totalCoursesCompleted': 0,
          'totalThemesCompleted': 0,
          'totalExercisesAnswered': 0,
          'totalCorrectAnswers': 0,
        };
      }

      final result = await _client.rpc(
        'get_user_stats',
        params: {'p_user_id': currentUser.id},
      );

      if (result != null && result is List && result.isNotEmpty) {
        final stats = result.first;
        return {
          'totalCoursesEnrolled': stats['total_courses_enrolled'] ?? 0,
          'totalCoursesCompleted': stats['total_courses_completed'] ?? 0,
          'totalThemesCompleted': stats['total_themes_completed'] ?? 0,
          'totalExercisesAnswered': stats['total_exercises_answered'] ?? 0,
          'totalCorrectAnswers': stats['total_correct_answers'] ?? 0,
        };
      }

      return {
        'totalCoursesEnrolled': 0,
        'totalCoursesCompleted': 0,
        'totalThemesCompleted': 0,
        'totalExercisesAnswered': 0,
        'totalCorrectAnswers': 0,
      };
    } catch (error) {
      print('Error obteniendo estadísticas del usuario: $error');
      return {
        'totalCoursesEnrolled': 0,
        'totalCoursesCompleted': 0,
        'totalThemesCompleted': 0,
        'totalExercisesAnswered': 0,
        'totalCorrectAnswers': 0,
      };
    }
  }

  /// Obtiene el perfil completo del usuario
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return null;

      // Asegurar que el usuario existe
      final userExists = await ensureUserExists();
      if (!userExists) return null;

      final profile = await _client
          .from('users')
          .select('*')
          .eq('id', currentUser.id)
          .single();

      return profile;
    } catch (error) {
      print('Error obteniendo perfil del usuario: $error');
      return null;
    }
  }

  /// Actualiza el perfil del usuario
  static Future<bool> updateUserProfile({
    String? name,
    String? avatarUrl,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return false;

      // Asegurar que el usuario existe
      final userExists = await ensureUserExists();
      if (!userExists) return false;

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

      await _client.from('users').update(updateData).eq('id', currentUser.id);

      print('Perfil actualizado exitosamente');
      return true;
    } catch (error) {
      print('Error actualizando perfil: $error');
      return false;
    }
  }

  /// Limpia todos los datos del usuario (para testing o logout completo)
  static Future<void> clearUserData() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return;

      // Usar la función SQL para limpiar datos de forma segura
      await _client.rpc(
        'clean_user_data',
        params: {'p_user_id': currentUser.id},
      );

      print('Datos del usuario limpiados usando función SQL');
    } catch (error) {
      print(
        'Error limpiando datos con función SQL, intentando manualmente: $error',
      );

      // Fallback: eliminar manualmente
      try {
        final currentUser = _client.auth.currentUser;
        if (currentUser == null) return;

        // Eliminar datos en orden correcto (respetando foreign keys)
        await _client
            .from('ai_interactions')
            .delete()
            .eq('user_id', currentUser.id);
        await _client
            .from('user_form_submissions')
            .delete()
            .eq('user_id', currentUser.id);
        await _client
            .from('user_answers')
            .delete()
            .eq('user_id', currentUser.id);
        await _client
            .from('user_progress')
            .delete()
            .eq('user_id', currentUser.id);

        // Actualizar referencias en users
        await _client
            .from('users')
            .update({
              'last_viewed_course_id': null,
              'last_viewed_theme_id': null,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', currentUser.id);

        print('Datos del usuario limpiados manualmente');
      } catch (manualError) {
        print('Error limpiando datos manualmente: $manualError');
      }
    }
  }

  /// Obtiene el último tema visto de un curso
  static Future<String?> getLastViewedTheme(String courseId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return null;

      final user = await _client
          .from('users')
          .select('last_viewed_course_id, last_viewed_theme_id')
          .eq('id', currentUser.id)
          .single();

      // Solo retornar el tema si coincide con el curso actual
      if (user['last_viewed_course_id'] == courseId) {
        return user['last_viewed_theme_id'] as String?;
      }

      return null;
    } catch (error) {
      print('Error obteniendo último tema visto: $error');
      return null;
    }
  }

  /// Marca un tema como completado
  static Future<bool> markThemeAsCompleted({
    required String courseId,
    required String themeId,
  }) async {
    return await updateThemeProgress(
      courseId: courseId,
      themeId: themeId,
      progressPercentage: 100.0,
      isCompleted: true,
    );
  }

  /// Obtiene el progreso de un tema específico
  static Future<Map<String, dynamic>?> getThemeProgress({
    required String courseId,
    required String themeId,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return null;

      final progress = await _client
          .from('user_progress')
          .select('*')
          .eq('user_id', currentUser.id)
          .eq('course_id', courseId)
          .eq('theme_id', themeId)
          .maybeSingle();

      return progress;
    } catch (error) {
      print('Error obteniendo progreso del tema: $error');
      return null;
    }
  }
}
