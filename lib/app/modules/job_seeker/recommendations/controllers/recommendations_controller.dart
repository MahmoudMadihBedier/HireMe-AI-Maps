import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:hire_me/app/modules/job_seeker/dashboard/controllers/job_seeker_dashboard_controller.dart';
import 'package:hire_me/app/modules/job_seeker/dashboard/models/job_model.dart';
import 'package:hire_me/app/modules/job_seeker/profile/controllers/profile_controller.dart';

class JobRecommendation {
  final String jobId;
  final int matchPercentage;
  final List<String> reasons;
  final JobModel job;

  JobRecommendation({
    required this.jobId,
    required this.matchPercentage,
    required this.reasons,
    required this.job,
  });
}

class RecommendationsController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  final recommendations = <JobRecommendation>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  bool get profileHasMinimumData {
    final profile = Get.find<ProfileController>();
    return profile.skills.length >= 2 &&
        (profile.experience.isNotEmpty || profile.education.isNotEmpty);
  }

  Future<void> fetchRecommendations() async {
    final user = _auth.currentUser;
    if (user == null) {
      errorMessage.value = 'Not logged in';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Ensure fresh auth token before calling the function
      await user.getIdToken(true);

      final uid = user.uid;

      final result = await _functions
          .httpsCallable('getJobRecommendations')
          .call({'uid': uid});

      final data = List<dynamic>.from(result.data as List);
      final dashboardCtrl = Get.find<JobSeekerDashboardController>();
      final allJobs = dashboardCtrl.allJobs;

      final mapped = <JobRecommendation>[];
      for (final item in data) {
        final map = Map<String, dynamic>.from(item as Map);
        final jobId = map['jobId'] as String? ?? '';
        final matchPercentage = map['matchPercentage'] as int? ?? 0;
        final reasons =
            (map['reasons'] as List?)?.map((e) => e.toString()).toList() ??
            <String>[];

        final job = allJobs.firstWhereOrNull((j) => j.id == jobId);
        if (job == null) continue;

        mapped.add(
          JobRecommendation(
            jobId: jobId,
            matchPercentage: matchPercentage,
            reasons: reasons,
            job: job,
          ),
        );
      }

      mapped.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
      recommendations.value = mapped;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'unauthenticated') {
        errorMessage.value = 'Session expired. Please login again.';
      } else {
        errorMessage.value = e.message ?? 'Failed to get recommendations';
      }
    } catch (e) {
      errorMessage.value = 'Something went wrong';
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchRecommendations();
  }
}
