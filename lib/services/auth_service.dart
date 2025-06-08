// lib/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io' show Platform;

class AuthService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  // Configuración de Google Sign-In
  static const String _webClientId =
      '79558485851-r0sh30uu822p353l0hf596p0355ifpdt.apps.googleusercontent.com';
  static const String _iosClientId =
      '79558485851-fu7531gtb8s9e61s4ej5rjddc90jc71i.apps.googleusercontent.com';

  // ==========================================
  // GETTERS Y ESTADO
  // ==========================================

  /// Obtiene el usuario actual
  User? get currentUser => _supabaseClient.auth.currentUser;

  /// Stream del estado de autenticación
  Stream<AuthState> get authStateChanges =>
      _supabaseClient.auth.onAuthStateChange;

  /// Verifica si el usuario está autenticado
  bool get isAuthenticated => currentUser != null;

  /// Verifica si el usuario inició sesión con Google
  bool get isGoogleUser => currentUser?.appMetadata['provider'] == 'google';

  // ==========================================
  // AUTENTICACIÓN CON EMAIL/CONTRASEÑA
  // ==========================================

  /// Inicia sesión con email y contraseña
  Future<User?> signIn(String email, String password) async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      debugPrint("SignIn exitoso para: ${response.user?.email}");
      return response.user;
    } catch (e) {
      debugPrint("Error en signIn: $e");
      rethrow;
    }
  }

  /// Registra un nuevo usuario
  Future<User?> signUp(String email, String password, String fullName) async {
    try {
      final response = await _supabaseClient.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
      );
      debugPrint("SignUp exitoso para: ${response.user?.email}");
      return response.user;
    } catch (e) {
      debugPrint("Error en signUp: $e");
      rethrow;
    }
  }

  /// Envía email para restablecer contraseña
  Future<void> resetPasswordForEmail(String email, {String? redirectTo}) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: redirectTo,
      );
      debugPrint("Email de recuperación enviado a: $email");
    } catch (e) {
      debugPrint("Error en resetPasswordForEmail: $e");
      rethrow;
    }
  }

  // ==========================================
  // AUTENTICACIÓN CON GOOGLE
  // ==========================================

  /// Obtiene la instancia configurada de GoogleSignIn
  GoogleSignIn get _googleSignIn => GoogleSignIn(
    clientId: Platform.isIOS ? _iosClientId : null,
    serverClientId: _webClientId,
  );

  /// Inicia sesión con Google (método nativo)
  Future<User?> signInWithGoogleNative() async {
    try {
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw 'Inicio de sesión con Google cancelado.';
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw 'No se encontró Access Token de Google.';
      }
      if (idToken == null) {
        throw 'No se encontró ID Token de Google.';
      }

      final response = await _supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      debugPrint("Google SignIn exitoso para: ${response.user?.email}");
      return response.user;
    } catch (e) {
      debugPrint("Error en signInWithGoogleNative: $e");
      if (e.toString().contains('sign_in_failed') ||
          e.toString().contains('network')) {
        throw 'Error al iniciar sesión con Google. Verifica tu conexión o configuración.';
      }
      rethrow;
    }
  }

  /// Inicia sesión con Google (método webview - alternativo)
  Future<void> signInWithGoogleWebView() async {
    try {
      await _supabaseClient.auth.signInWithOAuth(OAuthProvider.google);
      debugPrint("Google WebView SignIn iniciado");
    } catch (e) {
      debugPrint("Error en signInWithGoogleWebView: $e");
      rethrow;
    }
  }

  // ==========================================
  // CERRAR SESIÓN
  // ==========================================

  /// Cierra sesión completamente (Supabase + Google)
  Future<void> signOut() async {
    try {
      // Cerrar sesión de Google si está activo
      await _signOutFromGoogle();

      // Cerrar sesión de Supabase
      await _supabaseClient.auth.signOut();
      debugPrint("SignOut completo exitoso");
    } catch (e) {
      debugPrint("Error en signOut: $e");
      rethrow;
    }
  }

  /// Cierra sesión solo de Supabase
  Future<void> signOutSupabaseOnly() async {
    try {
      await _supabaseClient.auth.signOut();
      debugPrint("SignOut de Supabase exitoso");
    } catch (e) {
      debugPrint("Error en signOutSupabaseOnly: $e");
      rethrow;
    }
  }

  /// Cierra sesión de Google Sign-In (método privado)
  Future<void> _signOutFromGoogle() async {
    try {
      final isSignedIn = await _googleSignIn.isSignedIn();
      if (isSignedIn) {
        await _googleSignIn.signOut();
        debugPrint("Google Sign-In: Sesión cerrada correctamente");
      }
    } catch (e) {
      debugPrint("Error al cerrar sesión de Google: $e");
      // No relanzamos el error porque el logout de Supabase es más importante
    }
  }

  /// Desconecta completamente Google (revoca tokens)
  Future<void> disconnectGoogle() async {
    try {
      await _googleSignIn.disconnect();
      debugPrint("Google Sign-In: Desconectado y tokens revocados");
    } catch (e) {
      debugPrint("Error al desconectar Google: $e");
      rethrow;
    }
  }

  // ==========================================
  // ACTUALIZACIÓN DE PERFIL
  // ==========================================

  /// Actualiza el email del usuario
  Future<void> updateEmail(String newEmail) async {
    try {
      await _supabaseClient.auth.updateUser(
        UserAttributes(email: newEmail.trim()),
      );
      debugPrint("Email actualizado a: $newEmail");
    } catch (e) {
      debugPrint("Error al actualizar email: $e");
      rethrow;
    }
  }

  /// Actualiza la contraseña del usuario
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabaseClient.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      debugPrint("Contraseña actualizada exitosamente");
    } catch (e) {
      debugPrint("Error al actualizar contraseña: $e");
      rethrow;
    }
  }

  /// Actualiza los metadatos del usuario
  Future<void> updateUserMetadata(Map<String, dynamic> data) async {
    try {
      await _supabaseClient.auth.updateUser(UserAttributes(data: data));
      debugPrint("Metadatos actualizados: $data");
    } catch (e) {
      debugPrint("Error al actualizar metadatos: $e");
      rethrow;
    }
  }

  // ==========================================
  // MANEJO DE ERRORES
  // ==========================================

  /// Convierte errores de Supabase a mensajes legibles
  String getErrorMessage(String error) {
    debugPrint("Supabase Auth Error: $error");

    // Errores específicos de Google
    if (error.toLowerCase().contains('google')) {
      if (error.toLowerCase().contains('cancelled') ||
          error.toLowerCase().contains('aborted')) {
        return 'Inicio de sesión con Google cancelado.';
      }
      return 'Error con Google: Revisa tu configuración o conexión.';
    }

    // Errores comunes de Supabase
    switch (error.toLowerCase()) {
      case 'invalid login credentials':
      case 'invalid_credentials':
        return 'Email o contraseña incorrectos.';

      case 'email not confirmed':
      case 'email_not_confirmed':
        return 'Debes confirmar tu email antes de iniciar sesión.';

      case 'user already registered':
      case 'user_already_exists':
        return 'Ya existe una cuenta con este email.';

      case 'invalid email':
      case 'invalid_email':
        return 'El formato del email no es válido.';

      case 'weak password':
      case 'password too short':
        return 'La contraseña debe tener al menos 6 caracteres.';

      case 'too many requests':
      case 'rate_limit_exceeded':
        return 'Demasiados intentos. Espera unos minutos.';

      case 'signup disabled':
        return 'El registro está temporalmente deshabilitado.';

      case 'email rate limit exceeded':
        return 'Has enviado demasiados emails. Espera antes de intentar de nuevo.';

      // Errores específicos que lanzas en el código
      case 'inicio de sesión con google cancelado.':
        return 'Inicio de sesión con Google cancelado.';

      case 'no se encontró access token de google.':
        return 'Token de acceso de Google no encontrado.';

      case 'no se encontró id token de google.':
        return 'ID Token de Google no encontrado.';

      case 'error al iniciar sesión con google. verifica tu conexión o configuración.':
        return 'Error al iniciar sesión con Google. Verifica tu conexión o configuración.';

      default:
        // Errores de red
        if (error.contains('network') ||
            error.contains('connection') ||
            error.contains('internet')) {
          return 'Error de conexión. Verifica tu conexión a internet.';
        }

        // Error genérico
        return 'Error inesperado. Inténtalo de nuevo.';
    }
  }

  // ==========================================
  // UTILIDADES
  // ==========================================

  /// Verifica si hay conexión de red (básico)
  Future<bool> hasNetworkConnection() async {
    try {
      // Intenta hacer ping a Supabase
      await _supabaseClient.from('users').select('id').limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Limpia la caché de autenticación
  Future<void> clearAuthCache() async {
    try {
      await _signOutFromGoogle();
      // Nota: Supabase maneja automáticamente la limpieza de tokens
      debugPrint("Caché de autenticación limpiada");
    } catch (e) {
      debugPrint("Error al limpiar caché: $e");
    }
  }
}
