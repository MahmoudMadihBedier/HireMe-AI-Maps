import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hire_me/core/utils/app_color.dart';
import 'package:hire_me/app/routes/app_pages.dart';
import 'package:hire_me/app/modules/job_seeker/job_details/controllers/job_seeker_job_details_controller.dart';

class ApplyButton extends GetView<JobSeekerJobDetailsController> {
  const ApplyButton({super.key});

  @override
  Widget build(BuildContext context) {
    final job = controller.job.value!;
    final isClosed = job.status.toLowerCase() == 'closed';

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isClosed ? null : controller.goToApplyJob,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.kblue,
          disabledBackgroundColor: AppColor.greyLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: Text(
          isClosed ? 'Closed' : 'Apply Now',
          style: TextStyle(
            color: AppColor.kwhite,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class AnalyzeCvButton extends GetView<JobSeekerJobDetailsController> {
  const AnalyzeCvButton({super.key});

  @override
  Widget build(BuildContext context) {
    final job = controller.job.value!;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => Get.toNamed(
          Routes.jobSeekerCvAnalysis,
          arguments: {
            'jobDescription':
                '${job.description}\n\nRequirements:\n${job.requirements}',
          },
        ),
        icon: const Icon(Icons.analytics_outlined, size: 20),
        label: const Text(
          'Analyze My CV',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColor.kblue,
          side: BorderSide(color: AppColor.kblue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
      ),
    );
  }
}
