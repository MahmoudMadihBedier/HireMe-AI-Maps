import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hire_me/app/modules/job_seeker/dashboard/controllers/job_seeker_dashboard_controller.dart';
import 'package:hire_me/app/modules/job_seeker/recommendations/controllers/recommendations_controller.dart';
import 'package:hire_me/app/modules/job_seeker/recommendations/views/widgets/recommended_job_card.dart';
import 'package:hire_me/core/utils/app_color.dart';
import 'package:hire_me/core/utils/app_text_style.dart';

class RecommendationsView extends GetView<RecommendationsController> {
  const RecommendationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardCtrl = Get.find<JobSeekerDashboardController>();

    return Obx(() {
      if (controller.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.only(top: 40),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.errorMessage.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 60, color: AppColor.greyLight),
                const SizedBox(height: 12),
                Text(
                  controller.errorMessage.value,
                  style: TextStyle(color: AppColor.greyLight),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: controller.fetchRecommendations,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.kblue,
                    foregroundColor: AppColor.kwhite,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (controller.recommendations.isEmpty) {
        return Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.auto_awesome, size: 70, color: AppColor.greyLight),
                const SizedBox(height: 12),
                Text(
                  'No recommendations yet',
                  style: CustomTextstyle.poppins500Grey.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  'Complete your profile to get AI-powered job suggestions',
                  style: TextStyle(color: AppColor.greyLight, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: controller.fetchRecommendations,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.kblue,
                    foregroundColor: AppColor.kwhite,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 8, 25, 0),
            child: Row(
              children: [
                Text(
                  'Recommended for You',
                  style: CustomTextstyle.poppinsBold.copyWith(
                    fontSize: 18,
                    color: AppColor.eblack,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: controller.fetchRecommendations,
                  child: Icon(Icons.refresh_rounded,
                      color: AppColor.kblue, size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: controller.recommendations.length,
            itemBuilder: (context, index) {
              final rec = controller.recommendations[index];
              return Obx(
                () => RecommendedJobCard(
                  job: rec.job,
                  isSaved: dashboardCtrl.isJobSaved(rec.jobId),
                  onSaveTap: () => dashboardCtrl.toggleSaveJob(rec.jobId),
                  distance: dashboardCtrl.jobDistances[rec.job.companyId],
                  matchPercentage: rec.matchPercentage,
                  reasons: rec.reasons,
                ),
              );
            },
          ),
        ],
      );
    });
  }
}
