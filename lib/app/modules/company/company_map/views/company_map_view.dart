import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../controllers/company_map_controller.dart';

class CompanyMapView extends GetView<CompanyMapController> {
  const CompanyMapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        actions: [
          Obx(() {
            if (controller.isEditMode.value) {
              return TextButton(
                onPressed: controller.cancelEdit,
                child: const Text('Cancel'),
              );
            }
            return IconButton(
              icon: const Icon(Icons.edit),
              onPressed: controller.enterEditMode,
              tooltip: 'Edit Location',
            );
          }),
        ],
      ),
      body: Stack(
        children: [
          Obx(
            () => GoogleMap(
              onMapCreated: controller.onMapCreated,
              initialCameraPosition: CameraPosition(
                target: controller.cameraPosition.value,
                zoom: 12,
              ),
              onTap: controller.onMapTap,
              markers: _buildMarkers(),
            ),
          ),
          if (controller.isLoading.value)
            const Center(child: CircularProgressIndicator()),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Obx(() {
              if (controller.isEditMode.value &&
                  controller.selectedLocation.value != null) {
                return ElevatedButton(
                  onPressed: controller.saveLocation,
                  child: const Text('Save Location'),
                );
              }
              return const SizedBox.shrink();
            }),
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    if (controller.savedLocation.value != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('saved'),
          position: controller.savedLocation.value!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: controller.companyName.value),
        ),
      );
    }
    if (controller.isEditMode.value &&
        controller.selectedLocation.value != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('selected'),
          position: controller.selectedLocation.value!,
        ),
      );
    }
    return markers;
  }
}
