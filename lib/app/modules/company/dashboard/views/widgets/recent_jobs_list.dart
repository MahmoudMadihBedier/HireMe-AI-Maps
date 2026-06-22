import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../../core/utils/app_color.dart';
import '../../controllers/company_dashboard_controller.dart';
import 'empty_card.dart';

class RecentJobsList extends StatelessWidget {
  final List<CompanyRecentJob> jobs;

  const RecentJobsList({super.key, required this.jobs});

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return const EmptyCard(
        icon: Icons.work_outline_rounded,
        title: 'No posted jobs yet',
        subtitle: 'Your latest posted jobs will appear here.',
      );
    }

    return Column(
      children: jobs.map((job) => _JobCard(job: job)).toList(),
    );
  }
}

class _JobCard extends StatelessWidget {
  final CompanyRecentJob job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final isOpen = job.status.toLowerCase() == 'open';

    return Container(
      height: 72,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColor.kwhite,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColor.kblack.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _JobFieldLogo(job: job),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  job.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColor.kblack,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: AppColor.kblue,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        job.location.isEmpty ? 'No location' : job.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColor.greyLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.groups_outlined,
                      color: AppColor.kblue,
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${job.applicantCount}',
                      style: TextStyle(
                        color: AppColor.greyLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: isOpen ? const Color(0xffE8F7EE) : const Color(0xffF1F1F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              job.status,
              style: TextStyle(
                color: isOpen ? const Color(0xff1E9E55) : AppColor.greyLight,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobFieldLogo extends StatelessWidget {
  final CompanyRecentJob job;
  const _JobFieldLogo({required this.job});

  @override
  Widget build(BuildContext context) {
    final iconUrl = job.subFieldIconUrl.isNotEmpty
        ? job.subFieldIconUrl
        : job.mainFieldIconUrl;

    return Container(
      width: 46,
      height: 46,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AppColor.kblue.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: iconUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: iconUrl,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) {
                  return Icon(
                    Icons.work_outline_rounded,
                    color: AppColor.kblue,
                    size: 24,
                  );
                },
              )
            : Icon(Icons.work_outline_rounded, color: AppColor.kblue, size: 24),
      ),
    );
  }
}
