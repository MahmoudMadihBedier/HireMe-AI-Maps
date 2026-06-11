import 'package:get/get.dart';

import '../controllers/company_map_controller.dart';

class CompanyMapBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CompanyMapController>(
      () => CompanyMapController(),
    );
  }
}
