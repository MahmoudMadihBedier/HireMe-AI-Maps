import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_color.dart';
import '../../../../routes/app_pages.dart';
import '../../application_list/controllers/application_list_controller.dart';
import '../../company_main_wrapper/controllers/company_main_wrapper_controller.dart';
import '../controllers/company_dashboard_controller.dart';
import 'widgets/analytics_section.dart';
import 'widgets/quick_actions.dart';
import 'widgets/recent_applicants_list.dart';
import 'widgets/recent_jobs_list.dart';
import 'widgets/section_header.dart';
import 'widgets/welcome_card.dart';

class CompanyDashboardView extends GetView<CompanyDashboardController> {
  const CompanyDashboardView({super.key});

  void _goToPostedJobs() {
    if (Get.isRegistered<ApplicationListController>()) {
      Get.find<ApplicationListController>().switchTab('jobs');
    }

    if (Get.isRegistered<CompanyMainWrapperController>()) {
      Get.find<CompanyMainWrapperController>().changePage(0);
    }
  }

  void _goToApplicants() {
    if (Get.isRegistered<ApplicationListController>()) {
      Get.find<ApplicationListController>().switchTab('applications');
    }

    if (Get.isRegistered<CompanyMainWrapperController>()) {
      Get.find<CompanyMainWrapperController>().changePage(0);
    }
  }

  void _goToPostJob() {
    if (Get.isRegistered<CompanyMainWrapperController>()) {
      Get.find<CompanyMainWrapperController>().goToPostJob();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        backgroundColor: AppColor.kblue,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'Dashboard',
          style: TextStyle(
            color: AppColor.kwhite,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Obx(
            () => Badge(
              isLabelVisible: controller.unreadCount > 0,
              label: Text('${controller.unreadCount}'),
              textStyle: const TextStyle(color: Colors.white, fontSize: 10),
              textColor: Colors.white,
              backgroundColor: Colors.red,
              smallSize: 18,
              child: GestureDetector(
                onTap: () => Get.toNamed(Routes.companyNotifications),
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: AppColor.kwhite,
                  size: 26,
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: AppColor.kblue),
          );
        }

        return RefreshIndicator(
          color: AppColor.kblue,
          onRefresh: controller.refreshDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const WelcomeCard(),
                const SizedBox(height: 12),
                QuickActions(
                  onPostJob: _goToPostJob,
                  onMyJobs: _goToPostedJobs,
                ),
                const SizedBox(height: 16),
                AnalyticsSection(controller: controller),
                const SizedBox(height: 16),
                SectionHeader(
                  title: 'Recent Posted Jobs',
                  onMoreTap: _goToPostedJobs,
                ),
                const SizedBox(height: 12),
                RecentJobsList(jobs: controller.recentJobs),
                const SizedBox(height: 16),
                SectionHeader(
                  title: 'Recent Applicants',
                  onMoreTap: _goToApplicants,
                ),
                const SizedBox(height: 12),
                RecentApplicantsList(
                  applicants: controller.recentApplicants,
                  formatDate: controller.formatDate,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
