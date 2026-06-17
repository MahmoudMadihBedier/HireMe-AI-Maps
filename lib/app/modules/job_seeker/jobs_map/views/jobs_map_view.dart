import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:hire_me/core/utils/app_color.dart';
import '../controllers/jobs_map_controller.dart';

class JobsMapView extends GetView<JobsMapController> {
  const JobsMapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator(color: AppColor.kblue));
      }

      if (!controller.hasLocationPermission.value) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off, size: 64, color: AppColor.kblue),
              const SizedBox(height: 16),
              Text(
                'Location access needed',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Geolocator.openAppSettings(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.kblue,
                  foregroundColor: AppColor.kwhite,
                ),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }

      return Stack(
        children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  controller.userPosition.value!.latitude,
                  controller.userPosition.value!.longitude,
                ),
                zoom: 12,
              ),
              markers: controller.markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          if (controller.markers.isEmpty &&
              controller.companiesWithNoLocation.value > 0)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColor.kwhite,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Some jobs are hidden — companies haven\'t set their location yet',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
        ],
      );
    });
  }
}
