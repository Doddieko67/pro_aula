// lib/screens/course_detail_screen.dart - VERSIÓN ACTUALIZADA
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pro_aula/core/theme/app_theme.dart';
import 'package:pro_aula/models/course_model.dart';
import 'package:pro_aula/models/theme_model.dart';
import 'package:pro_aula/extensions/riverpod_extensions.dart'; // ✅ NUEVO IMPORT
import 'package:pro_aula/services/user_service.dart'; // ✅ NUEVO IMPORT
import 'package:pro_aula/widgets/theme_list_item.dart';
import 'package:pro_aula/screens/theme_content_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isHeaderExpanded = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _updateLastViewedCourse();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final isExpanded = _scrollController.offset < 200;
    if (isExpanded != _isHeaderExpanded) {
      setState(() {
        _isHeaderExpanded = isExpanded;
      });
    }
  }

  /// ✅ MÉTODO ACTUALIZADO CON MEJOR MANEJO DE ERRORES
  Future<void> _updateLastViewedCourse() async {
    try {
      await ref.updateLastViewedCourse(widget.courseId);
    } catch (error) {
      debugPrint('Error updating last viewed course: $error');
      // No mostrar error al usuario, es una operación secundaria
    }
  }

  /// ✅ MÉTODO COMPLETAMENTE REESCRITO CON MANEJO ROBUSTO
  Future<void> _enrollInCourse() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      _showLoginDialog();
      return;
    }

    try {
      // Mostrar indicador de carga
      ref.read(isLoadingProvider.notifier).state = true;

      // Usar el nuevo método de la extensión
      final success = await ref.enrollUserInCourse(widget.courseId);

      if (!mounted) return;

      if (success) {
        _showSuccessMessage('¡Te has inscrito al curso exitosamente!');
      } else {
        _showErrorMessage(
          'Error al inscribirse en el curso. Intenta nuevamente.',
        );
      }
    } catch (error) {
      if (mounted) {
        _showErrorMessage('Error al inscribirse: ${_getReadableError(error)}');
      }
    } finally {
      if (mounted) {
        ref.read(isLoadingProvider.notifier).state = false;
      }
    }
  }

  /// ✅ MÉTODO REESCRITO CON MEJOR FLUJO
  Future<void> _startCourse() async {
    try {
      ref.read(isLoadingProvider.notifier).state = true;

      // Verificar que el usuario está inscrito
      final isEnrolled = await UserService.isUserEnrolled(widget.courseId);
      if (!isEnrolled) {
        if (mounted) {
          _showErrorMessage('Debes inscribirte en el curso primero.');
        }
        return;
      }

      // Obtener curso y temas
      final course = await ref.read(
        courseDetailProvider(widget.courseId).future,
      );

      if (course.themes?.isEmpty == true) {
        if (mounted) {
          _showErrorMessage('Este curso no tiene contenido disponible aún.');
        }
        return;
      }

      // Obtener último tema visto o usar el primero
      final lastViewedThemeId = await ref.read(
        lastViewedThemeProvider(widget.courseId).future,
      );
      final themeId = lastViewedThemeId ?? course.themes!.first.id;

      // Navegar al tema
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ThemeContentScreen(themeId: themeId, courseId: widget.courseId),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        _showErrorMessage(
          'Error al iniciar el curso: ${_getReadableError(error)}',
        );
      }
    } finally {
      if (mounted) {
        ref.read(isLoadingProvider.notifier).state = false;
      }
    }
  }

  /// ✅ MÉTODO ACTUALIZADO PARA REFRESCAR DATOS
  Future<void> _refreshData() async {
    try {
      ref.read(isLoadingProvider.notifier).state = true;

      // Usar el método de la extensión para refrescar todos los datos
      await ref.refreshAllUserData();

      // Invalidar providers específicos de este curso
      ref.invalidate(courseDetailProvider(widget.courseId));
      ref.invalidate(isEnrolledProvider(widget.courseId));
      ref.invalidate(courseProgressProvider(widget.courseId));
      ref.invalidate(lastViewedThemeProvider(widget.courseId));
    } catch (error) {
      if (mounted) {
        _showErrorMessage(
          'Error al actualizar datos: ${_getReadableError(error)}',
        );
      }
    } finally {
      if (mounted) {
        ref.read(isLoadingProvider.notifier).state = false;
      }
    }
  }

  /// ✅ MÉTODOS AUXILIARES PARA MOSTRAR MENSAJES
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.progressGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Reintentar',
          textColor: Colors.white,
          onPressed: _refreshData,
        ),
      ),
    );
  }

  /// ✅ MÉTODO PARA OBTENER ERRORES LEGIBLES
  String _getReadableError(dynamic error) {
    if (error.toString().contains('foreign key constraint')) {
      return 'Error de datos del usuario. Intenta cerrar sesión e iniciar nuevamente.';
    }
    if (error.toString().contains('invalid input syntax')) {
      return 'Error en formato de datos. Contacta soporte si persiste.';
    }
    if (error.toString().contains('network')) {
      return 'Error de conexión. Verifica tu internet.';
    }
    return error.toString().length > 100
        ? 'Error inesperado. Intenta nuevamente.'
        : error.toString();
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar Sesión Requerido'),
        content: const Text(
          'Necesitas crear una cuenta o iniciar sesión para inscribirte en cursos y guardar tu progreso.',
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

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseDetailProvider(widget.courseId));

    return Scaffold(
      body: courseAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.vibrantRed),
          ),
        ),
        error: (error, stack) => _buildErrorView(error),
        data: (course) => RefreshIndicator(
          onRefresh: _refreshData,
          color: AppColors.vibrantRed,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildSliverAppBar(course),
              SliverToBoxAdapter(child: _buildCourseContent(course)),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ VISTA DE ERROR MEJORADA
  Widget _buildErrorView(dynamic error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.peachy,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error al cargar el curso',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _getReadableError(error),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.border,
                    foregroundColor: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _refreshData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vibrantRed,
                    foregroundColor: AppColors.surface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(Course course) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.vibrantRed,
      flexibleSpace: FlexibleSpaceBar(
        title: AnimatedOpacity(
          opacity: _isHeaderExpanded ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Text(
            course.title,
            style: const TextStyle(
              color: AppColors.surface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // ✅ IMAGEN CON MANEJO MEJORADO DE ERRORES
            course.thumbnailUrl != null
                ? CachedNetworkImage(
                    imageUrl: course.thumbnailUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.peachy,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.vibrantRed,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => _buildFallbackImage(),
                  )
                : _buildFallbackImage(),

            // Overlay gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),

            // Información del curso
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: AnimatedOpacity(
                opacity: _isHeaderExpanded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: _buildHeaderInfo(course),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ IMAGEN DE RESPALDO MEJORADA
  Widget _buildFallbackImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.vibrantRed, AppColors.golden],
        ),
      ),
      child: const Icon(
        Icons.science_outlined,
        size: 80,
        color: AppColors.surface,
      ),
    );
  }

  Widget _buildHeaderInfo(Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _getDifficultyColor(course.difficulty),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            course.difficulty,
            style: const TextStyle(
              color: AppColors.surface,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          course.title,
          style: const TextStyle(
            color: AppColors.surface,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (course.themes?.isNotEmpty == true)
          Text(
            '${course.themes!.length} temas disponibles',
            style: TextStyle(
              color: AppColors.surface.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
      ],
    );
  }

  Widget _buildCourseContent(Course course) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Descripción del curso
          if (course.description?.isNotEmpty == true) ...[
            _buildDescriptionSection(course.description!),
            const SizedBox(height: 24),
          ],

          // ✅ SECCIÓN DE PROGRESO MEJORADA
          _buildProgressSection(),
          const SizedBox(height: 24),

          // Lista de temas
          _buildThemesSection(course),
          const SizedBox(height: 100), // Espacio para elementos flotantes
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(String description) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.vibrantRed, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Acerca de este curso',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ SECCIÓN DE PROGRESO COMPLETAMENTE REESCRITA
  Widget _buildProgressSection() {
    final user = Supabase.instance.client.auth.currentUser;
    final isLoading = ref.watch(isLoadingProvider);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: isLoading
            ? _buildLoadingCard()
            : user == null
            ? _buildGuestActionCard()
            : _buildUserProgressCard(),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return const SizedBox(
      height: 100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.vibrantRed),
            ),
            SizedBox(height: 12),
            Text(
              'Procesando...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestActionCard() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.vibrantRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.login, size: 48, color: AppColors.vibrantRed),
        ),
        const SizedBox(height: 16),
        Text(
          'Inicia sesión para inscribirte',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Crea una cuenta gratuita para acceder a todos los cursos y guardar tu progreso.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/auth'),
            icon: const Icon(Icons.person_add),
            label: const Text('Crear Cuenta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vibrantRed,
              foregroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserProgressCard() {
    return Consumer(
      builder: (context, ref, child) {
        final isEnrolledAsync = ref.watch(isEnrolledProvider(widget.courseId));

        return isEnrolledAsync.when(
          loading: () => _buildLoadingCard(),
          error: (error, stack) => _buildErrorCard(error.toString()),
          data: (isEnrolled) {
            if (!isEnrolled) {
              return _buildEnrollmentCard();
            }

            final progressAsync = ref.watch(
              courseProgressProvider(widget.courseId),
            );
            return progressAsync.when(
              loading: () => _buildLoadingCard(),
              error: (error, stack) => _buildErrorCard(error.toString()),
              data: (progress) => _buildProgressCard(progress),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorCard(String errorMessage) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.error,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Error al cargar información',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          _getReadableError(errorMessage),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _refreshData,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.vibrantRed,
            foregroundColor: AppColors.surface,
          ),
        ),
      ],
    );
  }

  Widget _buildEnrollmentCard() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.progressGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.school_outlined,
            size: 48,
            color: AppColors.progressGreen,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '¡Comienza tu aprendizaje!',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Inscríbete en este curso para acceder a todo el contenido y hacer seguimiento de tu progreso.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _enrollInCourse,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Inscribirse en el Curso'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.progressGreen,
              foregroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tu progreso',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.vibrantRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${progress.toInt()}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.vibrantRed,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: progress / 100,
          backgroundColor: AppColors.border,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.vibrantRed),
          minHeight: 8,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _startCourse,
            icon: Icon(progress > 0 ? Icons.play_arrow : Icons.start),
            label: Text(progress > 0 ? 'Continuar Curso' : 'Comenzar Curso'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vibrantRed,
              foregroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemesSection(Course course) {
    if (course.themes?.isEmpty == true) {
      return _buildEmptyThemesCard();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.list_alt, color: AppColors.vibrantRed, size: 20),
            const SizedBox(width: 8),
            Text(
              'Contenido del curso',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: course.themes!.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: AppColors.border.withOpacity(0.5)),
            itemBuilder: (context, index) {
              final theme = course.themes![index];
              return EnhancedThemeListItem(
                theme: theme,
                courseId: course.id,
                index: index + 1,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyThemesCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.golden.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.hourglass_empty,
                size: 48,
                color: AppColors.golden,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Contenido próximamente',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Este curso está en desarrollo. Los temas se agregarán pronto.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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

/// ✅ WIDGET ACTUALIZADO PARA TEMAS CON MEJOR MANEJO DE ESTADOS
class EnhancedThemeListItem extends ConsumerWidget {
  final CourseTheme theme;
  final String courseId;
  final int index;

  const EnhancedThemeListItem({
    super.key,
    required this.theme,
    required this.courseId,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProgressAsync = ref.watch(
      userProgressThemeProvider((courseId: courseId, themeId: theme.id)),
    );

    return InkWell(
      onTap: () => _navigateToTheme(context, ref),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildThemeNumber(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap para comenzar',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildProgressIndicator(themeProgressAsync),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _buildTrailingIcon(themeProgressAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeNumber() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.vibrantRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.vibrantRed.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          index.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.vibrantRed,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(
    AsyncValue<Map<String, dynamic>?> progressAsync,
  ) {
    return progressAsync.when(
      loading: () => Container(
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
        child: const LinearProgressIndicator(
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.vibrantRed),
        ),
      ),
      error: (error, stack) => Container(
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      data: (progress) {
        if (progress == null) {
          return Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }

        final progressPercentage =
            (progress['progress_percentage'] as num?)?.toDouble() ?? 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
              child: LinearProgressIndicator(
                value: progressPercentage / 100,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.vibrantRed,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${progressPercentage.toInt()}% completado',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrailingIcon(AsyncValue<Map<String, dynamic>?> progressAsync) {
    return progressAsync.whenOrNull(
          data: (progress) => progress?['is_completed'] == true
              ? const Icon(
                  Icons.check_circle,
                  color: AppColors.progressGreen,
                  size: 24,
                )
              : const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
        ) ??
        const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textTertiary,
        );
  }

  Future<void> _navigateToTheme(BuildContext context, WidgetRef ref) async {
    try {
      // Actualizar progreso antes de navegar usando la extensión
      await ref.updateThemeProgress(
        courseId: courseId,
        themeId: theme.id,
        progressPercentage: 0.0, // Se iniciará desde 0 si es la primera vez
      );

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ThemeContentScreen(themeId: theme.id, courseId: courseId),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir tema: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
