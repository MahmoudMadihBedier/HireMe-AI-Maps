import 'package:flutter/material.dart';

import '../../../../../../core/utils/app_color.dart';

class QuickActions extends StatelessWidget {
  final VoidCallback onPostJob;
  final VoidCallback onMyJobs;

  const QuickActions({
    super.key,
    required this.onPostJob,
    required this.onMyJobs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _actionButton(
          icon: Icons.add_rounded,
          title: 'Post a Job',
          onTap: onPostJob,
        )),
        const SizedBox(width: 10),
        Expanded(child: _actionButton(
          icon: Icons.list_alt_rounded,
          title: 'My Jobs',
          onTap: onMyJobs,
        )),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
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
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColor.kblue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColor.kblue, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColor.kblack,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
