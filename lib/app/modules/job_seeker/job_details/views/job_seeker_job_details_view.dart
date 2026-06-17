import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hire_me/core/utils/app_color.dart';
import 'package:hire_me/core/utils/app_text_style.dart';

import '../controllers/job_seeker_job_details_controller.dart';
import '../../jobseeker_main_wrapper/views/main_wrapper_view.dart';
import 'widgets/job_header_card.dart';
import 'widgets/job_section_card.dart';
import 'widgets/action_buttons.dart';

class JobSeekerJobDetailsView extends GetView<JobSeekerJobDetailsController> {
  const JobSeekerJobDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final job = controller.job.value;

      if (job == null) {
        return Scaffold(
          backgroundColor: const Color(0xffF5F7FA),
          body: Center(child: CircularProgressIndicator(color: AppColor.kblue)),
        );
      }

      return Scaffold(
        backgroundColor: const Color(0xffF5F7FA),
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const JobHeaderCard(),
                      const SizedBox(height: 16),
                      _buildDescriptionCard(),
                      const SizedBox(height: 16),
                      _buildRequirementsCard(),
                      const SizedBox(height: 28),
                      const ApplyButton(),
                      const SizedBox(height: 12),
                      const AnalyzeCvButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const MainBottomNavBar(navigateToWrapper: true),
      );
    });
  }

  Widget _buildAppBar() {
    return Container(
      height: 68,
      width: double.infinity,
      color: AppColor.kblue,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          GestureDetector(
            onTap: Get.back,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColor.kwhite,
              size: 20,
            ),
          ),
          Expanded(
            child: Text(
              'Job Description',
              textAlign: TextAlign.center,
              style: CustomTextstyle.poppinsSemiBoldWhite.copyWith(
                fontSize: 18,
                color: AppColor.kwhite,
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    final job = controller.job.value!;

    return JobSectionCard(
      title: 'Job Description',
      child: JobSectionCard.sectionText(
        job.description.isNotEmpty
            ? job.description
            : 'No job description available.',
      ),
    );
  }

  Widget _buildRequirementsCard() {
    final job = controller.job.value!;

    final requirementsText = job.requirements.isNotEmpty
        ? job.requirements
        : 'No requirements added for this job.';

    return JobSectionCard(
      title: 'Requirements and Skills',
      child: JobSectionCard.requirementsText(requirementsText),
    );
  }
}
