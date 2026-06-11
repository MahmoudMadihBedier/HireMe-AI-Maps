import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../controllers/company_map_controller.dart';

class CompanyMapView extends GetView<CompanyMapController> {
  const CompanyMapView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map Test')),
      body: const GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(31.5, 34.4),
          zoom: 12,
        ),
      ),
    );
  }
}
