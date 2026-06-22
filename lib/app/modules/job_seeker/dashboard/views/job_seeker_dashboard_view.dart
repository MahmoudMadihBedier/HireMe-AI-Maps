import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hire_me/app/modules/job_seeker/dashboard/controllers/job_seeker_dashboard_controller.dart';
import 'package:hire_me/app/modules/job_seeker/dashboard/views/widgets/header_widget.dart';
import 'package:hire_me/app/modules/job_seeker/dashboard/views/widgets/job_card_widget.dart';
import 'package:hire_me/app/modules/job_seeker/dashboard/views/widgets/job_filter_bottom_sheet.dart';
import 'package:hire_me/app/modules/job_seeker/dashboard/views/widgets/main_fields_widget.dart';
import 'package:hire_me/app/modules/job_seeker/dashboard/views/widgets/search_widget.dart';
import 'package:hire_me/app/modules/job_seeker/dashboard/views/widgets/sub_fields_widget.dart';
import 'package:hire_me/app/modules/job_seeker/recommendations/views/recommendations_view.dart';
import 'package:hire_me/core/utils/app_color.dart';
import 'package:hire_me/core/utils/app_text_style.dart';

class JobSeekerDashboardView extends GetView<JobSeekerDashboardController> {
  const JobSeekerDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refreshDashboard,
          color: AppColor.kblue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HeaderWidget(),

                Transform.translate(
                  offset: const Offset(0, -28),
                  child: SearchFilterWidget(
                    searchController: controller.searchTextController,
                    onChanged: controller.onSearch,
                    onFilterTap: JobFilterBottomSheet.show,
                  ),
                ),

                const MainFieldsWidget(),

                const SubFieldsWidget(),

                // ─── Tab bar ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(25, 12, 25, 4),
                  child: Obx(
                    () => Row(
                      children: [
                        _buildTabChip('All Jobs', 'all'),
                        const SizedBox(width: 10),
                        _buildTabChip('Recommended', 'recommended'),
                      ],
                    ),
                  ),
                ),

                // ─── Content ─────────────────────────────
                Obx(() {
                  if (controller.selectedDashboardTab.value ==
                      'recommended') {
                    return const RecommendationsView();
                  }

                  // 'all' tab
                  if (controller.isLoading.value) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${controller.filteredJobs.length} Jobs Found',
                              style: CustomTextstyle.poppinsSemiBold.copyWith(
                                fontSize: 13,
                                color: AppColor.greyLight,
                              ),
                            ),
                            Row(
                              children: [
                                Obx(
                                  () => GestureDetector(
                                    onTap: controller.toggleSortByDistance,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: controller.sortByDistance.value
                                            ? AppColor.kblue
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppColor.kblue,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        'Nearest',
                                        style: TextStyle(
                                          color:
                                              controller.sortByDistance.value
                                                  ? AppColor.kwhite
                                                  : AppColor.kblue,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: controller.clearFilters,
                                  child: Text(
                                    'Clear',
                                    style: TextStyle(
                                      color: AppColor.kblue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      if (controller.filteredJobs.isEmpty)
                        _buildEmptyState()
                      else
                        _buildJobList(),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabChip(String label, String value) {
    final isSelected = controller.selectedDashboardTab.value == value;
    return GestureDetector(
      onTap: () => controller.selectDashboardTab(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.kblue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColor.kblue),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColor.kwhite : AppColor.kblue,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildJobList() {
    final displayJobs = controller.filteredJobs.take(
      controller.displayCount.value,
    ).toList();

    final hasMore = controller.filteredJobs.length >
        controller.displayCount.value;

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          itemCount: displayJobs.length,
          itemBuilder: (context, index) {
            final job = displayJobs[index];

            return Obx(
              () => JobCardWidget(
                job: job,
                isSaved: controller.isJobSaved(job.id),
                onSaveTap: () => controller.toggleSaveJob(job.id),
                distance: controller.jobDistances[job.companyId],
              ),
            );
          },
        ),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: TextButton(
              onPressed: controller.loadMore,
              child: Text(
                'Load More (${controller.filteredJobs.length - controller.displayCount.value} remaining)',
                style: TextStyle(
                  color: AppColor.kblue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 78, color: AppColor.greyLight),
            const SizedBox(height: 12),
            Text(
              'No jobs found',
              style: CustomTextstyle.poppins500Grey.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Try changing the search or filters',
              style: TextStyle(color: AppColor.greyLight, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
