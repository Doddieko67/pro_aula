// lib/widgets/course_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pro_aula/core/theme/app_theme.dart';
import 'package:pro_aula/models/course_model.dart';
import 'package:pro_aula/providers/supabase_providers.dart';
import 'package:pro_aula/screens/course_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CourseCard extends ConsumerWidget {
  final Course course;

  const CourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navegación directa a CourseDetailScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailScreen(courseId: course.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del curso - Mantener proporción original
            Expanded(
              flex: 2, // <-- CAMBIO AQUÍ: Reducido de 3 a 2
              child: Container(
                width: double.infinity,
                child: course.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: course.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.peachy,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.vibrantRed,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.peachy,
                          child: const Icon(
                            Icons.science_outlined,
                            size: 40,
                            color: AppColors.vibrantRed,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.peachy,
                        child: const Icon(
                          Icons.science_outlined,
                          size: 40,
                          color: AppColors.vibrantRed,
                        ),
                      ),
              ),
            ),

            // Contenido - Mantener estructura original pero con más espacio
            Expanded(
              flex: 3, // <-- CAMBIO AQUÍ: Aumentado de 2 a 3
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Text(
                      course.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),
                    // Dificultad
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(
                          course.difficulty,
                        ).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getDifficultyColor(course.difficulty),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        course.difficulty,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _getDifficultyColor(course.difficulty),
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Progreso (solo si el usuario está logueado)
                    if (user != null) ...[
                      _buildProgressIndicator(context, ref),
                    ] else ...[
                      // Número de temas para invitados
                      Row(
                        children: [
                          const Icon(
                            Icons.play_circle_outline,
                            size: 16,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${course.themes?.length ?? 0} temas',
                              style: Theme.of(
                                context,
                              ).textTheme.labelSmall?.copyWith(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, WidgetRef ref) {
    // Aquí podrías usar un provider para obtener el progreso del usuario en este curso
    // Por ahora simularemos un progreso
    const progress = 0.0; // TODO: Implementar progreso real

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progreso',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontSize: 11),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 4,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.vibrantRed,
            ),
          ),
        ),
      ],
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
