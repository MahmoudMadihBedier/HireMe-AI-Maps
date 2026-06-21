import 'package:flutter/material.dart';
import 'package:hire_me/core/utils/app_color.dart';
import 'package:hire_me/app/modules/job_seeker/dashboard/views/widgets/job_card_widget.dart';
import 'package:hire_me/app/modules/job_seeker/dashboard/models/job_model.dart';

class RecommendedJobCard extends StatelessWidget {
  final JobModel job;
  final bool isSaved;
  final VoidCallback onSaveTap;
  final double? distance;
  final int matchPercentage;
  final List<String> reasons;

  const RecommendedJobCard({
    super.key,
    required this.job,
    required this.isSaved,
    required this.onSaveTap,
    this.distance,
    required this.matchPercentage,
    required this.reasons,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColor.kshadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Stack(
              children: [
                JobCardWidget(
                  job: job,
                  isSaved: isSaved,
                  onSaveTap: onSaveTap,
                  distance: distance,
                ),
                Positioned(
                  top: 16,
                  right: 56,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _matchColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          '$matchPercentage%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (reasons.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(19, 0, 19, 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColor.kblue.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: reasons.map((reason) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColor.kblue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      reason,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColor.kblue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Color get _matchColor {
    if (matchPercentage >= 80) return Colors.green;
    if (matchPercentage >= 60) return Colors.orange;
    return Colors.grey;
  }
}
