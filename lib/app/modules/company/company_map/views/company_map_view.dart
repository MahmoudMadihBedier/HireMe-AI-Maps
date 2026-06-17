import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../controllers/company_map_controller.dart';
import 'widgets/map_app_bar_actions.dart';
import 'widgets/save_location_button.dart';

class CompanyMapView extends GetView<CompanyMapController> {
  const CompanyMapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        actions: const [MapAppBarActions()],
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
              markers: controller.markers,
            ),
          ),
          Obx(
            () => controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink(),
          ),
          const Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SaveLocationButton(),
          ),
        ],
      ),
    );
  }
}
