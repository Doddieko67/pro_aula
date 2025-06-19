// lib/models/physics_place_model.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum PhysicsCategory {
  mechanics,      // Mecánica
  thermodynamics, // Termodinámica
  electromagnetism, // Electromagnetismo
  optics,         // Óptica
  waves,          // Ondas
  modernPhysics,  // Física moderna
  general,        // General
}

class PhysicsPlace {
  final String id;
  final String name;
  final String description;
  final LatLng location;
  final PhysicsCategory category;
  final List<String> physicsTopics;
  final String? imageUrl;
  final double? rating;
  final String? address;
  final String? website;
  final String? phone;
  final List<String> relatedThemes; // IDs de temas relacionados
  final String physicsExplanation;

  const PhysicsPlace({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.category,
    required this.physicsTopics,
    required this.physicsExplanation,
    this.imageUrl,
    this.rating,
    this.address,
    this.website,
    this.phone,
    this.relatedThemes = const [],
  });

  factory PhysicsPlace.fromJson(Map<String, dynamic> json) {
    return PhysicsPlace(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      location: LatLng(
        json['latitude']?.toDouble() ?? 0.0,
        json['longitude']?.toDouble() ?? 0.0,
      ),
      category: PhysicsCategory.values.firstWhere(
        (cat) => cat.name == json['category'],
        orElse: () => PhysicsCategory.general,
      ),
      physicsTopics: List<String>.from(json['physics_topics'] ?? []),
      physicsExplanation: json['physics_explanation'] ?? '',
      imageUrl: json['image_url'],
      rating: json['rating']?.toDouble(),
      address: json['address'],
      website: json['website'],
      phone: json['phone'],
      relatedThemes: List<String>.from(json['related_themes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'category': category.name,
      'physics_topics': physicsTopics,
      'physics_explanation': physicsExplanation,
      'image_url': imageUrl,
      'rating': rating,
      'address': address,
      'website': website,
      'phone': phone,
      'related_themes': relatedThemes,
    };
  }

  // Calcular distancia desde una ubicación
  double distanceFrom(LatLng userLocation) {
    // Simple cálculo de distancia euclidiana (para demo)
    // En producción usar fórmula haversine o Geolocator.distanceBetween
    final latDiff = location.latitude - userLocation.latitude;
    final lngDiff = location.longitude - userLocation.longitude;
    return (latDiff * latDiff + lngDiff * lngDiff) * 111.32; // Aproximado en km
  }
}

// Extensiones útiles
extension PhysicsCategoryExtension on PhysicsCategory {
  String get displayName {
    switch (this) {
      case PhysicsCategory.mechanics:
        return 'Mecánica';
      case PhysicsCategory.thermodynamics:
        return 'Termodinámica';
      case PhysicsCategory.electromagnetism:
        return 'Electromagnetismo';
      case PhysicsCategory.optics:
        return 'Óptica';
      case PhysicsCategory.waves:
        return 'Ondas';
      case PhysicsCategory.modernPhysics:
        return 'Física Moderna';
      case PhysicsCategory.general:
        return 'General';
    }
  }

  String get icon {
    switch (this) {
      case PhysicsCategory.mechanics:
        return '⚙️';
      case PhysicsCategory.thermodynamics:
        return '🌡️';
      case PhysicsCategory.electromagnetism:
        return '⚡';
      case PhysicsCategory.optics:
        return '🔍';
      case PhysicsCategory.waves:
        return '〰️';
      case PhysicsCategory.modernPhysics:
        return '⚛️';
      case PhysicsCategory.general:
        return '🔬';
    }
  }
}