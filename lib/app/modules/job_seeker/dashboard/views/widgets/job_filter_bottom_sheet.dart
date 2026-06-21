import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hire_me/app/modules/job_seeker/dashboard/views/widgets/filter_section_widget.dart';
import 'package:hire_me/core/utils/app_color.dart';
import 'package:hire_me/core/utils/app_text_style.dart';

import '../../controllers/job_seeker_dashboard_controller.dart';

class JobFilterBottomSheet extends GetView<JobSeekerDashboardController> {
  JobFilterBottomSheet({super.key});

  final _minSalaryCtrl = TextEditingController();
  final _maxSalaryCtrl = TextEditingController();

  static void show() {
    Get.bottomSheet(
      JobFilterBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    _minSalaryCtrl.text = controller.salaryMin.value;
    _maxSalaryCtrl.text = controller.salaryMax.value;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.84,
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Obx(
        () => SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BottomSheetHandle(),

                const SizedBox(height: 22),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Jobs',
                      style: CustomTextstyle.poppinsBold.copyWith(fontSize: 20),
                    ),
                    GestureDetector(
                      onTap: controller.clearFilters,
                      child: Text(
                        'Clear All',
                        style: TextStyle(
                          color: AppColor.kblue,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                FieldFilterSectionWidget(
                  title: 'Category',
                  items: controller.mainFields,
                  selectedValue: controller.selectedMainFieldId.value,
                  onAllTap: () => controller.selectMainField('all'),
                  onItemTap: controller.selectMainField,
                ),

                if (controller.selectedMainFieldId.value != 'all' &&
                    controller.subFields.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  FieldFilterSectionWidget(
                    title: 'Specialization',
                    items: controller.subFields,
                    selectedValue: controller.selectedSubFieldId.value,
                    onAllTap: () => controller.selectSubField('all'),
                    onItemTap: controller.selectSubField,
                  ),
                ],

                const SizedBox(height: 22),

                FilterSectionWidget(
                  title: 'Job Type',
                  items: controller.jobTypes,
                  selectedValue: controller.selectedJobType.value,
                  onItemTap: controller.setJobTypeFilter,
                ),

                const SizedBox(height: 22),

                FilterSectionWidget(
                  title: 'Work Mode',
                  items: controller.workModes,
                  selectedValue: controller.selectedWorkMode.value,
                  onItemTap: controller.setWorkModeFilter,
                ),

                const SizedBox(height: 22),

                FilterSectionWidget(
                  title: 'Location',
                  items: controller.locations,
                  selectedValue: controller.selectedLocation.value,
                  onItemTap: controller.setLocationFilter,
                ),

                const SizedBox(height: 22),

                _buildSalarySection(),

                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _minSalaryCtrl.clear();
                          _maxSalaryCtrl.clear();
                          controller.clearFilters();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColor.kblue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Clear',
                          style: TextStyle(color: AppColor.kblue),
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          controller.setSalaryMin(_minSalaryCtrl.text);
                          controller.setSalaryMax(_maxSalaryCtrl.text);
                          controller.applyFilters();
                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.kblue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Apply',
                          style: TextStyle(color: AppColor.kwhite),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSalarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Salary Range',
          style: CustomTextstyle.poppinsSemiBold.copyWith(
            fontSize: 14,
            color: AppColor.eblack,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minSalaryCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Min',
                  hintStyle: const TextStyle(
                    color: Color(0xFF8A8A9A),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColor.kblue, width: 1.8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('—', style: TextStyle(fontSize: 16)),
            ),
            Expanded(
              child: TextField(
                controller: _maxSalaryCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Max',
                  hintStyle: const TextStyle(
                    color: Color(0xFF8A8A9A),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColor.kblue, width: 1.8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
