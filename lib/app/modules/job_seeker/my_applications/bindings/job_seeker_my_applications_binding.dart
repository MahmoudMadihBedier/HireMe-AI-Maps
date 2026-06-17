import 'package:get/get.dart';

import 'package:hire_me/app/modules/job_seeker/saved_jobs/controllers/job_seeker_saved_jobs_controller.dart';

import '../controllers/job_seeker_my_applications_controller.dart';

class JobSeekerMyApplicationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<JobSeekerMyApplicationsController>(
      () => JobSeekerMyApplicationsController(),
    );
    Get.lazyPut<JobSeekerSavedJobsController>(() => JobSeekerSavedJobsController());
  }
}
