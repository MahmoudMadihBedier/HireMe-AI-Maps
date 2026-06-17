import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hire_me/core/utils/app_color.dart';
import 'package:hire_me/core/utils/app_text_style.dart';
import 'package:hire_me/app/modules/job_seeker/job_details/controllers/job_seeker_job_details_controller.dart';

class JobHeaderCard extends GetView<JobSeekerJobDetailsController> {
  const JobHeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    final job = controller.job.value!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: AppColor.kwhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColor.eblack.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLogoBox(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CustomTextstyle.poppinsSemiBold.copyWith(
                        fontSize: 16,
                        color: AppColor.eblack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColor.greydark,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _locationRow(),
                    _distanceRow(),
                    const SizedBox(height: 8),
                    Text(
                      job.salary.trim().isNotEmpty
                          ? job.salary.trim()
                          : 'Salary not specified',
                      style: TextStyle(
                        color: AppColor.kblue,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Obx(
                () => IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: controller.toggleSaveJob,
                  icon: Icon(
                    controller.isSaved.value
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: AppColor.kblue,
                    size: 27,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _badge(
                controller.formatJobType(job.jobType),
                isPrimary: false,
              ),
              const SizedBox(width: 10),
              _badge(_formatWorkMode(job.workMode), isPrimary: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _locationRow() {
    final job = controller.job.value!;

    return Row(
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 15,
          color: Colors.green.shade600,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            job.location.isNotEmpty ? job.location : 'Not specified',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColor.greydark,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _distanceRow() {
    return Obx(() {
      final d = controller.jobDistance.value;
      if (d == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            const Text('📏', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              '$d km away',
              style: TextStyle(
                color: AppColor.greydark,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _fieldLogoBox() {
    final job = controller.job.value!;
    final iconUrl = job.subFieldIconUrl.isNotEmpty
        ? job.subFieldIconUrl
        : job.mainFieldIconUrl;

    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AppColor.kblue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: iconUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: iconUrl,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Icon(
                  Icons.work_outline_rounded,
                  color: AppColor.kblue,
                  size: 30,
                ),
              )
            : Icon(Icons.work_outline_rounded, color: AppColor.kblue, size: 30),
      ),
    );
  }

  Widget _badge(String text, {required bool isPrimary}) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isPrimary ? AppColor.kblue : AppColor.kwhite,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColor.kblue, width: 1),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isPrimary ? AppColor.kwhite : AppColor.kblue,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _formatWorkMode(String value) {
    switch (value) {
      case 'OnSite':
        return 'On Site';
      case 'Remote':
        return 'Remote';
      case 'Hybrid':
        return 'Hybrid';
      default:
        return value.isEmpty ? 'Not specified' : value;
    }
  }
}
