import 'package:flutter/material.dart';

import '../../../../../../core/utils/app_color.dart';
import '../../controllers/company_dashboard_controller.dart';
import 'empty_card.dart';

class RecentApplicantsList extends StatelessWidget {
  final List<CompanyRecentApplicant> applicants;
  final String Function(dynamic) formatDate;

  const RecentApplicantsList({
    super.key,
    required this.applicants,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    if (applicants.isEmpty) {
      return const EmptyCard(
        icon: Icons.groups_outlined,
        title: 'No applicants yet',
        subtitle: 'New applicants will appear here.',
      );
    }

    return Column(
      children: applicants.map((applicant) => _ApplicantCard(
        applicant: applicant,
        formatDate: formatDate,
      )).toList(),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  final CompanyRecentApplicant applicant;
  final String Function(dynamic) formatDate;

  const _ApplicantCard({
    required this.applicant,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          _Avatar(imageUrl: applicant.imageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    applicant.applicantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColor.kblack,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.work_outline_rounded,
                        color: AppColor.kblue,
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          applicant.jobTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColor.greyLight,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: AppColor.kblue,
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          applicant.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColor.greyLight,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w400,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 42,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatDate(applicant.createdAt),
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: AppColor.greyLight,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColor.greyLight,
                  size: 13,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String imageUrl;
  const _Avatar({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xffDEE8F8),
          borderRadius: BorderRadius.circular(27),
        ),
        child: Icon(Icons.person_rounded, color: AppColor.kblue, size: 29),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(27),
      child: Image.network(
        imageUrl,
        width: 54,
        height: 54,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xffDEE8F8),
              borderRadius: BorderRadius.circular(27),
            ),
            child: Icon(Icons.person_rounded, color: AppColor.kblue, size: 29),
          );
        },
      ),
    );
  }
}
