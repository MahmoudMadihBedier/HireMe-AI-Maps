import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hire_me/app/modules/company/company_map/controllers/company_map_controller.dart';

class MapAppBarActions extends GetView<CompanyMapController> {
  const MapAppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
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
    });
  }
}
