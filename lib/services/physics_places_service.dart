// lib/services/physics_places_service.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pro_aula/models/physics_place_model.dart';

class PhysicsPlacesService {
  // Lista de lugares de física (en producción vendría de base de datos)
  static final List<PhysicsPlace> _samplePlaces = [
    PhysicsPlace(
      id: '1',
      name: 'Puente Golden Gate',
      description: 'Icónico puente colgante que demuestra principios de ingeniería y física estructural.',
      location: const LatLng(37.8199, -122.4783),
      category: PhysicsCategory.mechanics,
      physicsTopics: ['Tensión', 'Fuerzas', 'Equilibrio', 'Materiales'],
      physicsExplanation: '''
El Golden Gate es un excelente ejemplo de física aplicada:

🔧 **Tensión y Compresión**: Los cables principales trabajan bajo tensión mientras las torres soportan compresión.

⚖️ **Equilibrio de Fuerzas**: El peso del puente se distribuye equilibradamente a través de los cables hacia las torres y anclajes.

🌪️ **Resonancia**: Diseñado para resistir vientos y evitar frecuencias de resonancia peligrosas.

📐 **Geometría Parabólica**: La forma catenaria de los cables distribuye uniformemente las cargas.
      ''',
      address: 'Golden Gate Bridge, San Francisco, CA',
      rating: 4.8,
      relatedThemes: ['tema_fuerzas', 'tema_equilibrio'],
    ),
    
    PhysicsPlace(
      id: '2',
      name: 'Observatorio Griffith',
      description: 'Observatorio astronómico que demuestra principios de óptica y astronomía.',
      location: const LatLng(34.1184, -118.3004),
      category: PhysicsCategory.optics,
      physicsTopics: ['Telescopios', 'Lentes', 'Refracción', 'Astronomía'],
      physicsExplanation: '''
El Observatorio Griffith es perfecto para entender óptica:

🔭 **Telescopios Refractores**: Usan lentes para enfocar la luz y magnificar objetos distantes.

💫 **Refracción de la Luz**: Las lentes curvan la luz según la ley de Snell.

🌈 **Dispersión**: Los prismas separan la luz blanca en sus componentes espectrales.

📡 **Radiación Electromagnética**: Detecta diferentes longitudes de onda del espacio.
      ''',
      address: '2800 E Observatory Rd, Los Angeles, CA',
      rating: 4.6,
      relatedThemes: ['tema_optica', 'tema_ondas'],
    ),

    PhysicsPlace(
      id: '3',
      name: 'Represa Hoover',
      description: 'Monumental obra de ingeniería que demuestra principios hidráulicos y energéticos.',
      location: const LatLng(36.0162, -114.7376),
      category: PhysicsCategory.mechanics,
      physicsTopics: ['Presión Hidráulica', 'Energía Potencial', 'Turbinas'],
      physicsExplanation: '''
La Represa Hoover es un laboratorio de física hidráulica:

💧 **Presión Hidrostática**: P = ρgh - La presión aumenta con la profundidad del agua.

⚡ **Conversión de Energía**: Energía potencial → cinética → eléctrica a través de turbinas.

🔧 **Principio de Arquímedes**: El agua ejerce fuerzas sobre la estructura de la represa.

🌊 **Flujo de Fluidos**: Las turbinas aprovechan la dinámica de fluidos para generar electricidad.
      ''',
      address: 'Hoover Dam, Nevada-Arizona Border',
      rating: 4.7,
      relatedThemes: ['tema_energia', 'tema_fluidos'],
    ),

    PhysicsPlace(
      id: '4',
      name: 'Torre de Telecomunicaciones',
      description: 'Antenas y torres que demuestran propagación de ondas electromagnéticas.',
      location: const LatLng(40.7589, -73.9851), // Empire State Building como ejemplo
      category: PhysicsCategory.electromagnetism,
      physicsTopics: ['Ondas Electromagnéticas', 'Frecuencia', 'Propagación'],
      physicsExplanation: '''
Las torres de telecomunicaciones son ejemplos de ondas electromagnéticas:

📡 **Propagación de Ondas**: Las señales viajan a la velocidad de la luz (c = 3×10⁸ m/s).

📻 **Frecuencias**: Diferentes servicios usan diferentes frecuencias del espectro electromagnético.

🔌 **Antenas**: Convierten señales eléctricas en ondas electromagnéticas y viceversa.

🌐 **Línea de Vista**: Las ondas de alta frecuencia necesitan visión directa entre antenas.
      ''',
      address: 'Various telecommunications towers',
      rating: 4.2,
      relatedThemes: ['tema_ondas', 'tema_electromagnetismo'],
    ),

    PhysicsPlace(
      id: '5',
      name: 'Planta de Energía Solar',
      description: 'Instalación que convierte energía solar en electricidad usando efecto fotoeléctrico.',
      location: const LatLng(35.0276, -118.8597), // Ejemplo en California
      category: PhysicsCategory.modernPhysics,
      physicsTopics: ['Efecto Fotoeléctrico', 'Fotones', 'Semiconductores'],
      physicsExplanation: '''
Las plantas solares demuestran física cuántica aplicada:

☀️ **Efecto Fotoeléctrico**: Los fotones liberan electrones de materiales semiconductores.

⚛️ **Energía de Fotones**: E = hf, donde h es la constante de Planck.

🔋 **Semiconductores**: El silicio dopado crea uniones p-n que generan corriente.

🌞 **Conversión Energética**: Energía luminosa → energía eléctrica con eficiencia del ~20%.
      ''',
      address: 'Solar power facilities',
      rating: 4.4,
      relatedThemes: ['tema_fisica_moderna', 'tema_energia'],
    ),
  ];

  /// Obtiene la ubicación actual del usuario
  Future<Position?> getCurrentLocation() async {
    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Obtener ubicación actual
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Obtiene lugares de física cerca de una ubicación
  Future<List<PhysicsPlace>> getPlacesNearby({
    required LatLng userLocation,
    double radiusKm = 50.0,
    PhysicsCategory? category,
    String? themeId,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Simular API call

      List<PhysicsPlace> filteredPlaces = _samplePlaces.where((place) {
        // Filtrar por distancia
        final distance = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          place.location.latitude,
          place.location.longitude,
        ) / 1000; // Convertir a km

        if (distance > radiusKm) return false;

        // Filtrar por categoría si se especifica
        if (category != null && place.category != category) return false;

        // Filtrar por tema relacionado si se especifica
        if (themeId != null && !place.relatedThemes.contains(themeId)) return false;

        return true;
      }).toList();

      // Ordenar por distancia
      filteredPlaces.sort((a, b) {
        final distanceA = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          a.location.latitude,
          a.location.longitude,
        );
        final distanceB = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          b.location.latitude,
          b.location.longitude,
        );
        return distanceA.compareTo(distanceB);
      });

      return filteredPlaces;
    } catch (e) {
      debugPrint('Error getting nearby places: $e');
      return [];
    }
  }

  /// Obtiene un lugar específico por ID
  PhysicsPlace? getPlaceById(String id) {
    try {
      return _samplePlaces.firstWhere((place) => place.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene lugares por categoría
  List<PhysicsPlace> getPlacesByCategory(PhysicsCategory category) {
    return _samplePlaces.where((place) => place.category == category).toList();
  }

  /// Calcula la distancia entre dos puntos
  double calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    ) / 1000; // Convertir a km
  }

  /// Busca lugares por texto
  List<PhysicsPlace> searchPlaces(String query) {
    final lowerQuery = query.toLowerCase();
    return _samplePlaces.where((place) {
      return place.name.toLowerCase().contains(lowerQuery) ||
             place.description.toLowerCase().contains(lowerQuery) ||
             place.physicsTopics.any((topic) => topic.toLowerCase().contains(lowerQuery));
    }).toList();
  }
}