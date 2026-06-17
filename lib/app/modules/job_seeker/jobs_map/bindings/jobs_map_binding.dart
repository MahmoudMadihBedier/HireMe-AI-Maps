import 'package:get/get.dart';

import '../controllers/jobs_map_controller.dart';

class JobsMapBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<JobsMapController>(() => JobsMapController());
  }
}
