import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hire_me/app/modules/company/company_map/controllers/company_map_controller.dart';

class SaveLocationButton extends GetView<CompanyMapController> {
  const SaveLocationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isEditMode.value &&
          controller.selectedLocation.value != null) {
        return ElevatedButton(
          onPressed: controller.saveLocation,
          child: const Text('Save Location'),
        );
      }
      return const SizedBox.shrink();
    });
  }
}
