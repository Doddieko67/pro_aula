// lib/screens/physics_nearby_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pro_aula/core/theme/app_theme.dart';
import 'package:pro_aula/models/physics_place_model.dart';
import 'package:pro_aula/services/physics_places_service.dart';
import 'package:pro_aula/widgets/main_bottom_navigation.dart';

// Providers
final physicsPlacesServiceProvider = Provider((ref) => PhysicsPlacesService());

final userLocationProvider = FutureProvider<Position?>((ref) async {
  final service = ref.watch(physicsPlacesServiceProvider);
  return await service.getCurrentLocation();
});

final nearbyPlacesProvider = FutureProvider.family<List<PhysicsPlace>, LatLng>((ref, location) async {
  final service = ref.watch(physicsPlacesServiceProvider);
  return await service.getPlacesNearby(userLocation: location);
});

class PhysicsNearbyScreen extends ConsumerStatefulWidget {
  const PhysicsNearbyScreen({super.key});

  @override
  ConsumerState<PhysicsNearbyScreen> createState() => _PhysicsNearbyScreenState();
}

class _PhysicsNearbyScreenState extends ConsumerState<PhysicsNearbyScreen> {
  GoogleMapController? _mapController;
  PhysicsCategory? _selectedCategory;
  bool _showList = true;

  @override
  Widget build(BuildContext context) {
    final userLocationAsync = ref.watch(userLocationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Física cerca de ti'),
        backgroundColor: AppColors.vibrantRed,
        foregroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: Icon(_showList ? Icons.map : Icons.list),
            onPressed: () {
              setState(() {
                _showList = !_showList;
              });
            },
          ),
        ],
      ),
      body: userLocationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildLocationError(),
        data: (position) {
          if (position == null) return _buildLocationPermissionDenied();
          
          final userLocation = LatLng(position.latitude, position.longitude);
          final nearbyPlacesAsync = ref.watch(nearbyPlacesProvider(userLocation));

          return Column(
            children: [
              _buildCategoryFilter(),
              Expanded(
                child: nearbyPlacesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => _buildErrorWidget(error),
                  data: (places) {
                    final filteredPlaces = _selectedCategory == null
                        ? places
                        : places.where((place) => place.category == _selectedCategory).toList();

                    if (filteredPlaces.isEmpty) {
                      return _buildEmptyState();
                    }

                    return _showList
                        ? _buildPlacesList(filteredPlaces, userLocation)
                        : _buildPlacesMap(filteredPlaces, userLocation);
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const MainBottomNavigation(currentIndex: -1), // No highlight ningún tab
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildCategoryChip(null, 'Todos', '🔬'),
          ...PhysicsCategory.values.map((category) =>
            _buildCategoryChip(category, category.displayName, category.icon),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(PhysicsCategory? category, String label, String icon) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(
              color: isSelected ? AppColors.surface : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            )),
          ],
        ),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
        },
        backgroundColor: AppColors.peachy,
        selectedColor: AppColors.vibrantRed,
      ),
    );
  }

  Widget _buildPlacesList(List<PhysicsPlace> places, LatLng userLocation) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: places.length,
      itemBuilder: (context, index) {
        final place = places[index];
        final distance = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          place.location.latitude,
          place.location.longitude,
        ) / 1000;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () => _showPlaceDetail(place),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.golden.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            place.category.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              place.category.displayName,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${distance.toStringAsFixed(1)} km',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.vibrantRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (place.rating != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, color: AppColors.golden, size: 16),
                                Text(
                                  place.rating!.toStringAsFixed(1),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    place.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: place.physicsTopics.take(3).map((topic) =>
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.peachy,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          topic,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.vibrantRed,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlacesMap(List<PhysicsPlace> places, LatLng userLocation) {
    final markers = places.map((place) =>
      Marker(
        markerId: MarkerId(place.id),
        position: place.location,
        infoWindow: InfoWindow(
          title: place.name,
          snippet: place.category.displayName,
          onTap: () => _showPlaceDetail(place),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(_getCategoryColor(place.category)),
      ),
    ).toSet();

    // Agregar marcador del usuario
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: userLocation,
        infoWindow: const InfoWindow(title: 'Tu ubicación'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    return GoogleMap(
      onMapCreated: (controller) => _mapController = controller,
      initialCameraPosition: CameraPosition(
        target: userLocation,
        zoom: 12,
      ),
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }

  double _getCategoryColor(PhysicsCategory category) {
    switch (category) {
      case PhysicsCategory.mechanics:
        return BitmapDescriptor.hueRed;
      case PhysicsCategory.thermodynamics:
        return BitmapDescriptor.hueOrange;
      case PhysicsCategory.electromagnetism:
        return BitmapDescriptor.hueYellow;
      case PhysicsCategory.optics:
        return BitmapDescriptor.hueGreen;
      case PhysicsCategory.waves:
        return BitmapDescriptor.hueCyan;
      case PhysicsCategory.modernPhysics:
        return BitmapDescriptor.hueViolet;
      case PhysicsCategory.general:
        return BitmapDescriptor.hueRose;
    }
  }

  void _showPlaceDetail(PhysicsPlace place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.golden.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                place.category.icon,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  place.name,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  place.category.displayName,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.vibrantRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Descripción',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        place.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Física Aplicada',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        place.physicsExplanation,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Conceptos Físicos',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: place.physicsTopics.map((topic) =>
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.golden.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.golden.withOpacity(0.3)),
                            ),
                            child: Text(
                              topic,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.golden,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ).toList(),
                      ),
                      if (place.address != null) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: AppColors.vibrantRed),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                place.address!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error de ubicación',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'No se pudo obtener tu ubicación actual.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(userLocationProvider),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_disabled, size: 64, color: AppColors.golden),
            const SizedBox(height: 16),
            Text(
              'Permisos de ubicación',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Necesitamos acceso a tu ubicación para mostrar lugares de física cercanos.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(userLocationProvider),
              child: const Text('Permitir ubicación'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'No hay lugares cercanos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'No encontramos lugares de física en tu área. Intenta ampliar tu búsqueda.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}