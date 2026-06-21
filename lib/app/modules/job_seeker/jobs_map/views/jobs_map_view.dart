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

      return Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: controller.initialCameraTarget,
              zoom: 12,
            ),
            markers: controller.markers,
            myLocationEnabled: controller.hasLocationPermission.value,
            myLocationButtonEnabled: controller.hasLocationPermission.value,
          ),
          if (!controller.hasLocationPermission.value)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColor.kwhite,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_off, color: AppColor.kblue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Location access is off. Showing jobs on the map anyway.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Geolocator.openAppSettings(),
                      child: const Text('Open Settings'),
                    ),
                  ],
                ),
              ),
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
