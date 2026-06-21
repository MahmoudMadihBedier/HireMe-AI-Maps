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
    return Stack(
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
        if (reasons.isNotEmpty)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
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
    );
  }

  Color get _matchColor {
    if (matchPercentage >= 80) return Colors.green;
    if (matchPercentage >= 60) return Colors.orange;
    return Colors.grey;
  }
}
