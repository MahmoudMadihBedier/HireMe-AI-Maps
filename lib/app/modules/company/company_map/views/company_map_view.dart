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
          Obx(
            () => controller.hasSelection
                ? IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: controller.resetLocation,
                  )
                : const SizedBox(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Obx(
            () => GoogleMap(
              onMapCreated: (map) => controller.mapController = map,
              initialCameraPosition: CameraPosition(
                target: controller.cameraPosition.value,
                zoom: 12,
              ),
              onTap: controller.onMapTap,
              markers: controller.selectedLocation.value != null
                  ? {
                      Marker(
                        markerId: const MarkerId('selected'),
                        position: controller.selectedLocation.value!,
                        infoWindow:
                            const InfoWindow(title: 'Company Location'),
                      ),
                    }
                  : {},
            ),
          ),
          if (controller.isLoading.value)
            const Center(child: CircularProgressIndicator()),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Obx(
              () => ElevatedButton(
                onPressed: controller.selectedLocation.value != null
                    ? controller.saveLocation
                    : null,
                child: const Text('Save Location'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
