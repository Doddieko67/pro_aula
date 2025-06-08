// lib/widgets/last_viewed_course_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pro_aula/core/theme/app_theme.dart';
import 'package:pro_aula/models/course_model.dart';
import 'package:pro_aula/screens/course_detail_screen.dart'; // Importar CourseDetailScreen

class LastViewedCourseCard extends ConsumerWidget {
  final Course course;

  const LastViewedCourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Obtener el último tema visto y el progreso
    // Por ahora usaremos datos simulados
    final lastTheme = course.themes?.first;
    const progress = 0.6; // 60% de progreso simulado

    return Card(
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Imagen del curso
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.peachy,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: course.thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: course.thumbnailUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Icon(
                            Icons.science_outlined,
                            color: AppColors.vibrantRed,
                            size: 32,
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.science_outlined,
                            color: AppColors.vibrantRed,
                            size: 32,
                          ),
                        )
                      : const Icon(
                          Icons.science_outlined,
                          color: AppColors.vibrantRed,
                          size: 32,
                        ),
                ),
              ),

              const SizedBox(width: 16),

              // Información del curso
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    if (lastTheme != null) ...[
                      Text(
                        'Último: ${lastTheme.title}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),
                    ],

                    // Progreso
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progreso',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.vibrantRed,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.vibrantRed,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Botón de continuar
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.vibrantRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: AppColors.surface,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
