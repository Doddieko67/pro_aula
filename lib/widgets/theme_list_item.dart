// lib/widgets/theme_list_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_aula/core/theme/app_theme.dart';
import 'package:pro_aula/models/theme_model.dart';
import 'package:pro_aula/providers/supabase_providers.dart';
import 'package:pro_aula/screens/theme_content_screen.dart'; // Importar ThemeContentScreen
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider para obtener el progreso de un tema específico
final themeProgressProvider =
    FutureProvider.family<
      Map<String, dynamic>?,
      ({String courseId, String themeId})
    >((ref, args) async {
      final supabase = ref.watch(supabaseClientProvider);
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) return null;

      final response = await supabase
          .from('user_progress')
          .select('progress_percentage, is_completed')
          .eq('user_id', userId)
          .eq('course_id', args.courseId)
          .eq('theme_id', args.themeId)
          .maybeSingle();

      return response;
    });

class ThemeListItem extends ConsumerWidget {
  final CourseTheme theme;
  final String courseId;
  final int index;

  const ThemeListItem({
    super.key,
    required this.theme,
    required this.courseId,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final isGuest = user == null;

    if (isGuest) {
      return _buildGuestThemeItem(context);
    }

    final progressAsync = ref.watch(
      themeProgressProvider((courseId: courseId, themeId: theme.id)),
    );

    return progressAsync.when(
      loading: () => _buildLoadingThemeItem(context),
      error: (error, stack) => _buildErrorThemeItem(context, error),
      data: (progress) => _buildThemeItem(context, progress),
    );
  }

  Widget _buildGuestThemeItem(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.peachy,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '$index',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.vibrantRed,
            ),
          ),
        ),
      ),
      title: Text(
        theme.title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: _buildThemeSubtitle(),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.textTertiary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textTertiary.withOpacity(0.3)),
        ),
        child: const Text(
          'Bloqueado',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
          ),
        ),
      ),
      onTap: () {
        _showLoginRequiredDialog(context);
      },
    );
  }

  Widget _buildLoadingThemeItem(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      title: Text(theme.title),
      subtitle: _buildThemeSubtitle(),
      trailing: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorThemeItem(BuildContext context, Object error) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.error_outline,
          color: AppColors.error,
          size: 20,
        ),
      ),
      title: Text(theme.title),
      subtitle: const Text('Error al cargar progreso'),
      trailing: const Icon(Icons.refresh, color: AppColors.error),
    );
  }

  Widget _buildThemeItem(BuildContext context, Map<String, dynamic>? progress) {
    final isCompleted = progress?['is_completed'] == true;
    final progressPercentage =
        (progress?['progress_percentage'] as num?)?.toDouble() ?? 0.0;
    final isStarted = progress != null;
    final canAccess = _canAccessTheme(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: _buildLeadingIcon(
        isCompleted,
        isStarted,
        canAccess,
        progressPercentage,
      ),
      title: Text(
        theme.title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: canAccess
              ? AppColors.darkTextPrimary
              : AppColors.textSecondary, // Mejor contraste
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThemeSubtitle(),
          if (isStarted && !isCompleted) ...[
            const SizedBox(height: 8),
            _buildProgressBar(progressPercentage),
          ],
        ],
      ),
      trailing: _buildTrailingWidget(isCompleted, isStarted, canAccess),
      onTap: canAccess ? () => _navigateToTheme(context) : null,
    );
  }

  Widget _buildLeadingIcon(
    bool isCompleted,
    bool isStarted,
    bool canAccess,
    double progress,
  ) {
    if (isCompleted) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.progressGreen,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.check, color: AppColors.surface, size: 20),
      );
    }

    if (isStarted) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.golden.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.golden, width: 2),
        ),
        child: Center(
          child: Text(
            '${progress.toInt()}%',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.golden,
            ),
          ),
        ),
      );
    }

    if (canAccess) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.vibrantRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.textSecondary, width: 1),
        ),
        child: Center(
          child: Text(
            '$index',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.lock_outline,
        color: AppColors.textTertiary,
        size: 20,
      ),
    );
  }

  Widget _buildThemeSubtitle() {
    // Extraer información del contenido JSONB si está disponible
    final content = theme.content;
    String subtitle = 'Contenido del tema';

    if (content.containsKey('duration')) {
      subtitle = '${content['duration']} min de lectura';
    } else if (content.containsKey('blocks')) {
      final blocks = content['blocks'] as List?;
      if (blocks != null) {
        subtitle = '${blocks.length} secciones';
      }
    }

    return Text(
      subtitle,
      style: TextStyle(
        fontSize: 12,
        color: AppColors.textLight, // Cambiado para mejor contraste
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress / 100,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.golden,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildTrailingWidget(
    bool isCompleted,
    bool isStarted,
    bool canAccess,
  ) {
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.progressGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.progressGreen),
        ),
        child: const Text(
          'Completado',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.progressGreen,
          ),
        ),
      );
    }

    if (isStarted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.golden.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.golden),
        ),
        child: const Text(
          'En progreso',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.golden,
          ),
        ),
      );
    }

    if (canAccess) {
      return const Icon(Icons.play_arrow, color: AppColors.vibrantRed);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.textTertiary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textTertiary.withOpacity(0.3)),
      ),
      child: const Text(
        'Bloqueado',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  bool _canAccessTheme(BuildContext context) {
    // Lógica para determinar si el usuario puede acceder al tema
    // Por ahora, permitimos acceso al primer tema siempre
    // Los demás temas requieren completar el anterior

    if (index == 1) return true; // Primer tema siempre accesible

    // TODO: Implementar lógica para verificar si el tema anterior está completado
    // Por ahora, permitimos acceso a todos los temas
    return true;
  }

  void _navigateToTheme(BuildContext context) {
    // Navegación directa a ThemeContentScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ThemeContentScreen(themeId: theme.id, courseId: courseId),
      ),
    );
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar Sesión Requerido'),
        content: const Text(
          'Necesitas crear una cuenta o iniciar sesión para acceder al contenido de los temas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, '/auth');
            },
            child: const Text('Iniciar Sesión'),
          ),
        ],
      ),
    );
  }
}
