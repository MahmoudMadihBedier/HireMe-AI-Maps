import 'package:get/get.dart';
import '../controllers/cv_analysis_controller.dart';

class CvAnalysisBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CvAnalysisController>(() {
      final args = Get.arguments as Map<String, dynamic>;
      return CvAnalysisController(
        jobDescription: args['jobDescription'] as String,
      );
    });
  }
}
