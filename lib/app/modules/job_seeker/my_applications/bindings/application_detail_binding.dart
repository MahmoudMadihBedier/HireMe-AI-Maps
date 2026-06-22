import 'package:get/get.dart';

import '../controllers/application_detail_controller.dart';

class ApplicationDetailBinding extends Bindings {
  @override
  void dependencies() {
    final applicationId = Get.parameters['applicationId'] ?? '';
    Get.lazyPut<ApplicationDetailController>(
      () => ApplicationDetailController(applicationId: applicationId),
    );
  }
}
