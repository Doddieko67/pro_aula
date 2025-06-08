// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pro_aula/core/theme/app_theme.dart';
import 'package:pro_aula/services/auth_service.dart';
import 'package:pro_aula/widgets/main_bottom_navigation.dart';
import 'package:pro_aula/providers/supabase_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Providers para ProfileScreen
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) return null;

  final response = await supabase
      .from('users')
      .select('*')
      .eq('id', userId)
      .maybeSingle();

  return response;
});

final userStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) {
    return {
      'totalCourses': 0,
      'completedCourses': 0,
      'totalExercises': 0,
      'correctAnswers': 0,
      'studyStreak': 0,
    };
  }

  // Obtener estadísticas del usuario
  final progressResponse = await supabase
      .from('user_progress')
      .select('course_id, is_completed')
      .eq('user_id', userId);

  final answersResponse = await supabase
      .from('user_answers')
      .select('is_correct')
      .eq('user_id', userId);

  final totalCourses = progressResponse.length;
  final completedCourses = progressResponse
      .where((progress) => progress['is_completed'] == true)
      .length;

  final totalExercises = answersResponse.length;
  final correctAnswers = answersResponse
      .where((answer) => answer['is_correct'] == true)
      .length;

  return {
    'totalCourses': totalCourses,
    'completedCourses': completedCourses,
    'totalExercises': totalExercises,
    'correctAnswers': correctAnswers,
    'studyStreak': 7, // TODO: Calcular racha real
  };
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final AuthService _authService = AuthService(); // Agregar esta línea
  bool _isEditingProfile = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // REEMPLAZA tu método _signOut() existente con este:
  Future<void> _signOut() async {
    try {
      // Usar el AuthService centralizado
      await _authService.signOut();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al cerrar sesión: ${_authService.getErrorMessage(error.toString())}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // OPCIONAL: Método para desconectar completamente Google
  Future<void> _disconnectGoogle() async {
    try {
      await _authService.disconnectGoogle();
      await _authService.signOutSupabaseOnly();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta de Google desconectada completamente'),
            backgroundColor: AppColors.progressGreen,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al desconectar Google: ${_authService.getErrorMessage(error.toString())}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // OPCIONAL: Diálogo mejorado con opción de desconectar Google
  void _showSignOutDialog() {
    final user = Supabase.instance.client.auth.currentUser;
    final isGoogleUser = user?.appMetadata['provider'] == 'google';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Qué acción quieres realizar?'),
            if (isGoogleUser) ...[
              const SizedBox(height: 12),
              const Text(
                'Como iniciaste sesión con Google, puedes:',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vibrantRed,
              foregroundColor: AppColors.surface,
            ),
            child: const Text('Cerrar Sesión'),
          ),
          if (isGoogleUser)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _disconnectGoogle();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.surface,
              ),
              child: const Text('Desconectar Google'),
            ),
        ],
      ),
    );
  }

  Future<void> _updateProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) return;

      await supabase
          .from('users')
          .update({'name': _nameController.text.trim()})
          .eq('id', userId);

      // Actualizar email si cambió
      if (_emailController.text.trim() != supabase.auth.currentUser?.email) {
        await supabase.auth.updateUser(
          UserAttributes(email: _emailController.text.trim()),
        );
      }

      ref.invalidate(userProfileProvider);

      setState(() {
        _isEditingProfile = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: AppColors.progressGreen,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar perfil: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final isGuest = user == null;

    if (isGuest) {
      return _buildGuestProfile();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        automaticallyImplyLeading: false,
        actions: [
          if (_isEditingProfile)
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditingProfile = false;
                });
              },
              child: const Text('Cancelar'),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                setState(() {
                  _isEditingProfile = true;
                });
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProfileProvider);
          ref.invalidate(userStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 24),
              _buildStatsSection(),
              const SizedBox(height: 24),
              _buildOptionsSection(),
              const SizedBox(height: 24),
              _buildAboutSection(),
              const SizedBox(height: 100), // Espacio para bottom nav
            ],
          ),
        ),
      ),
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildGuestProfile() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.peachy,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 80,
                  color: AppColors.vibrantRed,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Modo Invitado',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Crea una cuenta para guardar tu progreso y acceder a todas las funciones',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/auth'),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Crear Cuenta'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/auth'),
                  icon: const Icon(Icons.login),
                  label: const Text('Iniciar Sesión'),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildProfileHeader() {
    return Consumer(
      builder: (context, ref, child) {
        final profileAsync = ref.watch(userProfileProvider);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error: $error'),
              data: (profile) {
                final user = Supabase.instance.client.auth.currentUser!;
                final name = profile?['displayName'] ?? 'Usuario';
                final email = user.email ?? '';

                // Inicializar controladores cuando no estamos editando
                if (!_isEditingProfile) {
                  _nameController.text = name;
                  _emailController.text = email;
                }

                return Column(
                  children: [
                    // Avatar
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppColors.vibrantRed, AppColors.golden],
                            ),
                          ),
                          child: profile?['avatar_url'] != null
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: profile!['avatar_url'],
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) =>
                                        const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: AppColors.surface,
                                        ),
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: AppColors.surface,
                                ),
                        ),
                        if (_isEditingProfile)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.golden,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (_isEditingProfile) ...[
                      // Modo edición
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _isEditingProfile = false;
                                });
                              },
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _updateProfile,
                              child: const Text('Guardar'),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Modo visualización
                      Text(
                        name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.progressGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.progressGreen,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Miembro activo',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.progressGreen,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsSection() {
    return Consumer(
      builder: (context, ref, child) {
        final statsAsync = ref.watch(userStatsProvider);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estadísticas',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                statsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Text('Error: $error'),
                  data: (stats) => Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              icon: Icons.school_outlined,
                              title: 'Cursos',
                              value:
                                  '${stats['completedCourses']}/${stats['totalCourses']}',
                              color: AppColors.vibrantRed,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              icon: Icons.quiz_outlined,
                              title: 'Ejercicios',
                              value:
                                  '${stats['correctAnswers']}/${stats['totalExercises']}',
                              color: AppColors.golden,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              icon: Icons.local_fire_department,
                              title: 'Racha de estudio',
                              value: '${stats['studyStreak']} días',
                              color: AppColors.progressGreen,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              icon: Icons.trending_up,
                              title: 'Precisión',
                              value: stats['totalExercises'] > 0
                                  ? '${((stats['correctAnswers'] / stats['totalExercises']) * 100).toInt()}%'
                                  : '0%',
                              color: AppColors.aiAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Card(
      child: Column(
        children: [
          _buildOptionTile(
            icon: Icons.settings_outlined,
            title: 'Configuración',
            subtitle: 'Preferencias de la aplicación',
            onTap: () {
              // TODO: Navegar a configuración
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Configuración próximamente'),
                  backgroundColor: AppColors.vibrantRed,
                ),
              );
            },
          ),
          const Divider(),
          _buildOptionTile(
            icon: Icons.notifications_outlined,
            title: 'Notificaciones',
            subtitle: 'Gestionar recordatorios',
            onTap: () {
              // TODO: Navegar a notificaciones
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notificaciones próximamente'),
                  backgroundColor: AppColors.vibrantRed,
                ),
              );
            },
          ),
          const Divider(),
          _buildOptionTile(
            icon: Icons.download_outlined,
            title: 'Descargas',
            subtitle: 'Contenido offline',
            onTap: () {
              // TODO: Navegar a descargas
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Descargas próximamente'),
                  backgroundColor: AppColors.vibrantRed,
                ),
              );
            },
          ),
          const Divider(),
          _buildOptionTile(
            icon: Icons.help_outline,
            title: 'Ayuda y Soporte',
            subtitle: 'FAQ y contacto',
            onTap: () {
              // TODO: Navegar a ayuda
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ayuda próximamente'),
                  backgroundColor: AppColors.vibrantRed,
                ),
              );
            },
          ),
          const Divider(),
          _buildOptionTile(
            icon: Icons.logout,
            title: 'Cerrar Sesión',
            subtitle: 'Salir de tu cuenta',
            onTap: _showSignOutDialog,
            iconColor: AppColors.error,
            titleColor: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.vibrantRed),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, color: titleColor),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.peachy,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.science_outlined,
                size: 32,
                color: AppColors.vibrantRed,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Física AI',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Versión 1.0.0',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              'Aprende física con la ayuda de inteligencia artificial. Una experiencia de aprendizaje personalizada y adaptativa.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // TODO: Abrir términos y condiciones
                  },
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Términos'),
                ),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Abrir política de privacidad
                  },
                  icon: const Icon(Icons.privacy_tip_outlined),
                  label: const Text('Privacidad'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
