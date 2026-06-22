import 'package:get/get.dart';

import '../controllers/company_public_controller.dart';

class CompanyPublicBinding extends Bindings {
  @override
  void dependencies() {
    final companyId = Get.parameters['companyId'] ?? '';
    Get.lazyPut<CompanyPublicController>(
      () => CompanyPublicController(companyId: companyId),
    );
  }
}
